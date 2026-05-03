public protocol TextCaptureService: Sendable {
    func captureSelection() async throws -> CapturedText
    func captureClipboard() async throws -> CapturedText
}
