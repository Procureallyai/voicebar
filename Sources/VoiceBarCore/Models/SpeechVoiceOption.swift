import Foundation
import TTSKit

public struct SpeechVoiceOption: Identifiable, Equatable, Codable, Sendable {
    public var id: String
    public var displayName: String
    public var voiceDescription: String
    public var nativeLanguage: String

    public init(
        id: String,
        displayName: String,
        voiceDescription: String,
        nativeLanguage: String
    ) {
        self.id = id
        self.displayName = displayName
        self.voiceDescription = voiceDescription
        self.nativeLanguage = nativeLanguage
    }
}

public enum SpeechVoiceCatalog {
    public static let legacyDefaultVoiceIdentifier = Qwen3Speaker.ryan.rawValue
    public static let defaultVoiceIdentifier = Qwen3Speaker.serena.rawValue
    public static let defaultOption = SpeechVoiceOption(
        id: Qwen3Speaker.serena.rawValue,
        displayName: Qwen3Speaker.serena.displayName,
        voiceDescription: Qwen3Speaker.serena.voiceDescription,
        nativeLanguage: Qwen3Speaker.serena.nativeLanguage
    )

    public static let allOptions: [SpeechVoiceOption] = Qwen3Speaker.allCases.map { speaker in
        SpeechVoiceOption(
            id: speaker.rawValue,
            displayName: speaker.displayName,
            voiceDescription: speaker.voiceDescription,
            nativeLanguage: speaker.nativeLanguage
        )
    }

    public static func option(for identifier: String) -> SpeechVoiceOption? {
        allOptions.first { $0.id == identifier }
    }
}
