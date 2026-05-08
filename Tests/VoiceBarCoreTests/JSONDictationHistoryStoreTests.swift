import Foundation
import XCTest
@testable import VoiceBarCore

final class JSONDictationHistoryStoreTests: XCTestCase {
    func testSaveEntryKeepsNewestEntriesWithinRetentionLimit() async throws {
        let storageURL = temporaryStorageURL()
        let store = JSONDictationHistoryStore(storageURL: storageURL)

        let oldest = entry(id: "oldest", secondsAgo: 30)
        let middle = entry(id: "middle", secondsAgo: 20)
        let newest = entry(id: "newest", secondsAgo: 10)

        _ = try await store.saveEntry(oldest, retentionLimit: 2)
        _ = try await store.saveEntry(middle, retentionLimit: 2)
        let entries = try await store.saveEntry(newest, retentionLimit: 2)

        XCTAssertEqual(entries.map(\.id), ["newest", "middle"])
    }

    func testUpdateInsertionSummaryPreservesStoredText() async throws {
        let storageURL = temporaryStorageURL()
        let store = JSONDictationHistoryStore(storageURL: storageURL)
        let originalEntry = entry(id: "entry-one", secondsAgo: 5)

        _ = try await store.saveEntry(originalEntry, retentionLimit: 10)
        let updatedEntries = try await store.updateInsertionSummary(
            entryID: originalEntry.id,
            insertionSummary: "Insertion: pasted at the cursor and restored the prior clipboard.",
            retentionLimit: 10
        )

        XCTAssertEqual(updatedEntries.first?.id, originalEntry.id)
        XCTAssertEqual(updatedEntries.first?.rawTranscript, originalEntry.rawTranscript)
        XCTAssertEqual(updatedEntries.first?.formattedText, originalEntry.formattedText)
        XCTAssertEqual(
            updatedEntries.first?.insertionSummary,
            "Insertion: pasted at the cursor and restored the prior clipboard."
        )
    }

    func testClearEntriesLeavesAnEmptyHistoryFile() async throws {
        let storageURL = temporaryStorageURL()
        let store = JSONDictationHistoryStore(storageURL: storageURL)

        _ = try await store.saveEntry(entry(id: "entry-one", secondsAgo: 5), retentionLimit: 10)
        try await store.clearEntries()
        let entries = try await store.loadEntries()

        XCTAssertEqual(entries, [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))
    }

    func testLegacyEntriesWithoutCharacterCountsStillDecode() async throws {
        let storageURL = temporaryStorageURL()
        try FileManager.default.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let legacyJSON = """
        [
          {
            "id": "legacy-entry",
            "createdAt": "2026-05-08T12:00:00Z",
            "rawTranscript": "legacy raw transcript",
            "formattedText": "Legacy formatted transcript.",
            "formatterPath": "ollama",
            "formatterModelIdentifier": "llama3.2",
            "frontmostBundleIdentifier": "com.example.Editor",
            "insertionSummary": "Insertion: pending."
          }
        ]
        """
        try legacyJSON.data(using: .utf8)?.write(to: storageURL, options: .atomic)

        let entries = try await JSONDictationHistoryStore(storageURL: storageURL).loadEntries()

        XCTAssertEqual(entries.first?.rawTranscriptCharacterCount, "legacy raw transcript".count)
        XCTAssertEqual(entries.first?.formattedCharacterCount, "Legacy formatted transcript.".count)
    }

    func testTrimEntriesPrunesCurrentStoredEntriesWithoutInjectingCachedEntries() async throws {
        let storageURL = temporaryStorageURL()
        let store = JSONDictationHistoryStore(storageURL: storageURL)

        _ = try await store.saveEntry(entry(id: "first", secondsAgo: 30), retentionLimit: 10)
        _ = try await store.saveEntry(entry(id: "second", secondsAgo: 20), retentionLimit: 10)
        _ = try await store.saveEntry(entry(id: "third", secondsAgo: 10), retentionLimit: 10)
        let entries = try await store.trimEntries(retentionLimit: 2)
        let persistedEntries = try await store.loadEntries()

        XCTAssertEqual(entries.map(\.id), ["third", "second"])
        XCTAssertEqual(persistedEntries.map(\.id), ["third", "second"])
    }

    private func temporaryStorageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("dictation-history.json", isDirectory: false)
    }

    private func entry(
        id: String,
        secondsAgo: TimeInterval
    ) -> DictationHistoryEntry {
        DictationHistoryEntry(
            id: id,
            createdAt: Date().addingTimeInterval(-secondsAgo),
            rawTranscript: "raw transcript \(id)",
            formattedText: "Formatted transcript \(id).",
            formatterPath: .ollama,
            formatterModelIdentifier: "llama3.2",
            frontmostBundleIdentifier: "com.example.Editor",
            insertionSummary: "Insertion: pending."
        )
    }
}
