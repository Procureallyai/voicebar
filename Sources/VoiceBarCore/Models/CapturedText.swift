import Foundation

public enum CaptureSource: String, Codable, Sendable, CaseIterable {
    case accessibility
    case service
    case clipboard
    case copyFallback
    case unknown
}

public struct CapturedText: Equatable, Codable, Sendable {
    public var text: String
    public var source: CaptureSource
    public var frontmostBundleIdentifier: String?
    public var capturedAt: Date

    public init(
        text: String,
        source: CaptureSource,
        frontmostBundleIdentifier: String? = nil,
        capturedAt: Date = .now
    ) {
        self.text = text
        self.source = source
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.capturedAt = capturedAt
    }
}
