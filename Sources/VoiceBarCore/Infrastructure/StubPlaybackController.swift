public actor StubPlaybackController: PlaybackController {
    private var currentState = PlaybackState()
    private let diagnostics: DiagnosticsCapture

    public init(diagnostics: DiagnosticsCapture) {
        self.diagnostics = diagnostics
    }

    public func state() async -> PlaybackState {
        currentState
    }

    public func submit(_ request: SpeechRequest) async throws {
        currentState = PlaybackState(
            status: .failed,
            lastRequest: request,
            lastErrorDescription: "Playback wiring is intentionally deferred until Prompt 004."
        )

        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.submit.blocked",
                detail: "Rejected request for \(request.preferredMode.rawValue) because the speech engine lane is not merged yet."
            )
        )

        throw VoiceBarBootstrapError.notYetImplemented(
            "Playback is scaffolded only. Prompt 004 owns the first real speech pipeline."
        )
    }

    public func pause() async {
        // The bootstrap controller should only expose a paused state when playback was active.
        guard currentState.status == .speaking else {
            return
        }

        currentState.status = .paused
    }

    public func resume() async {
        currentState.status = .speaking
    }

    public func stop() async {
        currentState = PlaybackState(status: .idle)
    }

    public func replayLast() async throws {
        guard let lastRequest = currentState.lastRequest else {
            throw VoiceBarBootstrapError.notYetImplemented(
                "Replay has no prior request because real speech playback has not been wired yet."
            )
        }

        try await submit(lastRequest)
    }
}
