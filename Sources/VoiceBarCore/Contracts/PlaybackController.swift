public protocol PlaybackController: Sendable {
    func state() async -> PlaybackState
    func submit(_ request: SpeechRequest) async throws
    func pause() async
    func resume() async
    func stop() async
    func replayLast() async throws
}
