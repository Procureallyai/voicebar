@preconcurrency import AVFoundation
import Foundation
import VoiceBarCore

enum DictationCaptureStopReason: String, Sendable {
    case manual
    case silence
    case maximumDuration
}

struct DictationAudioCaptureResult: Sendable {
    var audioFileURL: URL
    var durationSeconds: TimeInterval
    var stopReason: DictationCaptureStopReason
    var sampleCount: Int
    var peakAmplitude: Float
    var audioWriteMilliseconds: Int
}

struct DictationCaptureDebugSnapshot: Sendable {
    var sampleCount: Int
    var durationSeconds: TimeInterval
    var peakAmplitude: Float
    var hasObservedSpeech: Bool
}

final class DictationMicrophoneCaptureController: @unchecked Sendable {
    private enum Constants {
        static let sampleRate = 16_000.0
        static let defaultAmplitudeThreshold: Float = 0.012
        static let defaultToggleAutoStopSilenceSeconds = 1.25
        static let minimumToggleAutoStopSilenceSeconds = 0.6
        static let maximumToggleAutoStopSilenceSeconds = 2.5
        static let amplitudeThreshold: Float = resolvedAmplitudeThreshold()
        static let toggleAutoStopSilenceSeconds: TimeInterval = resolvedToggleAutoStopSilenceSeconds()
        static let minimumCaptureSeconds = 0.35
        static let maximumCaptureSeconds = 90.0

        private static func resolvedAmplitudeThreshold() -> Float {
            guard
                let rawValue = ProcessInfo.processInfo.environment["VOICEBAR_DICTATION_AMPLITUDE_THRESHOLD"],
                let parsedValue = Float(rawValue),
                parsedValue > 0,
                parsedValue <= 1
            else {
                return defaultAmplitudeThreshold
            }

            return parsedValue
        }

        private static func resolvedToggleAutoStopSilenceSeconds() -> TimeInterval {
            guard
                let rawValue = ProcessInfo.processInfo.environment["VOICEBAR_DICTATION_SILENCE_SECONDS"],
                let parsedValue = TimeInterval(rawValue)
            else {
                return defaultToggleAutoStopSilenceSeconds
            }

            return min(max(parsedValue, minimumToggleAutoStopSilenceSeconds), maximumToggleAutoStopSilenceSeconds)
        }
    }

    private static let emptySnapshot = DictationCaptureDebugSnapshot(
        sampleCount: 0,
        durationSeconds: 0,
        peakAmplitude: 0,
        hasObservedSpeech: false
    )

    private let audioEngine = AVAudioEngine()
    private let stateQueue = DispatchQueue(label: "ai.procureally.voicebar.dictation.capture")
    private var capturedSamples: [Float] = []
    private var lastSpeechSampleIndex = 0
    private var peakAmplitude: Float = 0
    private var hasObservedSpeech = false
    private var automaticallyStopsOnSilence = true
    private var isRecording = false
    private var isAutoStopPending = false
    private var pendingAutoStopReason: DictationCaptureStopReason?
    private var lastCaptureSnapshot = DictationMicrophoneCaptureController.emptySnapshot
    private var autoStopHandler: ((Result<DictationAudioCaptureResult, Error>) -> Void)?

    static var toggleAutoStopSilenceSeconds: TimeInterval {
        Constants.toggleAutoStopSilenceSeconds
    }

    static var speechAmplitudeThreshold: Float {
        Constants.amplitudeThreshold
    }

    var recording: Bool {
        isRecording
    }

