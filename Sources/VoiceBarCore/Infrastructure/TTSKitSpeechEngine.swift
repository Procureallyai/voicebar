import CoreML
import Foundation
import Hub
import TTSKit

private enum VoiceBarPlaybackTuning {
    // Keep live segments large enough to avoid sentence-by-sentence churn,
    // while still capping each prebuffer so startup remains interactive.
    static let maximumAdaptivePrebufferDuration: TimeInterval = 12.0
    // Pin the Qwen/TTSKit buffer floor locally so VoiceBar's behavior stays
    // reviewable even if the dependency changes its default in a later update.
    static let minimumAdaptivePrebufferDuration: TimeInterval = 0.08
    static let estimatedWordsPerSecond: Double = 2.2
    static let maximumWordsPerStreamingSegment: Int = 24
    static let premiumLongFormWordThreshold = 28
    static let premiumLongFormDeficitRatio = 0.45
    // Emit roughly 1 second of audio at a time so the live player keeps a
    // healthier queued lead on the operator's M1 Max during long-form reads.
    static let minimumEmissionChunkDuration: TimeInterval = 0.96
}

private actor TTSKitSpeechEngineState {
    private let identifier: String
    private let downloadBaseURL: URL
    private var runtimeSnapshot: SpeechEngineRuntimeSnapshot
    private var speechKit: TTSKit?

    init(identifier: String, downloadBaseURL: URL) {
        self.identifier = identifier
        self.downloadBaseURL = downloadBaseURL
        self.runtimeSnapshot = SpeechEngineRuntimeSnapshot(
            identifier: identifier,
            warmState: .cold
        )
    }

    func snapshot() -> SpeechEngineRuntimeSnapshot {
        runtimeSnapshot
    }

    func configuredSpeechKit(
        variant: TTSModelVariant,
        verbose: Bool
    ) async throws -> TTSKit {
        if let speechKit {
            return speechKit
        }

        // Keep the Hugging Face cache under VoiceBar's own Application Support
        // tree so model preparation does not trigger a separate Documents prompt.
        try VoiceBarStorageLocation.ensureDirectoryExists(at: downloadBaseURL)

        let configuration = TTSKitConfig(
            model: variant,
            downloadBase: downloadBaseURL,
            verbose: verbose
        )
        configuration.computeOptions = machineComputeOptions(for: variant)
        // The tokenizer repo is separate from the CoreML model repo, so point
        // TTSKit at a local tokenizer folder that lives under the same private
        // VoiceBar cache root instead of the Hub default Documents location.
        configuration.tokenizerFolder = try await resolveTokenizerFolder()
        configuration.load = false

        let speechKit = try await TTSKit(configuration)
        self.speechKit = speechKit
        return speechKit
    }

    func recordSuccessfulPrepare() {
        runtimeSnapshot.warmState = .warm
        runtimeSnapshot.lastFailureDescription = nil
    }

    func recordFailure(_ description: String) {
        runtimeSnapshot.lastFailureDescription = description
    }

    private func resolveTokenizerFolder() async throws -> URL {
        let tokenizerFolder = VoiceBarStorageLocation.ttsTokenizerRepoCacheURL
        let tokenizerJSONPath = tokenizerFolder
            .appendingPathComponent("tokenizer.json", isDirectory: false)
            .path

        if FileManager.default.fileExists(atPath: tokenizerJSONPath) {
            return tokenizerFolder
        }

        let hubApi = HubApi(downloadBase: downloadBaseURL)
        let repo = Hub.Repo(id: Qwen3TTSConstants.defaultTokenizerRepo, type: .models)

        return try await hubApi.snapshot(
            from: repo,
            matching: [
                "config.json",
                "tokenizer_config.json",
                "tokenizer.json",
                "chat_template.jinja",
                "chat_template.json"
            ]
        )
    }

    private func machineComputeOptions(for variant: TTSModelVariant) -> ComputeOptions {
        switch variant {
        case .qwen3TTS_1_7b:
            // Standalone TTSKit runs on this M1 Max reproduced a Premium-path
            // ANE/CoreML inference failure. Keep the heavier 1.7B decoder stack
            // on CPU+GPU so VoiceBar favors stability over an ANE path that is
            // currently failing on the operator machine.
            return ComputeOptions(
                embedderComputeUnits: .cpuOnly,
                codeDecoderComputeUnits: .cpuAndGPU,
                multiCodeDecoderComputeUnits: .cpuAndGPU,
                speechDecoderComputeUnits: .cpuAndGPU
            )
        case .qwen3TTS_0_6b:
            return ComputeOptions()
        }
    }
}

