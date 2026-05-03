public struct UnconfiguredSpeechEngine: SpeechEngine {
    public let identifier: String
    private let unavailableReason: String

    public init(
        identifier: String,
        unavailableReason: String
    ) {
        self.identifier = identifier
        self.unavailableReason = unavailableReason
    }

    public var availability: SpeechEngineAvailability {
        SpeechEngineAvailability(
            isAvailable: false,
            reason: unavailableReason
        )
    }

    public var runtimeSnapshot: SpeechEngineRuntimeSnapshot {
        SpeechEngineRuntimeSnapshot(
            identifier: identifier,
            warmState: .cold,
            lastFailureDescription: unavailableReason
        )
    }

    public func prepare() async throws {
        throw VoiceBarBootstrapError.notYetImplemented(unavailableReason)
    }

    public func synthesize(_ request: SpeechRequest) -> AsyncThrowingStream<SpeechChunk, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: VoiceBarBootstrapError.notYetImplemented(
                    "Speech synthesis for '\(request.preferredMode.rawValue)' mode is intentionally deferred until Prompt 004."
                )
            )
        }
    }

    public func stop() async {}
}
