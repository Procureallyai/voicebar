import XCTest
@testable import VoiceBarCore

final class DictationPipelineFormatterPolishTests: XCTestCase {
    func testModelCommandLabelStillPolishesInsertableQuestionTextWithoutActionAuthority() async throws {
        let pipeline = DictationPipeline(
            formatterService: InsertableCommandLabelFormatter(),
            snippetStore: EmptySnippetStore(),
            actionStore: EmptyActionStore()
        )

        let result = try await pipeline.processTranscript(
            "can you send me the latest build status",
            formattingMode: .notes,
            qualityMode: .quality,
            formatterModelIdentifier: "synthetic-local-formatter",
            frontmostBundleIdentifier: "com.example.voicebar.synthetic-host"
        )

        XCTAssertNil(result.resolvedAction)
        XCTAssertEqual(result.formatterPath, .ollama)
        XCTAssertEqual(result.insertionText, "Can you send me the latest build status?")
    }
}

private struct InsertableCommandLabelFormatter: DictationFormatterService {
    func availability() async -> DictationServiceAvailability {
        DictationServiceAvailability(isAvailable: true, reason: "Synthetic formatter for tests.")
    }

    func resolvedModelIdentifier(for formatterModelIdentifier: String) -> String {
        formatterModelIdentifier
    }

    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        DictationFormatterResponse(
            cleanedText: "Can you send me the latest build status.",
            formattedText: "Can you send me the latest build status.",
            detectedMode: .command,
            snippetApplications: [],
            actionCandidates: [],
            shouldInsertText: true,
            confidence: 0.8
        )
    }
}

private struct EmptySnippetStore: DictationSnippetStore {
    func loadSnippets() async throws -> [DictationSnippet] {
        []
    }

    func replaceSnippets(_ snippets: [DictationSnippet], creatingBackup: Bool) async throws -> URL? {
        nil
    }
}

private struct EmptyActionStore: DictationActionRegistryStore {
    func loadActions() async throws -> [DictationActionDefinition] {
        []
    }
}
