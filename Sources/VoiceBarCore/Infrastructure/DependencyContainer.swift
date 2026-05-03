public struct DependencyContainer: Sendable {
    public var textCaptureService: TextCaptureService
    public var textNormalizationService: TextNormalizationService
    public var pronunciationService: PronunciationService
    public var premiumSpeechEngine: SpeechEngine
    public var quickSpeechEngine: SpeechEngine
    public var playbackController: PlaybackController
    public var appProfileStore: AppProfileStore
    public var diagnostics: DiagnosticsCapture
    public var speechToTextService: SpeechToTextService
    public var dictationFormatterService: DictationFormatterService
    public var dictationPipeline: DictationPipeline

    public init(
        textCaptureService: TextCaptureService,
        textNormalizationService: TextNormalizationService,
        pronunciationService: PronunciationService,
        premiumSpeechEngine: SpeechEngine,
        quickSpeechEngine: SpeechEngine,
        playbackController: PlaybackController,
        appProfileStore: AppProfileStore,
        diagnostics: DiagnosticsCapture,
        speechToTextService: SpeechToTextService,
        dictationFormatterService: DictationFormatterService,
        dictationPipeline: DictationPipeline
    ) {
        self.textCaptureService = textCaptureService
        self.textNormalizationService = textNormalizationService
        self.pronunciationService = pronunciationService
        self.premiumSpeechEngine = premiumSpeechEngine
        self.quickSpeechEngine = quickSpeechEngine
        self.playbackController = playbackController
        self.appProfileStore = appProfileStore
        self.diagnostics = diagnostics
        self.speechToTextService = speechToTextService
        self.dictationFormatterService = dictationFormatterService
        self.dictationPipeline = dictationPipeline
    }

    public static func live() -> DependencyContainer {
        let diagnostics = InMemoryDiagnosticsCapture()
        let premiumSpeechEngine = TTSKitPremiumEngine()
        // Prompt 012 runtime pivot: prefer Kokoro for the Quick lane when the
        // local runtime is configured, but keep the existing Qwen quick engine
        // as a local fallback so bootstrap still works before setup.
        let quickSpeechEngine: SpeechEngine = KokoroPythonSpeechEngine.isRuntimeConfigured()
            ? KokoroPythonSpeechEngine()
            : TTSKitQuickEngine()
        let appProfileStore = JSONAppProfileStore()
        let formatterService = OllamaFormatterService()
        let snippetStore = JSONDictationSnippetStore()
        let actionStore = JSONDictationActionRegistryStore()

        return DependencyContainer(
            textCaptureService: LiveTextCaptureService(),
            textNormalizationService: DefaultTextNormalizationService(),
            pronunciationService: JSONPronunciationService(),
            premiumSpeechEngine: premiumSpeechEngine,
            quickSpeechEngine: quickSpeechEngine,
            playbackController: QueuedPlaybackController(
                premiumSpeechEngine: premiumSpeechEngine,
                quickSpeechEngine: quickSpeechEngine,
                diagnostics: diagnostics
            ),
            appProfileStore: appProfileStore,
            diagnostics: diagnostics,
            speechToTextService: WhisperCppSpeechToTextService(),
            dictationFormatterService: formatterService,
            dictationPipeline: DictationPipeline(
                formatterService: formatterService,
                snippetStore: snippetStore,
                actionStore: actionStore
            )
        )
    }
}