private final class ChunkEmissionState: @unchecked Sendable {
    private let lock = NSLock()
    private var nextSequenceNumber: Int
    private var hasYieldedTextForCurrentSegment = false
    private var hasYieldedAudioForCurrentSegment = false
    private var pendingAudioSamples: [Float] = []
    private var pendingSampleRate: Int?
    private var segmentPrebufferLeadDuration: TimeInterval?

    init(nextSequenceNumber: Int) {
        self.nextSequenceNumber = nextSequenceNumber
    }

    func emittedAudioForCurrentSegment() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return hasYieldedAudioForCurrentSegment
    }

    func appendAudioSamples(
        _ audioSamples: [Float],
        sampleRate: Int,
        segmentText: String,
        prebufferLeadDuration: TimeInterval?,
        minimumEmissionChunkDuration: TimeInterval
    ) -> SpeechChunk? {
        lock.lock()
        defer { lock.unlock() }

        guard audioSamples.isEmpty == false else {
            return nil
        }

        if pendingSampleRate == nil {
            pendingSampleRate = sampleRate
        }

        // Keep the largest lead estimate seen so far for this segment. Premium
        // often looks faster on its earliest decode steps than it does a few
        // seconds later on this M1 Max, so later hints must be able to grow
        // the initial buffer before the first flush commits playback.
        if let prebufferLeadDuration {
            if let existingLead = segmentPrebufferLeadDuration {
                segmentPrebufferLeadDuration = max(existingLead, prebufferLeadDuration)
            } else {
                segmentPrebufferLeadDuration = prebufferLeadDuration
            }
        }

        pendingAudioSamples.append(contentsOf: audioSamples)

        let bufferedDuration = Double(pendingAudioSamples.count) / Double(sampleRate)
        guard bufferedDuration >= minimumEmissionChunkDuration else {
            return nil
        }

        return emitPendingChunkLocked(for: segmentText)
    }

    func flushPendingAudioIfNeeded(for segmentText: String) -> SpeechChunk? {
        lock.lock()
        defer { lock.unlock() }

        guard pendingAudioSamples.isEmpty == false else {
            return nil
        }

        return emitPendingChunkLocked(for: segmentText)
    }

    func nextSequence() -> Int {
        lock.lock()
        defer { lock.unlock() }

        let sequenceNumber = nextSequenceNumber
        nextSequenceNumber += 1
        return sequenceNumber
    }

    private func emitPendingChunkLocked(for segmentText: String) -> SpeechChunk {
        let sequenceNumber = nextSequenceNumber
        let chunkText = hasYieldedTextForCurrentSegment ? "" : segmentText
        let audioSamples = pendingAudioSamples
        let sampleRate = pendingSampleRate
        let prebufferLeadDuration = segmentPrebufferLeadDuration

        hasYieldedTextForCurrentSegment = true
        hasYieldedAudioForCurrentSegment = true
        nextSequenceNumber += 1
        pendingAudioSamples.removeAll(keepingCapacity: true)
        pendingSampleRate = nil

        return SpeechChunk(
            textFragment: chunkText,
            sequenceNumber: sequenceNumber,
            audioSamples: audioSamples,
            sampleRate: sampleRate,
            prebufferLeadDuration: prebufferLeadDuration
        )
    }
}

open class TTSKitSpeechEngine: @unchecked Sendable, SpeechEngine {
    public let identifier: String
    public let downloadBaseURL: URL

    private let modelVariant: TTSModelVariant
    private let defaultSpeaker: Qwen3Speaker
    private let language: Qwen3Language
    private let supportsInstructionPrompt: Bool
    private let verboseLogging: Bool
    // Quick still uses grouped streaming slices, so the injected chunker stays
    // meaningful even though Premium now runs as one continuous session again.
    private let chunker: SpeechRequestChunker
    private let state: TTSKitSpeechEngineState
    private let synthesisTaskLock = NSLock()
    private var activeSynthesisID: UUID?
    private var activeSynthesisTask: Task<Void, Never>?

