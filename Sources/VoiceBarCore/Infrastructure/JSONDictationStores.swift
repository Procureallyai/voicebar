import Foundation

public actor JSONDictationSnippetStore: DictationSnippetStore {
    private static let maximumBackupFileCount = 20
    private static let storageLock = NSLock()
    private let storageURL: URL

    public init(storageURL: URL = VoiceBarStorageLocation.dictationSnippetsURL) {
        self.storageURL = storageURL
    }

    public func loadSnippets() async throws -> [DictationSnippet] {
        // These operator-facing files are intentionally editable outside the
        // app, so each load should reflect the latest on-disk JSON state.
        try Self.withStorageLock {
            try loadOrSeed(seed: Self.seededSnippets())
        }
    }

    private func loadOrSeed(seed: [DictationSnippet]) throws -> [DictationSnippet] {
        if FileManager.default.fileExists(atPath: storageURL.path) {
            let data = try Data(contentsOf: storageURL)
            return try JSONDecoder().decode([DictationSnippet].self, from: data)
        }

        try persist(seed)
        return seed
    }

    private func persist(_ snippets: [DictationSnippet]) throws {
        try VoiceBarStorageLocation.ensureDirectoryExists(for: storageURL)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(snippets)
        try data.write(to: storageURL, options: .atomic)
    }

    public func replaceSnippets(
        _ snippets: [DictationSnippet],
        creatingBackup: Bool = true
    ) throws -> URL? {
        try Self.withStorageLock {
            let backupURL = creatingBackup ? try backupCurrentSnippets() : nil
            try persist(snippets)
            pruneOldBackups(preserving: backupURL)
            return backupURL
        }
    }

    public func updateSnippets(
        creatingBackup: Bool = true,
        _ transform: @Sendable ([DictationSnippet]) throws -> [DictationSnippet]
    ) throws -> (snippets: [DictationSnippet], backupURL: URL?) {
        try Self.withStorageLock {
            let currentSnippets = try loadOrSeed(seed: Self.seededSnippets())
            let updatedSnippets = try transform(currentSnippets)
            let backupURL = creatingBackup ? try backupCurrentSnippets() : nil
            try persist(updatedSnippets)
            pruneOldBackups(preserving: backupURL)
            return (updatedSnippets, backupURL)
        }
    }

    public func updateSnippetsWithResult<Result: Sendable>(
        creatingBackup: Bool = true,
        _ transform: @Sendable ([DictationSnippet]) throws -> (snippets: [DictationSnippet], result: Result)
    ) throws -> (snippets: [DictationSnippet], backupURL: URL?, result: Result) {
        try Self.withStorageLock {
            let currentSnippets = try loadOrSeed(seed: Self.seededSnippets())
            let update = try transform(currentSnippets)
            let backupURL = creatingBackup ? try backupCurrentSnippets() : nil
            try persist(update.snippets)
            pruneOldBackups(preserving: backupURL)
            return (update.snippets, backupURL, update.result)
        }
    }

    public func backupCurrentSnippets() throws -> URL {
        try VoiceBarStorageLocation.ensureDirectoryExists(for: storageURL)

        // Backups sit beside the editable JSON file so an import can always be
        // rolled back without knowing the operator's Application Support path.
        let preferredBackupURL = storageURL
            .deletingLastPathComponent()
            .appendingPathComponent(Self.backupFileName(for: Date()), isDirectory: false)
        let backupURL = Self.uniqueBackupURL(
            preferredBackupURL,
            fileManager: FileManager.default
        )

        if FileManager.default.fileExists(atPath: storageURL.path) {
            try FileManager.default.copyItem(at: storageURL, to: backupURL)
        } else {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode([DictationSnippet]()).write(to: backupURL, options: .atomic)
        }

        return backupURL
    }

    private static func backupFileName(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")

        return "dictation-snippets.backup-\(timestamp)-\(UUID().uuidString).json"
    }

    private static func uniqueBackupURL(_ preferredURL: URL, fileManager: FileManager) -> URL {
        guard fileManager.fileExists(atPath: preferredURL.path) else {
            return preferredURL
        }

        let directoryURL = preferredURL.deletingLastPathComponent()
        let baseName = preferredURL.deletingPathExtension().lastPathComponent
        let pathExtension = preferredURL.pathExtension
        var suffix = 2

        while true {
            let candidateURL = directoryURL
                .appendingPathComponent("\(baseName)-\(suffix)", isDirectory: false)
                .appendingPathExtension(pathExtension)

            if fileManager.fileExists(atPath: candidateURL.path) == false {
                return candidateURL
            }

            suffix += 1
        }
    }

    private func pruneOldBackups(preserving preservedURL: URL?) {
        let fileManager = FileManager.default
        let directoryURL = storageURL.deletingLastPathComponent()

        guard let backupURLs = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        let sortedBackupURLs = backupURLs
            .filter(Self.isSnippetBackupURL)
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        let preservedFileName = preservedURL?.lastPathComponent
        var retainedCount = 0

        for backupURL in sortedBackupURLs {
            if backupURL.lastPathComponent == preservedFileName {
                retainedCount += 1
                continue
            }

            if retainedCount < Self.maximumBackupFileCount {
                retainedCount += 1
                continue
            }

            // Backup pruning should never turn a successful import write into
            // a failed import; stale backups are best-effort cleanup.
            try? fileManager.removeItem(at: backupURL)
        }
    }

    private static func withStorageLock<T>(_ body: () throws -> T) rethrows -> T {
        storageLock.lock()
        defer {
            storageLock.unlock()
        }

        return try body()
    }

    private static func isSnippetBackupURL(_ url: URL) -> Bool {
        let fileName = url.lastPathComponent
        return fileName.hasPrefix("dictation-snippets.backup-")
            && fileName.hasSuffix(".json")
    }

    private static func seededSnippets() -> [DictationSnippet] {
        [
            DictationSnippet(
                id: "procure-ally-ai",
                triggers: ["procure ally ai", "procure ally"],
                expansion: "Procure Ally AI"
            ),
            DictationSnippet(
                id: "local-notes",
                triggers: ["local notes"],
                expansion: "Local Notes"
            ),
            DictationSnippet(
                id: "bigquery",
                triggers: ["big query"],
                expansion: "BigQuery"
            )
        ]
    }
}

