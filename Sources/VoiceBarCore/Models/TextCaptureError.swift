import Foundation

public enum TextCaptureError: LocalizedError, Equatable, Sendable {
    case accessibilityPermissionRequired
    case inaccessibleSelection(String)
    case noSelectedText
    case clipboardEmpty
    case copyFallbackUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            return "VoiceBar needs Accessibility access before it can inspect the focused selection."
        case let .inaccessibleSelection(reason):
            return reason
        case .noSelectedText:
            return "The focused app did not expose any selected text."
        case .clipboardEmpty:
            return "The clipboard does not currently contain plain text."
        case let .copyFallbackUnavailable(reason):
            return reason
        }
    }
}