    public init(
        identifier: String,
        modelVariant: TTSModelVariant,
        speaker: Qwen3Speaker = .serena,
        language: Qwen3Language = .english,
        supportsInstructionPrompt: Bool,
        downloadBaseURL: URL = VoiceBarStorageLocation.ttsModelDownloadBaseURL,
        verboseLogging: Bool = false,
        chunker: SpeechRequestChunker = SpeechRequestChunker()
    ) {
        self.identifier = identifier
        self.downloadBaseURL = downloadBaseURL
        self.modelVariant = modelVariant
        self.defaultSpeaker = speaker
        self.language = language
        self.supportsInstructionPrompt = supportsInstructionPrompt
        self.verboseLogging = verboseLogging
        self.chunker = chunker
        self.state = TTSKitSpeechEngineState(
            identifier: identifier,
            downloadBaseURL: downloadBaseURL
        )
    }

    public var availability: SpeechEngineAvailability {
        get async {
            let snapshot = await state.snapshot()

            if let lastFailureDescription = snapshot.lastFailureDescription {
                return SpeechEngineAvailability(
                    isAvailable: false,
                    reason: lastFailureDescription
                )
            }

            return SpeechEngineAvailability(
                isAvailable: true,
                reason: snapshot.warmState == .warm
                    ? "Loaded and ready."
                    : "Configured for on-demand load. First use remains unverified on this machine until the model is prepared."
            )
        }
    }

    public var runtimeSnapshot: SpeechEngineRuntimeSnapshot {
        get async {
            await state.snapshot()
        }
    }

    public func prepare() async throws {
        let speechKit = try await state.configuredSpeechKit(
            variant: modelVariant,
            verbose: verboseLogging
        )

        guard speechKit.modelState != .loaded else {
            await state.recordSuccessfulPrepare()
            return
        }

        do {
            try await speechKit.loadModels()
            await state.recordSuccessfulPrepare()
        } catch {
            await state.recordFailure(describe(error))
            throw error
        }
    }

