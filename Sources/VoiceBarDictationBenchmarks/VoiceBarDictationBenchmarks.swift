import Foundation
import VoiceBarCore

@main
struct VoiceBarDictationBenchmarks {
    struct Case {
        var id: String
        var transcript: String
        var expected: String?
        var requiredFragments: [String]
        var requiredFormatterPath: DictationFormatterPath?
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

        var cases = [
            Case(
                id: "statement",
                transcript: "hello world this is a test",
                expected: "Hello world this is a test.",
                requiredFragments: [],
                requiredFormatterPath: nil,
                formattingMode: .notes,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "question",
                transcript: "can you send me the latest build status",
                expected: "Can you send me the latest build status?",
                requiredFragments: [],
                requiredFormatterPath: nil,
                formattingMode: .notes,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "spoken_punctuation",
                transcript: "hello comma world exclamation point",
                expected: "Hello, world!",
                requiredFragments: [],
                requiredFormatterPath: nil,
                formattingMode: .automatic,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "numbered_list",
                transcript: "make this a numbered list one apples two oranges three pears",
                expected: "1. apples\n2. oranges\n3. pears",
                requiredFragments: [],
                requiredFormatterPath: nil,
                formattingMode: .notes,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "bullet_list",
                transcript: "write this as a bullet list apples oranges pears",
                expected: "- apples\n- oranges\n- pears",
                requiredFragments: [],
                requiredFormatterPath: nil,
                formattingMode: .bulletList,
                qualityMode: requestedQualityMode
            ),
            Case(
                id: "email",
                transcript: "format this as an email to the team saying the report is ready",
                expected: "To: the team\n\nThe report is ready.",
                requiredFragments: [],
                requiredFormatterPath: nil,
                formattingMode: .email,
                qualityMode: requestedQualityMode
            )
        ]

        if useLiveOllama {
            cases.append(
                Case(
                    id: "normal_use_long",
                    transcript: "this is a normal use formatter reliability benchmark i want to check whether voicebar keeps the punctuation capitalization and question marks stable when the dictation is longer than a short sentence can you make this read like a clear update for the user",
                    expected: nil,
                    requiredFragments: [
                        "VoiceBar",
                        "punctuation",
                        "capitalization",
                        "question marks",
                        "clear update"
                    ],
                    requiredFormatterPath: .ollama,
                    formattingMode: .notes,
                    qualityMode: requestedQualityMode
                )
            )
        }

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

            let didPass = didBenchmarkResultPass(result, benchmarkCase: benchmarkCase)
            if didPass {
                passed += 1
            }

            print("\(benchmarkCase.id)\t\(result.formatterPath.rawValue)\t\(latency)\t\(didPass)")

            if didPass == false {
                if let expected = benchmarkCase.expected {
                    print("  expected: \(expected.replacingOccurrences(of: "\n", with: "\\n"))")
                }
                if let requiredFormatterPath = benchmarkCase.requiredFormatterPath {
                    print("  required_path: \(requiredFormatterPath.rawValue)")
                }
                if benchmarkCase.requiredFragments.isEmpty == false {
                    print("  required_fragments: \(benchmarkCase.requiredFragments.joined(separator: ", "))")
                }
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

    private static func didBenchmarkResultPass(
        _ result: DictationPipelineResult,
        benchmarkCase: Case
    ) -> Bool {
        if let expected = benchmarkCase.expected, normalize(result.insertionText) != normalize(expected) {
            return false
        }

        if let requiredFormatterPath = benchmarkCase.requiredFormatterPath,
           result.formatterPath != requiredFormatterPath {
            return false
        }

        let normalizedInsertionText = normalize(result.insertionText).lowercased()
        return benchmarkCase.requiredFragments.allSatisfy { fragment in
            normalizedInsertionText.contains(fragment.lowercased())
        }
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
