import OSLog

public actor InMemoryDiagnosticsCapture: DiagnosticsCapture {
    private let maxStoredEvents = 1000
    private var events: [DiagnosticEvent] = []
    private static let logger = Logger(
        subsystem: "ai.procureally.voicebar",
        category: "Diagnostics"
    )

    public init() {}

    public func record(_ event: DiagnosticEvent) async {
        events.append(event)

        // Mirror diagnostics into the unified log so machine-local playback
        // regressions can be inspected even when the floating controller is not
        // visible from the current surface.
        Self.logger.info(
            "[\(event.name, privacy: .public)] \(event.detail, privacy: .public)"
        )

        // Keep the bootstrap diagnostics store bounded so a long-lived menu bar
        // session does not accumulate unbounded in-memory history.
        if events.count > maxStoredEvents {
            events.removeFirst(events.count - maxStoredEvents)
        }
    }

    public func recentEvents(limit: Int) async -> [DiagnosticEvent] {
        Array(events.suffix(limit))
    }
}
