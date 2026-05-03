import Foundation

public actor QueuedPlaybackController: PlaybackController {
    private let premiumSpeechEngine: SpeechEngine
    private let quickSpeechEngine: SpeechEngine
    private let diagnostics: DiagnosticsCapture
    private let player: AudioChunkPlayer
    private let premiumFailureThreshold: Int

    private var currentState = PlaybackState()
    private var activeRequest: SpeechRequest?
    private var pendingRequests: [SpeechRequest] = []
    private var activeTask: Task<Void, Never>?
    private var activeRunID = UUID()
    private var stopTask: Task<Void, Never>?
    private var lastReplayableRequest: SpeechRequest?
    private var premiumFailureCount = 0
    private var activeEngine: SpeechEngine?

    public init(
        premiumSpeechEngine: SpeechEngine,
        quickSpeechEngine: SpeechEngine,
        diagnostics: DiagnosticsCapture,
        player: AudioChunkPlayer = AVAudioChunkPlayer(),
        premiumFailureThreshold: Int = 2
    ) {
        self.premiumSpeechEngine = premiumSpeechEngine
        self.quickSpeechEngine = quickSpeechEngine
        self.diagnostics = diagnostics
        self.player = player
        self.premiumFailureThreshold = premiumFailureThreshold
    }

    public func state() async -> PlaybackState {
        currentState
    }

    public func submit(_ request: SpeechRequest) async throws {
        // New requests wait for any in-flight stop so an older stop call cannot
        // cancel the shared engine or player underneath fresh playback.
        if let stopTask {
            await stopTask.value
        }

        let queueDepthBeforeSubmit = pendingRequests.count
        lastReplayableRequest = request

        if activeRequest == nil, activeTask == nil {
            activeRequest = request
            currentState = PlaybackState(
                status: .preparing,
                lastRequest: request,
                currentEngineIdentifier: currentState.currentEngineIdentifier,
                queuedRequestCount: pendingRequests.count
            )
            startProcessingLoop()
        } else {
            pendingRequests.append(request)
            currentState.queuedRequestCount = pendingRequests.count

            await diagnostics.record(
                DiagnosticEvent(
                    name: "playback.request.queued",
                    detail: "Queued a request in \(request.preferredMode.rawValue) mode. Queue depth is now \(pendingRequests.count)."
                )
            )
        }

        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.request.received",
                detail: "Received \(request.preferredMode.rawValue) playback request with \(request.text.count) characters. Queue depth before submit: \(queueDepthBeforeSubmit)."
            )
        )
    }

    public func pause() async {
        guard activeTask != nil else {
            return
        }

        await player.pause()
        currentState.status = .paused

        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.paused",
                detail: "Paused playback on \(currentState.currentEngineIdentifier ?? "unknown engine")."
            )
        )
    }

    public func resume() async {
        guard activeTask != nil else {
            return
        }

        await player.resume()
        currentState.status = .speaking

        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.resumed",
                detail: "Resumed playback on \(currentState.currentEngineIdentifier ?? "unknown engine")."
            )
        )
    }

    public func stop() async {
        if let stopTask {
            await stopTask.value
            return
        }

        let requestedStatus = currentState.status
        let requestedQueueDepth = pendingRequests.count

        activeRunID = UUID()
        pendingRequests.removeAll()
        activeRequest = nil
        let taskToCancel = activeTask
        activeTask = nil
        let engineToStop = activeEngine
        activeEngine = nil

        taskToCancel?.cancel()
        currentState = PlaybackState(
            status: .idle,
            lastRequest: currentState.lastRequest,
            currentEngineIdentifier: currentState.currentEngineIdentifier,
            queuedRequestCount: 0
        )

        // Snapshot the stop work before awaiting so actor reentrancy cannot let
        // a later submit get clobbered by this older stop call.
        let stopTask = Task { [player] in
            if let engineToStop {
                await engineToStop.stop()
            }

            await player.stop()
        }
        self.stopTask = stopTask
        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.stop.requested",
                detail: "Stop requested while playback state was \(requestedStatus.rawValue). Queue depth: \(requestedQueueDepth)."
            )
        )
        await stopTask.value
        self.stopTask = nil

        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.stopped",
                detail: "Stopped playback and cleared the queued requests."
            )
        )
        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.stop.completed",
                detail: "Stop completed. Replayable request retained: \(lastReplayableRequest == nil ? "false" : "true")."
            )
        )
    }

    public func replayLast() async throws {
        guard let replayableRequest = lastReplayableRequest else {
            await diagnostics.record(
                DiagnosticEvent(
                    name: "playback.replay.unavailable",
                    detail: "Replay was requested, but no replayable speech request is stored."
                )
            )
            throw SpeechPlaybackError.noReplayRequest
        }

        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.replay.requested",
                detail: "Replay requested while playback state was \(currentState.status.rawValue). Queue depth: \(pendingRequests.count)."
            )
        )

        if activeRequest != nil || activeTask != nil || pendingRequests.isEmpty == false {
            await stop()
        }

        do {
            await diagnostics.record(
                DiagnosticEvent(
                    name: "playback.replay.submitted",
                    detail: "Submitting replay request in \(replayableRequest.preferredMode.rawValue) mode."
                )
            )
            try await submit(replayableRequest)
            await diagnostics.record(
                DiagnosticEvent(
                    name: "playback.replay.started",
                    detail: "Replay request accepted by the playback queue."
                )
            )
        } catch {
            await diagnostics.record(
                DiagnosticEvent(
                    name: "playback.replay.failed",
                    detail: "Replay submission failed: \(describe(error))"
                )
            )
            throw error
        }
    }

    private func startProcessingLoop() {
        let runID = UUID()
        activeRunID = runID

        activeTask = Task { [weak self] in
            await self?.processRequests(runID: runID)
        }
    }

    private func processRequests(runID: UUID) async {
        while runID == activeRunID, let request = activeRequest {
            do {
                try await perform(request: request, runID: runID)
            } catch is CancellationError {
                break
            } catch {
                currentState.status = .failed
                currentState.lastErrorDescription = describe(error)

                await diagnostics.record(
                    DiagnosticEvent(
                        name: "playback.failed",
                        detail: "Playback failed for \(request.preferredMode.rawValue): \(describe(error))"
                    )
                )
            }

            if runID != activeRunID {
                break
            }

            if pendingRequests.isEmpty {
                activeRequest = nil
                activeTask = nil

                if currentState.status != .failed {
                    currentState.status = .idle
                    currentState.lastErrorDescription = nil
                }

                currentState.queuedRequestCount = 0
            } else {
                activeRequest = pendingRequests.removeFirst()
                currentState.queuedRequestCount = pendingRequests.count
            }
        }
    }

    private func perform(request: SpeechRequest, runID: UUID) async throws {
        currentState.status = .preparing
        currentState.lastRequest = request
        currentState.lastErrorDescription = nil
        currentState.queuedRequestCount = pendingRequests.count

        let selection = await selectEngine(for: request.preferredMode)

        if let degradationDiagnostic = selection.degradationDiagnostic {
            await diagnostics.record(
                degradationDiagnostic
            )
        }

        do {
            try await play(request: request, using: selection.primary, runID: runID)

            if selection.primary.identifier == premiumSpeechEngine.identifier {
                premiumFailureCount = 0
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // Stops invalidate the run before the engine/player have fully
            // unwound, so treat any late error from an obsolete run as a
            // cancellation instead of poisoning failure tracking or fallback.
            if runID != activeRunID || Task.isCancelled {
                throw CancellationError()
            }

            if selection.primary.identifier == premiumSpeechEngine.identifier {
                premiumFailureCount += 1
            }

            guard let fallbackEngine = selection.fallback else {
                throw error
            }

            await diagnostics.record(
                DiagnosticEvent(
                    name: "engine.fallback",
                    detail: "Falling back from \(selection.primary.identifier) to \(fallbackEngine.identifier): \(describe(error))"
                )
            )

            try await play(request: request, using: fallbackEngine, runID: runID)
        }
    }

    private func play(
        request: SpeechRequest,
        using engine: SpeechEngine,
        runID: UUID
    ) async throws {
        activeEngine = engine
        currentState.currentEngineIdentifier = engine.identifier

        let runtimeSnapshot = await engine.runtimeSnapshot
        let requestStart = ContinuousClock.now
        var firstAudioDuration: Duration?
        var firstBufferScheduledDuration: Duration?
        var producedAnyAudio = false

        await diagnostics.record(
            DiagnosticEvent(
                name: "engine.prepare.started",
                detail: "Preparing \(engine.identifier) from a \(runtimeSnapshot.warmState.rawValue) state."
            )
        )

        let stream = engine.synthesize(request)
        await diagnostics.record(
            DiagnosticEvent(
                name: "engine.stream.created",
                detail: "Created the \(engine.identifier) synthesis stream after \(formatDuration(requestStart.duration(to: .now))). Warm state: \(runtimeSnapshot.warmState.rawValue)."
            )
        )

        do {
            for try await chunk in stream {
                try Task.checkCancellation()

                guard
                    chunk.sampleRate != nil,
                    chunk.audioSamples.isEmpty == false
                else {
                    continue
                }

                if firstAudioDuration == nil {
                    firstAudioDuration = requestStart.duration(to: .now)

                    await diagnostics.record(
                        DiagnosticEvent(
                            name: "playback.first-audio",
                            detail: """
                            Engine \(engine.identifier) produced first audio after \(formatDuration(firstAudioDuration!)).
                            Warm state: \(runtimeSnapshot.warmState.rawValue).
                            """
                        )
                    )
                }

                // A stop can land while diagnostics are recording, so re-check
                // cancellation before any buffered audio is enqueued.
                try Task.checkCancellation()

                if chunk.isParagraphPause == false {
                    producedAnyAudio = true
                }

                try await player.enqueue(chunk)

                if firstBufferScheduledDuration == nil {
                    firstBufferScheduledDuration = requestStart.duration(to: .now)
                    await diagnostics.record(
                        DiagnosticEvent(
                            name: "playback.first-buffer-scheduled",
                            detail: """
                            Engine \(engine.identifier) scheduled the first audio buffer after \(formatDuration(firstBufferScheduledDuration!)).
                            First engine audio: \(formatDuration(firstAudioDuration ?? .zero)).
                            """
                        )
                    )
                }

                try Task.checkCancellation()

                if await player.isPaused() == false {
                    currentState.status = .speaking
                }
            }
        } catch {
            await player.stop()
            throw error
        }

        guard producedAnyAudio else {
            await player.stop()
            throw SpeechPlaybackError.noAudioProduced(engine.identifier)
        }

        guard runID == activeRunID, Task.isCancelled == false else {
            throw CancellationError()
        }

        let totalGenerationDuration = requestStart.duration(to: .now)

        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.completed",
                detail: """
                Engine \(engine.identifier) completed generation in \(formatDuration(totalGenerationDuration)).
                First audio: \(formatDuration(firstAudioDuration ?? .zero)).
                Warm state: \(runtimeSnapshot.warmState.rawValue).
                """
            )
        )

        let drainStart = ContinuousClock.now
        await player.waitUntilDrained()

        // Only the still-active playback run may finalize success after drain.
        guard runID == activeRunID, Task.isCancelled == false else {
            throw CancellationError()
        }
        await diagnostics.record(
            DiagnosticEvent(
                name: "playback.drained",
                detail: "Audio player drained \(engine.identifier) playback in \(formatDuration(drainStart.duration(to: .now)))."
            )
        )
        currentState.status = .idle
        currentState.lastErrorDescription = nil
    }

    private func selectEngine(for mode: SpeechMode) async -> EngineSelection {
        let premiumSnapshot = await premiumSpeechEngine.runtimeSnapshot

        switch mode {
        case .premium:
            return EngineSelection(
                primary: premiumSpeechEngine,
                fallback: quickSpeechEngine,
                degradationDiagnostic: nil
            )
        case .quick:
            return EngineSelection(
                primary: quickSpeechEngine,
                fallback: nil,
                degradationDiagnostic: nil
            )
        case .auto:
            if premiumFailureCount >= premiumFailureThreshold {
                return EngineSelection(
                    primary: quickSpeechEngine,
                    fallback: nil,
                    degradationDiagnostic: DiagnosticEvent(
                        name: "engine.auto.degraded",
                        detail: "Auto mode selected Quick because Premium has failed \(premiumFailureCount) times in a row on this machine."
                    )
                )
            }

            if premiumSnapshot.warmState == .cold {
                return EngineSelection(
                    primary: quickSpeechEngine,
                    fallback: premiumSpeechEngine,
                    degradationDiagnostic: DiagnosticEvent(
                        name: "engine.auto.degraded",
                        detail: "Auto mode selected Quick because Premium is still cold on this machine."
                    )
                )
            }

            return EngineSelection(
                primary: premiumSpeechEngine,
                fallback: quickSpeechEngine,
                degradationDiagnostic: nil
            )
        }
    }

    private func describe(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return error.localizedDescription
    }

    private func formatDuration(_ duration: Duration) -> String {
        let milliseconds = Double(duration.components.seconds) * 1000
            + Double(duration.components.attoseconds) / 1_000_000_000_000_000
        return String(format: "%.0fms", milliseconds)
    }
}

private struct EngineSelection {
    let primary: SpeechEngine
    let fallback: SpeechEngine?
    let degradationDiagnostic: DiagnosticEvent?
}
