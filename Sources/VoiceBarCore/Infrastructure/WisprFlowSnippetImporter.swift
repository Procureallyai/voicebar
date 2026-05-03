import Foundation

public enum WisprFlowSnippetImportError: LocalizedError, Equatable, Sendable {
    case unsupportedJSONShape

    public var errorDescription: String? {
        switch self {
        case .unsupportedJSONShape:
            return "Wispr Flow snippet import expected a JSON array or an object containing snippets, entries, items, or data."
        }
    }
}

public struct WisprFlowSnippetImportPreview: Equatable, Codable, Sendable {
    public var entryCount: Int
    public var importableEntryCount: Int
    public var newSnippetCount: Int
    public var updatedSnippetCount: Int
    public var unchangedSnippetCount: Int
    public var ignoredDeletedCount: Int
    public var invalidEntryCount: Int
    public var duplicateTriggerCount: Int
    public var quarantinedSensitiveEntryCount: Int
    public var commandTextEntryCount: Int
    public var categoryCounts: [String: Int]
    public var invalidReasonCounts: [String: Int]

    public init(
        entryCount: Int,
        importableEntryCount: Int,
        newSnippetCount: Int,
        updatedSnippetCount: Int,
        unchangedSnippetCount: Int,
        ignoredDeletedCount: Int,
        invalidEntryCount: Int,
        duplicateTriggerCount: Int,
        quarantinedSensitiveEntryCount: Int,
        commandTextEntryCount: Int,
        categoryCounts: [String: Int],
        invalidReasonCounts: [String: Int]
    ) {
        self.entryCount = entryCount
        self.importableEntryCount = importableEntryCount
        self.newSnippetCount = newSnippetCount
        self.updatedSnippetCount = updatedSnippetCount
        self.unchangedSnippetCount = unchangedSnippetCount
        self.ignoredDeletedCount = ignoredDeletedCount
        self.invalidEntryCount = invalidEntryCount
        self.duplicateTriggerCount = duplicateTriggerCount
        self.quarantinedSensitiveEntryCount = quarantinedSensitiveEntryCount
        self.commandTextEntryCount = commandTextEntryCount
        self.categoryCounts = categoryCounts
        self.invalidReasonCounts = invalidReasonCounts
    }
}

public struct WisprFlowSnippetApplySummary: Equatable, Codable, Sendable {
    public var preview: WisprFlowSnippetImportPreview
    public var storedSnippetCount: Int
    public var backupURL: URL?

    public init(
        preview: WisprFlowSnippetImportPreview,
        storedSnippetCount: Int,
        backupURL: URL?
    ) {
        self.preview = preview
        self.storedSnippetCount = storedSnippetCount
        self.backupURL = backupURL
    }
}

public struct WisprFlowSnippetImporter: Sendable {
    public static let defaultMaximumExpansionCharacterCount = 50_000

    private let snippetStore: JSONDictationSnippetStore
    private let maximumExpansionCharacterCount: Int
    private let quarantineSensitiveEntries: Bool

    public init(
        storageURL: URL = VoiceBarStorageLocation.dictationSnippetsURL,
        maximumExpansionCharacterCount: Int = Self.defaultMaximumExpansionCharacterCount,
        quarantineSensitiveEntries: Bool = true
    ) {
        self.snippetStore = JSONDictationSnippetStore(storageURL: storageURL)
        self.maximumExpansionCharacterCount = maximumExpansionCharacterCount
        self.quarantineSensitiveEntries = quarantineSensitiveEntries
    }

    public func previewImport(
        from data: Data,
        manifestData: Data? = nil,
        existingSnippets: [DictationSnippet] = []
    ) throws -> WisprFlowSnippetImportPreview {
        try buildPlan(from: data, manifestData: manifestData, existingSnippets: existingSnippets).preview
    }

    public func applyImport(from data: Data, manifestData: Data? = nil) async throws -> WisprFlowSnippetApplySummary {
        let update = try await snippetStore.updateSnippetsWithResult(creatingBackup: true) { existingSnippets in
            let plan = try buildPlan(from: data, manifestData: manifestData, existingSnippets: existingSnippets)
            return (plan.mergedSnippets, plan.preview)
        }

        return WisprFlowSnippetApplySummary(
            preview: update.result,
            storedSnippetCount: update.snippets.count,
            backupURL: update.backupURL
        )
    }

