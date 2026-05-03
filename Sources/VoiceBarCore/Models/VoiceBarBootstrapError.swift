import Foundation

public enum VoiceBarBootstrapError: LocalizedError, Sendable {
    case notYetImplemented(String)

    public var errorDescription: String? {
        switch self {
        case .notYetImplemented(let detail):
            return detail
        }
    }
}
