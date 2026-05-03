public protocol SpeechEngine: Sendable {
    var identifier: String { get }
    var availability: SpeechEngineAvailability { get async }
    var runtimeSnapshot: SpeechEngineRuntimeSnapshot { get async }

    func prepare() async throws
    func synthesize(_ request: SpeechRequest) -> AsyncThrowingStream<SpeechChunk, Error>
    func stop() async
}
