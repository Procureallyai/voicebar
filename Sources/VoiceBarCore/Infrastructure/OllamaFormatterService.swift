import Foundation

public struct OllamaFormatterService: DictationFormatterService {
    public static let modelOverrideEnvironmentKey = "VOICEBAR_OLLAMA_FORMATTER_MODEL"
    public static let hostOverrideEnvironmentKey = "VOICEBAR_OLLAMA_HOST"
    public static let timeoutOverrideEnvironmentKey = "VOICEBAR_OLLAMA_FORMATTER_TIMEOUT_SECONDS"
    public static let defaultModel = "llama3.2:3b"
    public static let requestTimeoutSeconds: TimeInterval = 2

    private static let warmUpTimeoutSeconds: TimeInterval = 20

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
        let requestTimeoutSeconds = Self.requestTimeoutSeconds(
            for: request.qualityMode,
            transcriptCharacterCount: request.transcript.count
        )

        let payload: [String: Any] = [
            "model": model,
            "stream": false,
            "format": schema,
            "keep_alive": "10m",
            "options": [
                "temperature": 0,
                "num_predict": Self.responseTokenLimit(for: request.transcript.count)
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
        urlRequest.timeoutInterval = requestTimeoutSeconds
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let responseData: Data
        let response: URLResponse

        do {
            (responseData, response) = try await session.data(for: urlRequest)
        } catch let error as URLError where error.code == .timedOut {
            throw DictationRuntimeError.formattingFailed(
                "Ollama formatter timed out after \(formatSeconds(requestTimeoutSeconds))s using \(model) in \(request.qualityMode.rawValue) mode. VoiceBar inserted deterministic output without LLM cleanup."
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

        for candidate in Self.responseJSONCandidates(from: content) {
            if let response = try? JSONDecoder().decode(
                DictationFormatterResponse.self,
                from: Data(candidate.utf8)
            ) {
                return response
            }

            if let response = try? Self.decodeLenientFormatterResponse(from: candidate) {
                return response
            }
        }

        throw DictationRuntimeError.formattingFailed(
            "VoiceBar could not decode the formatter response schema after tolerant JSON extraction."
        )
    }

    public static func requestTimeoutSeconds(
        for qualityMode: DictationFormatterQualityMode,
        transcriptCharacterCount: Int? = nil
    ) -> TimeInterval {
        let timeoutOverride = ProcessInfo.processInfo.environment[Self.timeoutOverrideEnvironmentKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let overriddenTimeout = timeoutOverride.flatMap { TimeInterval($0) }

        if let overriddenTimeout, overriddenTimeout > 0 {
            return overriddenTimeout
        }

        let baseTimeout = qualityMode.timeoutSeconds
        guard let transcriptCharacterCount else {
            return baseTimeout
        }

        switch qualityMode {
        case .fast:
            return baseTimeout
        case .balanced:
            if transcriptCharacterCount <= 120 {
                return baseTimeout
            }

            if transcriptCharacterCount <= 320 {
                return 6
            }

            if transcriptCharacterCount <= 700 {
                return 7
            }

            return 8
        case .quality:
            if transcriptCharacterCount <= 120 {
                return baseTimeout
            }

            if transcriptCharacterCount <= 700 {
                return 10
            }

            return 12
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

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let rounded = seconds.rounded()
        if rounded == seconds {
            return "\(Int(rounded))"
        }

        return String(format: "%.1f", seconds)
    }

    private static func responseTokenLimit(for transcriptCharacterCount: Int) -> Int {
        min(1024, max(256, transcriptCharacterCount * 2 + 128))
    }

    private static func responseJSONCandidates(from content: String) -> [String] {
        var candidates: [String] = []
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        appendUnique(trimmedContent, to: &candidates)
        appendUnique(stripMarkdownFence(from: trimmedContent), to: &candidates)

        if let extractedObject = extractJSONObject(from: trimmedContent) {
            appendUnique(extractedObject, to: &candidates)
        }

        return candidates.filter { $0.isEmpty == false }
    }

    private static func stripMarkdownFence(from content: String) -> String {
        guard content.hasPrefix("```") else {
            return content
        }

        var lines = content.components(separatedBy: .newlines)
        if lines.first?.hasPrefix("```") == true {
            lines.removeFirst()
        }

        if lines.last?.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("```") == true {
            lines.removeLast()
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractJSONObject(from content: String) -> String? {
        guard
            let startIndex = content.firstIndex(of: "{"),
            let endIndex = content.lastIndex(of: "}"),
            startIndex <= endIndex
        else {
            return nil
        }

        return String(content[startIndex...endIndex])
    }

    private static func appendUnique(_ value: String, to candidates: inout [String]) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isEmpty == false, candidates.contains(trimmedValue) == false else {
            return
        }

        candidates.append(trimmedValue)
    }

    private static func decodeLenientFormatterResponse(from content: String) throws -> DictationFormatterResponse {
        let data = Data(content.utf8)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DictationRuntimeError.formattingFailed("Formatter response was not a JSON object.")
        }

        let formattedText = stringValue(for: object, keys: ["formattedText", "formatted_text", "text", "output"])
            ?? ""
        let cleanedText = stringValue(for: object, keys: ["cleanedText", "cleaned_text", "cleaned"])
            ?? formattedText
        let detectedMode = detectedModeValue(for: object["detectedMode"] ?? object["detected_mode"])
        let defaultShouldInsertText = formattedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let shouldInsertText = boolValue(for: object["shouldInsertText"] ?? object["should_insert_text"])
            ?? defaultShouldInsertText
        let confidence = numberValue(for: object["confidence"])

        return DictationFormatterResponse(
            cleanedText: cleanedText,
            formattedText: formattedText,
            detectedMode: detectedMode,
            snippetApplications: decodedArray(
                DictationSnippetApplication.self,
                from: object["snippetApplications"] ?? object["snippet_applications"]
            ) ?? [],
            actionCandidates: decodedArray(
                DictationActionCandidate.self,
                from: object["actionCandidates"] ?? object["action_candidates"]
            ) ?? [],
            shouldInsertText: shouldInsertText,
            confidence: confidence
        )
    }

    private static func stringValue(for object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = object[key] as? String {
                return value
            }
        }

        return nil
    }

    private static func detectedModeValue(for value: Any?) -> DictationDetectedMode {
        guard let value = value as? String else {
            return .dictation
        }

        return DictationDetectedMode(rawValue: value.lowercased()) ?? .dictation
    }

    private static func boolValue(for value: Any?) -> Bool? {
        if let value = value as? Bool {
            return value
        }

        guard let stringValue = value as? String else {
            return nil
        }

        switch stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            return nil
        }
    }

    private static func numberValue(for value: Any?) -> Double? {
        if let value = value as? Double {
            return value
        }

        if let value = value as? Int {
            return Double(value)
        }

        if let value = value as? String {
            return Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return nil
    }

    private static func decodedArray<Element: Decodable>(
        _ type: Element.Type,
        from value: Any?
    ) -> [Element]? {
        guard let value, JSONSerialization.isValidJSONObject(value) else {
            return nil
        }

        guard let data = try? JSONSerialization.data(withJSONObject: value) else {
            return nil
        }

        return try? JSONDecoder().decode([Element].self, from: data)
    }

    private static let voiceBarFormatterMetaPrompt = """
    You are VoiceBar's local dictation formatter and conservative action classifier.

    Hard constraints:
    - Preserve speaker meaning. Do not invent facts, commands, or entities.
    - Return ONLY JSON that matches the provided schema. No markdown, no prose.
    - Never emit executable shell text or implied shell steps.
    - Keep output concise and insertion-ready.

    Formatting behavior:
    - Treat transcript text as spoken dictation that needs written-form cleanup.
    - Honor explicit formatting instructions from the transcript.
    - Use sentence case for normal sentences. Do not title-case normal dictation.
    - Always restore obvious capitalization, sentence boundaries, terminal punctuation, and question marks.
    - Use exclamation marks only when the transcript explicitly says "exclamation point", explicitly says "exclamation mark", or clearly carries urgency.
    - Remove filler words only when meaning is unchanged.
    - Keep already-expanded snippets intact; do not "improve" or rewrite snippet expansions.
    - Apply headings, paragraphs, and list formatting only when clearly requested.
    - For explicit list commands, render plain-text or markdown-style lists with one item per line.
    - For explicit email requests, shape output as an email while avoiding invented recipients, subjects, or signoffs.
    - For Notes mode, prefer concise readable notes with light paragraphing instead of a single run-on sentence.
    - For Bullet List mode, prefer bullet items when the transcript contains multiple distinct items.

    Quality mode behavior:
    - Fast: make minimal safe cleanup and avoid heavy rewriting.
    - Balanced: improve punctuation, capitalization, sentence boundaries, and light structure.
    - Quality: polish the writing more thoroughly while preserving all meaning and technical terms.

    Examples:
    - Transcript: "hello world this is a test" -> formattedText: "Hello world this is a test."
    - Transcript: "can you send me the latest build status" -> formattedText: "Can you send me the latest build status?"

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
