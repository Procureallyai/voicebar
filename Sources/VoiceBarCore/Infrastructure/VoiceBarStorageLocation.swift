import Foundation

public enum VoiceBarStorageLocation {
    private static let folderName = "VoiceBar"

    public static var baseDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
    }

    public static var ttsModelDownloadBaseURL: URL {
        baseDirectoryURL
            .appendingPathComponent("huggingface", isDirectory: true)
    }

    public static var ttsModelRepoCacheURL: URL {
        ttsModelDownloadBaseURL
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent("argmaxinc", isDirectory: true)
            .appendingPathComponent("ttskit-coreml", isDirectory: true)
    }

    public static var runtimeBaseDirectoryURL: URL {
        baseDirectoryURL
            .appendingPathComponent("runtime", isDirectory: true)
    }

    public static var kokoroRuntimeRootURL: URL {
        runtimeBaseDirectoryURL
            .appendingPathComponent("kokoro-venv", isDirectory: true)
    }

    public static var kokoroPythonExecutableURL: URL {
        kokoroRuntimeRootURL
            .appendingPathComponent("bin", isDirectory: true)
            .appendingPathComponent("python", isDirectory: false)
    }

    public static var whisperRuntimeRootURL: URL {
        runtimeBaseDirectoryURL
            .appendingPathComponent("whisper.cpp", isDirectory: true)
    }

    public static var whisperSourceRootURL: URL {
        whisperRuntimeRootURL
            .appendingPathComponent("source", isDirectory: true)
    }

    public static var whisperBuildRootURL: URL {
        whisperSourceRootURL
            .appendingPathComponent("build", isDirectory: true)
    }

    public static var whisperBinaryURL: URL {
        whisperBuildRootURL
            .appendingPathComponent("bin", isDirectory: true)
            .appendingPathComponent("whisper-cli", isDirectory: false)
    }

    public static var whisperModelsDirectoryURL: URL {
        whisperRuntimeRootURL
            .appendingPathComponent("models", isDirectory: true)
    }

    public static var defaultWhisperModelURL: URL {
        whisperModelsDirectoryURL
            .appendingPathComponent("ggml-base.en.bin", isDirectory: false)
    }

    public static var dictationSnippetsURL: URL {
        fileURL(named: "dictation-snippets.json")
    }

    public static var dictationActionsURL: URL {
        fileURL(named: "dictation-actions.json")
    }

    public static var dictationHistoryURL: URL {
        fileURL(named: "dictation-history.json")
    }

    public static var privateDirectoryURL: URL {
        baseDirectoryURL
            .appendingPathComponent("private", isDirectory: true)
    }

    public static var wisprFlowSnippetsPrivateExportURL: URL {
        privateDirectoryURL
            .appendingPathComponent("wispr-flow-snippets-private-export.json", isDirectory: false)
    }

    public static var wisprFlowSnippetsRedactedManifestURL: URL {
        privateDirectoryURL
            .appendingPathComponent("wispr-flow-snippets-redacted-manifest.json", isDirectory: false)
    }

    public static var wisprFlowSnippetsReportDirectoryURL: URL {
        privateDirectoryURL
            .appendingPathComponent("wispr-flow-import-reports", isDirectory: true)
    }

    public static var wisprFlowSnippetsPreviewReportURL: URL {
        wisprFlowSnippetsReportDirectoryURL
            .appendingPathComponent("wispr-flow-snippets-preview-report.json", isDirectory: false)
    }

    public static var wisprFlowSnippetsApplyReportURL: URL {
        wisprFlowSnippetsReportDirectoryURL
            .appendingPathComponent("wispr-flow-snippets-apply-report.json", isDirectory: false)
    }

    public static var ttsTokenizerRepoCacheURL: URL {
        ttsModelDownloadBaseURL
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent("Qwen", isDirectory: true)
            .appendingPathComponent("Qwen3-0.6B", isDirectory: true)
    }

    public static func fileURL(named fileName: String) -> URL {
        baseDirectoryURL.appendingPathComponent(fileName, isDirectory: false)
    }

    public static func ensureDirectoryExists(for fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    public static func ensureDirectoryExists(at directoryURL: URL) throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
