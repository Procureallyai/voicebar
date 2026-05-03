import Foundation

public struct AppProfile: Identifiable, Equatable, Codable, Sendable {
    public var bundleIdentifier: String
    public var preferredMode: SpeechMode
    public var stylePreset: String
    public var normalizationOptions: NormalizationOptions
    public var pacingMultiplier: Double?
    public var allowClipboardFallback: Bool

    public var id: String { bundleIdentifier }

    public init(
        bundleIdentifier: String,
        preferredMode: SpeechMode,
        stylePreset: String,
        normalizationOptions: NormalizationOptions,
        pacingMultiplier: Double? = nil,
        allowClipboardFallback: Bool
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.preferredMode = preferredMode
        self.stylePreset = stylePreset
        self.normalizationOptions = normalizationOptions
        self.pacingMultiplier = pacingMultiplier
        self.allowClipboardFallback = allowClipboardFallback
    }

    public static var bootstrapDefaults: [AppProfile] {
        // These profiles freeze the first honest app-level defaults so later
        // feature lanes can extend behavior without changing the shared shape.
        [
            AppProfile(
                bundleIdentifier: "com.openai.codex",
                preferredMode: .quick,
                stylePreset: "Warm Explainer",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true,
                    skipInlineCode: true
                ),
                pacingMultiplier: 1.0,
                allowClipboardFallback: true
            ),
            AppProfile(
                bundleIdentifier: "com.apple.Safari",
                preferredMode: .quick,
                stylePreset: "Calm Narrator",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true
                ),
                pacingMultiplier: 0.96,
                allowClipboardFallback: false
            ),
            AppProfile(
                bundleIdentifier: "com.google.Chrome",
                preferredMode: .quick,
                stylePreset: "Calm Narrator",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true
                ),
                pacingMultiplier: 0.96,
                allowClipboardFallback: false
            ),
            AppProfile(
                bundleIdentifier: "company.thebrowser.Browser",
                preferredMode: .quick,
                stylePreset: "Calm Narrator",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true
                ),
                pacingMultiplier: 0.96,
                allowClipboardFallback: false
            ),
            AppProfile(
                bundleIdentifier: "com.brave.Browser",
                preferredMode: .quick,
                stylePreset: "Calm Narrator",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true
                ),
                pacingMultiplier: 0.96,
                allowClipboardFallback: false
            ),
            AppProfile(
                bundleIdentifier: "org.mozilla.firefox",
                preferredMode: .quick,
                stylePreset: "Calm Narrator",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true
                ),
                pacingMultiplier: 0.96,
                allowClipboardFallback: false
            ),
            AppProfile(
                bundleIdentifier: "com.microsoft.edgemac",
                preferredMode: .quick,
                stylePreset: "Calm Narrator",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true
                ),
                pacingMultiplier: 0.96,
                allowClipboardFallback: false
            ),
            AppProfile(
                bundleIdentifier: "com.tinyspeck.slackmacgap",
                preferredMode: .quick,
                stylePreset: "Neutral Professional",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true,
                    skipInlineCode: true
                ),
                pacingMultiplier: 1.02,
                allowClipboardFallback: true
            ),
            AppProfile(
                bundleIdentifier: "com.apple.mail",
                preferredMode: .quick,
                stylePreset: "Neutral Professional",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true
                ),
                pacingMultiplier: 0.98,
                allowClipboardFallback: false
            ),
            AppProfile(
                bundleIdentifier: "com.apple.Notes",
                preferredMode: .quick,
                stylePreset: "Calm Narrator",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .proseFirst,
                    skipCodeBlocks: true
                ),
                pacingMultiplier: 0.97,
                allowClipboardFallback: false
            ),
            AppProfile(
                bundleIdentifier: "com.apple.TextEdit",
                preferredMode: .quick,
                stylePreset: "Calm Narrator",
                normalizationOptions: NormalizationOptions(
                    handlingMode: .readEverything,
                    skipCodeBlocks: false
                ),
                pacingMultiplier: 1.0,
                allowClipboardFallback: true
            )
        ]
    }
}

public func resolvedPreferredMode(
    selectedMode: SpeechMode,
    profile: AppProfile?
) -> SpeechMode {
    profile?.preferredMode ?? selectedMode
}