    private func buildPlan(
        from data: Data,
        manifestData: Data?,
        existingSnippets: [DictationSnippet]
    ) throws -> ImportPlan {
        let manifest = try manifestData.map(parseManifest(from:)) ?? [:]
        let parsedImport = try parseImport(from: data, manifest: manifest)
        var mergedSnippets = existingSnippets
        var newSnippetCount = 0
        var updatedSnippetCount = 0
        var unchangedSnippetCount = 0
        var invalidEntryCount = 0
        var duplicateTriggerCount = 0
        var invalidReasonCounts: [String: Int] = [:]

        for candidate in parsedImport.candidates {
            guard quarantineSensitiveEntries == false || candidate.isSensitive == false else {
                continue
            }

            if let matchingIndex = matchingSnippetIndex(for: candidate, in: mergedSnippets) {
                if hasTriggerConflictOutsideMatch(
                    for: candidate,
                    matchingIndex: matchingIndex,
                    in: mergedSnippets
                ) {
                    invalidEntryCount += 1
                    duplicateTriggerCount += 1
                    invalidReasonCounts.increment("duplicateExistingTrigger")
                    continue
                }

                let existingSnippet = mergedSnippets[matchingIndex]
                let updatedSnippet = mergedSnippet(from: candidate, existingSnippet: existingSnippet)

                if updatedSnippet == existingSnippet {
                    unchangedSnippetCount += 1
                } else {
                    updatedSnippetCount += 1
                }

                mergedSnippets[matchingIndex] = updatedSnippet
            } else {
                let newSnippet = newSnippet(from: candidate, existingSnippets: mergedSnippets)
                mergedSnippets.append(newSnippet)
                newSnippetCount += 1
            }
        }

        let importableEntryCount = newSnippetCount + updatedSnippetCount + unchangedSnippetCount

        let preview = WisprFlowSnippetImportPreview(
            entryCount: parsedImport.entryCount,
            importableEntryCount: importableEntryCount,
            newSnippetCount: newSnippetCount,
            updatedSnippetCount: updatedSnippetCount,
            unchangedSnippetCount: unchangedSnippetCount,
            ignoredDeletedCount: parsedImport.ignoredDeletedCount,
            invalidEntryCount: parsedImport.invalidEntryCount + invalidEntryCount,
            duplicateTriggerCount: parsedImport.duplicateTriggerCount + duplicateTriggerCount,
            quarantinedSensitiveEntryCount: quarantineSensitiveEntries ? parsedImport.sensitiveEntryCount : 0,
            commandTextEntryCount: parsedImport.commandTextEntryCount,
            categoryCounts: parsedImport.categoryCounts,
            invalidReasonCounts: parsedImport.invalidReasonCounts.merging(invalidReasonCounts, uniquingKeysWith: +)
        )

        return ImportPlan(preview: preview, mergedSnippets: mergedSnippets)
    }

