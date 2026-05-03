import Foundation

public enum SpeechPlaybackError: LocalizedError, Equatable, Sendable {
    case noReplayRequest
    case noAudioProduced(String)
    case engineUnavailable(String)
    case playbackFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noReplayRequest:
            return "Replay is unavailable because VoiceBar has not spoken anything yet."
        case .noAudioProduced(let engineIdentifier):
            return "The \(engineIdentifier) engine finished without producing audio."
        case .engineUnavailable(let detail):
            return detail
        case .playbackFailed(let detail):
            return detail
        }
    }
}
