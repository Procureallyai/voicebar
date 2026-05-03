import AVFoundation
import Foundation
import OSLog

public protocol AudioChunkPlayer: Sendable {
    func enqueue(_ chunk: SpeechChunk) async throws
    func pause() async
    func resume() async
    func stop() async
    func waitUntilDrained() async
    func isPaused() async -> Bool
}

package enum AudioChunkPlayerPrebufferPolicy {
    package static func nextBufferDuration(
        currentBufferDuration: TimeInterval?,
        bufferThresholdMet: Bool,
        incomingChunk: SpeechChunk
    ) -> TimeInterval? {
        guard let prebufferLeadDuration = incomingChunk.prebufferLeadDuration else {
            return nil
        }

        // Adaptive buffering should only grow while the initial prebuffer is
        // still accumulating. Once the first flush has happened, later hints
        // belong to the same continuous segment and must not re-arm buffering.
        guard bufferThresholdMet == false else {
            return nil
        }

        return max(currentBufferDuration ?? 0, prebufferLeadDuration)
    }
}

public actor AVAudioChunkPlayer: AudioChunkPlayer {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private var sampleRate: Int?
    private var pendingPlaybackCount = 0
    private var paused = false
    private var pauseStartedAt: CFAbsoluteTime?
    private var drainContinuations: [CheckedContinuation<Void, Never>] = []
    private var bufferDuration: TimeInterval?
    // Pending frames are the next contiguous slice of audio that still needs
    // enough lead time before we hand it to CoreAudio.
    private var pendingFrames: [[Float]] = []
    private var pendingDuration: TimeInterval = 0
    private var bufferThresholdMet = false
    // `tailFrame` is only used when a buffering run is explicitly draining.
    // Keeping live speech packets unscheduled until a future callback arrives
    // caused the exact mid-read cut-outs the operator reported on this Mac.
    private var tailFrame: [Float]?
    private var needsFadeIn = true
    private var expectedPlaybackEnd: CFAbsoluteTime = 0

    private static let fadeLengthSamples = 256
    private static let logger = Logger(
        subsystem: "ai.procureally.voicebar",
        category: "AudioChunkPlayer"
    )

    public init() {}

    public func enqueue(_ chunk: SpeechChunk) async throws {
        guard
            chunk.audioSamples.isEmpty == false,
            let chunkSampleRate = chunk.sampleRate
        else {
            return
        }

        try ensureEngine(sampleRate: chunkSampleRate)

        if let nextBufferDuration = AudioChunkPlayerPrebufferPolicy.nextBufferDuration(
            currentBufferDuration: bufferDuration,
            bufferThresholdMet: bufferThresholdMet,
            incomingChunk: chunk
        ),
            nextBufferDuration != bufferDuration
        {
            setBufferDuration(nextBufferDuration)
        }

        try enqueueAudioChunk(chunk.audioSamples)
    }

    public func pause() async {
        guard let playerNode else {
            return
        }

        playerNode.pause()
        paused = true
        pauseStartedAt = CFAbsoluteTimeGetCurrent()
    }

    public func resume() async {
        guard let playerNode else {
            return
        }

        if let pauseStartedAt {
            expectedPlaybackEnd += CFAbsoluteTimeGetCurrent() - pauseStartedAt
            self.pauseStartedAt = nil
        }

        playerNode.play()
        paused = false
    }

    public func stop() async {
        pendingPlaybackCount = 0
        pendingFrames.removeAll()
        pendingDuration = 0
        bufferThresholdMet = false
        bufferDuration = nil
        tailFrame = nil
        needsFadeIn = true
        expectedPlaybackEnd = 0
        resumeDrainContinuations()
        playerNode?.stop()
        audioEngine?.stop()
        playerNode = nil
        audioEngine = nil
        audioFormat = nil
        sampleRate = nil
        paused = false
        pauseStartedAt = nil
    }

    public func waitUntilDrained() async {
        do {
            try flushPendingFrames()
        } catch {
            Self.logger.error(
                "Failed to flush pending frames while draining playback: \(error.localizedDescription, privacy: .public)"
            )
        }

        do {
            try commitTailFrameForDrain()
        } catch {
            Self.logger.error(
                "Failed to commit the tail frame while draining playback: \(error.localizedDescription, privacy: .public)"
            )
        }

        guard pendingPlaybackCount > 0 else {
            return
        }

        await withCheckedContinuation { continuation in
            drainContinuations.append(continuation)
        }
    }

    public func isPaused() async -> Bool {
        paused
    }

    private func ensureEngine(sampleRate: Int) throws {
        if let existingSampleRate = self.sampleRate, existingSampleRate != sampleRate {
            // Once we discard the old engine for a new sample rate, any
            // waiters must be released because the old buffers will not finish
            // on the new playback path.
            pendingPlaybackCount = 0
            pendingFrames.removeAll()
            pendingDuration = 0
            bufferThresholdMet = false
            bufferDuration = nil
            tailFrame = nil
            needsFadeIn = true
            expectedPlaybackEnd = 0
            resumeDrainContinuations()
            playerNode?.stop()
            audioEngine?.stop()
            playerNode = nil
            audioEngine = nil
            audioFormat = nil
            self.sampleRate = nil
            paused = false
            pauseStartedAt = nil
        }

        if audioEngine != nil, playerNode != nil {
            return
        }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(sampleRate),
            channels: 1,
            interleaved: false
        ) else {
            throw SpeechPlaybackError.playbackFailed("VoiceBar could not create a playback format for \(sampleRate)Hz audio.")
        }

        let audioEngine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

        try audioEngine.start()
        playerNode.play()

        self.audioEngine = audioEngine
        self.playerNode = playerNode
        self.audioFormat = format
        self.sampleRate = sampleRate
        self.bufferThresholdMet = false
    }

    private func setBufferDuration(_ seconds: TimeInterval) {
        let duration = max(0, seconds)
        bufferDuration = duration

        // Close out the prior contiguous run before a new segment changes the
        // buffering target. This keeps boundary fades aligned with the actual
        // buffering transitions instead of smearing them across segments.
        if let tailFrame {
            do {
                try schedule(
                    samples: tailFrame,
                    fadeIn: needsFadeIn,
                    fadeOut: true
                )
                needsFadeIn = true
                self.tailFrame = nil
            } catch {
                Self.logger.error(
                    "Failed to commit the prior tail frame while re-arming buffering: \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        if duration == 0 {
            bufferThresholdMet = true
            do {
                try flushPendingFrames()
            } catch {
                Self.logger.error(
                    "Failed to flush pending frames after switching to immediate playback: \(error.localizedDescription, privacy: .public)"
                )
            }
        } else {
            bufferThresholdMet = false
            if pendingDuration >= duration {
                do {
                    try flushPendingFrames()
                } catch {
                    Self.logger.error(
                        "Failed to flush pending frames after updating the prebuffer target: \(error.localizedDescription, privacy: .public)"
                    )
                }
            }
        }
    }

    private func enqueueAudioChunk(_ samples: [Float]) throws {
        if bufferThresholdMet {
            let playerDrained = paused == false && CFAbsoluteTimeGetCurrent() > expectedPlaybackEnd

            if playerDrained {
                needsFadeIn = true
            }

            // Once the initial prebuffer has been satisfied, schedule each new
            // speech packet immediately. Retaining the newest live packet until
            // the *next* callback arrived introduced operator-heard cut-outs
            // whenever model generation briefly lagged behind playback.
            try schedule(
                samples: samples,
                fadeIn: needsFadeIn,
                fadeOut: false
            )
            needsFadeIn = false
            tailFrame = nil
            return
        }

        pendingFrames.append(samples)
        pendingDuration += duration(for: samples)

        if let bufferDuration, pendingDuration >= bufferDuration {
            try flushPendingFrames()
        }
    }

    private func flushPendingFrames() throws {
        guard pendingFrames.isEmpty == false else {
            bufferThresholdMet = true
            return
        }

        // If the first flush only has one packet, play it immediately instead
        // of waiting for a second callback and adding a fake startup stall.
        if pendingFrames.count == 1 {
            try schedule(
                samples: pendingFrames[0],
                fadeIn: needsFadeIn,
                fadeOut: false
            )
            needsFadeIn = false
            pendingFrames.removeAll()
            pendingDuration = 0
            bufferThresholdMet = true
            tailFrame = nil
            return
        }

        var lastScheduledIndex: Int?

        for index in pendingFrames.indices {
            let needsInitialFade = index == 0 && needsFadeIn
            do {
                try schedule(
                    samples: pendingFrames[index],
                    fadeIn: needsInitialFade,
                    fadeOut: false
                )
                lastScheduledIndex = index
            } catch {
                if let lastScheduledIndex {
                    let unscheduledStart = lastScheduledIndex + 1
                    let remainingFrames = Array(pendingFrames[unscheduledStart...])
                    pendingFrames = remainingFrames
                    pendingDuration = remainingFrames.reduce(into: 0) { partialResult, frame in
                        partialResult += duration(for: frame)
                    }
                }
                bufferThresholdMet = false
                throw error
            }

            if needsInitialFade {
                needsFadeIn = false
            }
        }

        tailFrame = nil
        pendingFrames.removeAll()
        pendingDuration = 0
        bufferThresholdMet = true
    }

    private func commitTailFrameForDrain() throws {
        guard let tailFrame else {
            return
        }

        try schedule(
            samples: tailFrame,
            fadeIn: needsFadeIn,
            fadeOut: true
        )
        self.tailFrame = nil
        needsFadeIn = false
    }

    private func schedule(
        samples: [Float],
        fadeIn: Bool,
        fadeOut: Bool
    ) throws {
        guard let playerNode, let audioFormat else {
            throw SpeechPlaybackError.playbackFailed("VoiceBar could not configure the audio output.")
        }

        // Capture the actor reference as an immutable local so the completion
        // callback does not capture actor-isolated `self` directly.
        let owner = self

        let frameCount = AVAudioFrameCount(samples.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            throw SpeechPlaybackError.playbackFailed("VoiceBar could not allocate an audio buffer.")
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData else {
            throw SpeechPlaybackError.playbackFailed("VoiceBar could not access audio buffer channel data.")
        }

        samples.withUnsafeBufferPointer { sourceBuffer in
            guard let sourceBaseAddress = sourceBuffer.baseAddress else {
                return
            }

            channelData[0].update(from: sourceBaseAddress, count: samples.count)
        }

        if fadeIn || fadeOut {
            let fadeLength = min(Self.fadeLengthSamples, samples.count / 2)

            if fadeLength > 0 {
                let fadeData = channelData[0]
                let inverseFadeLength = 1.0 / Float(fadeLength)

                if fadeIn {
                    for index in 0..<fadeLength {
                        fadeData[index] *= Float(index) * inverseFadeLength
                    }
                }

                if fadeOut {
                    let fadeOutStart = samples.count - fadeLength

                    for index in 0..<fadeLength {
                        fadeData[fadeOutStart + index] *= Float(fadeLength - index) * inverseFadeLength
                    }
                }
            }
        }

        let isFirstScheduledBuffer = pendingPlaybackCount == 0
        pendingPlaybackCount += 1
        expectedPlaybackEnd = max(expectedPlaybackEnd, CFAbsoluteTimeGetCurrent()) + duration(for: samples)

        if isFirstScheduledBuffer {
            Self.logger.info(
                "Scheduled the first output buffer after prebuffering \(self.duration(for: samples), privacy: .public)s of audio."
            )
        }

        playerNode.scheduleBuffer(
            buffer,
            completionCallbackType: .dataPlayedBack
        ) { _ in
            Task {
                await owner.didFinishBufferPlayback()
            }
        }

        if paused == false {
            playerNode.play()
        }
    }

    private func duration(for samples: [Float]) -> TimeInterval {
        guard let sampleRate else {
            return 0
        }

        return Double(samples.count) / Double(sampleRate)
    }

    private func didFinishBufferPlayback() {
        pendingPlaybackCount = max(0, pendingPlaybackCount - 1)

        if pendingPlaybackCount == 0 {
            resumeDrainContinuations()
        }
    }

    private func resumeDrainContinuations() {
        let continuations = drainContinuations
        drainContinuations.removeAll()
        continuations.forEach { $0.resume() }
    }
}