    private func parseImport(
        from data: Data,
        manifest: [String: ManifestEntry]
    ) throws -> ParsedImport {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let rawEntries = try snippetEntries(from: jsonObject)
        var candidates: [ImportCandidate] = []
        var ignoredDeletedCount = 0
        var invalidEntryCount = 0
        var duplicateTriggerCount = 0
        var sensitiveEntryCount = 0
        var commandTextEntryCount = 0
        var invalidReasonCounts: [String: Int] = [:]
        var categoryCounts: [String: Int] = [:]
        var seenTriggers: Set<String> = []

        for rawEntry in rawEntries {
            guard let entry = rawEntry as? [String: Any] else {
                invalidEntryCount += 1
                invalidReasonCounts.increment("unsupportedEntry")
                continue
            }

            if boolValue(in: entry, keys: ["deleted", "isDeleted"]) == true {
                ignoredDeletedCount += 1
                continue
            }

            let expansion = string(in: entry, keys: ["expansion", "text", "content", "replacement"])
            let triggers = triggerValues(from: entry)
            let label = trimmedString(in: entry, keys: ["label", "name", "title"])
                ?? triggers.first
            let entryIdentifier = trimmedString(in: entry, keys: ["id", "uuid", "snippetID", "snippet_id"])
            let manifestEntry = manifestEntry(
                for: entry,
                entryIdentifier: entryIdentifier,
                triggers: triggers,
                manifest: manifest
            )
            var invalidReasons: [String] = []

            if triggers.isEmpty {
                invalidReasons.append("missingTrigger")
            }

            if expansion?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                invalidReasons.append("missingExpansion")
            } else if let expansion, expansion.count > maximumExpansionCharacterCount {
                invalidReasons.append("expansionTooLarge")
            }

            if invalidReasons.isEmpty == false {
                invalidEntryCount += 1
                for reason in invalidReasons {
                    invalidReasonCounts.increment(reason)
                }
                continue
            }

            let metadata = importMetadata(
                from: entry,
                entryIdentifier: entryIdentifier,
                manifestEntry: manifestEntry
            )
            let normalizedCategory = Self.normalizedClassificationValue(metadata.category)
            let sourceKind = Self.normalizedClassificationValue(metadata.sourceKind)
            let isCommandText = sourceKind == "command-text"
                || normalizedCategory == "command-text"
            let isSensitive = normalizedCategory == "sensitive-secret"
                || (expansion.map(Self.looksSensitive) ?? false)
            let reservesTriggers = quarantineSensitiveEntries == false || isSensitive == false

            // Trigger validation uses the same normalized shape as merge
            // matching. Quarantined entries do not reserve triggers because
            // they will not be written into the active snippets file.
            let normalizedTriggers = Set(triggers.map(Self.normalizedTrigger))
            if reservesTriggers && normalizedTriggers.contains(where: seenTriggers.contains) {
                invalidReasons.append("duplicateTrigger")
                duplicateTriggerCount += 1
            }

            if invalidReasons.isEmpty == false {
                invalidEntryCount += 1
                for reason in invalidReasons {
                    invalidReasonCounts.increment(reason)
                }
                continue
            }

            if reservesTriggers {
                for normalizedTrigger in normalizedTriggers {
                    seenTriggers.insert(normalizedTrigger)
                }
            }

            if isCommandText {
                commandTextEntryCount += 1
            }

            if isSensitive {
                sensitiveEntryCount += 1
            }

            categoryCounts.increment(metadata.category ?? "uncategorized")

            candidates.append(
                ImportCandidate(
                    label: label ?? "",
                    triggers: triggers,
                    expansion: expansion ?? "",
                    metadata: metadata,
                    isSensitive: isSensitive,
                    isCommandText: isCommandText
                )
            )
        }

