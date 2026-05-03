import Foundation

public enum PronunciationMatchKind: String, Codable, Sendable {
    case exactText
}

public struct PronunciationEntry: Identifiable, Equatable, Codable, Sendable {
    public var id: String
    public var match: String
    public var replacement: String
    public var isEnabled: Bool
    public var matchKind: PronunciationMatchKind
    public var isCaseSensitive: Bool

    public init(
        id: String = UUID().uuidString,
        match: String,
        replacement: String,
        isEnabled: Bool = true,
        matchKind: PronunciationMatchKind = .exactText,
        isCaseSensitive: Bool = false
    ) {
        self.id = id
        self.match = match
        self.replacement = replacement
        self.isEnabled = isEnabled
        self.matchKind = matchKind
        self.isCaseSensitive = isCaseSensitive
    }
}

public struct PronunciationDictionary: Equatable, Codable, Sendable {
    public var version: Int
    public var entries: [PronunciationEntry]

    public init(
        version: Int = 1,
        entries: [PronunciationEntry]
    ) {
        self.version = version
        self.entries = entries
    }

    public static var bootstrapDefaults: PronunciationDictionary {
        PronunciationDictionary(
            entries: [
                // These seeded entries double as the required operator-facing
                // examples for the editable JSON dictionary, even when the text
                // normalization layer already reaches the intended spoken form.
                PronunciationEntry(
                    id: "codex",
                    match: "Codex",
                    replacement: "Code ex"
                ),
                PronunciationEntry(
                    id: "hugging-face",
                    match: "Hugging Face",
                    replacement: "Hugging Face"
                ),
                PronunciationEntry(
                    id: "qwen",
                    match: "Qwen",
                    replacement: "Queen"
                ),
                PronunciationEntry(
                    id: "evidary",
                    match: "Evidary",
                    replacement: "Eh vid airy"
                ),
                PronunciationEntry(
                    id: "eu-ai-act",
                    // Keep the raw operator-facing sample term here even though
                    // end-to-end playback already reaches the same spoken form
                    // during acronym normalization before exact replacement.
                    match: "EU AI Act",
                    replacement: "E U A I Act"
                )
            ]
        )
    }
}
