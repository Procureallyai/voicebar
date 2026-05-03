import Foundation

public struct OllamaFormatterService: DictationFormatterService {
    public static let modelOverrideEnvironmentKey = "VOICEBAR_OLLAMA_FORMATTER_MODEL"
    public static let hostOverrideEnvironmentKey = "VOICEBAR_OLLAMA_HOST"
    public static let defaultModel = "llama3.2:3b"
    public static let requestTimeoutSeconds: TimeInterval = 2

    private static let warmUpTimeoutSeconds: TimeInterval = 2

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func availability() async -> DictationServiceAvailability {
        let tagsURL = apiBaseURL().appendingPathComponent("tags")
        var request = URLRequest(url: tagsURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 3

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return DictationServiceAvailability(
                    isAvailable: false,
                    reason: "Ollama did not respond successfully at \(tagsURL.absoluteString)."
                )
            }
        } catch {
            return DictationServiceAvailability(
                isAvailable: false,
                reason: "Ollama is not reachable at \(tagsURL.absoluteString)."
            )
        }

        return DictationServiceAvailability(
            isAvailable: true,
            reason: "Ollama is reachable locally for formatter and action routing."
        )
    }

    public func resolvedModelIdentifier(for formatterModelIdentifier: String) -> String {
        let overriddenModel = ProcessInfo.processInfo.environment[Self.modelOverrideEnvironmentKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let overriddenModel, overriddenModel.isEmpty == false {
            return overriddenModel
        }

        let requestedModel = formatterModelIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if requestedModel.isEmpty == false {
            return requestedModel
        }

        return Self.defaultModel
    }

    public func warmUp(modelIdentifier: String?) async -> DictationFormatterWarmUpResult {
        let startNanoseconds = DispatchTime.now().uptimeNanoseconds
        let resolvedModel = resolvedModelIdentifier(for: modelIdentifier ?? "")
        let url = apiBaseURL().appendingPathComponent("generate")

        let payload: [String: Any] = [
            "model": resolvedModel,
            "stream": false,
            "keep_alive": "10m",
            "options": [
                "temperature": 0,
                "num_predict": 1
            ],
            "prompt": "VoiceBar formatter warm-up."
        ]

        do {
            let body = try JSONSerialization.data(withJSONObject: payload)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = Self.warmUpTimeoutSeconds
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            let (_, response) = try await session.data(for: request)
            let elapsedMilliseconds = Int((DispatchTime.now().uptimeNanoseconds - startNanoseconds) / 1_000_000)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                return DictationFormatterWarmUpResult(
                    modelIdentifier: resolvedModel,
                    didSucceed: false,
                    elapsedMilliseconds: elapsedMilliseconds,
                    detail: "Warm-up returned HTTP \(statusCode)."
                )
            }

            return DictationFormatterWarmUpResult(
                modelIdentifier: resolvedModel,
                didSucceed: true,
                elapsedMilliseconds: elapsedMilliseconds,
                detail: "Formatter model warmed successfully."
            )
        } catch {
            let elapsedMilliseconds = Int((DispatchTime.now().uptimeNanoseconds - startNanoseconds) / 1_000_000)
            return DictationFormatterWarmUpResult(
                modelIdentifier: resolvedModel,
                didSucceed: false,
                elapsedMilliseconds: elapsedMilliseconds,
                detail: "Warm-up failed. \(describe(error))"
            )
        }
    }

    public func format(_ request: DictationFormattingRequest) async throws -> DictationFormatterResponse {
        let url = apiBaseURL().appendingPathComponent("chat")
        let schema = Self.responseSchema()

        // Capture the resolved model early for use in diagnostics (e.g., timeout messages)
        let model = resolvedModelIdentifier(for: request.formatterModelIdentifier)

        let payload: [String: Any] = [
            "model": model,
            "stream": false,
            "format": schema,
            "options": [
                "temperature": 0
            ],
            "messages": [
                [
                    "role": "system",
                    "content": Self.voiceBarFormatterMetaPrompt
                ],
                [
                    "role": "user",
                    "content": try serializedRequestPrompt(from: request)
                ]
            ]
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        // Dictation has to stay responsive on the operator Mac, so formatter
        // attempts bail out quickly and let the pipeline fall back to direct
        // snippet-expanded insertion when structured cleanup is too slow.
        urlRequest.timeoutInterval = Self.requestTimeoutSeconds
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let responseData: Data
        let response: URLResponse

        do {
            (responseData, response) = try await session.data(for: urlRequest)
        } catch let error as URLError where error.code == .timedOut {
            throw DictationRuntimeError.formattingFailed(
                "Ollama formatter timed out after \(Self.requestTimeoutSeconds)s using \(model). VoiceBar inserted deterministic output without LLM cleanup."
            )
        } catch {
            throw DictationRuntimeError.formattingFailed(
                "VoiceBar could not reach Ollama for dictation cleanup. \(describe(error))"
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictationRuntimeError.formattingFailed(
                "VoiceBar received a non-HTTP response from Ollama."
            )
        }

        guard httpResponse.statusCode == 200 else {
            let errorPayload = String(decoding: responseData, as: UTF8.self)
            throw DictationRuntimeError.formattingFailed(
                "Ollama returned HTTP \(httpResponse.statusCode). \(errorPayload)"
            )
        }

        return try Self.decodeFormatterResponse(from: responseData)
    }

    public static func decodeFormatterResponse(from responseData: Data) throws -> DictationFormatterResponse {
        let envelope = try JSONDecoder().decode(OllamaChatEnvelope.self, from: responseData)
        let content = envelope.message.content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard content.isEmpty == false else {
            throw DictationRuntimeError.formattingFailed(
                "Ollama returned an empty formatter payload."
            )
        }

        do {
            return try JSONDecoder().decode(
                DictationFormatterResponse.self,
                from: Data(content.utf8)
            )
        } catch {
            throw DictationRuntimeError.formattingFailed(
                "VoiceBar could not decode the formatter response schema. \(error.localizedDescription)"
            )
        }
    }

    private func apiBaseURL() -> URL {
        let host = ProcessInfo.processInfo.environment[Self.hostOverrideEnvironmentKey]
            ?? "http://127.0.0.1:11434/api"
        return URL(string: host) ?? URL(string: "http://127.0.0.1:11434/api")!
    }

    private func serializedRequestPrompt(from request: DictationFormattingRequest) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(request)
        let requestJSON = String(decoding: data, as: UTF8.self)
        return """
        VoiceBar request payload (JSON):
        \(requestJSON)
        """
    }

    private static let voiceBarFormatterMetaPrompt = """
    You are VoiceBar's local dictation formatter and conservative action classifier.

    Hard constraints:
    - Preserve speaker meaning. Do not invent facts, commands, or entities.
    - Return ONLY JSON that matches the provided schema. No markdown, no prose.
    - Never emit executable shell text or implied shell steps.
    - Keep output concise and insertion-ready.

    Formatting behavior:
    - Honor explicit formatting instructions from the transcript.
    - Remove filler words only when meaning is unchanged.
    - Keep already-expanded snippets intact; do not "improve" or rewrite snippet expansions.
    - Apply punctuation, headings, paragraphs, and list formatting only when clearly requested.
    - For explicit list commands, render plain-text or markdown-style lists.
    - For explicit email requests, shape output as an email (subject/body/signoff only when requested).

    Mode behavior:
    - detectedMode=dictation for normal insertion text.
    - detectedMode=command only when utterance is clearly an allowlisted action trigger.
    - detectedMode=mixed only when both insertion text and an action trigger are clearly present.

    Action candidate behavior:
    - Be conservative. If uncertain, return an empty actionCandidates array.
    - Prefer exact spoken trigger phrases over paraphrases.
    - Do not fabricate action IDs.

    Quality guardrails:
    - Preserve names, numbers, and intent.
    - Avoid over-editing short fragments.
    """

    private static func responseSchema() -> [String: Any] {
        [
            "type": "object",
            "required": [
                "cleanedText",
                "formattedText",
                "detectedMode",
                "snippetApplications",
                "actionCandidates",
                "shouldInsertText"
            ],
            "properties": [
                "cleanedText": [
                    "type": "string"
                ],
                "formattedText": [
                    "type": "string"
                ],
                "detectedMode": [
                    "type": "string",
                    "enum": [
                        DictationDetectedMode.dictation.rawValue,
                        DictationDetectedMode.command.rawValue,
                        DictationDetectedMode.mixed.rawValue
                    ]
                ],
                "snippetApplications": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "required": ["snippetID", "trigger", "expansion"],
                        "properties": [
                            "snippetID": ["type": "string"],
                            "trigger": ["type": "string"],
                            "expansion": ["type": "string"]
                        ]
                    ]
                ],
                "actionCandidates": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "actionID": ["type": "string"],
                            "triggerPhrase": ["type": "string"],
                            "confidence": ["type": "number"]
                        ]
                    ]
                ],
                "shouldInsertText": [
                    "type": "boolean"
                ],
                "confidence": [
                    "type": "number"
                ]
            ]
        ]
    }

    private func describe(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return error.localizedDescription
    }
}

private struct OllamaChatEnvelope: Decodable {
    struct Message: Decodable {
        var content: String
    }

    var message: Message
}
