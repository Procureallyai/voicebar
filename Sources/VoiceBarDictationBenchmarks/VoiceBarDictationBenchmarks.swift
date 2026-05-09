import Foundation
import VoiceBarCore

@main
struct VoiceBarDictationBenchmarks {
    struct Case {
        var id: String
        var transcript: String
        var expected: String
        var formattingMode: DictationFormattingMode
        var qualityMode: DictationFormatterQualityMode
    }

    static func main() async {
        let useLiveOllama = CommandLine.arguments.contains("--live-ollama")
        let requestedQualityMode = qualityModeFromArguments() ?? .balanced
        let formatterService: any DictationFormatterService = useLiveOllama
            ? OllamaFormatterService()
            : BenchmarkFailingFormatter()
        let runnerLabel = useLiveOllama ? "live Ollama when available" : "deterministic plus fallback"

        let cases = [
            Case(
                id: "statement",
                transcript: "hello world this is a test",
                expected: "Hello world this is a test.",
                formattingMode: .notes,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "question",
                transcript: "can you send me the latest build status",
                expected: "Can you send me the latest build status?",
                formattingMode: .notes,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "spoken_punctuation",
                transcript: "hello comma world exclamation point",
                expected: "Hello, world!",
                formattingMode: .automatic,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "numbered_list",
                transcript: "make this a numbered list one apples two oranges three pears",
                expected: "1. apples\n2. oranges\n3. pears",
                formattingMode: .notes,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "bullet_list",
                transcript: "write this as a bullet list apples oranges pears",
                expected: "- apples\n- oranges\n- pears",
                formattingMode: .bulletList,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "email",
                transcript: "format this as an email to the team saying the report is ready",
                expected: "To: the team\n\nThe report is ready.",
                formattingMode: .email,
                qualityMode: requestedQualityMode
            )
        ]

        print("VoiceBar dictation formatting benchmark")
        print("Runner: \(runnerLabel)")
        print("Quality: \(requestedQualityMode.rawValue)")
        print("Cases: \(cases.count)")

        if useLiveOllama {
            let warmUpStartedAt = DispatchTime.now().uptimeNanoseconds
            let warmUpResult = await OllamaFormatterService().warmUp(
                modelIdentifier: OllamaFormatterService.defaultModel
            )
            let warmUpLatency = Int((DispatchTime.now().uptimeNanoseconds - warmUpStartedAt) / 1_000_000)
            print("Warm-up: \(warmUpResult.didSucceed ? "passed" : "failed") \(warmUpLatency)ms \(warmUpResult.detail)")
        }

        print("")
        print("id\tpath\tlatency_ms\tpass")

        var passed = 0
        var totalLatency = 0

        for benchmarkCase in cases {
            let pipeline = DictationPipeline(
                formatterService: formatterService,
                snippetStore: BenchmarkSnippetStore(),
                actionStore: BenchmarkActionStore()
            )

            let startedAt = DispatchTime.now().uptimeNanoseconds
            let result: DictationPipelineResult

            do {
                result = try await pipeline.processTranscript(
                    benchmarkCase.transcript,
                    formattingMode: benchmarkCase.formattingMode,
                    qualityMode: benchmarkCase.qualityMode,
                    formatterModelIdentifier: OllamaFormatterService.defaultModel,
                    frontmostBundleIdentifier: "com.example.voicebar.benchmark"
                )
            } catch {
                fputs("\(benchmarkCase.id)\tfailed\t0\tfalse\n", stderr)
                fputs("  error: \(error.localizedDescription)\n", stderr)
                continue
            }

            let latency = Int((DispatchTime.now().uptimeNanoseconds - startedAt) / 1_000_000)
            totalLatency += latency

            let didPass = normalize(result.insertionText) == normalize(benchmarkCase.expected)
            if didPass {
                passed += 1
            }

            print("\(benchmarkCase.id)\t\(result.formatterPath.rawValue)\t\(latency)\t\(didPass)")

            if didPass == false {
                print("  expected: \(benchmarkCase.expected.replacingOccurrences(of: "\n", with: "\\n"))")
                print("  actual:   \(result.insertionText.replacingOccurrences(of: "\n", with: "\\n"))")
            }
        }

        let averageLatency = cases.isEmpty ? 0 : totalLatency / cases.count
        print("")
        print("Passed: \(passed)/\(cases.count)")
        print("Average latency: \(averageLatency)ms")

        if passed != cases.count {
            Foundation.exit(1)
        }
    }

    private static func normalize(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func qualityModeFromArguments() -> DictationFormatterQualityMode? {
        guard let qualityIndex = CommandLine.arguments.firstIndex(of: "--quality") else {
            return nil
        }

        let valueIndex = CommandLine.arguments.index(after: qualityIndex)
        guard valueIndex < CommandLine.arguments.endIndex else {
            fputs("Missing value for --quality. Use fast, balanced, or quality.\n", stderr)
            Foundation.exit(2)
        }

        let value = CommandLine.arguments[valueIndex].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch value {
        case "fast":
            return .fast
        case "balanced":
            return .balanced
        case "quality":
            return .quality
        default:
            fputs("Unknown quality mode '\(value)'. Use fast, balanced, or quality.\n", stderr)
            Foundation.exit(2)
        }
    }
}

private struct BenchmarkFailingFormatter: DictationFormatterService {
    func availability() async -> DictationServiceAvailability {
        DictationServiceAvailability(isAvailable: false, reason: "Benchmark formatter intentionally uses fallback.")
    }

    func resolvedModelIdentifier(for formatterModelIdentifier: String) -> String {
        formatterModelIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? OllamaFormatterService.defaultModel
            : formatterModelIdentifier
    }

    func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        throw DictationRuntimeError.formattingFailed("Benchmark fallback path.")
    }
}

private struct BenchmarkSnippetStore: DictationSnippetStore {
    func loadSnippets() async throws -> [DictationSnippet] {
        []
    }

    func replaceSnippets(_ snippets: [DictationSnippet], creatingBackup: Bool) async throws -> URL? {
        nil
    }
}

private struct BenchmarkActionStore: DictationActionRegistryStore {
    func loadActions() async throws -> [DictationActionDefinition] {
        []
    }
}
