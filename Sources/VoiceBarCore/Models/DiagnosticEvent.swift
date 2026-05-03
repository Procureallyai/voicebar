import Foundation

public struct DiagnosticEvent: Equatable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var detail: String
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        name: String,
        detail: String,
        timestamp: Date = .now
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.timestamp = timestamp
    }
}
