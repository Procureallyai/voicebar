import Darwin
import Foundation
import OSLog

private enum KokoroPythonRuntimeConfig {
    static let engineIdentifier = "kokoro-quick"
    static let sampleRate = 24_000
    static let chunkSampleCount = 2_048
    static let maximumWordsPerStreamingSegment = 12
    static let maximumWordsPerSegment = 10
    static let defaultVoice = "af_heart"
    static let pythonOverrideEnvironmentKey = "VOICEBAR_KOKORO_PYTHON"
    static let voiceOverrideEnvironmentKey = "VOICEBAR_KOKORO_VOICE"
    static let repositoryOverrideEnvironmentKey = "VOICEBAR_KOKORO_REPO_ID"
    static let setupHint = "bash scripts/setup-kokoro-runtime.sh"

    // Keep the helper inline so the local sidecar remains self-contained and
    // can run from the installed app bundle without depending on repo files.
    static let embeddedHelper = #"""
import base64
import json
import os
import sys

import numpy as np
from kokoro import KPipeline

repo_id = os.environ.get("VOICEBAR_KOKORO_REPO_ID") or None
pipeline = KPipeline(lang_code="a", repo_id=repo_id)
sample_rate = 24000
print(json.dumps({"type": "ready", "sample_rate": sample_rate}), flush=True)

for raw_line in sys.stdin:
    line = raw_line.strip()
    if not line:
        continue

    try:
        payload = json.loads(line)
    except Exception:
        print(json.dumps({"type": "error", "id": "__runtime__", "message": "invalid request payload"}), flush=True)
        continue

    request_id = payload.get("id")
    text = payload.get("text", "")
    voice = payload.get("voice") or os.environ.get("VOICEBAR_KOKORO_VOICE", "af_heart")

    if payload.get("type") == "shutdown":
        print(json.dumps({"type": "done", "id": request_id}), flush=True)
        break

