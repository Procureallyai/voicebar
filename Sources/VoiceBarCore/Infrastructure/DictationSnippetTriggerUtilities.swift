import Foundation

public enum DictationSnippetTriggerUtilities {
    public static func normalizedTrigger(_ trigger: String) -> String {
        trigger
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func triggerComparisonKey(_ trigger: String) -> String {
        let foldedTrigger = foldedLiteralTrigger(trigger)
        let normalizedTrigger = normalizedTrigger(trigger)
        if normalizedTrigger.isEmpty == false, containsNonASCIIAlphanumeric(foldedTrigger) == false {
            return normalizedTrigger
        }

        // Non-Latin and mixed-script labels can be valid exact triggers even
        // when ASCII-oriented normalization erases or partially erases them.
        return foldedTrigger
    }

    private static func foldedLiteralTrigger(_ trigger: String) -> String {
        trigger
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsNonASCIIAlphanumeric(_ trigger: String) -> Bool {
        trigger.unicodeScalars.contains { scalar in
            CharacterSet.alphanumerics.contains(scalar) && scalar.isASCII == false
        }
    }

    public static func uniquedTriggers(_ triggers: [String]) -> [String] {
        var seen: Set<String> = []
        var uniqueTriggers: [String] = []

        for trigger in triggers {
            let trimmedTrigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
            let comparisonKey = triggerComparisonKey(trimmedTrigger)
            guard trimmedTrigger.isEmpty == false, seen.contains(comparisonKey) == false else {
                continue
            }

            seen.insert(comparisonKey)
            uniqueTriggers.append(trimmedTrigger)
        }

        return uniqueTriggers
    }

    public static func addingLabelAsTrigger(
        label: String,
        to triggers: [String]
    ) -> [String] {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLabel.isEmpty == false else {
            return uniquedTriggers(triggers)
        }

        return uniquedTriggers(triggers + [trimmedLabel])
    }

    public static func conservativeSpeechAliases(for label: String) -> [String] {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLabel.isEmpty == false else {
            return []
        }

        let speakableLabel = String(trimmedLabel.drop { $0 == "@" })
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let baseLabel = speakableLabel.isEmpty ? trimmedLabel : speakableLabel
        var aliases = [baseLabel]

        let baseAliases = aliases
        for alias in baseAliases {
            let spacedCamelCase = alias.replacingOccurrences(
                of: "([a-z0-9])([A-Z])",
                with: "$1 $2",
                options: .regularExpression
            )
            if spacedCamelCase != alias {
                aliases.append(spacedCamelCase)
            }
        }

        aliases.append(contentsOf: verifiedSpeechRecognitionAliases(for: baseLabel))

        return uniquedTriggers(aliases)
    }

    public static func verifiedSpeechRecognitionAliases(for label: String) -> [String] {
        let comparisonKey = triggerComparisonKey(label)

        // Public defaults use synthetic product-name correction fixtures only;
        // real maintainer aliases belong in private local snippet configuration.
        if comparisonKey == "exampleaudit" || comparisonKey == "@exampleaudit" {
            return ["Example Audit"]
        }

        return []
    }
}
