import Foundation

public enum PlaybackStatus: String, Codable, Sendable {
    case idle
    case preparing
    case speaking
    case paused
    case failed
}

public struct PlaybackState: Equatable, Codable, Sendable {
    public var status: PlaybackStatus
    public var lastRequest: SpeechRequest?
    public var lastErrorDescription: String?
    public var currentEngineIdentifier: String?
    public var queuedRequestCount: Int

    public init(
        status: PlaybackStatus = .idle,
        lastRequest: SpeechRequest? = nil,
        lastErrorDescription: String? = nil,
        currentEngineIdentifier: String? = nil,
        queuedRequestCount: Int = 0
    ) {
        self.status = status
        self.lastRequest = lastRequest
        self.lastErrorDescription = lastErrorDescription
        self.currentEngineIdentifier = currentEngineIdentifier
        self.queuedRequestCount = queuedRequestCount
    }
}