    try:
        for _, _, audio in pipeline(text, voice=voice):
            encoded_audio = base64.b64encode(np.asarray(audio, dtype=np.float32).tobytes()).decode("ascii")
            print(
                json.dumps(
                    {
                        "type": "chunk",
                        "id": request_id,
                        "audio_b64": encoded_audio
                    }
                ),
                flush=True
            )
        print(json.dumps({"type": "done", "id": request_id}), flush=True)
    except Exception as exc:
        print(
            json.dumps(
                {
                    "type": "error",
                    "id": request_id,
                    "message": str(exc)
                }
            ),
            flush=True
        )
"""#
}

private actor KokoroPythonRuntimeState {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "VoiceBar",
        category: "KokoroPythonSpeechEngine"
    )

    // `FileHandle.write(_:)` on a broken pipe can raise SIGPIPE and terminate
    // the process. Ignore SIGPIPE once so pipe failures surface as write errors.
    private static let sigpipeConfigured: Void = {
        _ = Darwin.signal(SIGPIPE, SIG_IGN)
    }()

    private var process: Process?
    private var stdinHandle: FileHandle?
    private var stdoutHandle: FileHandle?
    private var stdoutBuffer = Data()
    private var runtimeSnapshot = SpeechEngineRuntimeSnapshot(
        identifier: KokoroPythonRuntimeConfig.engineIdentifier,
        warmState: .cold
    )

    func snapshot() -> SpeechEngineRuntimeSnapshot {
        runtimeSnapshot
    }

    func availability() -> SpeechEngineAvailability {
        if runtimeSnapshot.warmState == .warm {
            return SpeechEngineAvailability(
                isAvailable: true,
                reason: "Loaded and ready."
            )
        }

        if Self.isKokoroRuntimeConfigured() {
            return SpeechEngineAvailability(
                isAvailable: true,
                reason: "Configured for on-demand local Kokoro synthesis. First use may load the Python runtime."
            )
        }

        return SpeechEngineAvailability(
            isAvailable: false,
            reason: "Local Kokoro runtime is not configured. Run `\(KokoroPythonRuntimeConfig.setupHint)`."
        )
    }

    func prepare() async throws {
        try await ensureProcess()
    }

    func synthesize(
        requestID: String,
        text: String,
        voice: String,
        yield: (SpeechChunk) -> Void
    ) async throws {
        try await ensureProcess()

        guard
            let stdinHandle,
            let stdoutHandle
        else {
            throw SpeechPlaybackError.engineUnavailable(
                "Kokoro sidecar is unavailable because the helper process handles were not ready."
            )
        }

        let requestStart = ContinuousClock.now
        try writeJSONLine(
            [
                "id": requestID,
                "type": "synthesize",
                "text": text,
                "voice": voice
            ],
            to: stdinHandle
        )

        var sequenceNumber = 0
        var firstChunkDuration: Duration?

        Self.logger.info(
            "Kokoro sidecar accepted request \(requestID, privacy: .public) with \(text.count, privacy: .public) characters."
        )

        while true {
            try Task.checkCancellation()

            let message = try await readJSONLine(from: stdoutHandle)
            guard
                let responseID = message["id"] as? String,
                responseID == requestID,
                let type = message["type"] as? String
            else {
                continue
            }

            if type == "done" {
                return
            }

            if type == "error" {
                let detail = (message["message"] as? String) ?? "unknown Kokoro runtime error"
                throw SpeechPlaybackError.engineUnavailable(
                    "Kokoro runtime failed: \(detail)"
                )
            }

            guard
                type == "chunk",
                let encodedAudio = message["audio_b64"] as? String,
                let audioData = Data(base64Encoded: encodedAudio)
            else {
                continue
            }

            let sampleCount = audioData.count / MemoryLayout<Float>.size
            guard sampleCount > 0 else {
                continue
            }

            if firstChunkDuration == nil {
                firstChunkDuration = requestStart.duration(to: .now)
                Self.logger.info(
                    "Kokoro sidecar produced first chunk for request \(requestID, privacy: .public) after \(Self.formatDuration(firstChunkDuration!), privacy: .public). Samples: \(sampleCount, privacy: .public)."
                )
            }

            // The helper serializes little-endian Float32 PCM values.
            var samples = [Float](repeating: 0, count: sampleCount)
            _ = samples.withUnsafeMutableBytes { destination in
                audioData.copyBytes(to: destination)
            }

            for chunk in samples.chunked(into: KokoroPythonRuntimeConfig.chunkSampleCount) {
                yield(
                    SpeechChunk(
                        textFragment: sequenceNumber == 0 ? text : "",
                        sequenceNumber: sequenceNumber,
                        audioSamples: chunk,
                        sampleRate: KokoroPythonRuntimeConfig.sampleRate
                    )
                )
                sequenceNumber += 1
            }
        }
    }

    func stop() async {
        terminateProcess(clearFailure: true)
    }

    private func ensureProcess() async throws {
        _ = Self.sigpipeConfigured

        if
            let process,
            process.isRunning,
            stdinHandle != nil,
            stdoutHandle != nil
        {
            return
        }

        let bootstrapStart = ContinuousClock.now
        terminateProcess(clearFailure: true)

        let executable = try resolvedPythonExecutable()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["-u", "-c", KokoroPythonRuntimeConfig.embeddedHelper]

        var environment = ProcessInfo.processInfo.environment
        environment["PYTHONUNBUFFERED"] = "1"
        process.environment = environment

        let stdoutPipe = Pipe()
        let stdinPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stdoutPipe
        process.standardInput = stdinPipe

        do {
            try process.run()
        } catch {
            runtimeSnapshot.lastFailureDescription = "Kokoro sidecar failed to start: \(error.localizedDescription)"
            throw SpeechPlaybackError.engineUnavailable(
                runtimeSnapshot.lastFailureDescription ?? "Kokoro sidecar failed to start."
            )
        }

        self.process = process
        self.stdinHandle = stdinPipe.fileHandleForWriting
        self.stdoutHandle = stdoutPipe.fileHandleForReading
        self.stdoutBuffer = Data()

        do {
            let readyMessage = try await readJSONLine(from: stdoutPipe.fileHandleForReading)
            guard
                let type = readyMessage["type"] as? String,
                type == "ready"
            else {
                throw SpeechPlaybackError.engineUnavailable(
                    "Kokoro sidecar did not report a ready state."
                )
            }
        } catch {
            runtimeSnapshot.lastFailureDescription = "Kokoro sidecar failed during bootstrap: \(error.localizedDescription)"
            terminateProcess(clearFailure: false)
            throw error
        }

        runtimeSnapshot.warmState = .warm
        runtimeSnapshot.lastFailureDescription = nil
        Self.logger.info(
            "Kokoro sidecar became ready after \(Self.formatDuration(bootstrapStart.duration(to: .now)), privacy: .public)."
        )
    }

    private func writeJSONLine(
        _ payload: [String: String],
        to handle: FileHandle
    ) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        let fileDescriptor = Int32(handle.fileDescriptor)
        try Self.writeAll(jsonData, to: fileDescriptor)
        try Self.writeAll(Data([0x0A]), to: fileDescriptor)
    }

    private func readJSONLine(from handle: FileHandle) async throws -> [String: Any] {
        while true {
            if let newlineRange = stdoutBuffer.firstRange(of: Data([0x0A])) {
                let lineData = stdoutBuffer[..<newlineRange.lowerBound]
                let removalEnd = stdoutBuffer.index(after: newlineRange.lowerBound)
                stdoutBuffer.removeSubrange(..<removalEnd)

                if lineData.isEmpty {
                    continue
                }

                // The helper merges stdout/stderr so upstream libraries can emit
                // warning lines that are not JSON payloads. Ignore non-JSON lines
                // and keep scanning until the sidecar sends a valid protocol frame.
                guard let object = try? JSONSerialization.jsonObject(with: Data(lineData)) else {
                    continue
                }
                guard let dictionary = object as? [String: Any] else {
                    continue
                }
                return dictionary
            }

            let nextChunk = try await Self.readChunk(
                fileDescriptor: Int32(handle.fileDescriptor),
                maxBytes: 65_536
            )
            if nextChunk.isEmpty {
                throw SpeechPlaybackError.engineUnavailable(
                    "Kokoro sidecar stopped unexpectedly while waiting for output."
                )
            }

            stdoutBuffer.append(nextChunk)
        }
    }

    private static func readChunk(
        fileDescriptor: Int32,
        maxBytes: Int
    ) async throws -> Data {
        try await Task.detached(priority: .utility) {
            var buffer = [UInt8](repeating: 0, count: maxBytes)

            while true {
                let bytesRead = Darwin.read(fileDescriptor, &buffer, maxBytes)
                if bytesRead >= 0 {
                    return Data(buffer.prefix(Int(bytesRead)))
                }

                let readError = errno
                if readError == EINTR {
                    continue
                }

                throw POSIXError(POSIXErrorCode(rawValue: readError) ?? .EIO)
            }
        }.value
    }

    private static func writeAll(
        _ data: Data,
        to fileDescriptor: Int32
    ) throws {
        try data.withUnsafeBytes { rawBufferPointer in
            guard let baseAddress = rawBufferPointer.baseAddress else {
                return
            }

            var totalWritten = 0

            while totalWritten < rawBufferPointer.count {
                let bytesRemaining = rawBufferPointer.count - totalWritten
                let nextWriteAddress = baseAddress.advanced(by: totalWritten)
                let bytesWritten = Darwin.write(fileDescriptor, nextWriteAddress, bytesRemaining)

                if bytesWritten > 0 {
                    totalWritten += bytesWritten
                    continue
                }

                if bytesWritten == 0 {
                    throw SpeechPlaybackError.engineUnavailable(
                        "Kokoro sidecar stopped before accepting the synthesis request."
                    )
                }

                let writeError = errno
                if writeError == EINTR {
                    continue
                }

                if writeError == EPIPE {
                    throw SpeechPlaybackError.engineUnavailable(
                        "Kokoro sidecar stopped before accepting the synthesis request."
                    )
                }

                throw POSIXError(POSIXErrorCode(rawValue: writeError) ?? .EIO)
            }
        }
    }

    private static func formatDuration(_ duration: Duration) -> String {
        let milliseconds = Double(duration.components.seconds) * 1000
            + Double(duration.components.attoseconds) / 1_000_000_000_000_000
        return String(format: "%.0fms", milliseconds)
    }

    private func terminateProcess(clearFailure: Bool) {
        if let process, process.isRunning {
            process.terminate()
        }

        process = nil
        stdinHandle = nil
        stdoutHandle = nil
        stdoutBuffer = Data()
        runtimeSnapshot.warmState = .cold
        if clearFailure {
            runtimeSnapshot.lastFailureDescription = nil
        }
    }

    private func resolvedPythonExecutable() throws -> String {
        let environment = ProcessInfo.processInfo.environment
        if
            let override = environment[KokoroPythonRuntimeConfig.pythonOverrideEnvironmentKey],
            FileManager.default.isExecutableFile(atPath: override)
        {
            return override
        }

        let defaultPath = VoiceBarStorageLocation.kokoroPythonExecutableURL.path
        if FileManager.default.isExecutableFile(atPath: defaultPath) {
            return defaultPath
        }

        throw SpeechPlaybackError.engineUnavailable(
            "Kokoro runtime python executable is missing at `\(defaultPath)`. Run `\(KokoroPythonRuntimeConfig.setupHint)`."
        )
    }

    static func isKokoroRuntimeConfigured() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        if
            let override = environment[KokoroPythonRuntimeConfig.pythonOverrideEnvironmentKey],
            FileManager.default.isExecutableFile(atPath: override)
        {
            return true
        }

        return FileManager.default.isExecutableFile(
            atPath: VoiceBarStorageLocation.kokoroPythonExecutableURL.path
        )
    }
}

package enum KokoroPlaybackPlanner {
    package static let initialPrebufferLeadDuration: TimeInterval = 0.08

    private static let chunker = SpeechRequestChunker(
        maximumWordsPerSegment: KokoroPythonRuntimeConfig.maximumWordsPerSegment,
        maximumWordsPerStreamingSegment: KokoroPythonRuntimeConfig.maximumWordsPerStreamingSegment
    )

    package static func plannedSegments(for text: String) -> [ChunkedSpeechSegment] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else {
            return []
        }

        let groupedSegments = chunker.chunkForStreaming(trimmedText)
        return groupedSegments.isEmpty
            ? [ChunkedSpeechSegment(text: trimmedText)]
            : groupedSegments
    }

    package static func makePauseSamples(
        durationMilliseconds: Int,
        sampleRate: Int
    ) -> [Float] {
        let sampleCount = max(1, Int((Double(durationMilliseconds) / 1000.0) * Double(sampleRate)))
        return Array(repeating: 0, count: sampleCount)
    }
}

public final class KokoroPythonSpeechEngine: SpeechEngine, @unchecked Sendable {
    public let identifier = KokoroPythonRuntimeConfig.engineIdentifier

    private let runtimeState = KokoroPythonRuntimeState()
    private let synthesisTaskLock = NSLock()
    private var activeSynthesisID: UUID?
    private var activeSynthesisTask: Task<Void, Never>?

    public init() {}

    public var availability: SpeechEngineAvailability {
        get async {
            await runtimeState.availability()
        }
    }

    public var runtimeSnapshot: SpeechEngineRuntimeSnapshot {
        get async {
            await runtimeState.snapshot()
        }
    }

    public func prepare() async throws {
        try await runtimeState.prepare()
    }

    public func synthesize(_ request: SpeechRequest) -> AsyncThrowingStream<SpeechChunk, Error> {
        AsyncThrowingStream { continuation in
            let synthesisID = UUID()
            let task = Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                do {
                    let trimmedText = request.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmedText.isEmpty == false else {
                        continuation.finish()
                        return
                    }

                    let voice = self.resolvedVoiceIdentifier(for: request)
                    let segments = KokoroPlaybackPlanner.plannedSegments(for: trimmedText)
                    var nextSequenceNumber = 0

                    // Keep the Kokoro quick lane interactive by feeding it the
                    // same smaller grouped segments the older quick path used.
                    for (segmentIndex, segment) in segments.enumerated() {
                        try Task.checkCancellation()

                        let requestID = "\(synthesisID.uuidString)-\(segmentIndex)"
                        var emittedChunkCount = 0

                        try await self.runtimeState.synthesize(
                            requestID: requestID,
                            text: segment.text,
                            voice: voice
                        ) { chunk in
                            emittedChunkCount = max(emittedChunkCount, chunk.sequenceNumber + 1)

                            continuation.yield(
                                SpeechChunk(
                                    textFragment: chunk.sequenceNumber == 0 ? segment.text : "",
                                    sequenceNumber: nextSequenceNumber + chunk.sequenceNumber,
                                    audioSamples: chunk.audioSamples,
                                    sampleRate: chunk.sampleRate,
                                    isParagraphPause: chunk.isParagraphPause,
                                    prebufferLeadDuration: chunk.sequenceNumber == 0
                                        ? KokoroPlaybackPlanner.initialPrebufferLeadDuration
                                        : nil
                                )
                            )
                        }

                        nextSequenceNumber += emittedChunkCount

                        if
                            segment.pauseAfterMilliseconds > 0,
                            emittedChunkCount > 0
                        {
                            continuation.yield(
                                SpeechChunk(
                                    textFragment: "",
                                    sequenceNumber: nextSequenceNumber,
                                    audioSamples: KokoroPlaybackPlanner.makePauseSamples(
                                        durationMilliseconds: segment.pauseAfterMilliseconds,
                                        sampleRate: KokoroPythonRuntimeConfig.sampleRate
                                    ),
                                    sampleRate: KokoroPythonRuntimeConfig.sampleRate,
                                    isParagraphPause: true
                                )
                            )
                            nextSequenceNumber += 1
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }

                self.clearActiveSynthesisTask(id: synthesisID)
            }

            setActiveSynthesisTask(id: synthesisID, task: task)
            continuation.onTermination = { [weak self] _ in
                task.cancel()
                self?.clearActiveSynthesisTask(id: synthesisID)
            }
        }
    }

    public func stop() async {
        cancelActiveSynthesisTask()
        await runtimeState.stop()
    }

    public static func isRuntimeConfigured() -> Bool {
        KokoroPythonRuntimeState.isKokoroRuntimeConfigured()
    }

    private func resolvedVoiceIdentifier(for request: SpeechRequest) -> String {
        let environment = ProcessInfo.processInfo.environment
        if let overrideVoice = environment[KokoroPythonRuntimeConfig.voiceOverrideEnvironmentKey] {
            let trimmedOverride = overrideVoice.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedOverride.isEmpty == false {
                return trimmedOverride
            }
        }

        let qwenToKokoroVoiceMap: [String: String] = [
            "serena": "af_heart",
            "ryan": "am_adam"
        ]

        if
            let requestedVoice = request.voiceIdentifier?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            requestedVoice.isEmpty == false
        {
            return qwenToKokoroVoiceMap[requestedVoice] ?? KokoroPythonRuntimeConfig.defaultVoice
        }

        return KokoroPythonRuntimeConfig.defaultVoice
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

private extension Array where Element == Float {
    func chunked(into size: Int) -> [[Float]] {
        guard size > 0, isEmpty == false else {
            return isEmpty ? [] : [self]
        }

        var chunks: [[Float]] = []
        chunks.reserveCapacity((count + size - 1) / size)

        var index = 0
        while index < count {
            let endIndex = Swift.min(index + size, count)
            chunks.append(Array(self[index..<endIndex]))
            index += size
        }

        return chunks
    }
}