        return ParsedImport(
            entryCount: rawEntries.count,
            candidates: candidates,
            ignoredDeletedCount: ignoredDeletedCount,
            invalidEntryCount: invalidEntryCount,
            duplicateTriggerCount: duplicateTriggerCount,
            sensitiveEntryCount: sensitiveEntryCount,
            commandTextEntryCount: commandTextEntryCount,
            categoryCounts: categoryCounts,
            invalidReasonCounts: invalidReasonCounts
        )
    }

    private func parseManifest(from data: Data) throws -> [String: ManifestEntry] {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let rawEntries = try snippetEntries(from: jsonObject)
        var manifest: [String: ManifestEntry] = [:]

        for rawEntry in rawEntries {
            guard let entry = rawEntry as? [String: Any] else {
                continue
            }

            let manifestEntry = ManifestEntry(
                category: Self.normalizedClassificationValue(
                    trimmedString(in: entry, keys: ["expansionCategory", "expansion_category", "category"])
                ),
                trigger: trimmedString(in: entry, keys: ["trigger", "phrase", "shortcut"])
            )

            if let identifier = trimmedString(in: entry, keys: ["id", "uuid", "snippetID", "snippet_id"]) {
                manifest["id:\(identifier)"] = manifestEntry
            }

            if let trigger = manifestEntry.trigger {
                manifest["trigger:\(Self.normalizedTrigger(trigger))"] = manifestEntry
            }
        }

        return manifest
    }

    private func snippetEntries(from jsonObject: Any) throws -> [Any] {
        if let entries = jsonObject as? [Any] {
            return entries
        }

        guard let dictionary = jsonObject as? [String: Any] else {
            throw WisprFlowSnippetImportError.unsupportedJSONShape
        }

        for key in ["snippets", "entries", "items", "data"] {
            if let entries = dictionary[key] as? [Any] {
                return entries
            }

            if let nestedDictionary = dictionary[key] as? [String: Any],
               let entries = try? snippetEntries(from: nestedDictionary) {
                return entries
            }
        }

        let singletonEntryKeys: Set<String> = [
            "id",
            "uuid",
            "snippetID",
            "snippet_id",
            "trigger",
            "phrase",
            "shortcut",
            "expansion",
            "replacement",
            "expansionCategory",
            "expansion_category",
            "category"
        ]
        if dictionary.keys.contains(where: singletonEntryKeys.contains) {
            return [dictionary]
        }

        throw WisprFlowSnippetImportError.unsupportedJSONShape
    }

    private func manifestEntry(
        for entry: [String: Any],
        entryIdentifier: String?,
        triggers: [String],
        manifest: [String: ManifestEntry]
    ) -> ManifestEntry? {
        if let entryIdentifier,
           let manifestEntry = manifest["id:\(entryIdentifier)"] {
            return manifestEntry
        }

        for trigger in triggers {
            if let manifestEntry = manifest["trigger:\(Self.normalizedTrigger(trigger))"] {
                return manifestEntry
            }
        }

        return nil
    }

    private func importMetadata(
        from entry: [String: Any],
        entryIdentifier: String?,
        manifestEntry: ManifestEntry?
    ) -> DictationSnippetImportMetadata {
        let source = (entry["source"] as? [String: Any])
            ?? (entry["sourceMetadata"] as? [String: Any])
            ?? [:]
        let entrySourceIdentifier = entryIdentifier.map { "wispr-flow:\($0)" }
        let sourceIdentifier = entrySourceIdentifier
            ?? trimmedString(in: entry, keys: ["sourceIdentifier", "sourceID", "source_id"])
            ?? trimmedString(in: source, keys: ["identifier", "id"])
        let sourceApplication = trimmedString(
            in: source,
            keys: ["application", "app", "name"]
        ) ?? "Wispr Flow"
        let sourceKind = trimmedString(
            in: entry,
            keys: ["sourceKind", "kind", "type", "contentType", "content_type"]
        )

        return DictationSnippetImportMetadata(
            sourceApplication: sourceApplication,
            sourceIdentifier: sourceIdentifier,
            sourceKind: sourceKind,
            category: Self.normalizedClassificationValue(
                trimmedString(
                    in: entry,
                    keys: ["category", "expansionCategory", "expansion_category", "folder", "collection"]
                ) ?? manifestEntry?.category
            ),
            createdAt: trimmedString(in: entry, keys: ["createdAt", "created_at", "created"]),
            updatedAt: trimmedString(in: entry, keys: ["updatedAt", "updated_at", "modifiedAt", "modified_at"]),
            lastUsedAt: trimmedString(in: entry, keys: ["lastUsed", "last_used", "lastUsedAt", "last_used_at"]),
            frequencyUsed: intValue(in: entry, keys: ["frequencyUsed", "frequency_used", "useCount", "use_count"]),
            observedSource: trimmedString(in: entry, keys: ["observedSource", "observed_source"]),
            isStarred: boolValue(in: entry, keys: ["isStarred", "starred"]),
            importedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func triggerValues(from entry: [String: Any]) -> [String] {
        var values: [String] = []

        if let trigger = trimmedString(in: entry, keys: ["trigger", "shortcut", "phrase"]) {
            values.append(trigger)
        }

        for key in ["triggers", "phrases", "shortcuts"] {
            guard let rawValues = entry[key] as? [Any] else {
                continue
            }

            values.append(
                contentsOf: rawValues.compactMap { rawValue in
                    (rawValue as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            )
        }

        // VoiceBar treats duplicate spoken forms as one trigger for matching.
        return Self.uniqued(values.filter { $0.isEmpty == false }, by: Self.normalizedTrigger)
    }

    private func matchingSnippetIndex(
        for candidate: ImportCandidate,
        in snippets: [DictationSnippet]
    ) -> Int? {
        if let sourceIdentifier = candidate.metadata.sourceIdentifier {
            if let sourceMatch = snippets.firstIndex(where: {
                $0.importMetadata?.sourceIdentifier == sourceIdentifier
            }) {
                return sourceMatch
            }
        }

        let candidateTriggers = Set(candidate.triggers.map(Self.normalizedTrigger))
        return snippets.firstIndex { snippet in
            snippet.triggers
                .map(Self.normalizedTrigger)
                .contains(where: candidateTriggers.contains)
        }
    }

    private func hasTriggerConflictOutsideMatch(
        for candidate: ImportCandidate,
        matchingIndex: Int,
        in snippets: [DictationSnippet]
    ) -> Bool {
        let candidateTriggers = Set(candidate.triggers.map(Self.normalizedTrigger))

        // A candidate with several triggers can touch multiple existing snippets.
        // Treat that as a conflict instead of copying a trigger onto two snippets.
        return snippets.enumerated().contains { index, snippet in
            guard index != matchingIndex else {
                return false
            }

            return snippet.triggers
                .map(Self.normalizedTrigger)
                .contains(where: candidateTriggers.contains)
        }
    }

    private func mergedSnippet(
        from candidate: ImportCandidate,
        existingSnippet: DictationSnippet
    ) -> DictationSnippet {
        let mergedTriggers = Self.uniqued(
            existingSnippet.triggers + candidate.triggers,
            by: Self.normalizedTrigger
        )
        var metadata = candidate.metadata

        // Keep idempotent re-imports from looking like content updates just
        // because the transient imported-at timestamp was refreshed.
        if Self.matchesExcludingImportedAt(metadata, existingSnippet.importMetadata) {
            metadata.importedAt = existingSnippet.importMetadata?.importedAt
        }

        return DictationSnippet(
            id: existingSnippet.id,
            label: candidate.label,
            triggers: mergedTriggers,
            expansion: candidate.expansion,
            enabled: existingSnippet.enabled,
            importMetadata: metadata
        )
    }

    private static func matchesExcludingImportedAt(
        _ lhs: DictationSnippetImportMetadata,
        _ rhs: DictationSnippetImportMetadata?
    ) -> Bool {
        guard let rhs else {
            return false
        }

        return lhs.sourceApplication == rhs.sourceApplication
            && lhs.sourceIdentifier == rhs.sourceIdentifier
            && lhs.sourceKind == rhs.sourceKind
            && lhs.category == rhs.category
            && lhs.createdAt == rhs.createdAt
            && lhs.updatedAt == rhs.updatedAt
            && lhs.lastUsedAt == rhs.lastUsedAt
            && lhs.frequencyUsed == rhs.frequencyUsed
            && lhs.observedSource == rhs.observedSource
            && lhs.isStarred == rhs.isStarred
    }

    private func newSnippet(
        from candidate: ImportCandidate,
        existingSnippets: [DictationSnippet]
    ) -> DictationSnippet {
        let baseIdentifier = candidate.metadata.sourceIdentifier
            ?? candidate.label
        let uniqueIdentifier = Self.uniqueIdentifier(
            basedOn: baseIdentifier,
            existingIdentifiers: Set(existingSnippets.map(\.id))
        )

        return DictationSnippet(
            id: uniqueIdentifier,
            label: candidate.label,
            triggers: candidate.triggers,
            expansion: candidate.expansion,
            enabled: true,
            importMetadata: candidate.metadata
        )
    }

    private static func uniqueIdentifier(
        basedOn rawValue: String,
        existingIdentifiers: Set<String>
    ) -> String {
        let baseIdentifier = "wispr-flow-" + slug(rawValue)
        var identifier = baseIdentifier
        var suffix = 2

        while existingIdentifiers.contains(identifier) {
            identifier = "\(baseIdentifier)-\(suffix)"
            suffix += 1
        }

        return identifier
    }

    private static func slug(_ rawValue: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
        let scalars = rawValue.lowercased().unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars)
            .split(separator: "-")
            .joined(separator: "-")

        return collapsed.isEmpty ? "snippet" : collapsed
    }

    private static func normalizedTrigger(_ trigger: String) -> String {
        trigger
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: punctuationBoundaryCharacters)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
    }

    private static func normalizedClassificationValue(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              trimmedValue.isEmpty == false else {
            return nil
        }

        return trimmedValue
            .replacingOccurrences(of: "_", with: "-")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    // Match the runtime exact-trigger boundary handling so imports cannot create
    // punctuation-equivalent enabled triggers that resolve unpredictably.
    private static let punctuationBoundaryCharacters = CharacterSet(charactersIn: "\"'`.,;:!?()[]{}")

    private static func looksSensitive(_ value: String) -> Bool {
        let lowercasedValue = value.lowercased()
        let highConfidenceFragments = [
            "-----begin ",
            "private key-----",
            "aws_secret_access_key",
            "github_pat_",
            "ghp_",
            "xoxb-",
            "xoxp-"
        ]

        if highConfidenceFragments.contains(where: lowercasedValue.contains) {
            return true
        }

        let assignmentFragments = [
            "api_key=",
            "api key:",
            "access_token=",
            "access token:",
            "secret=",
            "secret:",
            "password=",
            "password:"
        ]

        return assignmentFragments.contains(where: lowercasedValue.contains)
            || containsSecretKeyPattern(in: value)
    }

    private static func containsSecretKeyPattern(in value: String) -> Bool {
        guard let expression = try? NSRegularExpression(
            pattern: #"(?i)\bsk-[a-z0-9_-]{16,}\b"#,
            options: []
        ) else {
            return false
        }

        return expression.firstMatch(
            in: value,
            range: NSRange(value.startIndex..., in: value)
        ) != nil
    }

    private static func uniqued(
        _ values: [String],
        by normalize: (String) -> String
    ) -> [String] {
        var seenValues: Set<String> = []
        var result: [String] = []

        for value in values {
            let normalizedValue = normalize(value)
            guard seenValues.contains(normalizedValue) == false else {
                continue
            }

            seenValues.insert(normalizedValue)
            result.append(value)
        }

        return result
    }
}

private struct ImportPlan {
    var preview: WisprFlowSnippetImportPreview
    var mergedSnippets: [DictationSnippet]
}

private struct ParsedImport {
    var entryCount: Int
    var candidates: [ImportCandidate]
    var ignoredDeletedCount: Int
    var invalidEntryCount: Int
    var duplicateTriggerCount: Int
    var sensitiveEntryCount: Int
    var commandTextEntryCount: Int
    var categoryCounts: [String: Int]
    var invalidReasonCounts: [String: Int]
}

private struct ImportCandidate {
    var label: String
    var triggers: [String]
    var expansion: String
    var metadata: DictationSnippetImportMetadata
    var isSensitive: Bool
    var isCommandText: Bool
}

private struct ManifestEntry {
    var category: String?
    var trigger: String?
}

private extension Dictionary where Key == String, Value == Int {
    mutating func increment(_ key: String) {
        self[key, default: 0] += 1
    }
}

private func string(in dictionary: [String: Any], keys: [String]) -> String? {
    for key in keys {
        if let value = dictionary[key] as? String {
            return value
        }
    }

    return nil
}

private func trimmedString(in dictionary: [String: Any], keys: [String]) -> String? {
    for key in keys {
        if let value = dictionary[key] as? String {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedValue.isEmpty == false {
                return trimmedValue
            }
        }
    }

    return nil
}

private func boolValue(in dictionary: [String: Any], keys: [String]) -> Bool? {
    for key in keys {
        if let value = dictionary[key] as? Bool {
            return value
        }

        if let value = dictionary[key] as? Int {
            return value != 0
        }

        if let value = dictionary[key] as? Double {
            return value != 0
        }

        if let value = dictionary[key] as? String {
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "yes":
                return true
            case "false", "0", "no":
                return false
            default:
                continue
            }
        }
    }

    return nil
}

private func intValue(in dictionary: [String: Any], keys: [String]) -> Int? {
    for key in keys {
        if let value = dictionary[key] as? Int {
            return value
        }

        if let value = dictionary[key] as? Double {
            return Int(value)
        }
    }

    return nil
}