    public func synthesize(_ request: SpeechRequest) -> AsyncThrowingStream<SpeechChunk, Error> {
        return AsyncThrowingStream { continuation in
            let synthesisID = UUID()
            let synthesisTask = Task { [weak self] in
                do {
                    guard let self else {
                        continuation.finish()
                        return
                    }

                    try await self.prepare()
                    let speechKit = try await self.state.configuredSpeechKit(
                        variant: modelVariant,
                        verbose: verboseLogging
                    )

                    try Task.checkCancellation()

                    let streamText = request.text.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    guard streamText.isEmpty == false else {
                        continuation.finish()
                        return
                    }

                    let options = self.generationOptions(for: request)
                    let speaker = self.resolvedSpeaker(for: request)

                    if self.modelVariant == .qwen3TTS_1_7b {
                        let emissionState = ChunkEmissionState(nextSequenceNumber: 0)

                        _ = try await speechKit.generate(
                            text: streamText,
                            voice: speaker.rawValue,
                            language: language.rawValue,
                            options: options,
                            callback: { progress in
                                if Task.isCancelled {
                                    return false
                                }

                                guard progress.audio.isEmpty == false else {
                                    return true
                                }

                                let prebufferLeadDuration = self.prebufferLeadDuration(
                                    for: streamText,
                                    progress: progress,
                                    sampleRate: speechKit.sampleRate
                                )

                                if let batchedChunk = emissionState.appendAudioSamples(
                                    progress.audio,
                                    sampleRate: speechKit.sampleRate,
                                    segmentText: streamText,
                                    prebufferLeadDuration: prebufferLeadDuration,
                                    minimumEmissionChunkDuration: VoiceBarPlaybackTuning.minimumEmissionChunkDuration
                                ) {
                                    continuation.yield(batchedChunk)
                                }

                                return true
                            }
                        )

                        if let trailingChunk = emissionState.flushPendingAudioIfNeeded(for: streamText) {
                            continuation.yield(trailingChunk)
                        }
                    } else {
                        // Keep the smaller Quick model on grouped streaming
                        // slices so it can refresh its lead cheaply between
                        // segments without paying Premium-sized decode costs.
                        let groupedSegments = self.chunker.chunkForStreaming(streamText)
                        let segments = groupedSegments.isEmpty
                            ? [ChunkedSpeechSegment(text: streamText)]
                            : groupedSegments
                        var nextSequenceNumber = 0

                        for segment in segments {
                            try Task.checkCancellation()

                            let emissionState = ChunkEmissionState(
                                nextSequenceNumber: nextSequenceNumber
                            )

                            _ = try await speechKit.generate(
                                text: segment.text,
                                voice: speaker.rawValue,
                                language: language.rawValue,
                                options: options,
                                callback: { progress in
                                    if Task.isCancelled {
                                        return false
                                    }

                                    guard progress.audio.isEmpty == false else {
                                        return true
                                    }

                                    let prebufferLeadDuration = self.prebufferLeadDuration(
                                        for: segment.text,
                                        progress: progress,
                                        sampleRate: speechKit.sampleRate
                                    )

                                    if let batchedChunk = emissionState.appendAudioSamples(
                                        progress.audio,
                                        sampleRate: speechKit.sampleRate,
                                        segmentText: segment.text,
                                        prebufferLeadDuration: prebufferLeadDuration,
                                        minimumEmissionChunkDuration: VoiceBarPlaybackTuning.minimumEmissionChunkDuration
                                    ) {
                                        continuation.yield(batchedChunk)
                                    }

                                    return true
                                }
                            )

                            if let trailingChunk = emissionState.flushPendingAudioIfNeeded(for: segment.text) {
                                continuation.yield(trailingChunk)
                            }

                            nextSequenceNumber = emissionState.nextSequence()

                            if
                                segment.pauseAfterMilliseconds > 0,
                                emissionState.emittedAudioForCurrentSegment()
                            {
                                let pauseSamples = makePauseSamples(
                                    durationMilliseconds: segment.pauseAfterMilliseconds,
                                    sampleRate: speechKit.sampleRate
                                )

                                continuation.yield(
                                    SpeechChunk(
                                        textFragment: "",
                                        sequenceNumber: nextSequenceNumber,
                                        audioSamples: pauseSamples,
                                        sampleRate: speechKit.sampleRate,
                                        isParagraphPause: true
                                    )
                                )

                                nextSequenceNumber += 1
                            }
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    await self?.state.recordFailure(self?.describe(error) ?? error.localizedDescription)
                    continuation.finish(throwing: error)
                }

                self?.clearActiveSynthesisTask(id: synthesisID)
            }

            setActiveSynthesisTask(id: synthesisID, task: synthesisTask)
            continuation.onTermination = { [weak self] _ in
                synthesisTask.cancel()
                self?.clearActiveSynthesisTask(id: synthesisID)
            }
        }
    }

    public func stop() async {
        cancelActiveSynthesisTask()
    }

    public func prewarmPromptCache(
        voiceIdentifier: String?,
        styleInstruction: String?
    ) async throws {
        try await prepare()

        let speechKit = try await state.configuredSpeechKit(
            variant: modelVariant,
            verbose: verboseLogging
        )
        let speaker = resolvedSpeaker(for: voiceIdentifier)
        let instruction: String?

        if supportsInstructionPrompt {
            let trimmedInstruction = styleInstruction?.trimmingCharacters(in: .whitespacesAndNewlines)
            instruction = trimmedInstruction?.isEmpty == false ? trimmedInstruction : nil
        } else {
            instruction = nil
        }

        _ = try await speechKit.buildPromptCache(
            speaker: speaker,
            language: language,
            instruction: instruction
        )
        await state.recordSuccessfulPrepare()
    }

    private func generationOptions(for request: SpeechRequest) -> GenerationOptions {
        var options = GenerationOptions(
            concurrentWorkerCount: 1,
            // VoiceBar now owns the streaming groups above, so TTSKit itself
            // stays on single-segment generation for each grouped slice.
            chunkingStrategy: TextChunkingStrategy.none
        )

        if supportsInstructionPrompt {
            let trimmedInstruction = request.styleInstruction?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let trimmedInstruction, trimmedInstruction.isEmpty == false {
                options.instruction = trimmedInstruction
            }
        }

        return options
    }

    private func resolvedSpeaker(for request: SpeechRequest) -> Qwen3Speaker {
        resolvedSpeaker(for: request.voiceIdentifier)
    }

    private func resolvedSpeaker(for voiceIdentifier: String?) -> Qwen3Speaker {
        guard
            let voiceIdentifier,
            let speaker = Qwen3Speaker(
                rawValue: voiceIdentifier.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
        else {
            return defaultSpeaker
        }

        return speaker
    }

    private func makePauseSamples(
        durationMilliseconds: Int,
        sampleRate: Int
    ) -> [Float] {
        let sampleCount = max(1, Int((Double(durationMilliseconds) / 1000.0) * Double(sampleRate)))
        return Array(repeating: 0, count: sampleCount)
    }

    private func prebufferLeadDuration(
        for segmentText: String,
        progress: SpeechProgress,
        sampleRate: Int
    ) -> TimeInterval? {
        guard
            let stepTime = progress.stepTime,
            progress.audio.isEmpty == false
        else {
            return nil
        }

        let progressAudioDuration = Double(progress.audio.count) / Double(sampleRate)
        guard stepTime > 0, progressAudioDuration > 0 else {
            return VoiceBarPlaybackTuning.minimumAdaptivePrebufferDuration
        }

        let speedRatio = progressAudioDuration / stepTime
        let modelAudioPerStep = PlaybackStrategy.audioPerStep(
            samplesPerFrame: Qwen3TTSConstants.samplesPerFrame,
            sampleRate: sampleRate
        )
        let estimatedWordCount = max(
            1,
            segmentText.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        )
        let estimatedSpeechDuration = max(
            modelAudioPerStep,
            Double(estimatedWordCount) / VoiceBarPlaybackTuning.estimatedWordsPerSecond
        )
        let estimatedRemainingSteps = max(
            1,
            Int(ceil(estimatedSpeechDuration / modelAudioPerStep))
        )
        let requiredBuffer: TimeInterval
        if speedRatio < 1 {
            requiredBuffer = PlaybackStrategy.requiredBuffer(
                stepTime: stepTime,
                maxNewTokens: estimatedRemainingSteps,
                samplesPerFrame: Qwen3TTSConstants.samplesPerFrame,
                sampleRate: sampleRate
            )
        } else {
            requiredBuffer = VoiceBarPlaybackTuning.minimumAdaptivePrebufferDuration
        }

        var adaptivePrebuffer = min(
            max(
                requiredBuffer,
                VoiceBarPlaybackTuning.minimumAdaptivePrebufferDuration
            ),
            VoiceBarPlaybackTuning.maximumAdaptivePrebufferDuration
        )

        if
            modelVariant == .qwen3TTS_1_7b,
            estimatedWordCount >= VoiceBarPlaybackTuning.premiumLongFormWordThreshold
        {
            // Real bundled-app probes on this M1 Max show Premium long-form
            // generation landing below speech real-time once the first few
            // seconds have passed. Hold a deeper lead up front so Premium
            // chooses a longer startup over the operator-heard mid-read cutouts.
            let premiumLongFormFloor = min(
                estimatedSpeechDuration * VoiceBarPlaybackTuning.premiumLongFormDeficitRatio,
                VoiceBarPlaybackTuning.maximumAdaptivePrebufferDuration
            )
            adaptivePrebuffer = max(adaptivePrebuffer, premiumLongFormFloor)
        }

        return adaptivePrebuffer
    }

    private func describe(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return error.localizedDescription
    }

    private func setActiveSynthesisTask(
        id: UUID,
        task: Task<Void, Never>
    ) {
        synthesisTaskLock.lock()
        activeSynthesisTask?.cancel()
        activeSynthesisID = id
        activeSynthesisTask = task
        synthesisTaskLock.unlock()
    }

    private func clearActiveSynthesisTask(id: UUID) {
        synthesisTaskLock.lock()
        defer { synthesisTaskLock.unlock() }

        guard activeSynthesisID == id else {
            return
        }

        activeSynthesisID = nil
        activeSynthesisTask = nil
    }

    private func cancelActiveSynthesisTask() {
        synthesisTaskLock.lock()
        let task = activeSynthesisTask
        activeSynthesisID = nil
        activeSynthesisTask = nil
        synthesisTaskLock.unlock()
        task?.cancel()
    }
}

public final class TTSKitPremiumEngine: TTSKitSpeechEngine, @unchecked Sendable {
    public init(
        downloadBaseURL: URL = VoiceBarStorageLocation.ttsModelDownloadBaseURL,
        chunker: SpeechRequestChunker = SpeechRequestChunker(
            maximumWordsPerStreamingSegment: 24
        )
    ) {
        super.init(
            identifier: "ttskit-premium",
            modelVariant: .qwen3TTS_1_7b,
            supportsInstructionPrompt: true,
            downloadBaseURL: downloadBaseURL,
            chunker: chunker
        )
    }
}

public final class TTSKitQuickEngine: TTSKitSpeechEngine, @unchecked Sendable {
    public init(
        downloadBaseURL: URL = VoiceBarStorageLocation.ttsModelDownloadBaseURL,
        chunker: SpeechRequestChunker = SpeechRequestChunker(
            maximumWordsPerStreamingSegment: 24
        )
    ) {
        super.init(
            identifier: "ttskit-quick",
            modelVariant: .qwen3TTS_0_6b,
            supportsInstructionPrompt: false,
            downloadBaseURL: downloadBaseURL,
            chunker: chunker
        )
    }
}
