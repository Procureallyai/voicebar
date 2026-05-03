import Foundation

private final class BufferedProcessOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    func finish(with trailingData: Data) -> Data {
        lock.lock()
        data.append(trailingData)
        let snapshot = data
        lock.unlock()
        return snapshot
    }
}

public struct WhisperCppSpeechToTextService: SpeechToTextService {
    public static let binaryOverrideEnvironmentKey = "VOICEBAR_WHISPER_CPP_BINARY"
    public static let modelOverrideEnvironmentKey = "VOICEBAR_WHISPER_CPP_MODEL"
    public static let threadOverrideEnvironmentKey = "VOICEBAR_WHISPER_CPP_THREADS"
    public static let setupHint = "bash scripts/setup-whisper-runtime.sh"

    public init() {}

    public func availability() async -> DictationServiceAvailability {
        let binaryURL = resolvedBinaryURL()
        let modelURL = resolvedModelURL()

        guard FileManager.default.isExecutableFile(atPath: binaryURL.path) else {
            return DictationServiceAvailability(
                isAvailable: false,
                reason: "whisper.cpp is not configured yet. Run `\(Self.setupHint)` to install the local runtime."
            )
        }

        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            return DictationServiceAvailability(
                isAvailable: false,
                reason: "The local whisper.cpp model is missing at \(modelURL.path). Run `\(Self.setupHint)` to install the English base model."
            )
        }

        return DictationServiceAvailability(
            isAvailable: true,
            reason: "whisper.cpp is configured locally and ready for English dictation."
        )
    }

    public func transcribe(
        audioFileURL: URL,
        rollingPrompt: String?
    ) async throws -> String {
        let binaryURL = resolvedBinaryURL()
        let modelURL = resolvedModelURL()

        guard FileManager.default.isExecutableFile(atPath: binaryURL.path) else {
            throw DictationRuntimeError.runtimeUnavailable(
                "VoiceBar could not find the whisper.cpp runtime at \(binaryURL.path). Run `\(Self.setupHint)` first."
            )
        }

        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw DictationRuntimeError.runtimeUnavailable(
                "VoiceBar could not find the local whisper.cpp model at \(modelURL.path). Run `\(Self.setupHint)` first."
            )
        }

        let outputBaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voicebar-whisper-\(UUID().uuidString)", isDirectory: false)
        let outputTextURL = outputBaseURL.appendingPathExtension("txt")

        var arguments = [
            "-m", modelURL.path,
            "-f", audioFileURL.path,
            "-l", "en",
            "-np",
            "-nt",
            "-otxt",
            "-of", outputBaseURL.path,
            "-t", "\(resolvedThreadCount())"
        ]

        let trimmedPrompt = rollingPrompt?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedPrompt, trimmedPrompt.isEmpty == false {
            arguments.append(contentsOf: ["--prompt", trimmedPrompt])
        }

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        let executionOutput: String

        do {
            executionOutput = try await run(process, collecting: outputPipe)
        } catch {
            throw DictationRuntimeError.transcriptionFailed(
                "whisper.cpp failed before transcription started. \(describe(error))"
            )
        }

        guard process.terminationStatus == 0 else {
            throw DictationRuntimeError.transcriptionFailed(
                "whisper.cpp exited with status \(process.terminationStatus). \(executionOutput.trimmingCharacters(in: .whitespacesAndNewlines))"
            )
        }

        guard
            let transcript = try? String(contentsOf: outputTextURL, encoding: .utf8),
            transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        else {
            throw DictationRuntimeError.transcriptionFailed(
                "whisper.cpp completed, but it did not produce a usable transcript file at \(outputTextURL.path)."
            )
        }

        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolvedBinaryURL() -> URL {
        if let overridePath = ProcessInfo.processInfo.environment[Self.binaryOverrideEnvironmentKey] {
            return URL(fileURLWithPath: overridePath)
        }

        return VoiceBarStorageLocation.whisperBinaryURL
    }

    private func resolvedModelURL() -> URL {
        if let overridePath = ProcessInfo.processInfo.environment[Self.modelOverrideEnvironmentKey] {
            return URL(fileURLWithPath: overridePath)
        }

        return VoiceBarStorageLocation.defaultWhisperModelURL
    }

    private func resolvedThreadCount() -> Int {
        if
            let override = ProcessInfo.processInfo.environment[Self.threadOverrideEnvironmentKey],
            let parsedOverride = Int(override),
            parsedOverride > 0
        {
            return parsedOverride
        }

        return max(2, min(8, ProcessInfo.processInfo.activeProcessorCount))
    }

    private func run(
        _ process: Process,
        collecting outputPipe: Pipe
    ) async throws -> String {
        let outputHandle = outputPipe.fileHandleForReading
        let bufferedOutput = BufferedProcessOutput()

        return try await withCheckedThrowingContinuation { continuation in
            outputHandle.readabilityHandler = { handle in
                let chunk = handle.availableData
                guard chunk.isEmpty == false else {
                    return
                }

                bufferedOutput.append(chunk)
            }

            // Register the handler before launching so a fast whisper.cpp
            // failure cannot strand the transcription continuation.
            process.terminationHandler = { completedProcess in
                outputHandle.readabilityHandler = nil

                // Drain the final EOF-delimited tail after the process exits so
                // whisper.cpp cannot deadlock behind an unread pipe buffer.
                let trailingData = outputHandle.readDataToEndOfFile()
                let completeOutput = bufferedOutput.finish(with: trailingData)

                let output = String(decoding: completeOutput, as: UTF8.self)

                if completedProcess.terminationReason == .uncaughtSignal {
                    continuation.resume(
                        throwing: DictationRuntimeError.transcriptionFailed(
                            "whisper.cpp terminated unexpectedly with signal \(completedProcess.terminationStatus). \(output)"
                        )
                    )
                    return
                }

                continuation.resume(returning: output)
            }

            do {
                try process.run()
            } catch {
                outputHandle.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }

    private func describe(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return error.localizedDescription
    }
}