public actor JSONDictationActionRegistryStore: DictationActionRegistryStore {
    private let storageURL: URL

    public init(storageURL: URL = VoiceBarStorageLocation.dictationActionsURL) {
        self.storageURL = storageURL
    }

    public func loadActions() async throws -> [DictationActionDefinition] {
        // These operator-facing files are intentionally editable outside the
        // app, so each load should reflect the latest on-disk JSON state.
        try loadOrSeed(seed: Self.seededActions())
    }

    private func loadOrSeed(seed: [DictationActionDefinition]) throws -> [DictationActionDefinition] {
        if FileManager.default.fileExists(atPath: storageURL.path) {
            let data = try Data(contentsOf: storageURL)
            return try JSONDecoder().decode([DictationActionDefinition].self, from: data)
        }

        try persist(seed)
        return seed
    }

    private func persist(_ actions: [DictationActionDefinition]) throws {
        try VoiceBarStorageLocation.ensureDirectoryExists(for: storageURL)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(actions)
        try data.write(to: storageURL, options: .atomic)
    }

    private static func seededActions() -> [DictationActionDefinition] {
        [
            DictationActionDefinition(
                id: "example-local-notes",
                displayName: "Example Local Notes",
                triggers: ["open example local notes"],
                scriptPath: "~/bin/voicebar-example-disabled.sh",
                enabled: false,
                requiresConfirmation: true,
                allowMixedMode: false
            )
        ]
    }
}

public actor JSONDictationHistoryStore: DictationHistoryStore {
    private let storageURL: URL

    public init(storageURL: URL = VoiceBarStorageLocation.dictationHistoryURL) {
        self.storageURL = storageURL
    }

    public func loadEntries() async throws -> [DictationHistoryEntry] {
        try loadCurrentEntries()
    }

    public func saveEntry(
        _ entry: DictationHistoryEntry,
        retentionLimit: Int
    ) async throws -> [DictationHistoryEntry] {
        let retainedLimit = Self.sanitizedRetentionLimit(retentionLimit)
        let currentEntries = try loadCurrentEntries()
            .filter { $0.id != entry.id }
        let nextEntries = Self.prunedEntries(
            [entry] + currentEntries,
            retentionLimit: retainedLimit
        )
        try persist(nextEntries)
        return nextEntries
    }

    public func updateInsertionSummary(
        entryID: String,
        insertionSummary: String,
        retentionLimit: Int
    ) async throws -> [DictationHistoryEntry] {
        let retainedLimit = Self.sanitizedRetentionLimit(retentionLimit)
        let nextEntries = try loadCurrentEntries().map { entry in
            guard entry.id == entryID else {
                return entry
            }

            var updatedEntry = entry
            updatedEntry.insertionSummary = insertionSummary
            return updatedEntry
        }
        let prunedEntries = Self.prunedEntries(
            nextEntries,
            retentionLimit: retainedLimit
        )
        try persist(prunedEntries)
        return prunedEntries
    }

    public func trimEntries(retentionLimit: Int) async throws -> [DictationHistoryEntry] {
        let retainedLimit = Self.sanitizedRetentionLimit(retentionLimit)
        let prunedEntries = Self.prunedEntries(
            try loadCurrentEntries(),
            retentionLimit: retainedLimit
        )
        try persist(prunedEntries)
        return prunedEntries
    }

    public func clearEntries() async throws {
        try persist([])
    }

    private func loadCurrentEntries() throws -> [DictationHistoryEntry] {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return []
        }

        let data = try Data(contentsOf: storageURL)
        return try Self.decoder.decode([DictationHistoryEntry].self, from: data)
            .sorted { lhs, rhs in
                lhs.createdAt > rhs.createdAt
            }
    }

    private func persist(_ entries: [DictationHistoryEntry]) throws {
        try VoiceBarStorageLocation.ensureDirectoryExists(for: storageURL)

        let data = try Self.encoder.encode(entries)
        try data.write(to: storageURL, options: .atomic)
    }

    private static func prunedEntries(
        _ entries: [DictationHistoryEntry],
        retentionLimit: Int
    ) -> [DictationHistoryEntry] {
        Array(
            entries
                .sorted { lhs, rhs in
                    lhs.createdAt > rhs.createdAt
                }
                .prefix(sanitizedRetentionLimit(retentionLimit))
        )
    }

    private static func sanitizedRetentionLimit(_ retentionLimit: Int) -> Int {
        min(200, max(1, retentionLimit))
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
