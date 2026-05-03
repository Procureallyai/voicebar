public protocol DiagnosticsCapture: Sendable {
    func record(_ event: DiagnosticEvent) async
    func recentEvents(limit: Int) async -> [DiagnosticEvent]
}
