import Foundation
import VoiceBarCore

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

struct DictationActionExecutionResult: Sendable {
    var output: String
}

struct DictationActionExecutor {
    func run(_ action: DictationActionDefinition) async throws -> DictationActionExecutionResult {
        let expandedScriptPath = NSString(string: action.scriptPath).expandingTildeInPath
        let scriptURL = URL(fileURLWithPath: expandedScriptPath)

        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            throw DictationRuntimeError.actionFailed(
                "VoiceBar could not find the allowlisted action script at \(scriptURL.path)."
            )
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path] + action.arguments

        // Blank operator-authored working directories should behave like the
        // unset case instead of silently inheriting the current process CWD.
        if
            let workingDirectory = action.workingDirectory?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            workingDirectory.isEmpty == false
        {
            let expandedWorkingDirectory = NSString(string: workingDirectory).expandingTildeInPath
            process.currentDirectoryURL = URL(fileURLWithPath: expandedWorkingDirectory, isDirectory: true)
        }

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
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

            // Register the handler before launching so a fast-exiting script
            // cannot slip past the continuation and leave the action hanging.
            process.terminationHandler = { completedProcess in
                outputHandle.readabilityHandler = nil

                // Drain the final EOF-delimited tail after the process exits so
                // large stdout/stderr streams never block behind a full pipe.
                let trailingData = outputHandle.readDataToEndOfFile()
                let completeOutput = bufferedOutput.finish(with: trailingData)

                let output = String(decoding: completeOutput, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard completedProcess.terminationStatus == 0 else {
                    continuation.resume(
                        throwing: DictationRuntimeError.actionFailed(
                            "VoiceBar action '\(action.displayName)' failed with status \(completedProcess.terminationStatus). \(output)"
                        )
                    )
                    return
                }

                continuation.resume(
                    returning: DictationActionExecutionResult(output: output)
                )
            }

            do {
                try process.run()
            } catch {
                outputHandle.readabilityHandler = nil
                continuation.resume(
                    throwing: DictationRuntimeError.actionFailed(
                        "VoiceBar could not start the allowlisted action script. \(error.localizedDescription)"
                    )
                )
            }
        }
    }
}
