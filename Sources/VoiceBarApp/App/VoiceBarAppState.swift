import AppKit
import Carbon.HIToolbox
import Foundation
import Observation
import OSLog
import VoiceBarCore

private enum SnippetManagementError: Error, Sendable {
    case duplicateTrigger(ownerID: String)
    case notFound
}

private struct SnippetAliasRule: Sendable {
    var name: String
    var aliases: [String]
}

private struct AliasUpdateSummary: Sendable {
    var updatedRuleNames: [String]
    var missingRuleNames: [String]
    var conflictedRuleNames: [String]
}

@MainActor
@Observable
final class VoiceBarAppState {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ai.procureally.voicebar",
        category: "VoiceBarAppState"
    )

    let dependencies: DependencyContainer

    private let preferencesStore: VoiceBarPreferencesStore
    private let hotkeyManager: HotkeyManager
    private let floatingControllerPanelController: FloatingControllerPanelController
    private let launchAtLoginManager: LaunchAtLoginManager
    private let dictationCaptureController: DictationMicrophoneCaptureController
    private let textInsertionService: LiveTextInsertionService
    private let actionExecutor: DictationActionExecutor
    private let dictationSnippetStore = JSONDictationSnippetStore()
    private let wisprFlowSnippetImporter = WisprFlowSnippetImporter()

    private var hasBootstrapped = false
    private var serviceObserver: NSObjectProtocol?
    private var activeApplicationObserver: NSObjectProtocol?
    private var playbackObservationTask: Task<Void, Never>?
    private var pendingCustomStylePersistenceTask: Task<Void, Never>?
    private var floatingControllerDismissed = false
    private var floatingControllerShownManually = false
    private var floatingControllerNeedsAttention = false
    private var lastFloatingControllerVisibility: Bool?
    private var lastFloatingControllerStateDescription: String?
    private var hasPromptedForAccessibilityThisSession = false
    private var dictationTargetBundleIdentifier: String?
    private var lastNonVoiceBarApplication: NSRunningApplication?
    // Three-state model for hold-to-talk async startup safety:
    //   holdToTalkStartupInFlight — set when a press begins, cleared only after
    //     startDictation() fully resolves (NOT cleared by release). This is the
    //     primary guard that blocks a second press while the first startup is pending.
    //   holdToTalkKeyDesired — true while the key is physically held; cleared on release.
    //     When startup resolves we check this to decide whether to continue recording
    //     or stop immediately (key was released during async startup).
    // Together these prevent the race where a release clears the in-flight guard,
    // allowing a second press to start a concurrent startDictation() call.
    private var holdToTalkStartupInFlight = false
    private var holdToTalkKeyDesired = false
    private var hasAttemptedFormatterWarmUp = false
    private var formatterWarmUpRequestID: UInt64 = 0
    private var formatterWarmUpStatus = "pending"
    private var lastDictationFormatterModelIdentifier = ""
    private var lastDictationFormatterUsedFallback = false
    private var dictationConfirmationGeneration: UInt64 = 0
    private var lastDictationConfirmationRequestedAtNanoseconds: UInt64?
    // Current capture mode for the active dictation session.
    // true  => toggle dictation (auto-stop on silence)
    // false => hold-to-talk (stop on key release)
    private var dictationAutomaticallyStopsOnSilence = true

    var preferences: VoiceBarPreferences
    var selectedSettingsTab: SettingsTab = .general
    var playbackState = PlaybackState()
    var statusMessage = "VoiceBar is ready to read from Accessibility, Services, or the clipboard. Kokoro-backed Quick is the primary reading path when the local runtime is configured, and Premium remains available as an advanced fallback." {
        didSet {
            guard statusMessage != oldValue else {
                return
            }

            refreshFloatingControllerPresentation()
        }
    }
    var diagnosticsSummary = "No diagnostics captured yet."
    var recentDiagnosticEvents: [DiagnosticEvent] = []
    var ttsKitStatus = TTSKitBootstrapProbe.integrationStatus
    var knownProfiles: [AppProfile] = []
    var accessibilitySummary = "Accessibility access has not been granted yet. Read Selection will prompt when you use it."
    var launchAtLoginStatus = LaunchAtLoginStatus.unverifiedBundleRequirement
    var hotkeyStatusMessage = "Global hotkeys use the native exclusive Carbon registration path."
    var dictationStatus = "VoiceBar dictation is ready to transcribe locally once whisper.cpp and Ollama are available."
    var dictationRuntimeSummary = "Dictation runtime status has not been checked yet."
    var snippetImportStatus = "Wispr Flow snippet import has not been previewed yet."
    var snippetManagementStatus = "Local snippets have not been loaded yet."
    var dictationSnippets: [DictationSnippet] = []
    var isWisprFlowSnippetImportInFlight = false
    var lastDictationSummary = "No dictation captured yet."
    var dictationHistoryStatus = "Recent dictation recovery has not loaded yet."
    var recentDictationHistoryEntries: [DictationHistoryEntry] = []
    var lastDictationRecoveryConfirmation: String?
    var isDictationRecording = false
    var isDictationProcessing = false

    init(
        dependencies: DependencyContainer,
        preferencesStore: VoiceBarPreferencesStore = VoiceBarPreferencesStore(),
        hotkeyManager: HotkeyManager = HotkeyManager(),
        floatingControllerPanelController: FloatingControllerPanelController = FloatingControllerPanelController(),
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager(),
        dictationCaptureController: DictationMicrophoneCaptureController = DictationMicrophoneCaptureController(),
        textInsertionService: LiveTextInsertionService = LiveTextInsertionService(),
        actionExecutor: DictationActionExecutor = DictationActionExecutor()
    ) {
        self.dependencies = dependencies
        self.preferencesStore = preferencesStore
        self.hotkeyManager = hotkeyManager
        self.floatingControllerPanelController = floatingControllerPanelController
        self.launchAtLoginManager = launchAtLoginManager
        self.dictationCaptureController = dictationCaptureController
        self.textInsertionService = textInsertionService
        self.actionExecutor = actionExecutor
        self.preferences = preferencesStore.load()
        self.lastDictationFormatterModelIdentifier = dependencies.dictationFormatterService
            .resolvedModelIdentifier(for: self.preferences.formatterModelIdentifier)

        serviceObserver = NotificationCenter.default.addObserver(
            forName: .voiceBarServiceRequestedRead,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard
                let self,
                let text = notification.userInfo?[VoiceBarServiceBridgeKeys.text] as? String
            else {
                return
            }

            let bundleIdentifier = notification.userInfo?[VoiceBarServiceBridgeKeys.bundleIdentifier] as? String

            Task { @MainActor [weak self] in
                await self?.handleServiceRequest(
                    text: text,
                    bundleIdentifier: bundleIdentifier
                )
            }
        }

        activeApplicationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }

            Task { @MainActor [weak self] in
                self?.rememberSelectionHostIfNeeded(application)
            }
        }

        hotkeyManager.onAction = { [weak self] action in
            self?.handleHotkey(action)
        }

        hotkeyManager.onHoldToTalkPressed = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handleHoldToTalkPressed()
            }
        }

        hotkeyManager.onHoldToTalkReleased = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handleHoldToTalkReleased()
            }
        }
    }

    deinit {
        MainActor.assumeIsolated {
            if let serviceObserver {
                NotificationCenter.default.removeObserver(serviceObserver)
            }

            if let activeApplicationObserver {
                NSWorkspace.shared.notificationCenter.removeObserver(activeApplicationObserver)
            }

            playbackObservationTask?.cancel()
            pendingCustomStylePersistenceTask?.cancel()
            // Flush the latest debounced Settings edit so the custom instruction survives app shutdown.
            preferencesStore.save(preferences)
        }
    }

    static func live() -> VoiceBarAppState {
        VoiceBarAppState(dependencies: .live())
    }

    private var liveTextCaptureService: LiveTextCaptureService? {
        dependencies.textCaptureService as? LiveTextCaptureService
    }

    private var isRunningFromAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    private var preferredRevealBundleURL: URL {
        if isRunningFromAppBundle {
            return Bundle.main.bundleURL
        }

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("VoiceBar.app", isDirectory: true)
    }

    var availableVoices: [SpeechVoiceOption] {
        SpeechVoiceCatalog.allOptions
    }

    var availableStylePresets: [SpeechStylePreset] {
        SpeechStyleCatalog.presets
    }

    var statusIconName: String {
        if isDictationRecording {
            return "mic.fill"
        }

        if isDictationProcessing {
            return "text.bubble"
        }

        switch playbackState.status {
        case .idle:
            return "waveform"
        case .preparing:
            return "hourglass"
        case .speaking:
            return "speaker.wave.2"
        case .paused:
            return "pause.circle"
        case .failed:
            return "exclamationmark.triangle"
        }
    }

    var pauseResumeTitle: String {
        playbackState.status == .paused ? "Resume" : "Pause"
    }

    var canPauseOrResume: Bool {
        switch playbackState.status {
        case .speaking, .paused:
            return true
        case .idle, .preparing, .failed:
            return false
        }
    }

    var canStop: Bool {
        switch playbackState.status {
        case .idle:
            return false
        case .preparing, .speaking, .paused, .failed:
            return true
        }
    }

    var canReplayLast: Bool {
        playbackState.lastRequest != nil
    }

    var canCopyLastDictation: Bool {
        recentDictationHistoryEntries.first?.formattedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty == false
    }

    var canRetryLastDictation: Bool {
        canCopyLastDictation
            && isDictationRecording == false
            && isDictationProcessing == false
    }

    var currentVoiceOption: SpeechVoiceOption? {
        let voiceIdentifier = playbackState.lastRequest?.voiceIdentifier
            ?? preferences.selectedVoiceIdentifier
        return SpeechVoiceCatalog.option(for: voiceIdentifier)
    }

    var currentVoiceSummary: String {
        currentVoiceOption?.displayName ?? SpeechVoiceCatalog.defaultOption.displayName
    }

    var currentVoiceDetail: String {
        if let currentVoiceOption {
            return "\(currentVoiceOption.displayName) · \(currentVoiceOption.nativeLanguage)"
        }

        return "\(SpeechVoiceCatalog.defaultOption.displayName) · \(SpeechVoiceCatalog.defaultOption.nativeLanguage)"
    }

    var currentStylePresetName: String {
        preferences.selectedStylePresetName
    }

    var floatingControllerMenuTitle: String {
        shouldPresentFloatingController ? "Hide Floating Controller" : "Show Floating Controller"
    }

    func bootstrap() async {
        guard hasBootstrapped == false else {
            return
        }

        hasBootstrapped = true
        if let frontmostApplication = NSWorkspace.shared.frontmostApplication {
            rememberSelectionHostIfNeeded(frontmostApplication)
        }
        registerHotkeys()
        launchAtLoginStatus = launchAtLoginManager.currentStatus()
        await refreshProfiles()
        await refreshDiagnostics()
        await syncPlaybackState()
        await refreshSpeechRuntimeStatus()
        await refreshCaptureReadiness()
        await refreshDictationReadiness()
        await reloadDictationSnippets()
        await reloadDictationHistory()
        startPlaybackObservationLoop()

        Task(priority: .background) { @MainActor [weak self] in
            await self?.warmUpDictationFormatterIfNeeded(reason: "bootstrap")
        }

        Task(priority: .background) { @MainActor [weak self] in
            await self?.preloadQuickEngineIfNeeded()
        }

        if preferences.preloadPremiumEngine {
            Task(priority: .background) { @MainActor [weak self] in
                // Keep Premium available for explicit opt-in use, but let the
                // Kokoro-backed Quick path warm first because it is now the
                // truthful primary reading path on this operator Mac.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await self?.preloadPremiumEngineIfNeeded()
            }
        }

        if
            let liveTextCaptureService,
            await liveTextCaptureService.isAccessibilityTrusted() == false
        {
            Self.logger.warning("Accessibility trust missing during launch; waiting for an explicit Read Selection action before prompting.")
            statusMessage = "VoiceBar can read selected text after Accessibility access is granted. Use Open Accessibility Settings from the menu when you're ready. If the existing VoiceBar row still looks enabled but Read Selection keeps failing, remove and re-add ~/Applications/VoiceBar.app or the Desktop launcher. Use Read Clipboard in the meantime."
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "capture.accessibility.pendingOnLaunch",
                    detail: "Accessibility access was missing during launch, so VoiceBar stayed quiet until the operator explicitly requests Read Selection."
                )
            )
            await refreshCaptureReadiness()
            await refreshDiagnostics()
        }
    }

    func readSelection() async {
        await readSelection(trigger: .menuOrToolbar)
    }

    private func readSelection(trigger: ReadSelectionTrigger) async {
        Self.logger.info("Read Selection triggered from menu or hotkey.")
        let actionStart = ContinuousClock.now

        guard let liveTextCaptureService else {
            await recordStatusEvent(
                name: "capture.selection.unavailable",
                message: "VoiceBar could not find the live text capture service."
            )
            return
        }

        guard await ensureAccessibilityTrustIfPossible(using: liveTextCaptureService) else {
            await handleMissingAccessibilityTrust(
                promptEventName: "capture.accessibility.prompted",
                repeatedEventName: "capture.accessibility.pending",
                promptSourceDescription: "from Read Selection"
            )
            return
        }

        if trigger == .menuOrToolbar {
            await restoreSelectionHostIfNeeded(using: liveTextCaptureService)
            await waitForSelectionHostRecovery(using: liveTextCaptureService)
        }

        let bundleIdentifier = await liveTextCaptureService.frontmostBundleIdentifier()
        let profile = await dependencies.appProfileStore.profile(for: bundleIdentifier)

        do {
            // Keep the hotkey path on the same retry-capable accessibility
            // capture contract as the menu action so rapid shortcut use does
            // not take a weaker, timing-sensitive route.
            let capturedText = try await liveTextCaptureService.captureSelection(
                retryCount: 4,
                retryDelayNanoseconds: 150_000_000
            )
            await consumeCapturedText(
                capturedText,
                profile: profile,
                actionStart: actionStart
            )
        } catch {
            let shouldAttemptCopyFallback = preferences.copyFallbackEnabled
                && (profile?.allowClipboardFallback ?? false)
            var copyFallbackError: Error?

            if shouldAttemptCopyFallback {
                do {
                    let fallbackResult = try await liveTextCaptureService.captureSelectionUsingCopyFallback()
                    await consumeCapturedText(
                        fallbackResult.capturedText,
                        profile: profile,
                        copyFallbackDidRestoreClipboard: fallbackResult.didRestoreClipboard,
                        actionStart: actionStart
                    )
                    return
                } catch {
                    copyFallbackError = error
                }
            }

            await recordSelectionFailure(
                primaryError: error,
                copyFallbackError: copyFallbackError,
                copyFallbackWasEligible: shouldAttemptCopyFallback,
                profileExists: profile != nil,
                bundleIdentifier: bundleIdentifier
            )
        }
    }

    func readClipboard() async {
        Self.logger.info("Read Clipboard triggered from menu or hotkey.")
        let actionStart = ContinuousClock.now

        do {
            let capturedText = try await dependencies.textCaptureService.captureClipboard()
            let profile = await dependencies.appProfileStore.profile(
                for: capturedText.frontmostBundleIdentifier
            )
            await consumeCapturedText(
                capturedText,
                profile: profile,
                actionStart: actionStart
            )
        } catch {
            await recordStatusEvent(
                name: "capture.clipboard.failed",
                message: "VoiceBar could not read the clipboard. \(describe(error))"
            )
            presentFloatingControllerAttention()
        }
    }

    func stopPlayback() async {
        await dependencies.playbackController.stop()
        statusMessage = "Playback stopped and the queue was cleared."
        floatingControllerDismissed = false
        floatingControllerNeedsAttention = true
        await syncPlaybackState()
        await refreshDiagnostics()
    }

    func toggleDictation() async {
        do {
            if isDictationRecording {
                await stopDictation()
            } else if isDictationProcessing {
                await recordStatusEvent(
                    name: "dictation.start.blockedProcessing",
                    message: "VoiceBar is still transcribing and inserting the previous dictation. Please wait for that to finish before starting another one."
                )
            } else {
                await startDictation()
            }
        } catch {
            // Defensive: catch any unexpected errors to prevent app crash
            let errorMessage = "Dictation toggle failed: \(describe(error))"
            Self.logger.error("\(errorMessage, privacy: .public)")
            statusMessage = errorMessage
            dictationStatus = errorMessage
            isDictationRecording = false
            isDictationProcessing = false
            dictationAutomaticallyStopsOnSilence = true
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.toggle.criticalError",
                    detail: errorMessage
                )
            )
            await refreshDiagnostics()
        }
    }

    func startDictation(automaticallyStopsOnSilence: Bool = true) async {
        if isDictationRecording {
            statusMessage = "VoiceBar dictation is already recording."
            return
        }

        if isDictationProcessing {
            await recordStatusEvent(
                name: "dictation.start.blockedProcessing",
                message: "VoiceBar is still transcribing and inserting the previous dictation. Please wait for that to finish before starting another one."
            )
            return
        }

        let permissionGranted = await dictationCaptureController.requestPermission()
        guard permissionGranted else {
            dictationStatus = "VoiceBar needs microphone access before local dictation can start."
            statusMessage = dictationStatus
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.microphone.permissionDenied",
                    detail: "VoiceBar could not start dictation because microphone permission is missing."
                )
            )
            await refreshDiagnostics()
            return
        }

        do {
            dictationTargetBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            try dictationCaptureController.start(automaticallyStopsOnSilence: automaticallyStopsOnSilence) { [weak self] result in
                Task { @MainActor [weak self] in
                    await self?.handleCompletedDictationCapture(result)
                }
            }
            isDictationRecording = true
            dictationAutomaticallyStopsOnSilence = automaticallyStopsOnSilence
            dictationStatus = automaticallyStopsOnSilence
                ? "Recording dictation now. Speak naturally; VoiceBar will stop after a short pause."
                : "Listening now. Hold the shortcut while speaking; release it to transcribe and insert."
            statusMessage = dictationStatus
            presentFloatingControllerAttention()
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.capture.started",
                    detail: "VoiceBar started local dictation capture. Capture mode: \(automaticallyStopsOnSilence ? "toggle" : "hold-to-talk"). Auto-stop on silence: \(automaticallyStopsOnSilence). Toggle silence threshold: \(String(format: "%.2f", DictationMicrophoneCaptureController.toggleAutoStopSilenceSeconds))s. Speech amplitude threshold: \(String(format: "%.3f", DictationMicrophoneCaptureController.speechAmplitudeThreshold))."
                )
            )
            await refreshDiagnostics()
            refreshFloatingControllerPresentation()
        } catch {
            dictationStatus = "VoiceBar could not start dictation. \(describe(error))"
            statusMessage = dictationStatus
        }
    }

    func stopDictation() async {
        guard isDictationRecording else {
            statusMessage = "VoiceBar dictation is not currently recording."
            return
        }

        // Capture current metrics before stopCapture mutates internal buffers so
        // failure diagnostics can still report truthful values.
        let preStopSnapshot = dictationCaptureController.debugSnapshot()

        do {
            let captureResult = try dictationCaptureController.stopCapture()
            await handleCompletedDictationCapture(.success(captureResult))
        } catch {
            let snapshot = dictationCaptureController.debugSnapshot()
            let captureSnapshot = snapshot.sampleCount > 0 ? snapshot : preStopSnapshot
            isDictationRecording = false
            isDictationProcessing = false
            dictationAutomaticallyStopsOnSilence = true
            dictationStatus = "VoiceBar stopped dictation, but there was not enough audio to transcribe. Captured \(formatDuration(captureSnapshot.durationSeconds)) with peak \(formatAmplitude(captureSnapshot.peakAmplitude))."
            statusMessage = "\(dictationStatus) \(describe(error))"
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.capture.tooShort",
                    detail: "\(dictationStatus) Samples: \(captureSnapshot.sampleCount). Speech detected: \(captureSnapshot.hasObservedSpeech)."
                )
            )
            await refreshDiagnostics()
        }
    }

    func pauseOrResume() async {
        switch playbackState.status {
        case .speaking:
            await dependencies.playbackController.pause()
            statusMessage = "Playback paused."
        case .paused:
            await dependencies.playbackController.resume()
            statusMessage = "Playback resumed."
        case .idle, .preparing, .failed:
            statusMessage = "Pause and resume are available while VoiceBar is actively speaking."
        }

        await syncPlaybackState()
        await refreshDiagnostics()
    }

    func replayLast() async {
        do {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "playback.replay.requested",
                    detail: "Replay requested from menu, hotkey, or floating controller. Existing playback state: \(playbackState.status.rawValue)."
                )
            )
            try await dependencies.playbackController.replayLast()
            statusMessage = "Replaying the last speech request."
        } catch {
            statusMessage = error.localizedDescription
        }

        await syncPlaybackState()
        await refreshDiagnostics()
    }

    func refreshProfiles() async {
        do {
            knownProfiles = try await dependencies.appProfileStore.loadProfiles()
        } catch {
            statusMessage = "VoiceBar could not load the per-app profiles. \(describe(error))"
        }
    }

    func refreshDiagnostics() async {
        let nextEvents = await dependencies.diagnostics.recentEvents(limit: 25)
        let nextSummary = nextEvents.isEmpty
            ? "No diagnostics captured yet."
            : nextEvents
                .prefix(3)
                .map { "\($0.name): \($0.detail)" }
                .joined(separator: "\n")

        if recentDiagnosticEvents != nextEvents {
            recentDiagnosticEvents = nextEvents
        }

        if diagnosticsSummary != nextSummary {
            diagnosticsSummary = nextSummary
        }
    }

    func syncPlaybackState() async {
        let previousState = playbackState
        let wasFloatingControllerDismissed = floatingControllerDismissed
        playbackState = await dependencies.playbackController.state()

        if previousState.status == .preparing,
           playbackState.status == .speaking,
           statusMessage.contains("Waiting for first audio")
        {
            statusMessage = "VoiceBar is now speaking with \(currentVoiceSummary)."
        }

        if previousState.status == .idle, playbackState.status != .idle {
            floatingControllerDismissed = false
            floatingControllerNeedsAttention = false
        }

        if playbackState != previousState || floatingControllerDismissed != wasFloatingControllerDismissed {
            refreshFloatingControllerPresentation()
        }
    }

    func refreshSpeechRuntimeStatus() async {
        let premiumAvailability = await dependencies.premiumSpeechEngine.availability
        let quickAvailability = await dependencies.quickSpeechEngine.availability

        ttsKitStatus = [
            "Quick: \(availabilitySummary(for: quickAvailability))",
            "Premium: \(availabilitySummary(for: premiumAvailability))"
        ].joined(separator: "\n")
    }

    func selectSettingsTab(_ tab: SettingsTab) {
        selectedSettingsTab = tab
    }

    func openAccessibilitySettings() {
        let accessibilityURL = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )

        if let accessibilityURL {
            NSWorkspace.shared.open(accessibilityURL)
        }
    }

    func revealInstalledAppInFinder() {
        let bundleURL = preferredRevealBundleURL

        if FileManager.default.fileExists(atPath: bundleURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
        } else {
            NSWorkspace.shared.open(bundleURL.deletingLastPathComponent())
        }
    }

    func relaunchInstalledApp() {
        let bundleURL = preferredRevealBundleURL
        guard FileManager.default.fileExists(atPath: bundleURL.path) else {
            statusMessage = "VoiceBar could not find the installed app bundle at \(bundleURL.path). Run bash scripts/run.sh to rebuild and reinstall it locally."
            return
        }

        Self.logger.info("Relaunching VoiceBar from installed bundle path \(bundleURL.path, privacy: .public).")

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { [weak self] _, error in
            if let error {
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    self.statusMessage = "VoiceBar could not relaunch the installed app bundle. \(self.describe(error))"
                }
                return
            }

            Task { @MainActor in
                NSApp.terminate(nil)
            }
        }
    }

    func selectMode(_ mode: SpeechMode) {
        preferences.selectedMode = mode
        persistPreferences()
        switch mode {
        case .quick:
            statusMessage = "Default reading path updated to Quick. VoiceBar will prefer Kokoro on this Mac when the local runtime is configured, and per-app profiles can still override it."
        case .premium:
            statusMessage = "Default reading path updated to Premium. Premium now remains an explicit advanced path on this Mac, and per-app profiles can still override it."
        case .auto:
            statusMessage = "Default reading path updated to Auto. VoiceBar may still choose Quick first while Premium is cold or degraded, and per-app profiles can still override it."
        }
    }

    func selectStylePreset(_ presetName: String) {
        preferences.selectedStylePresetName = presetName
        persistPreferences()

        if presetName == SpeechStyleCatalog.customPresetName {
            statusMessage = "Custom instruction is now the active global style. Fill in the custom text in Settings to make it speak differently."
        } else {
            statusMessage = "Default style preset updated to \(presetName)."
        }
    }

    func updateCustomStyleInstruction(_ customInstruction: String) {
        preferences.customStyleInstruction = customInstruction
        scheduleCustomStyleInstructionPersistence()
    }

    func selectVoice(identifier: String) {
        preferences.selectedVoiceIdentifier = identifier
        persistPreferences()

        if preferences.preloadPremiumEngine {
            Task { @MainActor [weak self] in
                await self?.preloadPremiumEngineIfNeeded()
            }
        }

        if let option = SpeechVoiceCatalog.option(for: identifier) {
            statusMessage = "Default voice updated to \(option.displayName)."
        } else {
            statusMessage = "Default voice updated."
        }
    }

    func updateFormatterModelIdentifier(_ modelIdentifier: String) {
        let normalizedModelIdentifier = modelIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedModelIdentifier != preferences.formatterModelIdentifier else {
            return
        }

        preferences.formatterModelIdentifier = normalizedModelIdentifier
        lastDictationFormatterModelIdentifier = dependencies.dictationFormatterService
            .resolvedModelIdentifier(for: normalizedModelIdentifier)
        hasAttemptedFormatterWarmUp = false
        formatterWarmUpStatus = "pending"
        persistPreferences()
        Task { @MainActor [weak self] in
            await self?.refreshDictationReadiness()
            await self?.warmUpDictationFormatterIfNeeded(reason: "formatterModelChange")
        }
    }

    func setDictationFormattingMode(_ formattingMode: DictationFormattingMode) {
        preferences.dictationFormattingMode = formattingMode
        persistPreferences()
    }

    func setDictationFormatterQualityMode(_ qualityMode: DictationFormatterQualityMode) {
        preferences.dictationFormatterQualityMode = qualityMode
        persistPreferences()
        Task { @MainActor [weak self] in
            await self?.refreshDictationReadiness()
        }
    }

    func setInsertDictationAtCursor(_ isEnabled: Bool) {
        preferences.insertDictationAtCursor = isEnabled
        persistPreferences()
    }

    func setAutoRunTrustedActions(_ isEnabled: Bool) {
        preferences.autoRunTrustedActions = isEnabled
        persistPreferences()
    }

    func setDictationAudioConfirmationEnabled(_ isEnabled: Bool) {
        preferences.dictationAudioConfirmationEnabled = isEnabled
        persistPreferences()
    }

    func setSaveRecentDictationsForRecovery(_ isEnabled: Bool) {
        preferences.saveRecentDictationsForRecovery = isEnabled
        if isEnabled == false {
            lastDictationRecoveryConfirmation = nil
        }
        persistPreferences()

        statusMessage = isEnabled
            ? "Recent dictation recovery is on. VoiceBar saves the raw and formatted text locally before insertion."
            : "Recent dictation recovery is off. New dictations will not be saved to the local rescue buffer."
    }

    func setDictationHistoryRetentionLimit(_ retentionLimit: Int) {
        preferences.dictationHistoryRetentionLimit = VoiceBarPreferences
            .sanitizedDictationHistoryRetentionLimit(retentionLimit)
        persistPreferences()

        Task { @MainActor [weak self] in
            await self?.trimDictationHistoryToPreference()
        }
    }

    func setCopyFallbackEnabled(_ isEnabled: Bool) {
        preferences.copyFallbackEnabled = isEnabled
        persistPreferences()

        statusMessage = isEnabled
            ? "Experimental copy fallback is on. VoiceBar will only try it after Accessibility selection capture fails."
            : "Experimental copy fallback is off. VoiceBar will steer you toward Services or Read Clipboard when Accessibility cannot read the current app."
    }

    func setPreloadPremiumEngine(_ isEnabled: Bool) {
        preferences.preloadPremiumEngine = isEnabled
        persistPreferences()

        if isEnabled {
            Task { @MainActor [weak self] in
                await self?.preloadPremiumEngineIfNeeded()
            }
        } else {
            statusMessage = "Premium background preload is off. VoiceBar will still prepare Premium on demand when you explicitly route playback there."
        }
    }

    func setFloatingControllerEnabled(_ isEnabled: Bool) {
        preferences.floatingControllerEnabled = isEnabled

        if isEnabled == false {
            floatingControllerDismissed = true
            floatingControllerShownManually = false
            floatingControllerNeedsAttention = false
        } else {
            floatingControllerDismissed = false
        }

        persistPreferences()
    }

    func toggleFloatingControllerVisibility() {
        if shouldPresentFloatingController {
            dismissFloatingController()
        } else {
            floatingControllerDismissed = false
            floatingControllerShownManually = true
            refreshFloatingControllerPresentation()
        }
    }

    func dismissFloatingController() {
        floatingControllerDismissed = true
        floatingControllerShownManually = false
        floatingControllerNeedsAttention = false
        recordFloatingControllerEvent(
            name: "floatingController.dismissed",
            detail: "The floating controller was dismissed by an explicit close or toggle action."
        )
        refreshFloatingControllerPresentation()
    }

    func setHotkeysEnabled(_ isEnabled: Bool) {
        preferences.hotkeysEnabled = isEnabled
        persistPreferences()
        registerHotkeys()
    }

    func updateHotkey(
        _ shortcut: HotkeyShortcut,
        for action: HotkeyAction
    ) {
        if preferences.holdToTalkEnabled,
           preferences.holdToTalkMode == .optionShortcut,
           VoiceBarPreferences.shortcutsConflict(
               shortcut,
               preferences.sanitizedHoldToTalkShortcut
           )
        {
            let conflictMessage = "\(action.title) cannot use the same shortcut as Hold-to-Talk. Choose a different shortcut for \(action.title) or Hold-to-Talk."
            hotkeyStatusMessage = conflictMessage
            statusMessage = conflictMessage
            return
        }

        preferences.setShortcut(shortcut, for: action)
        persistPreferences()
        registerHotkeys()
    }

    func setHoldToTalkEnabled(_ isEnabled: Bool) {
        preferences.holdToTalkEnabled = isEnabled

        if isEnabled, preferences.holdToTalkMode == .optionShortcut {
            ensureHoldToTalkShortcutDoesNotConflict()
        }

        persistPreferences()
        registerHotkeys()
    }

    func setHoldToTalkMode(_ mode: HoldToTalkMode) {
        preferences.holdToTalkMode = mode

        if mode == .optionShortcut {
            ensureHoldToTalkShortcutDoesNotConflict()
        }

        persistPreferences()
        registerHotkeys()

        switch mode {
        case .optionShortcut:
            statusMessage = "Hold-to-talk now uses the configured Option shortcut."
        case .functionKeyExperimental:
            statusMessage = "Function key (Fn) hold-to-talk is experimental. VoiceBar must observe both press and release events on this Mac before it is trusted."
        }
    }

    func updateHoldToTalkShortcut(_ shortcut: HotkeyShortcut) {
        let sanitizedShortcut = VoiceBarPreferences.sanitizedHoldToTalkShortcut(shortcut)

        if VoiceBarPreferences.shortcutsConflict(
            sanitizedShortcut,
            preferences.shortcut(for: .toggleDictation)
        ) {
            let toggleShortcut = preferences.shortcut(for: .toggleDictation).displayString
            let conflictMessage = "Hold-to-Talk cannot use the same shortcut as Toggle Dictation (currently \(toggleShortcut)). Choose another Hold-to-Talk key."
            hotkeyStatusMessage = conflictMessage
            statusMessage = conflictMessage
            return
        }

        preferences.holdToTalkShortcut = sanitizedShortcut
        persistPreferences()
        registerHotkeys()
    }

    func saveProfile(_ profile: AppProfile) async {
        let normalizedBundleIdentifier = profile.bundleIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedBundleIdentifier.isEmpty == false else {
            statusMessage = "Per-app profile saves need a bundle identifier."
            return
        }

        var savedProfile = profile
        savedProfile.bundleIdentifier = normalizedBundleIdentifier

        do {
            try await dependencies.appProfileStore.upsert(savedProfile)
            statusMessage = "Saved the VoiceBar profile for \(normalizedBundleIdentifier)."
            await refreshProfiles()
        } catch {
            statusMessage = "VoiceBar could not save the app profile. \(describe(error))"
        }
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = launchAtLoginManager.currentStatus()
    }

    func revealSnippetStoreInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([VoiceBarStorageLocation.dictationSnippetsURL])
    }

    func revealWisprFlowImportReportsInFinder() {
        let reportURLs = [
            VoiceBarStorageLocation.wisprFlowSnippetsPreviewReportURL,
            VoiceBarStorageLocation.wisprFlowSnippetsApplyReportURL
        ].filter { FileManager.default.fileExists(atPath: $0.path) }

        guard reportURLs.isEmpty == false else {
            snippetImportStatus = "No private Wispr Flow import reports exist yet. Run Preview Import or Apply Import first."
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting(reportURLs)
    }

    func reloadDictationSnippets() async {
        do {
            let snippets = try await dictationSnippetStore.loadSnippets()
            dictationSnippets = snippets
            snippetImportStatus = "Reloaded \(snippets.count) VoiceBar snippets from the editable local file."
            snippetManagementStatus = "Loaded \(snippets.count) local snippets."
            await ensureOperatorCriticalSnippetAliasesIfNeeded(snippets: snippets)
            await refreshDictationReadiness()
        } catch {
            snippetImportStatus = "VoiceBar could not reload snippets. \(describe(error))"
            snippetManagementStatus = "VoiceBar could not load snippets. \(describe(error))"
        }
    }

    func saveDictationSnippet(_ snippet: DictationSnippet) async {
        do {
            let sanitizedSnippet = Self.sanitizedSnippetForStorage(snippet)
            let update = try await dictationSnippetStore.updateSnippets(creatingBackup: true) { currentSnippets in
                var snippets = currentSnippets
                let existingTriggersBySnippet = snippets
                    .filter { $0.id != sanitizedSnippet.id }
                    .flatMap { existingSnippet in
                        existingSnippet.triggers.map { trigger in
                            (Self.normalizedSnippetTrigger(trigger), existingSnippet.id)
                        }
                    }
                let sanitizedTriggers = Set(sanitizedSnippet.triggers.map(Self.normalizedSnippetTrigger))
                if let duplicate = existingTriggersBySnippet.first(where: { sanitizedTriggers.contains($0.0) }) {
                    throw SnippetManagementError.duplicateTrigger(ownerID: duplicate.1)
                }

                if let existingIndex = snippets.firstIndex(where: { $0.id == sanitizedSnippet.id }) {
                    snippets[existingIndex] = sanitizedSnippet
                } else {
                    snippets.append(sanitizedSnippet)
                }

                return snippets
            }

            dictationSnippets = update.snippets
            snippetManagementStatus = "Saved snippet '\(Self.snippetDisplayLabel(sanitizedSnippet))'."
            snippetImportStatus = "Saved \(update.snippets.count) local snippets."
            await refreshDictationReadiness()
        } catch SnippetManagementError.duplicateTrigger(let ownerID) {
            snippetManagementStatus = "VoiceBar did not save this snippet because one trigger phrase already belongs to snippet \(ownerID)."
        } catch {
            snippetManagementStatus = "VoiceBar could not save the snippet. \(describe(error))"
        }
    }

    func deleteDictationSnippet(id: String) async {
        do {
            let update = try await dictationSnippetStore.updateSnippets(creatingBackup: true) { snippets in
                let remainingSnippets = snippets.filter { $0.id != id }
                guard remainingSnippets.count != snippets.count else {
                    throw SnippetManagementError.notFound
                }

                return remainingSnippets
            }

            dictationSnippets = update.snippets
            snippetManagementStatus = "Deleted snippet."
            snippetImportStatus = "Saved \(update.snippets.count) local snippets."
            await refreshDictationReadiness()
        } catch SnippetManagementError.notFound {
            snippetManagementStatus = "Snippet was already removed."
        } catch {
            snippetManagementStatus = "VoiceBar could not delete the snippet. \(describe(error))"
        }
    }

    func previewWisprFlowSnippetImport() async {
        guard isWisprFlowSnippetImportInFlight == false else {
            snippetImportStatus = "Wispr Flow snippet import is already running."
            return
        }

        isWisprFlowSnippetImportInFlight = true
        defer {
            isWisprFlowSnippetImportInFlight = false
        }

        do {
            let inputData = try await Task.detached(priority: .userInitiated) {
                try Self.loadWisprFlowImportInputData()
            }.value
            let existingSnippets = try await dictationSnippetStore.loadSnippets()
            let importer = wisprFlowSnippetImporter
            let preview = try await Task.detached(priority: .userInitiated) {
                try importer.previewImport(
                    from: inputData.exportData,
                    manifestData: inputData.manifestData,
                    existingSnippets: existingSnippets
                )
            }.value

            var status = Self.describe(preview: preview)
            do {
                try writeWisprFlowImportReport(
                    preview,
                    to: VoiceBarStorageLocation.wisprFlowSnippetsPreviewReportURL
                )
            } catch {
                status += " Preview succeeded, but the count-only report could not be saved. \(describe(error))"
            }

            snippetImportStatus = status
        } catch {
            snippetImportStatus = "Wispr Flow snippet preview failed. \(describe(error))"
        }
    }

    func applyWisprFlowSnippetImport() async {
        guard isWisprFlowSnippetImportInFlight == false else {
            snippetImportStatus = "Wispr Flow snippet import is already running."
            return
        }

        isWisprFlowSnippetImportInFlight = true
        defer {
            isWisprFlowSnippetImportInFlight = false
        }

        do {
            let inputData = try await Task.detached(priority: .userInitiated) {
                try Self.loadWisprFlowImportInputData()
            }.value
            let importer = wisprFlowSnippetImporter
            let summary = try await Task.detached(priority: .userInitiated) {
                try await importer.applyImport(
                    from: inputData.exportData,
                    manifestData: inputData.manifestData
                )
            }.value

            var status = Self.describe(summary: summary)
            do {
                try writeWisprFlowImportReport(
                    WisprFlowSnippetApplyReport(summary: summary),
                    to: VoiceBarStorageLocation.wisprFlowSnippetsApplyReportURL
                )
            } catch {
                status += " Import succeeded, but the count-only report could not be saved. \(describe(error))"
            }

            snippetImportStatus = status
            await refreshDictationReadiness()
            await reloadDictationSnippets()
        } catch {
            snippetImportStatus = "Wispr Flow snippet import failed. \(describe(error))"
        }
    }

    func revealActionRegistryInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([VoiceBarStorageLocation.dictationActionsURL])
    }

    func revealDictationHistoryInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([VoiceBarStorageLocation.dictationHistoryURL])
    }

    func reloadDictationHistory() async {
        do {
            let entries = try await dependencies.dictationHistoryStore.loadEntries()
            recentDictationHistoryEntries = entries
            dictationHistoryStatus = entries.isEmpty
                ? "No recent dictations are saved yet."
                : "Loaded \(entries.count) recent dictation\(entries.count == 1 ? "" : "s") from the local rescue buffer."
        } catch {
            recentDictationHistoryEntries = []
            lastDictationRecoveryConfirmation = nil
            dictationHistoryStatus = "VoiceBar could not load recent dictations. \(describe(error))"
        }
    }

    func copyLastDictationToClipboard() {
        guard let entry = recentDictationHistoryEntries.first else {
            statusMessage = "No recent dictation is available to copy."
            return
        }

        copyDictationHistoryEntry(id: entry.id)
    }

    func copyDictationHistoryEntry(id: String) {
        guard let entry = recentDictationHistoryEntries.first(where: { $0.id == id }) else {
            statusMessage = "VoiceBar could not find that recent dictation."
            return
        }

        let text = entry.formattedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else {
            statusMessage = "That recent dictation has no formatted text to copy."
            return
        }

        do {
            try textInsertionService.copyToClipboard(text)
            let message = "Copied \(formattedCharacterCount(text.count)) from recent dictation history."
            statusMessage = message
            dictationHistoryStatus = message
            Task { [dependencies] in
                await dependencies.diagnostics.record(
                    DiagnosticEvent(
                        name: "dictation.history.copied",
                        detail: "entryToken=\(Self.redactedDiagnosticToken(for: entry.id)) formattedChars=\(text.count)"
                    )
                )
            }
        } catch {
            statusMessage = "VoiceBar could not copy the recent dictation. \(describe(error))"
        }
    }

    func retryInsertLastDictation() async {
        guard isDictationRecording == false, isDictationProcessing == false else {
            statusMessage = "VoiceBar cannot retry a recent dictation while another dictation is recording or processing."
            return
        }

        guard let entry = recentDictationHistoryEntries.first else {
            statusMessage = "No recent dictation is available to retry."
            return
        }

        await retryInsertDictationHistoryEntry(id: entry.id)
    }

    func retryInsertDictationHistoryEntry(id: String) async {
        guard isDictationRecording == false, isDictationProcessing == false else {
            statusMessage = "VoiceBar cannot retry a recent dictation while another dictation is recording or processing."
            return
        }

        guard let entry = recentDictationHistoryEntries.first(where: { $0.id == id }) else {
            statusMessage = "VoiceBar could not find that recent dictation."
            return
        }

        let text = entry.formattedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else {
            statusMessage = "That recent dictation has no formatted text to retry."
            return
        }

        let insertionSummary = await insertDictationOutputIfNeeded(text)
        statusMessage = "Retried recent dictation. \(insertionSummary)"
        dictationHistoryStatus = statusMessage
        await updateDictationRecoveryEntryIfNeeded(
            entryID: entry.id,
            insertionSummary: "Retry: \(insertionSummary)"
        )
    }

    func showRecentDictations() {
        selectedSettingsTab = .dictation
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        statusMessage = "Recent dictations are available in Settings > Dictation."
    }

    func clearDictationHistory() async {
        do {
            try await dependencies.dictationHistoryStore.clearEntries()
            recentDictationHistoryEntries = []
            lastDictationRecoveryConfirmation = nil
            dictationHistoryStatus = "Cleared recent dictation history from local storage."
            statusMessage = dictationHistoryStatus
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.history.cleared",
                    detail: "Recent dictation history was cleared by explicit operator action."
                )
            )
        } catch {
            dictationHistoryStatus = "VoiceBar could not clear recent dictation history. \(describe(error))"
            statusMessage = dictationHistoryStatus
        }
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        do {
            launchAtLoginStatus = try launchAtLoginManager.setEnabled(isEnabled)
            statusMessage = launchAtLoginStatus.detail
        } catch {
            launchAtLoginStatus = launchAtLoginManager.currentStatus()
            statusMessage = "VoiceBar could not update launch at login. \(describe(error))"
        }
    }

    private func refreshCaptureReadiness() async {
        guard let liveTextCaptureService else {
            accessibilitySummary = "Accessibility status is unavailable because the live capture service is not wired."
            return
        }

        let isTrusted = await liveTextCaptureService.isAccessibilityTrusted()
        if isTrusted {
            hasPromptedForAccessibilityThisSession = false
            floatingControllerNeedsAttention = false
        }

        accessibilitySummary = isTrusted
            ? "Accessibility access is granted. Read Selection inspects the focused UI element first."
            : missingAccessibilitySummary()
    }

    private func refreshDictationReadiness() async {
        let speechToTextAvailability = await dependencies.speechToTextService.availability()
        let formatterStatus = await dependencies.dictationFormatterService.availability()
        let resolvedFormatterModel = dependencies.dictationFormatterService
            .resolvedModelIdentifier(for: preferences.formatterModelIdentifier)
        lastDictationFormatterModelIdentifier = resolvedFormatterModel

        let whisperStatusLine = "whisper.cpp: \(availabilitySummary(for: speechToTextAvailability))"
        let formatterStatusLine = "Ollama formatter: \(availabilitySummary(for: formatterStatus))"
        let formatterModelLine = "Formatter model: \(resolvedFormatterModel)"
        let formatterBaseTimeout = OllamaFormatterService.formattedTimeoutSeconds(
            OllamaFormatterService.requestTimeoutSeconds(for: preferences.dictationFormatterQualityMode)
        )
        let formatterQualityLine = "Formatter quality: \(preferences.dictationFormatterQualityMode.rawValue) (\(formatterBaseTimeout)s base timeout)"
        let warmUpLine = "Formatter warm-up: \(formatterWarmUpStatus)"
        let fallbackLine = lastDictationFormatterUsedFallback
            ? "Last dictation used formatter fallback."
            : "Last dictation used primary formatter path."

        dictationRuntimeSummary = [
            whisperStatusLine,
            formatterStatusLine,
            formatterModelLine,
            formatterQualityLine,
            warmUpLine,
            fallbackLine
        ].joined(separator: "\n")
    }

    private func warmUpDictationFormatterIfNeeded(reason: String) async {
        guard hasAttemptedFormatterWarmUp == false else {
            return
        }

        hasAttemptedFormatterWarmUp = true
        formatterWarmUpRequestID &+= 1
        let requestID = formatterWarmUpRequestID
        let requestedModel = dependencies.dictationFormatterService
            .resolvedModelIdentifier(for: preferences.formatterModelIdentifier)

        formatterWarmUpStatus = "running"
        await refreshDictationReadiness()

        let warmUpResult = await dependencies.dictationFormatterService.warmUp(
            modelIdentifier: requestedModel
        )

        let currentResolvedModel = dependencies.dictationFormatterService
            .resolvedModelIdentifier(for: preferences.formatterModelIdentifier)
        let isStaleResult = requestID != formatterWarmUpRequestID
            || warmUpResult.modelIdentifier != currentResolvedModel

        if isStaleResult {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.formatter.warmup.ignoredStale",
                    detail: "Reason=\(reason) staleModel=\(warmUpResult.modelIdentifier) currentModel=\(currentResolvedModel) elapsedMs=\(warmUpResult.elapsedMilliseconds)"
                )
            )
            return
        }

        let elapsed = formatMilliseconds(warmUpResult.elapsedMilliseconds)
        if warmUpResult.didSucceed {
            formatterWarmUpStatus = "ready (\(warmUpResult.modelIdentifier), \(elapsed))"
        } else {
            formatterWarmUpStatus = "degraded (\(warmUpResult.modelIdentifier)); continuing without warm-up"
        }

        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: warmUpResult.didSucceed ? "dictation.formatter.warmup.succeeded" : "dictation.formatter.warmup.failed",
                detail: "Reason=\(reason) model=\(warmUpResult.modelIdentifier) elapsedMs=\(warmUpResult.elapsedMilliseconds) detail=\(warmUpResult.detail)"
            )
        )

        await refreshDictationReadiness()
        await refreshDiagnostics()
    }

    private func preloadPremiumEngineIfNeeded() async {
        guard preferences.preloadPremiumEngine else {
            return
        }

        do {
            try await dependencies.premiumSpeechEngine.prepare()

            if let premiumEngine = dependencies.premiumSpeechEngine as? TTSKitSpeechEngine {
                try await premiumEngine.prewarmPromptCache(
                    voiceIdentifier: preferences.selectedVoiceIdentifier,
                    styleInstruction: SpeechStyleCatalog.instruction(
                        for: preferences.selectedStylePresetName,
                        customInstruction: preferences.customStyleInstruction
                    )
                )
            }

            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "engine.premium.preloaded",
                    detail: "Prepared the Premium engine and pre-warmed the selected voice/style cache during app bootstrap because preload is enabled."
                )
            )
            await refreshSpeechRuntimeStatus()
            await refreshDiagnostics()
        } catch {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "engine.premium.preloadFailed",
                    detail: "Premium preload failed during bootstrap: \(describe(error))"
                )
            )
            statusMessage = "Premium preload failed during launch. VoiceBar can still fall back to on-demand preparation. \(describe(error))"
            await refreshSpeechRuntimeStatus()
            await refreshDiagnostics()
        }
    }

    private func preloadQuickEngineIfNeeded() async {
        let snapshot = await dependencies.quickSpeechEngine.runtimeSnapshot
        guard snapshot.warmState == .cold else {
            return
        }

        do {
            try await dependencies.quickSpeechEngine.prepare()
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "engine.quick.preloaded",
                    detail: "Prepared the Quick engine in the background so the fallback path stays ready for interactive playback."
                )
            )
            await refreshSpeechRuntimeStatus()
            await refreshDiagnostics()
        } catch {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "engine.quick.preloadFailed",
                    detail: "Quick preload failed in the background: \(describe(error))"
                )
            )
            await refreshSpeechRuntimeStatus()
            await refreshDiagnostics()
        }
    }

    private func startPlaybackObservationLoop() {
        playbackObservationTask?.cancel()
        playbackObservationTask = Task { @MainActor [weak self] in
            while Task.isCancelled == false {
                guard let self else {
                    return
                }

                let previousState = self.playbackState
                await self.syncPlaybackState()

                if self.playbackState != previousState {
                    await self.refreshSpeechRuntimeStatus()
                    await self.refreshDiagnostics()
                }

                let sleepDuration: Duration
                if self.playbackState.status == .idle {
                    sleepDuration = .seconds(2)
                } else {
                    sleepDuration = .milliseconds(400)
                }

                try? await Task.sleep(for: sleepDuration)
            }
        }
    }

    private var shouldPresentFloatingController: Bool {
        if floatingControllerShownManually {
            return true
        }

        guard preferences.floatingControllerEnabled else {
            return false
        }

        guard floatingControllerDismissed == false else {
            return false
        }

        if floatingControllerNeedsAttention {
            return true
        }

        switch playbackState.status {
        case .idle:
            return false
        case .preparing, .speaking, .paused, .failed:
            return true
        }
    }

    private func refreshFloatingControllerPresentation() {
        let isVisible = shouldPresentFloatingController
        let stateDescription = [
            "visible=\(isVisible)",
            "status=\(playbackState.status.rawValue)",
            "dismissed=\(floatingControllerDismissed)",
            "manual=\(floatingControllerShownManually)",
            "attention=\(floatingControllerNeedsAttention)",
            "canReplay=\(canReplayLast)"
        ].joined(separator: " ")

        if let lastFloatingControllerVisibility,
           lastFloatingControllerVisibility != isVisible
        {
            recordFloatingControllerEvent(
                name: "floatingController.visibility.changed",
                detail: "Floating controller visibility changed to \(isVisible)."
            )
        }

        if lastFloatingControllerStateDescription != stateDescription {
            recordFloatingControllerEvent(
                name: "floatingController.state.changed",
                detail: stateDescription
            )
        }

        lastFloatingControllerVisibility = isVisible
        lastFloatingControllerStateDescription = stateDescription

        floatingControllerPanelController.update(
            snapshot: FloatingControllerSnapshot(
                statusText: playbackStatusTitle(),
                detailText: statusMessage,
                engineText: playbackState.currentEngineIdentifier ?? preferences.selectedMode.rawValue,
                voiceText: currentVoiceSummary,
                isDictationRecording: isDictationRecording,
                isDictationProcessing: isDictationProcessing,
                dictationAutomaticallyStopsOnSilence: dictationAutomaticallyStopsOnSilence,
                formatterModelText: "Formatter: \(lastDictationFormatterModelIdentifier)",
                formatterUsedFallback: lastDictationFormatterUsedFallback,
                dictationRecoveryText: lastDictationRecoveryConfirmation,
                pauseResumeTitle: pauseResumeTitle,
                canPauseResume: canPauseOrResume,
                canStop: canStop,
                canReplay: canReplayLast,
                canCopyLastDictation: canCopyLastDictation
            ),
            isVisible: isVisible,
            onPauseResume: { [weak self] in
                Task { @MainActor in
                    await self?.pauseOrResume()
                }
            },
            onStop: { [weak self] in
                Task { @MainActor in
                    await self?.stopPlayback()
                }
            },
            onReplay: { [weak self] in
                Task { @MainActor in
                    await self?.replayLast()
                }
            },
            onCopyLastDictation: { [weak self] in
                self?.copyLastDictationToClipboard()
            },
            onOpenDictationHistory: { [weak self] in
                self?.showRecentDictations()
            },
            onDismiss: { [weak self] in
                self?.dismissFloatingController()
            }
        )
    }

    private func recordFloatingControllerEvent(name: String, detail: String) {
        Task { [dependencies] in
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: name,
                    detail: detail
                )
            )
        }
    }

    private func persistPreferences() {
        pendingCustomStylePersistenceTask?.cancel()
        pendingCustomStylePersistenceTask = nil
        preferencesStore.save(preferences)
        refreshFloatingControllerPresentation()
    }

    private func scheduleCustomStyleInstructionPersistence() {
        pendingCustomStylePersistenceTask?.cancel()
        pendingCustomStylePersistenceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))

            guard let self, Task.isCancelled == false else {
                return
            }

            // Debounce the full preferences write so the custom-instruction TextEditor does not re-save the whole shell payload on every keystroke.
            self.preferencesStore.save(self.preferences)
            self.pendingCustomStylePersistenceTask = nil
        }
    }

    private func registerHotkeys() {
        ensureHoldToTalkShortcutDoesNotConflict()

        let result = hotkeyManager.updateRegistrations(using: preferences)

        if preferences.hotkeysEnabled == false {
            hotkeyStatusMessage = "Global hotkeys are turned off."
            Self.logger.info("Global hotkeys are disabled in preferences.")
            return
        }

        var statusParts: [String] = []

        if result.failures.isEmpty == false {
            let failedActions = result.failures
                .map { describeHotkeyRegistrationFailure($0) }
                .joined(separator: ", ")
            statusParts.append("VoiceBar could not register every hotkey: \(failedActions)")
            Self.logger.warning("Hotkey registration failures: \(failedActions, privacy: .public)")
        }

        if let holdToTalkFailure = result.holdToTalkFailure {
            statusParts.append("Hold-to-talk: \(holdToTalkFailure.reason)")
            Self.logger.warning("Hold-to-talk registration failed: \(holdToTalkFailure.reason, privacy: .public)")
        }

        if let holdToTalkStatus = result.holdToTalkStatus {
            statusParts.append("Hold-to-talk: \(holdToTalkStatus.detail)")
            Self.logger.info("Hold-to-talk status: \(holdToTalkStatus.detail, privacy: .public)")
        }

        if statusParts.isEmpty {
            hotkeyStatusMessage = "Global hotkeys are registered with the native exclusive Carbon path."
            Self.logger.info("Global hotkeys registered successfully with the exclusive Carbon path.")
            return
        }

        hotkeyStatusMessage = statusParts.joined(separator: " ")
        statusMessage = hotkeyStatusMessage
    }

    private func ensureHoldToTalkShortcutDoesNotConflict() {
        guard preferences.holdToTalkEnabled, preferences.holdToTalkMode == .optionShortcut else {
            return
        }

        let toggleShortcut = preferences.shortcut(for: .toggleDictation)
        let currentHoldShortcut = preferences.sanitizedHoldToTalkShortcut

        guard VoiceBarPreferences.shortcutsConflict(currentHoldShortcut, toggleShortcut) else {
            return
        }

        let fallbackShortcut = VoiceBarPreferences.defaultHoldToTalkShortcut
        if VoiceBarPreferences.shortcutsConflict(fallbackShortcut, toggleShortcut) == false {
            preferences.holdToTalkShortcut = fallbackShortcut
            hotkeyStatusMessage = "Hold-to-talk cannot share Toggle Dictation's shortcut. VoiceBar reset Hold-to-Talk to Option+Period."
            statusMessage = hotkeyStatusMessage
            persistPreferences()
            return
        }

        preferences.holdToTalkEnabled = false
        hotkeyStatusMessage = "Hold-to-talk was disabled because its shortcut conflicts with Toggle Dictation. Choose non-overlapping shortcuts before re-enabling it."
        statusMessage = hotkeyStatusMessage
        persistPreferences()
    }

    private func rememberSelectionHostIfNeeded(_ application: NSRunningApplication) {
        guard
            let bundleIdentifier = application.bundleIdentifier,
            bundleIdentifier != Bundle.main.bundleIdentifier
        else {
            return
        }

        lastNonVoiceBarApplication = application
        Self.logger.info("Updated last non-VoiceBar selection host to \(bundleIdentifier, privacy: .public).")
    }

    private func describeHotkeyRegistrationFailure(
        _ failure: HotkeyRegistrationFailure
    ) -> String {
        switch failure.status {
        case OSStatus(eventHotKeyExistsErr):
            return "\(failure.action.title) is already claimed by another macOS or app shortcut"
        default:
            return "\(failure.action.title) (\(failure.status))"
        }
    }

    private func handleHotkey(_ action: HotkeyAction) {
        // Wrap each hotkey action in defensive error handling to prevent crashes
        // from propagating and terminating the app
        Task { @MainActor in
            do {
                switch action {
                case .toggleDictation:
                    await toggleDictation()
                case .readSelection:
                    try await readSelection(trigger: .hotkey)
                case .readClipboard:
                    await readClipboard()
                case .pauseResume:
                    await pauseOrResume()
                case .stopPlayback:
                    await stopPlayback()
                case .replayLast:
                    try await replayLast()
                case .toggleFloatingController:
                    toggleFloatingControllerVisibility()
                }
            } catch {
                let errorMessage = "Hotkey action '\(action.rawValue)' failed: \(describe(error))"
                Self.logger.error("\(errorMessage, privacy: .public)")
                statusMessage = errorMessage
                await dependencies.diagnostics.record(
                    DiagnosticEvent(
                        name: "hotkey.action.failed",
                        detail: errorMessage
                    )
                )
                await refreshDiagnostics()
            }
        }
    }

    private func handleHoldToTalkPressed() async {
        do {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "holdToTalk.press",
                    detail: "mode=\(preferences.holdToTalkMode.rawValue) recording=\(isDictationRecording) processing=\(isDictationProcessing) startupInFlight=\(holdToTalkStartupInFlight)"
                )
            )

            // Always record key intent regardless of startup state. This handles
            // press → release during startup → press: the second press must set
            // holdToTalkKeyDesired=true so the post-startup check knows the key
            // is held again, even though we skip starting a new startDictation().
            holdToTalkKeyDesired = true

            // Block concurrent startDictation() calls: if already recording or if a
            // startup is currently in flight, intent is recorded above but we do not
            // start a second async startup. holdToTalkStartupInFlight is only cleared
            // after startDictation() fully resolves — NOT cleared by release — so
            // press/release/press overlap cannot spawn concurrent startDictation() calls.
            guard isDictationProcessing == false else {
                await recordStatusEvent(
                    name: "holdToTalk.press.blockedProcessing",
                    message: "VoiceBar is still finishing the previous dictation. Wait for insertion before holding the shortcut again."
                )
                return
            }

            guard isDictationRecording == false, holdToTalkStartupInFlight == false else {
                return
            }

            // Mark startup in-flight (key desired already set above).
            holdToTalkStartupInFlight = true

            await startDictation(automaticallyStopsOnSilence: false)

            // Startup has now fully resolved (permission check + engine start).
            // Clear the in-flight guard regardless of the outcome so future
            // presses are not permanently blocked.
            holdToTalkStartupInFlight = false

            // If the key was released during startup, stop immediately.
            // holdToTalkKeyDesired is false if handleHoldToTalkReleased() fired
            // while startDictation() was awaiting.
            if holdToTalkKeyDesired == false, isDictationRecording {
                Self.logger.info("Hold-to-talk released during startup; stopping dictation immediately.")
                await stopDictation()
            }
            // If holdToTalkKeyDesired is still true, the key is being held and
            // the release handler will call stopDictation() when the key lifts.
            // If isDictationRecording is false, startup failed or was a no-op;
            // no action needed (holdToTalkKeyDesired will be cleared on next release).
        } catch {
            // Defensive: clear flags and record error to prevent stuck state
            holdToTalkStartupInFlight = false
            let errorMessage = "Hold-to-talk press failed: \(describe(error))"
            Self.logger.error("\(errorMessage, privacy: .public)")
            statusMessage = errorMessage
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "holdToTalk.press.failed",
                    detail: errorMessage
                )
            )
            await refreshDiagnostics()
        }
    }

    private func handleHoldToTalkReleased() async {
        do {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "holdToTalk.release",
                    detail: "mode=\(preferences.holdToTalkMode.rawValue) recording=\(isDictationRecording) processing=\(isDictationProcessing) startupInFlight=\(holdToTalkStartupInFlight)"
                )
            )

            // Mark the key as no longer desired. The startup-in-flight guard
            // (holdToTalkStartupInFlight) is intentionally NOT cleared here;
            // it is only cleared by handleHoldToTalkPressed() after startDictation()
            // fully resolves. This prevents a new press from slipping in before the
            // first async startup finishes.
            holdToTalkKeyDesired = false

            // If startup is still in flight, we have signalled our desired state;
            // handleHoldToTalkPressed() will stop dictation once startup resolves.
            guard holdToTalkStartupInFlight == false else {
                return
            }

            // Startup is settled. Stop if we are currently recording.
            guard isDictationRecording else {
                return
            }

            await stopDictation()
        } catch {
            // Defensive: record error to prevent silent failures
            let errorMessage = "Hold-to-talk release failed: \(describe(error))"
            Self.logger.error("\(errorMessage, privacy: .public)")
            statusMessage = errorMessage
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "holdToTalk.release.failed",
                    detail: errorMessage
                )
            )
            await refreshDiagnostics()
        }
    }

    // MARK: - Debug Invariant Helpers

    #if DEBUG
    /// Returns a description of any violated hold-to-talk state invariants.
    /// Expected invariants:
    ///   1. startupInFlight → keyDesired may be true or false (release during startup is valid).
    ///   2. !startupInFlight && keyDesired → isDictationRecording (key held post-startup = recording).
    ///   3. !startupInFlight && !keyDesired → !isDictationRecording (not held, not in startup = idle).
    /// Invariant 3 has an exception: if dictation is still stopping asynchronously right after
    /// stopDictation() resolves, isDictationRecording may briefly remain true. The helper accepts
    /// that transient window and is intended for post-settle assertions only.
    var holdToTalkStateViolations: [String] {
        var violations: [String] = []
        if holdToTalkStartupInFlight == false, holdToTalkKeyDesired == true, isDictationRecording == false {
            violations.append("holdToTalkKeyDesired=true but no startup in flight and not recording")
        }
        return violations
    }

    var holdToTalkDebugDescription: String {
        "startupInFlight=\(holdToTalkStartupInFlight) keyDesired=\(holdToTalkKeyDesired) isDictationRecording=\(isDictationRecording)"
    }
    #endif

    private func handleServiceRequest(
        text: String,
        bundleIdentifier: String?
    ) async {
        let capturedText = CapturedText(
            text: text,
            source: .service,
            frontmostBundleIdentifier: bundleIdentifier
        )

        let profile = await dependencies.appProfileStore.profile(for: bundleIdentifier)
        await consumeCapturedText(capturedText, profile: profile)
    }

    private func consumeCapturedText(
        _ capturedText: CapturedText,
        profile: AppProfile?,
        copyFallbackDidRestoreClipboard: Bool? = nil,
        actionStart: ContinuousClock.Instant? = nil
    ) async {
        let shapingStart = ContinuousClock.now
        let effectiveProfile: AppProfile?

        if let profile {
            effectiveProfile = profile
        } else {
            effectiveProfile = await dependencies.appProfileStore.profile(
                for: capturedText.frontmostBundleIdentifier
            )
        }

        let normalizedText = await dependencies.textNormalizationService.normalize(
            capturedText,
            options: effectiveProfile?.normalizationOptions ?? NormalizationOptions(),
            profile: effectiveProfile
        )

        let spokenText = await dependencies.pronunciationService.applyOverrides(
            to: normalizedText,
            profile: effectiveProfile
        )

        let trimmedSpokenText = spokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSpokenText.isEmpty == false else {
            Self.logger.error("Captured text normalized to an empty speakable payload for source \(capturedText.source.rawValue, privacy: .public).")
            await recordStatusEvent(
                name: "capture.\(capturedText.source.rawValue).empty",
                message: "VoiceBar captured text from \(sourceLabel(for: capturedText.source)), but there was nothing speakable after text handling."
            )
            return
        }

        let restoreWarning = copyFallbackDidRestoreClipboard == false
            ? " VoiceBar captured the text, but clipboard restore could not be fully verified."
            : ""
        let preferredMode = resolvedPreferredMode(
            selectedMode: preferences.selectedMode,
            profile: effectiveProfile
        )
        let stylePresetName = effectiveProfile?.stylePreset ?? preferences.selectedStylePresetName
        let styleInstruction = SpeechStyleCatalog.instruction(
            for: stylePresetName,
            customInstruction: preferences.customStyleInstruction
        )

        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: "capture.\(capturedText.source.rawValue).success",
                detail: "Captured \(trimmedSpokenText.count) characters from \(capturedText.frontmostBundleIdentifier ?? "unknown app") via \(capturedText.source.rawValue)."
            )
        )
        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: "playback.text-shaped",
                detail: """
                Shaped \(trimmedSpokenText.count) speakable characters from \(capturedText.source.rawValue) in \(formatDuration(shapingStart.duration(to: .now))).
                Total action-to-shaped time: \(actionStart.map { formatDuration($0.duration(to: .now)) } ?? "unavailable").
                """
            )
        )

        statusMessage = "Captured via \(sourceLabel(for: capturedText.source)). Using \(preferredMode.rawValue) playback with \(currentVoiceSummary) and \(stylePresetName).\(restoreWarning)"

        // Compare the fully shaped request so retries only collapse when the
        // text, mode, voice, style, and target app are all still identical.
        let request = SpeechRequest(
            text: trimmedSpokenText,
            preferredMode: preferredMode,
            styleInstruction: styleInstruction,
            voiceIdentifier: preferences.selectedVoiceIdentifier,
            bundleIdentifier: capturedText.frontmostBundleIdentifier
        )

        if playbackState.status == .preparing {
            let isDuplicateRead = playbackState.lastRequest == request
            if isDuplicateRead {
                await dependencies.diagnostics.record(
                    DiagnosticEvent(
                        name: "playback.duplicateExplicitReadIgnored",
                        detail: "Ignored a duplicate explicit read from \(capturedText.source.rawValue) while VoiceBar was still preparing first audio."
                    )
                )
                statusMessage = "VoiceBar is still preparing the current \(sourceLabel(for: capturedText.source).lowercased()) read. Waiting for first audio before replacing it avoids restarting the Quick runtime.\(restoreWarning)"
                await refreshDiagnostics()
                await refreshSpeechRuntimeStatus()
                return
            }
        }

        if playbackState.status != .idle {
            // Operator-triggered reads should replace any in-flight utterance
            // or warm-up rather than hiding behind a long-running queue.
            await dependencies.playbackController.stop()
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "playback.interruptedForExplicitRead",
                    detail: "Stopped the in-flight playback before starting a new explicit read from \(capturedText.source.rawValue)."
                )
            )
            await syncPlaybackState()
        }

        let submitStart = ContinuousClock.now
        do {
            try await dependencies.playbackController.submit(request)
            Self.logger.info(
                "Playback submitted from source \(capturedText.source.rawValue, privacy: .public) using mode \(preferredMode.rawValue, privacy: .public)."
            )
            statusMessage = "Captured via \(sourceLabel(for: capturedText.source)). Preparing \(preferredMode.rawValue) playback with \(currentVoiceSummary). Waiting for first audio.\(restoreWarning)"
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "playback.submit.completed",
                    detail: "Submitted \(preferredMode.rawValue) playback in \(formatDuration(submitStart.duration(to: .now)))."
                )
            )
        } catch {
            Self.logger.error("Playback submission failed: \(self.describe(error), privacy: .public)")
            statusMessage = "Captured via \(sourceLabel(for: capturedText.source)), but playback could not start. \(describe(error))\(restoreWarning)"
            presentFloatingControllerAttention()
        }

        await syncPlaybackState()
        await refreshDiagnostics()
        await refreshSpeechRuntimeStatus()
    }

    private func recordSelectionFailure(
        primaryError: Error,
        copyFallbackError: Error?,
        copyFallbackWasEligible: Bool,
        profileExists: Bool,
        bundleIdentifier: String?
    ) async {
        let baseMessage = "VoiceBar couldn't read selected text from \(bundleIdentifier ?? "the current app") via Accessibility. \(describe(primaryError))"
        let fallbackMessage = copyFallbackError.map { " Copy fallback also failed: \(describe($0))" } ?? ""
        let nextStep: String

        Self.logger.error(
            "Selection capture failed for bundle \(bundleIdentifier ?? "unknown", privacy: .public). Primary error: \(self.describe(primaryError), privacy: .public)"
        )

        if copyFallbackWasEligible {
            nextStep = " Use Read with VoiceBar or Read Clipboard instead."
        } else if preferences.copyFallbackEnabled {
            nextStep = profileExists
                ? " The current app profile keeps copy fallback off for this app. Use Read with VoiceBar or Read Clipboard instead."
                : " No app profile exists for this app yet, so copy fallback was not attempted. Use Read with VoiceBar or Read Clipboard instead."
        } else {
            nextStep = " The experimental copy fallback is off. Use Read with VoiceBar or Read Clipboard instead."
        }

        await recordStatusEvent(
            name: "capture.selection.failed",
            message: baseMessage + fallbackMessage + nextStep
        )
        presentFloatingControllerAttention()
    }

    private func waitForSelectionHostRecovery(
        using liveTextCaptureService: LiveTextCaptureService
    ) async {
        let ownBundleIdentifier = Bundle.main.bundleIdentifier

        for _ in 0..<6 {
            let frontmostBundleIdentifier = await liveTextCaptureService.frontmostBundleIdentifier()

            if
                let frontmostBundleIdentifier,
                frontmostBundleIdentifier != ownBundleIdentifier
            {
                return
            }

            try? await Task.sleep(nanoseconds: 150_000_000)
        }
    }

    private func restoreSelectionHostIfNeeded(
        using liveTextCaptureService: LiveTextCaptureService
    ) async {
        guard
            let ownBundleIdentifier = Bundle.main.bundleIdentifier,
            let frontmostBundleIdentifier = await liveTextCaptureService.frontmostBundleIdentifier(),
            frontmostBundleIdentifier == ownBundleIdentifier
        else {
            return
        }

        guard let selectionHost = lastNonVoiceBarApplication else {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "capture.selection.noPreviousHost",
                    detail: "Read Selection was triggered while VoiceBar was frontmost, but no prior non-VoiceBar application was available to restore before Accessibility capture."
                )
            )
            return
        }

        guard selectionHost.isTerminated == false else {
            lastNonVoiceBarApplication = nil
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "capture.selection.previousHostTerminated",
                    detail: "Read Selection could not restore the previous app because that process has terminated; VoiceBar will wait for a fresh non-VoiceBar activation."
                )
            )
            return
        }

        let didActivate = selectionHost.activate(from: .current, options: [])
        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: didActivate ? "capture.selection.hostRestored" : "capture.selection.hostRestoreFailed",
                detail: "Read Selection attempted to restore \(selectionHost.bundleIdentifier ?? "unknown app") before Accessibility capture because the menu action left VoiceBar frontmost."
            )
        )

        if didActivate {
            // Give AppKit and the target process a short turn to make its
            // focused element current again before AX selection reads begin.
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    private func handleCompletedDictationCapture(
        _ result: Result<DictationAudioCaptureResult, Error>
    ) async {
        isDictationRecording = false
        dictationAutomaticallyStopsOnSilence = true
        refreshFloatingControllerPresentation()

        switch result {
        case let .success(captureResult):
            isDictationProcessing = true
            await processDictationCapture(captureResult)
        case let .failure(error):
            isDictationProcessing = false
            dictationStatus = "VoiceBar could not finish dictation capture. \(describe(error))"
            statusMessage = dictationStatus
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.capture.failed",
                    detail: dictationStatus
                )
            )
            await refreshDiagnostics()
        }
    }

    private func processDictationCapture(
        _ captureResult: DictationAudioCaptureResult
    ) async {
        let postCaptureStartedAt = DispatchTime.now().uptimeNanoseconds
        let captureDurationMilliseconds = max(0, Int((captureResult.durationSeconds * 1_000).rounded()))

        defer {
            isDictationProcessing = false
            refreshFloatingControllerPresentation()
        }

        dictationStatus = "Transcribing dictation locally with whisper.cpp..."
        statusMessage = dictationStatus
        presentFloatingControllerAttention()
        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: "dictation.capture.completed",
                detail: "Captured \(formatMilliseconds(captureDurationMilliseconds)); samples=\(captureResult.sampleCount); peak=\(formatAmplitude(captureResult.peakAmplitude)); stopReason=\(captureResult.stopReason.rawValue); audioWriteMs=\(captureResult.audioWriteMilliseconds)."
            )
        )

        let rollingPrompt = await dependencies.dictationPipeline.currentRollingContext()
            .joined(separator: "\n")

        do {
            let transcriptionStartedAt = DispatchTime.now().uptimeNanoseconds
            let transcript = try await dependencies.speechToTextService.transcribe(
                audioFileURL: captureResult.audioFileURL,
                rollingPrompt: rollingPrompt.isEmpty ? nil : rollingPrompt
            )
            let transcriptionMilliseconds = elapsedMilliseconds(since: transcriptionStartedAt)

            dictationStatus = "Trying Ollama dictation cleanup. VoiceBar will fall back to snippet-expanded text if the formatter stalls."
            statusMessage = dictationStatus

            let pipelineResult = try await dependencies.dictationPipeline.processTranscript(
                transcript,
                formattingMode: preferences.dictationFormattingMode,
                qualityMode: preferences.dictationFormatterQualityMode,
                formatterModelIdentifier: preferences.formatterModelIdentifier,
                frontmostBundleIdentifier: dictationTargetBundleIdentifier
            )
            await recordSnippetExpansionDiagnostics(
                transcriptCharacterCount: transcript.count,
                pipelineResult: pipelineResult
            )

            lastDictationFormatterModelIdentifier = pipelineResult.formatterModelIdentifier
            lastDictationFormatterUsedFallback = pipelineResult.formatterUsedFallback

            let recoveryEntryID = await saveDictationRecoveryEntryIfNeeded(
                pipelineResult: pipelineResult
            )

            let insertionStartedAt = DispatchTime.now().uptimeNanoseconds
            let insertionSummary = await insertDictationOutputIfNeeded(
                pipelineResult.insertionText
            )
            await updateDictationRecoveryEntryIfNeeded(
                entryID: recoveryEntryID,
                insertionSummary: insertionSummary
            )
            let insertionMilliseconds = elapsedMilliseconds(since: insertionStartedAt)

            let actionExecutionStartedAt = DispatchTime.now().uptimeNanoseconds
            let actionSummary = await runResolvedActionIfNeeded(
                pipelineResult.resolvedAction
            )
            let actionExecutionMilliseconds = elapsedMilliseconds(since: actionExecutionStartedAt)

            let latencyBreakdown = pipelineResult.latencyBreakdown
            let snippetExpansionMilliseconds = latencyBreakdown?.snippetExpansionMilliseconds ?? 0
            let deterministicFormattingMilliseconds = latencyBreakdown?.deterministicFormattingMilliseconds ?? 0
            let formatterMilliseconds = latencyBreakdown?.formatterMilliseconds ?? 0
            let actionRoutingMilliseconds = latencyBreakdown?.actionRoutingMilliseconds ?? 0
            let totalPostCaptureMilliseconds = elapsedMilliseconds(since: postCaptureStartedAt)

            let insertionCharacterCount = pipelineResult.insertionText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .count
            lastDictationRecoveryConfirmation = recoveryConfirmationMessage(
                insertionCharacterCount: insertionCharacterCount,
                insertionSummary: insertionSummary
            )

            let summaryParts = [
                "Formatter: \(pipelineResult.formatterPath.rawValue) using \(pipelineResult.formatterModelIdentifier)",
                pipelineResult.formatterStatusNote,
                insertionSummary,
                lastDictationRecoveryConfirmation,
                actionSummary,
                "Latency: capture \(formatMilliseconds(captureDurationMilliseconds)); transcribe \(formatMilliseconds(transcriptionMilliseconds)); snippets \(formatMilliseconds(snippetExpansionMilliseconds)); deterministic \(formatMilliseconds(deterministicFormattingMilliseconds)); formatter \(formatMilliseconds(formatterMilliseconds)); action routing \(formatMilliseconds(actionRoutingMilliseconds)); insertion \(formatMilliseconds(insertionMilliseconds)); action run \(formatMilliseconds(actionExecutionMilliseconds)); total post-capture \(formatMilliseconds(totalPostCaptureMilliseconds))."
            ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

            lastDictationSummary = summaryParts.joined(separator: "\n")
            dictationStatus = pipelineResult.formatterUsedFallback
                ? "VoiceBar dictation finished with formatter fallback."
                : "VoiceBar dictation finished."
            statusMessage = lastDictationSummary

            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.pipeline.completed",
                    detail: "formatterPath=\(pipelineResult.formatterPath.rawValue) formatterModel=\(pipelineResult.formatterModelIdentifier) fallback=\(pipelineResult.formatterUsedFallback) transcriptChars=\(transcript.count) insertionChars=\(insertionCharacterCount) shouldInsertText=\(pipelineResult.formatterResponse.shouldInsertText) detectedMode=\(pipelineResult.formatterResponse.detectedMode.rawValue)"
                )
            )

            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.pipeline.latency",
                    detail: "captureMs=\(captureDurationMilliseconds) transcribeMs=\(transcriptionMilliseconds) snippetMs=\(snippetExpansionMilliseconds) deterministicMs=\(deterministicFormattingMilliseconds) formatterMs=\(formatterMilliseconds) actionRoutingMs=\(actionRoutingMilliseconds) insertionMs=\(insertionMilliseconds) actionExecutionMs=\(actionExecutionMilliseconds) postCaptureTotalMs=\(totalPostCaptureMilliseconds)"
                )
            )

            if preferences.dictationAudioConfirmationEnabled, insertionCharacterCount > 0 {
                await playDictationConfirmation()
            }

            await refreshDiagnostics()
            await refreshDictationReadiness()
        } catch {
            dictationStatus = "VoiceBar dictation failed. \(describe(error))"
            statusMessage = dictationStatus
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.pipeline.failed",
                    detail: dictationStatus
                )
            )
            await refreshDiagnostics()
        }
    }

    private func saveDictationRecoveryEntryIfNeeded(
        pipelineResult: DictationPipelineResult
    ) async -> String? {
        guard preferences.saveRecentDictationsForRecovery else {
            return nil
        }

        let formattedText = pipelineResult.insertionText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard formattedText.isEmpty == false else {
            return nil
        }

        let entry = DictationHistoryEntry(
            rawTranscript: pipelineResult.rawTranscript,
            formattedText: formattedText,
            formatterPath: pipelineResult.formatterPath,
            formatterModelIdentifier: pipelineResult.formatterModelIdentifier,
            frontmostBundleIdentifier: dictationTargetBundleIdentifier,
            insertionSummary: "Insertion: pending.",
            rawTranscriptCharacterCount: pipelineResult.rawTranscript.count,
            formattedCharacterCount: formattedText.count
        )

        do {
            let entries = try await dependencies.dictationHistoryStore.saveEntry(
                entry,
                retentionLimit: preferences.dictationHistoryRetentionLimit
            )
            recentDictationHistoryEntries = entries
            dictationHistoryStatus = "Saved \(formattedCharacterCount(formattedText.count)) to the local dictation rescue buffer before insertion."
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.history.saved",
                    detail: "entryToken=\(Self.redactedDiagnosticToken(for: entry.id)) rawChars=\(entry.rawTranscriptCharacterCount) formattedChars=\(entry.formattedCharacterCount) formatterPath=\(entry.formatterPath.rawValue) retentionLimit=\(preferences.dictationHistoryRetentionLimit)"
                )
            )
            return entry.id
        } catch {
            dictationHistoryStatus = "VoiceBar could not save this dictation for recovery. \(describe(error))"
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.history.save.failed",
                    detail: "rawChars=\(pipelineResult.rawTranscript.count) formattedChars=\(formattedText.count) error=\(describe(error))"
                )
            )
            return nil
        }
    }

    private func updateDictationRecoveryEntryIfNeeded(
        entryID: String?,
        insertionSummary: String
    ) async {
        guard let entryID else {
            return
        }

        do {
            recentDictationHistoryEntries = try await dependencies.dictationHistoryStore
                .updateInsertionSummary(
                    entryID: entryID,
                    insertionSummary: insertionSummary,
                    retentionLimit: preferences.dictationHistoryRetentionLimit
                )
        } catch {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.history.update.failed",
                    detail: "entryToken=\(Self.redactedDiagnosticToken(for: entryID)) error=\(describe(error))"
                )
            )
        }
    }

    private func trimDictationHistoryToPreference() async {
        do {
            recentDictationHistoryEntries = try await dependencies.dictationHistoryStore.trimEntries(
                retentionLimit: preferences.dictationHistoryRetentionLimit
            )
            dictationHistoryStatus = "Recent dictation history now keeps up to \(preferences.dictationHistoryRetentionLimit) item\(preferences.dictationHistoryRetentionLimit == 1 ? "" : "s")."
        } catch {
            dictationHistoryStatus = "VoiceBar could not trim recent dictation history. \(describe(error))"
        }
    }

    private func recordSnippetExpansionDiagnostics(
        transcriptCharacterCount: Int,
        pipelineResult: DictationPipelineResult
    ) async {
        let applications = pipelineResult.formatterResponse.snippetApplications

        guard applications.isEmpty == false else {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.snippet.match.missed",
                    detail: "transcriptChars=\(transcriptCharacterCount) reason=no exact trigger or alias match"
                )
            )
            return
        }

        let matchedTriggerSummary = applications
            .map { application in
                "snippetToken=\(Self.redactedDiagnosticToken(for: application.snippetID)) triggerToken=\(Self.redactedDiagnosticToken(for: application.trigger))"
            }
            .joined(separator: "; ")

        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: "dictation.snippet.match.applied",
                detail: "matchCount=\(applications.count) \(matchedTriggerSummary)"
            )
        )
    }

    private func insertDictationOutputIfNeeded(_ insertionText: String) async -> String {
        let trimmedInsertionText = insertionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedInsertionText.isEmpty == false else {
            return "Insertion: skipped because the utterance resolved to a command-only result."
        }

        if preferences.insertDictationAtCursor {
            do {
                let insertionResult = try await textInsertionService.insertAtCursor(trimmedInsertionText)
                if insertionResult.didRestoreClipboard {
                    return "Insertion: pasted at the cursor and restored the prior clipboard."
                }

                return "Insertion: pasted at the cursor, but clipboard restore could not be fully verified."
            } catch {
                do {
                    try textInsertionService.copyToClipboard(trimmedInsertionText)
                    return "Insertion: cursor paste failed, so VoiceBar copied the result to the clipboard instead. \(describe(error))"
                } catch {
                    return "Insertion: VoiceBar could not paste or copy the dictation result."
                }
            }
        }

        do {
            try textInsertionService.copyToClipboard(trimmedInsertionText)
            return "Insertion: copied the dictation result to the clipboard by preference."
        } catch {
            return "Insertion: VoiceBar could not copy the dictation result to the clipboard."
        }
    }

    private func runResolvedActionIfNeeded(
        _ resolvedAction: ResolvedDictationAction?
    ) async -> String {
        guard let resolvedAction else {
            return ""
        }

        let shouldAskForConfirmation = resolvedAction.definition.requiresConfirmation
            || preferences.autoRunTrustedActions == false

        if shouldAskForConfirmation {
            let didConfirmAction = requestActionConfirmation(for: resolvedAction)
            guard didConfirmAction else {
                return "Action: detected \(resolvedAction.definition.displayName), but the operator canceled it."
            }
        }

        do {
            let executionResult = try await actionExecutor.run(resolvedAction.definition)
            if executionResult.output.isEmpty {
                return "Action: ran \(resolvedAction.definition.displayName)."
            }

            return "Action: ran \(resolvedAction.definition.displayName). Output: \(executionResult.output)"
        } catch {
            return "Action: \(resolvedAction.definition.displayName) failed. \(describe(error))"
        }
    }

    private func requestActionConfirmation(
        for resolvedAction: ResolvedDictationAction
    ) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Run VoiceBar action?"
        alert.informativeText = "VoiceBar matched the raw spoken transcript to the trusted action '\(resolvedAction.definition.displayName)' using the configured trigger '\(resolvedAction.matchedTrigger)'."
        alert.addButton(withTitle: "Run Action")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational

        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func playDictationConfirmation() async {
        let requestedAtNanoseconds = DispatchTime.now().uptimeNanoseconds
        dictationConfirmationGeneration += 1
        let currentGeneration = dictationConfirmationGeneration

        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: "dictation.confirmation.requested",
                detail: "Requested native audio confirmation for inserted dictation."
            )
        )

        if let lastRequest = lastDictationConfirmationRequestedAtNanoseconds,
           requestedAtNanoseconds - lastRequest < 1_000_000_000 {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.confirmation.replaced",
                    detail: "Replaced an earlier confirmation request because a newer dictation event arrived within one second."
                )
            )
        }
        lastDictationConfirmationRequestedAtNanoseconds = requestedAtNanoseconds

        try? await Task.sleep(nanoseconds: 35_000_000)
        guard currentGeneration == dictationConfirmationGeneration else {
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "dictation.confirmation.skipped",
                    detail: "Skipped stale confirmation because a newer dictation event replaced it."
                )
            )
            return
        }

        let didPlay: Bool
        if let sound = NSSound(named: "Glass") ?? NSSound(named: "Ping") {
            didPlay = sound.play()
        } else {
            NSSound.beep()
            didPlay = true
        }
        let latencyMilliseconds = elapsedMilliseconds(since: requestedAtNanoseconds)

        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: didPlay ? "dictation.confirmation.played" : "dictation.confirmation.skipped",
                detail: didPlay
                    ? "Played native confirmation sound without entering the speech playback queue."
                    : "Native confirmation sound was unavailable."
            )
        )

        await dependencies.diagnostics.record(
            DiagnosticEvent(
                name: "dictation.confirmation.latency",
                detail: "latencyMs=\(latencyMilliseconds)"
            )
        )
        await refreshDiagnostics()
    }

    private func ensureOperatorCriticalSnippetAliasesIfNeeded(snippets loadedSnippets: [DictationSnippet]) async {
        let aliasRules = [
            SnippetAliasRule(
                name: "Google Cloud Platform login",
                aliases: [
                    "Google Cloud login",
                    "Google Cloud log in",
                    "Google Cloud Logging",
                    "GCP login",
                    "GCP log in"
                ]
            ),
            SnippetAliasRule(
                name: "ExampleAudit",
                aliases: [
                    "ExampleAudit",
                    "Example Audit"
                ]
            )
        ]
        let initialSummary = Self.operatorCriticalAliasSummary(
            for: loadedSnippets,
            rules: aliasRules
        )

        guard initialSummary.updatedRuleNames.isEmpty == false else {
            if initialSummary.missingRuleNames.isEmpty == false {
                let missingNames = initialSummary.missingRuleNames.joined(separator: ", ")
                snippetManagementStatus = "Loaded \(loadedSnippets.count) local snippets. No matching snippets found for \(missingNames)."
            } else if initialSummary.conflictedRuleNames.isEmpty == false {
                let conflictedNames = initialSummary.conflictedRuleNames.joined(separator: ", ")
                snippetManagementStatus = "Loaded \(loadedSnippets.count) local snippets. Skipped conflicting aliases for \(conflictedNames)."
            }
            return
        }

        do {
            let update = try await dictationSnippetStore.updateSnippetsWithResult(creatingBackup: true) { currentSnippets in
                var snippets = currentSnippets
                let currentSummary = Self.operatorCriticalAliasSummary(
                    for: currentSnippets,
                    rules: aliasRules
                )

                for rule in aliasRules {
                    let normalizedAliasSet = Self.normalizedAliasLookupSet(for: rule)
                    guard let index = snippets.firstIndex(where: {
                        Self.snippet($0, matchesAliasSet: normalizedAliasSet)
                    }) else {
                        continue
                    }

                    let missingAliases = Self.nonConflictingMissingAliases(
                        for: rule,
                        snippets: snippets,
                        targetIndex: index
                    )
                    guard missingAliases.isEmpty == false else {
                        continue
                    }

                    var snippet = snippets[index]
                    snippet.triggers = Self.uniquedSnippetTriggers(snippet.triggers + missingAliases)
                    snippets[index] = snippet
                }

                return (
                    snippets,
                    currentSummary
                )
            }

            dictationSnippets = update.snippets

            if update.result.updatedRuleNames.isEmpty == false {
                let updatedNames = update.result.updatedRuleNames.joined(separator: ", ")
                snippetManagementStatus = "Loaded \(update.snippets.count) local snippets and added explicit aliases for \(updatedNames)."
            } else if update.result.missingRuleNames.isEmpty == false {
                let missingNames = update.result.missingRuleNames.joined(separator: ", ")
                snippetManagementStatus = "Loaded \(update.snippets.count) local snippets. No matching snippets found for \(missingNames)."
            } else if update.result.conflictedRuleNames.isEmpty == false {
                let conflictedNames = update.result.conflictedRuleNames.joined(separator: ", ")
                snippetManagementStatus = "Loaded \(update.snippets.count) local snippets. Skipped conflicting aliases for \(conflictedNames)."
            }
        } catch {
            snippetManagementStatus = "VoiceBar loaded snippets but could not save operator-critical aliases. \(describe(error))"
        }
    }

    private nonisolated static func operatorCriticalAliasSummary(
        for snippets: [DictationSnippet],
        rules: [SnippetAliasRule]
    ) -> AliasUpdateSummary {
        var updatedRuleNames: [String] = []
        var missingRuleNames: [String] = []
        var conflictedRuleNames: [String] = []

        for rule in rules {
            let normalizedAliasSet = normalizedAliasLookupSet(for: rule)
            guard let snippetIndex = snippets.firstIndex(where: {
                Self.snippet($0, matchesAliasSet: normalizedAliasSet)
            }) else {
                missingRuleNames.append(rule.name)
                continue
            }

            if aliasConflicts(for: rule, snippets: snippets, targetIndex: snippetIndex).isEmpty == false {
                conflictedRuleNames.append(rule.name)
            }

            if nonConflictingMissingAliases(for: rule, snippets: snippets, targetIndex: snippetIndex).isEmpty == false {
                updatedRuleNames.append(rule.name)
            }
        }

        return AliasUpdateSummary(
            updatedRuleNames: updatedRuleNames,
            missingRuleNames: missingRuleNames,
            conflictedRuleNames: conflictedRuleNames
        )
    }

    private nonisolated static func nonConflictingMissingAliases(
        for rule: SnippetAliasRule,
        snippets: [DictationSnippet],
        targetIndex: Int
    ) -> [String] {
        let existingTriggers = Set(snippets[targetIndex].triggers.map(normalizedSnippetTrigger))
        let conflicts = aliasConflicts(for: rule, snippets: snippets, targetIndex: targetIndex)

        return rule.aliases.filter { alias in
            let normalizedAlias = normalizedSnippetTrigger(alias)
            return existingTriggers.contains(normalizedAlias) == false
                && conflicts.contains(normalizedAlias) == false
        }
    }

    private nonisolated static func aliasConflicts(
        for rule: SnippetAliasRule,
        snippets: [DictationSnippet],
        targetIndex: Int
    ) -> Set<String> {
        let existingTriggers = Set(snippets[targetIndex].triggers.map(normalizedSnippetTrigger))
        let missingAliasKeys = Set(
            rule.aliases
                .map(normalizedSnippetTrigger)
                .filter { existingTriggers.contains($0) == false }
        )

        guard missingAliasKeys.isEmpty == false else {
            return []
        }

        let otherTriggerKeys = snippets.enumerated()
            .filter { offset, _ in offset != targetIndex }
            .flatMap { _, snippet in snippet.triggers.map(normalizedSnippetTrigger) }

        return Set(otherTriggerKeys.filter { missingAliasKeys.contains($0) })
    }

    private nonisolated static func snippet(
        _ snippet: DictationSnippet,
        matchesAliasSet normalizedAliasSet: Set<String>
    ) -> Bool {
        let triggerKeys = Set(snippet.triggers.map(normalizedSnippetTrigger))
        if triggerKeys.intersection(normalizedAliasSet).isEmpty == false {
            return true
        }

        // Labels remain display-only for dictation matching, but they are safe
        // retrieval handles for adding explicit aliases to known local snippets.
        guard let label = snippet.label else {
            return false
        }

        return normalizedAliasSet.contains(normalizedSnippetTrigger(label))
    }

    private nonisolated static func normalizedAliasLookupSet(for rule: SnippetAliasRule) -> Set<String> {
        // The canonical rule name is a retrieval handle only; actual dictation
        // matching still requires explicit trigger phrases on the stored snippet.
        Set(([rule.name] + rule.aliases).map(normalizedSnippetTrigger))
    }

    private nonisolated static func redactedDiagnosticToken(for value: String) -> String {
        // Swift hash values are process-local tokens, which is enough to
        // correlate one diagnostic event without making trigger text readable.
        let token = UInt(bitPattern: value.hashValue)
        return String(token, radix: 16)
    }

    private nonisolated static func sanitizedSnippetForStorage(_ snippet: DictationSnippet) -> DictationSnippet {
        let label = snippet.label?.trimmingCharacters(in: .whitespacesAndNewlines)

        // The triggers array stores both primary trigger phrases and explicit
        // aliases; matching remains exact after normalization rather than fuzzy.
        let triggers = DictationSnippetTriggerUtilities.uniquedTriggers(snippet.triggers)

        return DictationSnippet(
            id: snippet.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? UUID().uuidString : snippet.id,
            label: label?.isEmpty == true ? nil : label,
            triggers: triggers,
            expansion: snippet.expansion,
            enabled: snippet.enabled,
            importMetadata: snippet.importMetadata
        )
    }

    private nonisolated static func uniquedSnippetTriggers(_ triggers: [String]) -> [String] {
        DictationSnippetTriggerUtilities.uniquedTriggers(triggers)
    }

    private nonisolated static func normalizedSnippetTrigger(_ trigger: String) -> String {
        DictationSnippetTriggerUtilities.triggerComparisonKey(trigger)
    }

    private nonisolated static func snippetDisplayLabel(_ snippet: DictationSnippet) -> String {
        let label = snippet.label?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let label, label.isEmpty == false {
            return label
        }

        return snippet.triggers.first ?? snippet.id
    }

    private func playbackStatusTitle() -> String {
        switch playbackState.status {
        case .idle:
            return "Idle"
        case .preparing:
            return "Preparing"
        case .speaking:
            return "Speaking"
        case .paused:
            return "Paused"
        case .failed:
            return "Needs Attention"
        }
    }

    private func sourceLabel(for source: CaptureSource) -> String {
        switch source {
        case .accessibility:
            return "Accessibility"
        case .service:
            return "the Service path"
        case .clipboard:
            return "the clipboard"
        case .copyFallback:
            return "copy fallback"
        case .unknown:
            return "an unknown source"
        }
    }

    private func describe(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return error.localizedDescription
    }

    private struct WisprFlowImportInputData: Sendable {
        var exportData: Data
        var manifestData: Data?
    }

    private struct WisprFlowSnippetApplyReport: Codable {
        var preview: WisprFlowSnippetImportPreview
        var storedSnippetCount: Int
        var backupCreated: Bool

        init(summary: WisprFlowSnippetApplySummary) {
            self.preview = summary.preview
            self.storedSnippetCount = summary.storedSnippetCount
            self.backupCreated = summary.backupURL != nil
        }
    }

    nonisolated private static func loadWisprFlowImportInputData() throws -> WisprFlowImportInputData {
        WisprFlowImportInputData(
            exportData: try Data(contentsOf: VoiceBarStorageLocation.wisprFlowSnippetsPrivateExportURL),
            manifestData: try optionalData(contentsOf: VoiceBarStorageLocation.wisprFlowSnippetsRedactedManifestURL)
        )
    }

    nonisolated private static func optionalData(contentsOf url: URL) throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return try Data(contentsOf: url)
    }

    private func writeWisprFlowImportReport<T: Encodable>(_ value: T, to url: URL) throws {
        try VoiceBarStorageLocation.ensureDirectoryExists(for: url)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // Import reports are count-only Codable summaries; raw private expansions
        // and local filesystem paths stay out of normal logs and report files.
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }

    private static func describe(preview: WisprFlowSnippetImportPreview) -> String {
        "Preview ready: \(preview.importableEntryCount) importable, \(preview.newSnippetCount) new, \(preview.updatedSnippetCount) updates, \(preview.unchangedSnippetCount) unchanged, \(preview.duplicateTriggerCount) duplicate triggers, \(preview.quarantinedSensitiveEntryCount) quarantined, \(preview.ignoredDeletedCount) deleted ignored. Report saved privately."
    }

    private static func describe(summary: WisprFlowSnippetApplySummary) -> String {
        let backupName = summary.backupURL?.lastPathComponent ?? "none"
        return "Import applied: \(summary.preview.newSnippetCount) new, \(summary.preview.updatedSnippetCount) updated, \(summary.preview.unchangedSnippetCount) unchanged, \(summary.preview.quarantinedSensitiveEntryCount) quarantined, \(summary.preview.ignoredDeletedCount) deleted ignored. Backup: \(backupName)."
    }

    private func recordStatusEvent(
        name: String,
        message: String
    ) async {
        statusMessage = message
        await dependencies.diagnostics.record(
            DiagnosticEvent(name: name, detail: message)
        )
        await refreshDiagnostics()
    }

    private func presentFloatingControllerAttention() {
        guard preferences.floatingControllerEnabled else {
            return
        }

        floatingControllerDismissed = false
        floatingControllerNeedsAttention = true
        refreshFloatingControllerPresentation()
    }

    private func availabilitySummary(for availability: SpeechEngineAvailability) -> String {
        if availability.isAvailable {
            return availability.reason ?? "ready"
        }

        return availability.reason ?? "unavailable"
    }

    private func availabilitySummary(for availability: DictationServiceAvailability) -> String {
        if availability.isAvailable {
            return availability.reason ?? "ready"
        }

        return availability.reason ?? "unavailable"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%.2fs", max(0, duration))
    }

    private func formatDuration(_ duration: Duration) -> String {
        let milliseconds = Double(duration.components.seconds) * 1000
            + Double(duration.components.attoseconds) / 1_000_000_000_000_000
        return String(format: "%.0fms", max(0, milliseconds))
    }

    private func formatMilliseconds(_ milliseconds: Int) -> String {
        "\(max(0, milliseconds))ms"
    }

    private func formattedCharacterCount(_ characterCount: Int) -> String {
        "\(max(0, characterCount).formatted()) character\(characterCount == 1 ? "" : "s")"
    }

    private func recoveryConfirmationMessage(
        insertionCharacterCount: Int,
        insertionSummary: String
    ) -> String? {
        guard
            preferences.saveRecentDictationsForRecovery,
            insertionCharacterCount > 0
        else {
            return nil
        }

        let actionVerb = insertionSummary.localizedCaseInsensitiveContains("pasted at the cursor")
            ? "Inserted"
            : "Saved"

        return "\(actionVerb) \(insertionCharacterCount.formatted()) character\(insertionCharacterCount == 1 ? "" : "s"). Copy again / Open history."
    }

    private func elapsedMilliseconds(since startNanoseconds: UInt64) -> Int {
        Int((DispatchTime.now().uptimeNanoseconds - startNanoseconds) / 1_000_000)
    }

    private func formatAmplitude(_ amplitude: Float) -> String {
        String(format: "%.4f", max(0, amplitude))
    }

    private func handleMissingAccessibilityTrust(
        promptEventName: String,
        repeatedEventName: String,
        promptSourceDescription: String
    ) async {
        if isRunningFromAppBundle == false {
            Self.logger.warning("Accessibility trust missing while running from raw executable.")
            statusMessage = "Read Selection needs Accessibility access, but this raw development executable does not keep macOS trust reliably. Relaunch the installed VoiceBar.app from ~/Applications or the Desktop launcher, then grant Accessibility there. Use Read with VoiceBar or Read Clipboard until then."
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: "capture.accessibility.unbundled",
                    detail: "Accessibility trust was still missing \(promptSourceDescription) while VoiceBar was running from a raw development executable instead of an `.app` bundle."
                )
            )
            await refreshCaptureReadiness()
            await refreshDiagnostics()
            presentFloatingControllerAttention()
            return
        }

        if hasPromptedForAccessibilityThisSession == false {
            hasPromptedForAccessibilityThisSession = true
            Self.logger.warning("Accessibility trust missing; opening System Settings \(promptSourceDescription, privacy: .public).")
            statusMessage = "Read Selection needs Accessibility access. Turn on VoiceBar in System Settings > Privacy & Security > Accessibility. If the VoiceBar row still looks enabled but selection capture still fails, remove and re-add ~/Applications/VoiceBar.app or the Desktop launcher, then try again. Use Read with VoiceBar or Read Clipboard until then."
            openAccessibilitySettings()
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: promptEventName,
                    detail: "Opened Accessibility settings \(promptSourceDescription) because VoiceBar still lacked trust."
                )
            )
        } else {
            Self.logger.warning("Accessibility trust still missing after prior settings guidance in the same session.")
            statusMessage = "Read Selection still needs Accessibility access. Turn on VoiceBar in System Settings > Privacy & Security > Accessibility, then try again. If the current VoiceBar row still looks enabled but the app behaves as if trust is missing, remove and re-add ~/Applications/VoiceBar.app or the Desktop launcher. Use Read with VoiceBar or Read Clipboard until then."
            await dependencies.diagnostics.record(
                DiagnosticEvent(
                    name: repeatedEventName,
                    detail: "Accessibility access was still missing \(promptSourceDescription) after VoiceBar had already opened Accessibility settings in this session."
                )
            )
        }

        await refreshCaptureReadiness()
        await refreshDiagnostics()
        presentFloatingControllerAttention()
    }

    private func ensureAccessibilityTrustIfPossible(
        using liveTextCaptureService: LiveTextCaptureService
    ) async -> Bool {
        let isTrusted = await liveTextCaptureService.isAccessibilityTrusted()

        if isTrusted == false {
            Self.logger.info("Accessibility trust query returned false for the installed VoiceBar.app bundle; VoiceBar will guide the operator to System Settings instead of re-triggering the system trust prompt.")
        }

        return isTrusted
    }

    private func missingAccessibilitySummary() -> String {
        if isRunningFromAppBundle {
            return "Accessibility access is not granted yet. Read Selection will prompt once per session, and some apps may still need the Service or clipboard path. If the existing VoiceBar row stays stale, remove and re-add ~/Applications/VoiceBar.app or the Desktop launcher."
        }

        return "Accessibility access is not granted yet. VoiceBar is running from a raw development executable, so macOS may not keep the permission stable. Relaunch the installed VoiceBar.app from ~/Applications or the Desktop launcher before judging Read Selection."
    }

    private enum ReadSelectionTrigger {
        case menuOrToolbar
        case hotkey
    }
}
