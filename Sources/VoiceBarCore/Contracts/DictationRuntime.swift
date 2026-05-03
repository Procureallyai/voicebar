import Foundation

public protocol SpeechToTextService: Sendable {
    func availability() async -> DictationServiceAvailability
    func transcribe(
        audioFileURL: URL,
        rollingPrompt: String?
    ) async throws -> String
}

public protocol DictationFormatterService: Sendable {
    func availability() async -> DictationServiceAvailability
    func resolvedModelIdentifier(for formatterModelIdentifier: String) -> String
    func warmUp(modelIdentifier: String?) async -> DictationFormatterWarmUpResult
    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse
}

public extension DictationFormatterService {
    func resolvedModelIdentifier(for formatterModelIdentifier: String) -> String {
        formatterModelIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func warmUp(modelIdentifier: String?) async -> DictationFormatterWarmUpResult {
        let resolvedModel = resolvedModelIdentifier(for: modelIdentifier ?? "")
        return DictationFormatterWarmUpResult(
            modelIdentifier: resolvedModel,
            didSucceed: false,
            elapsedMilliseconds: 0,
            detail: "Formatter warm-up is not implemented for the current formatter backend."
        )
    }
}

public protocol DictationSnippetStore: Sendable {
    func loadSnippets() async throws -> [DictationSnippet]
    func replaceSnippets(_ snippets: [DictationSnippet], creatingBackup: Bool) async throws -> URL?
}

public protocol DictationActionRegistryStore: Sendable {
    func loadActions() async throws -> [DictationActionDefinition]
}
