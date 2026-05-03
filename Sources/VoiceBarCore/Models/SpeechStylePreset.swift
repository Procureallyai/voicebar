import Foundation

public struct SpeechStylePreset: Identifiable, Equatable, Codable, Sendable {
    public var id: String { name }
    public var name: String
    public var instruction: String

    public init(
        name: String,
        instruction: String
    ) {
        self.name = name
        self.instruction = instruction
    }
}

public enum SpeechStyleCatalog {
    public static let customPresetName = "Custom instruction"

    public static let presets: [SpeechStylePreset] = [
        SpeechStylePreset(
            name: "Warm Explainer",
            instruction: "Read in natural, warm, clear English with calm confidence and subtle emotional cadence."
        ),
        SpeechStylePreset(
            name: "Calm Narrator",
            instruction: "Read slowly and clearly in natural English with gentle pacing and a relaxed tone."
        ),
        SpeechStylePreset(
            name: "Neutral Professional",
            instruction: "Read clearly and naturally in English with professional tone and moderate pace."
        ),
        SpeechStylePreset(
            name: "Energetic Guide",
            instruction: "Read in natural English with energy, warmth, and slightly faster pacing without sounding rushed."
        ),
        SpeechStylePreset(
            name: customPresetName,
            instruction: ""
        )
    ]

    public static var defaultPresetName: String {
        "Warm Explainer"
    }

    public static func instruction(
        for presetName: String,
        customInstruction: String
    ) -> String? {
        if presetName == customPresetName {
            let trimmedInstruction = customInstruction.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return trimmedInstruction.isEmpty ? nil : trimmedInstruction
        }

        return presets.first { $0.name == presetName }?.instruction
    }
}