    func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func start(
        automaticallyStopsOnSilence: Bool = true,
        onAutoStop: @escaping (Result<DictationAudioCaptureResult, Error>) -> Void
    ) throws {
        guard isRecording == false else {
            return
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        guard inputFormat.channelCount > 0, inputFormat.sampleRate > 0 else {
            throw DictationRuntimeError.runtimeUnavailable(
                "VoiceBar could not read a usable microphone input format for local dictation."
            )
        }

        self.autoStopHandler = onAutoStop
        self.isRecording = true

        stateQueue.sync {
            capturedSamples = []
            lastSpeechSampleIndex = 0
            peakAmplitude = 0
            hasObservedSpeech = false
            // Reset cached metrics at the start of each recording so early-stop
            // diagnostics always belong to the active capture attempt.
            lastCaptureSnapshot = Self.emptySnapshot
            self.automaticallyStopsOnSilence = automaticallyStopsOnSilence
            isAutoStopPending = false
            pendingAutoStopReason = nil
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat) { [weak self] buffer, _ in
            self?.handleCapturedBuffer(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopCapture(
        stopReason: DictationCaptureStopReason = .manual
    ) throws -> DictationAudioCaptureResult {
        guard isRecording else {
            throw DictationRuntimeError.noAudioCaptured
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false

        let captureState = stateQueue.sync { () -> (samples: [Float], peak: Float, hasObservedSpeech: Bool) in
            let snapshot = capturedSamples
            let snapshotPeak = peakAmplitude
            let snapshotHasObservedSpeech = hasObservedSpeech

            // Persist the finalized capture snapshot before resetting buffers so
            // too-short/no-audio diagnostics still show truthful metrics.
            lastCaptureSnapshot = DictationCaptureDebugSnapshot(
                sampleCount: snapshot.count,
                durationSeconds: Double(snapshot.count) / Constants.sampleRate,
                peakAmplitude: snapshotPeak,
                hasObservedSpeech: snapshotHasObservedSpeech
            )

            capturedSamples = []
            hasObservedSpeech = false
            lastSpeechSampleIndex = 0
            peakAmplitude = 0
            automaticallyStopsOnSilence = true
            isAutoStopPending = false
            pendingAutoStopReason = nil
            return (snapshot, snapshotPeak, snapshotHasObservedSpeech)
        }

        let samples = captureState.samples
        let observedPeak = samples.reduce(captureState.peak) { currentPeak, sample in
            max(currentPeak, abs(sample))
        }

        guard
            samples.isEmpty == false,
            Double(samples.count) / Constants.sampleRate >= Constants.minimumCaptureSeconds
        else {
            throw DictationRuntimeError.noAudioCaptured
        }

        let audioWriteStartedAt = DispatchTime.now().uptimeNanoseconds
        let audioFileURL = try writeWAVFile(samples: samples)
        let audioWriteMilliseconds = Int(
            (DispatchTime.now().uptimeNanoseconds - audioWriteStartedAt) / 1_000_000
        )
        let durationSeconds = Double(samples.count) / Constants.sampleRate

        return DictationAudioCaptureResult(
            audioFileURL: audioFileURL,
            durationSeconds: durationSeconds,
            stopReason: stopReason,
            sampleCount: samples.count,
            peakAmplitude: observedPeak,
            audioWriteMilliseconds: audioWriteMilliseconds
        )
    }

    func debugSnapshot() -> DictationCaptureDebugSnapshot {
        stateQueue.sync {
            if capturedSamples.isEmpty {
                return lastCaptureSnapshot
            }

            return DictationCaptureDebugSnapshot(
                sampleCount: capturedSamples.count,
                durationSeconds: Double(capturedSamples.count) / Constants.sampleRate,
                peakAmplitude: peakAmplitude,
                hasObservedSpeech: hasObservedSpeech
            )
        }
    }

    private func handleCapturedBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let samples = extractWhisperReadyMonoSamples(from: buffer), samples.isEmpty == false else {
            return
        }

        let peak = samples.reduce(Float.zero) { currentPeak, sample in
            max(currentPeak, abs(sample))
        }

        let shouldAutoStop = stateQueue.sync { () -> Bool in
            capturedSamples.append(contentsOf: samples)

            if peak >= Constants.amplitudeThreshold {
                hasObservedSpeech = true
                lastSpeechSampleIndex = capturedSamples.count
            }
            peakAmplitude = max(peakAmplitude, peak)

            let totalSamples = capturedSamples.count
            let exceededMaximumDuration = Double(totalSamples) / Constants.sampleRate
                >= Constants.maximumCaptureSeconds
            guard exceededMaximumDuration == false else {
                let shouldStop = isAutoStopPending == false
                isAutoStopPending = true
                pendingAutoStopReason = .maximumDuration
                return shouldStop
            }

            guard hasObservedSpeech else {
                return false
            }

            guard automaticallyStopsOnSilence else {
                return false
            }

            let silenceSamples = totalSamples - lastSpeechSampleIndex
            let silenceDuration = Double(silenceSamples) / Constants.sampleRate
            let capturedDuration = Double(totalSamples) / Constants.sampleRate

            guard
                capturedDuration >= Constants.minimumCaptureSeconds,
                silenceDuration >= Constants.toggleAutoStopSilenceSeconds,
                isAutoStopPending == false
            else {
                return false
            }

            isAutoStopPending = true
            pendingAutoStopReason = .silence
            return true
        }

        guard shouldAutoStop else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.finishAutomatically()
        }
    }

    private func finishAutomatically() {
        guard isRecording else {
            return
        }

        let stopReason = stateQueue.sync {
            pendingAutoStopReason ?? .silence
        }

        let result = Result {
            try stopCapture(stopReason: stopReason)
        }

        autoStopHandler?(result)
    }

    private func extractWhisperReadyMonoSamples(from buffer: AVAudioPCMBuffer) -> [Float]? {
        let frameLength = Int(buffer.frameLength)
        guard
            frameLength > 0,
            buffer.format.sampleRate > 0,
            buffer.format.channelCount > 0,
            let channelData = buffer.floatChannelData
        else {
            return nil
        }

        let channelCount = Int(buffer.format.channelCount)
        let monoSamples: [Float] = (0..<frameLength).map { frameIndex in
            var sum = Float.zero
            for channelIndex in 0..<channelCount {
                sum += channelData[channelIndex][frameIndex]
            }
            return sum / Float(channelCount)
        }

        guard abs(buffer.format.sampleRate - Constants.sampleRate) > 0.5 else {
            return monoSamples
        }

        let sourceRate = buffer.format.sampleRate
        let outputFrameCount = max(1, Int(Double(monoSamples.count) * Constants.sampleRate / sourceRate))
        // Nearest-neighbour resampling is intentionally simple here: dictation
        // needs stable local capture more than studio-grade conversion, and
        // whisper.cpp tolerates this 16 kHz mono input well for operator speech.
        return (0..<outputFrameCount).map { outputIndex in
            let sourceIndex = min(
                monoSamples.count - 1,
                Int(Double(outputIndex) * sourceRate / Constants.sampleRate)
            )
            return monoSamples[sourceIndex]
        }
    }

    private func writeWAVFile(samples: [Float]) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voicebar-dictation-\(UUID().uuidString)")
            .appendingPathExtension("wav")

        let pcmSamples: [Int16] = samples.map { sample in
            let clampedSample = max(-1, min(1, sample))
            return Int16(clampedSample * Float(Int16.max))
        }

        let dataSize = pcmSamples.count * MemoryLayout<Int16>.size
        var wavData = Data(capacity: 44 + dataSize)

        wavData.append(contentsOf: Array("RIFF".utf8))
        wavData.append(UInt32(36 + dataSize).littleEndianData)
        wavData.append(contentsOf: Array("WAVE".utf8))
        wavData.append(contentsOf: Array("fmt ".utf8))
        wavData.append(UInt32(16).littleEndianData)
        wavData.append(UInt16(1).littleEndianData)
        wavData.append(UInt16(1).littleEndianData)
        wavData.append(UInt32(Constants.sampleRate).littleEndianData)
        wavData.append(UInt32(Constants.sampleRate * 2).littleEndianData)
        wavData.append(UInt16(2).littleEndianData)
        wavData.append(UInt16(16).littleEndianData)
        wavData.append(contentsOf: Array("data".utf8))
        wavData.append(UInt32(dataSize).littleEndianData)

        pcmSamples.forEach { sample in
            wavData.append(sample.littleEndianData)
        }

        try wavData.write(to: fileURL, options: .atomic)
        return fileURL
    }
}

private extension FixedWidthInteger {
    var littleEndianData: Data {
        withUnsafeBytes(of: littleEndian) { Data($0) }
    }
}
