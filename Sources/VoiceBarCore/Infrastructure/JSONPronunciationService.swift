import Foundation

public actor JSONPronunciationService: PronunciationService {
    private let storageURL: URL
    private var cachedDictionary: PronunciationDictionary?
    private var cachedStoredDictionary: PronunciationDictionary?

    public init(
        storageURL: URL = VoiceBarStorageLocation.fileURL(
            named: "pronunciation-dictionary.json"
        )
    ) {
        self.storageURL = storageURL
    }

    public func applyOverrides(
        to text: String,
        profile: AppProfile?
    ) async -> String {
        _ = profile

        guard let dictionary = try? loadDictionaryState() else {
            return text
        }

        let enabledEntries = dictionary.entries
            .filter(\.isEnabled)
            .sorted { $0.match.count > $1.match.count }

        return enabledEntries.reduce(text) { partialResult, entry in
            apply(entry: entry, to: partialResult)
        }
    }

    public func loadDictionary() async throws -> PronunciationDictionary {
        try loadDictionaryState()
    }

    public func updateDictionary(_ dictionary: PronunciationDictionary) async throws {
        let storedOverrides = explicitOverrideDictionary(from: dictionary)

        try persist(storedOverrides)
        cachedStoredDictionary = storedOverrides
        cachedDictionary = merge(
            defaults: PronunciationDictionary.bootstrapDefaults,
            overrides: storedOverrides
        )
    }

    private func loadDictionaryState() throws -> PronunciationDictionary {
        if let cachedDictionary {
            return cachedDictionary
        }

        let mergedDictionary = merge(
            defaults: PronunciationDictionary.bootstrapDefaults,
            overrides: try loadStoredDictionary()
        )

        cachedDictionary = mergedDictionary
        return mergedDictionary
    }

    private func persist(_ dictionary: PronunciationDictionary) throws {
        try VoiceBarStorageLocation.ensureDirectoryExists(for: storageURL)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(dictionary)
        try data.write(to: storageURL, options: .atomic)
    }

    private func apply(
        entry: PronunciationEntry,
        to text: String
    ) -> String {
        switch entry.matchKind {
        case .exactText:
            return replaceExactText(
                entry: entry,
                in: text
            )
        }
    }

    private func replaceExactText(
        entry: PronunciationEntry,
        in text: String
    ) -> String {
        // Editable JSON can contain malformed entries, so reject empty or
        // whitespace-only matches before they compile into a zero-width regex.
        let normalizedMatch = entry.match.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard normalizedMatch.isEmpty == false else {
            return text
        }

        let escapedMatch = NSRegularExpression.escapedPattern(for: entry.match)
        let escapedReplacement = NSRegularExpression.escapedTemplate(
            for: entry.replacement
        )

        let startsWithWord = entry.match.first?.isLetter == true || entry.match.first?.isNumber == true
        let endsWithWord = entry.match.last?.isLetter == true || entry.match.last?.isNumber == true

        let pattern = [
            startsWithWord ? #"(?<![\p{L}\p{N}])"# : "",
            escapedMatch,
            endsWithWord ? #"(?![\p{L}\p{N}])"# : ""
        ].joined()

        let options: NSRegularExpression.Options = entry.isCaseSensitive ? [] : [.caseInsensitive]

        guard let expression = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: escapedReplacement
        )
    }

    private func loadStoredDictionary() throws -> PronunciationDictionary {
        if let cachedStoredDictionary {
            return cachedStoredDictionary
        }

        let storedDictionary: PronunciationDictionary

        if FileManager.default.fileExists(atPath: storageURL.path) {
            let data = try Data(contentsOf: storageURL)
            storedDictionary = try JSONDecoder().decode(
                PronunciationDictionary.self,
                from: data
            )
        } else {
            storedDictionary = PronunciationDictionary(
                version: PronunciationDictionary.bootstrapDefaults.version,
                entries: []
            )
            try persist(storedDictionary)
        }

        // Legacy Prompt 005 builds persisted the full seeded dictionary. Treat
        // those exact copies as defaults rather than sticky user overrides so
        // future sample entries can still appear for existing installs.
        let explicitOverrides = explicitOverrideDictionary(from: storedDictionary)

        cachedStoredDictionary = explicitOverrides
        return explicitOverrides
    }

    private func explicitOverrideDictionary(
        from dictionary: PronunciationDictionary
    ) -> PronunciationDictionary {
        let defaultsByID = Dictionary(
            PronunciationDictionary.bootstrapDefaults.entries.map { ($0.id, $0) },
            uniquingKeysWith: { _, newest in newest }
        )
        let explicitEntries = dictionary.entries.compactMap { entry -> PronunciationEntry? in
            if defaultsByID[entry.id] == entry {
                return nil
            }

            return entry
        }

        return PronunciationDictionary(
            version: dictionary.version,
            entries: deduplicatedEntries(explicitEntries)
        )
    }

    private func merge(
        defaults: PronunciationDictionary,
        overrides: PronunciationDictionary
    ) -> PronunciationDictionary {
        var overridesByID = Dictionary(
            overrides.entries.map { ($0.id, $0) },
            uniquingKeysWith: { _, newest in newest }
        )
        let defaultIDs = Set(defaults.entries.map(\.id))

        let mergedDefaults = defaults.entries.map { entry in
            overridesByID.removeValue(forKey: entry.id) ?? entry
        }
        let customEntries = deduplicatedEntries(
            overrides.entries.filter { defaultIDs.contains($0.id) == false }
        )

        return PronunciationDictionary(
            version: max(defaults.version, overrides.version),
            entries: mergedDefaults + customEntries
        )
    }

    private func deduplicatedEntries(
        _ entries: [PronunciationEntry]
    ) -> [PronunciationEntry] {
        var lastIndexByID: [String: Int] = [:]

        for (index, entry) in entries.enumerated() {
            lastIndexByID[entry.id] = index
        }

        return entries.enumerated().compactMap { index, entry in
            lastIndexByID[entry.id] == index ? entry : nil
        }
    }
}
