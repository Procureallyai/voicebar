import Foundation

public enum DictationTextExpander {
    public static func applySnippets(
        to transcript: String,
        snippets: [DictationSnippet]
    ) -> (text: String, applications: [DictationSnippetApplication]) {
        var expandedText = transcript
        var applications: [DictationSnippetApplication] = []

        // Apply longer trigger phrases first so "procure ally ai" wins before
        // the shorter "procure ally" variant can partially rewrite the text.
        let orderedSnippets = snippets
            .filter(\.enabled)
            .flatMap { snippet in
                snippet.triggers.map { (snippet, $0) }
            }
            .sorted { $0.1.count > $1.1.count }

        let normalizedWholeUtterance = normalizeExactTriggerCandidate(transcript)
        if normalizedWholeUtterance.isEmpty == false {
            for (snippet, trigger) in orderedSnippets {
                // Support Wispr Flow-like behavior where a single trigger phrase
                // spoken as the entire utterance may include trailing punctuation
                // from STT (for example: "live email one.").
                let normalizedTrigger = normalizeExactTriggerCandidate(trigger)
                guard normalizedTrigger.isEmpty == false else {
                    continue
                }

                if normalizedWholeUtterance == normalizedTrigger {
                    return (
                        snippet.expansion,
                        [
                            DictationSnippetApplication(
                                snippetID: snippet.id,
                                trigger: trigger,
                                expansion: snippet.expansion
                            )
                        ]
                    )
                }
            }
        }

        for (snippet, trigger) in orderedSnippets {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: trigger) + "\\b"
            guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let range = NSRange(expandedText.startIndex..., in: expandedText)
            if expression.firstMatch(in: expandedText, range: range) == nil {
                continue
            }

            // Regex replacement templates treat `$1`-style sequences as capture
            // group references, so operator-authored snippet text must be escaped.
            let replacedText = expression.stringByReplacingMatches(
                in: expandedText,
                options: [],
                range: range,
                withTemplate: NSRegularExpression.escapedTemplate(for: snippet.expansion)
            )

            if replacedText != expandedText {
                expandedText = replacedText
                applications.append(
                    DictationSnippetApplication(
                        snippetID: snippet.id,
                        trigger: trigger,
                        expansion: snippet.expansion
                    )
                )
            }
        }

        return (expandedText, applications)
    }

    private static func normalizeExactTriggerCandidate(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: punctuationBoundaryCharacters)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Strip only boundary punctuation so triggers like "g c p" remain intact.
    private static let punctuationBoundaryCharacters = CharacterSet(charactersIn: "\"'`.,;:!?()[]{}")
}

public enum DictationDeterministicFormatter {
    public struct Result: Equatable, Sendable {
        public var text: String
        public var didApplyFormatting: Bool
        public var shouldBypassModel: Bool
        public var statusNote: String?

        public init(
            text: String,
            didApplyFormatting: Bool,
            shouldBypassModel: Bool,
            statusNote: String?
        ) {
            self.text = text
            self.didApplyFormatting = didApplyFormatting
            self.shouldBypassModel = shouldBypassModel
            self.statusNote = statusNote
        }
    }

    private enum ListStyle {
        case bullet
        case numbered
    }

    private static let structuralPhrases = [
        "new line",
        "new paragraph",
        "bullet list",
        "numbered list",
        "sorted numbered list",
        "make this a list",
        "format this as an email",
        "open quote",
        "close quote"
    ]

    private static let spokenPunctuationMap: [(spoken: String, symbol: String)] = [
        ("comma", ","),
        ("colon", ":"),
        ("period", "."),
        ("question mark", "?"),
        ("exclamation mark", "!")
    ]

    private static let trailingSpokenBoundaryPunctuation = CharacterSet(
        charactersIn: "\"'`.,;:!?()[]{}"
    )

    public static func apply(to transcript: String) -> Result {
        let normalizedForMatching = normalizeWhitespace(transcript)
        guard normalizedForMatching.isEmpty == false else {
            return Result(text: transcript, didApplyFormatting: false, shouldBypassModel: false, statusNote: nil)
        }

        var workingText = transcript
        var didApplyFormatting = false
        var appliedRules: [String] = []
        let hasStructuralIntent = containsAnyPhrase(structuralPhrases, in: normalizedForMatching)
        let shouldApplyLineBreakCommands = shouldApplyLineBreakFormatting(in: normalizedForMatching)

        let listResult = formatExplicitListIfRequested(in: workingText)
        if listResult.didApply {
            workingText = listResult.text
            didApplyFormatting = true
            appliedRules.append(listResult.ruleName)
        }

        let emailResult = formatExplicitEmailIfRequested(in: workingText)
        if emailResult.didApply {
            workingText = emailResult.text
            didApplyFormatting = true
            appliedRules.append("email")
        }

        if shouldApplyLineBreakCommands {
            let newParagraphResult = replaceWholePhrase(in: workingText, phrase: "new paragraph", replacement: "\n\n")
            if newParagraphResult.replacementCount > 0 {
                workingText = newParagraphResult.text
                didApplyFormatting = true
                appliedRules.append("new paragraph")
            }

            let newLineResult = replaceWholePhrase(in: workingText, phrase: "new line", replacement: "\n")
            if newLineResult.replacementCount > 0 {
                workingText = newLineResult.text
                didApplyFormatting = true
                appliedRules.append("new line")
            }
        }

        let openQuoteResult = replaceWholePhrase(in: workingText, phrase: "open quote", replacement: "\"")
        if openQuoteResult.replacementCount > 0 {
            workingText = openQuoteResult.text
            didApplyFormatting = true
            appliedRules.append("open quote")
        }

        let closeQuoteResult = replaceWholePhrase(in: workingText, phrase: "close quote", replacement: "\"")
        if closeQuoteResult.replacementCount > 0 {
            workingText = closeQuoteResult.text
            didApplyFormatting = true
            appliedRules.append("close quote")
        }

        let punctuationTokenCount = spokenPunctuationMap.reduce(0) { partialResult, mapping in
            partialResult + countWholePhrase(mapping.spoken, in: normalizedForMatching)
        }
        let shouldApplyPunctuationFormatting = hasStructuralIntent
            || punctuationTokenCount >= 2
            || endsWithSpokenPunctuation(normalizedForMatching)

        if shouldApplyPunctuationFormatting {
            for mapping in spokenPunctuationMap {
                let result = replaceWholePhrase(in: workingText, phrase: mapping.spoken, replacement: mapping.symbol)
                if result.replacementCount > 0 {
                    workingText = result.text
                    didApplyFormatting = true
                    appliedRules.append(mapping.spoken)
                }
            }
        }

        let formattedText = didApplyFormatting ? tidyFormattedText(workingText) : transcript
        let shouldBypassModel = didApplyFormatting
        let statusNote: String?
        if shouldBypassModel {
            let appliedRuleList = appliedRules.joined(separator: ", ")
            statusNote = "Deterministic formatting applied (\(appliedRuleList)). VoiceBar skipped Ollama cleanup for this utterance."
        } else {
            statusNote = nil
        }

        return Result(
            text: formattedText,
            didApplyFormatting: didApplyFormatting,
            shouldBypassModel: shouldBypassModel,
            statusNote: statusNote
        )
    }

    private static func formatExplicitListIfRequested(in text: String) -> (text: String, didApply: Bool, ruleName: String) {
        let normalized = normalizeWhitespace(text)
        guard normalized.isEmpty == false else {
            return (text, false, "")
        }

        let listStyle: ListStyle?
        let shouldSort = containsAnyPhrase(["sorted numbered list", "sorted list"], in: normalized)
        if containsAnyPhrase(["numbered list", "sorted numbered list", "sorted list"], in: normalized) {
            listStyle = .numbered
        } else if containsAnyPhrase(["bullet list", "make this a list"], in: normalized) {
            listStyle = .bullet
        } else {
            listStyle = nil
        }

        guard let listStyle else {
            return (text, false, "")
        }

        let commandStrippedText = removeWholePhrases(
            in: normalized,
            phrases: [
                "this should be a sorted numbered list",
                "make this a sorted numbered list",
                "sorted numbered list",
                "sorted list",
                "write this as a bullet list",
                "format this as a bullet list",
                "bullet list",
                "numbered list",
                "make this a list"
            ],
            replacement: " "
        )
        var listItems = extractEnumeratedItems(from: commandStrippedText)
        if listItems.isEmpty, listStyle == .bullet {
            listItems = extractSimpleListItems(from: commandStrippedText)
        }
        guard listItems.count >= 2 else {
            return (text, false, "")
        }

        if shouldSort {
            listItems.sort {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }
        }

        let renderedList = renderList(listItems, style: listStyle)
        let ruleName = shouldSort && listStyle == .numbered ? "sorted numbered list" : (listStyle == .numbered ? "numbered list" : "bullet list")
        return (renderedList, true, ruleName)
    }

    private static func formatExplicitEmailIfRequested(in text: String) -> (text: String, didApply: Bool) {
        let normalized = normalizeWhitespace(text)
        guard normalized.hasPrefix("format this as an email to ") else {
            return (text, false)
        }

        guard let sayingRange = normalized.range(of: " saying ") else {
            return (text, false)
        }

        let recipient = normalized[..<sayingRange.lowerBound]
            .replacingOccurrences(of: "format this as an email to ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let body = normalized[sayingRange.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard recipient.isEmpty == false, body.isEmpty == false else {
            return (text, false)
        }

        let sentence = body.prefix(1).uppercased() + String(body.dropFirst())
        let punctuatedSentence = sentence.hasSuffix(".") ? sentence : "\(sentence)."
        return ("To: \(recipient)\n\n\(punctuatedSentence)", true)
    }

    private static func extractEnumeratedItems(from text: String) -> [String] {
        guard let expression = try? NSRegularExpression(
            pattern: "\\b(one|two|three|four|five|six|seven|eight|nine|ten)\\b",
            options: [.caseInsensitive]
        ) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = expression.matches(in: text, options: [], range: range)
        guard matches.count >= 2 else {
            return []
        }

        var items: [String] = []
        for (index, match) in matches.enumerated() {
            let itemStartLocation = match.range.location + match.range.length
            let itemEndLocation = index < matches.count - 1
                ? matches[index + 1].range.location
                : range.location + range.length
            let itemRange = NSRange(location: itemStartLocation, length: max(0, itemEndLocation - itemStartLocation))

            guard
                let swiftRange = Range(itemRange, in: text)
            else {
                continue
            }

            let rawItem = String(text[swiftRange])
            let normalizedItem = rawItem
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: ",;:-"))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if normalizedItem.isEmpty == false {
                items.append(normalizedItem)
            }
        }

        return items
    }

    private static func extractSimpleListItems(from text: String) -> [String] {
        normalizeWhitespace(text)
            .components(separatedBy: " ")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ",;:-")) }
            .filter { $0.isEmpty == false }
    }

    private static func renderList(_ items: [String], style: ListStyle) -> String {
        switch style {
        case .bullet:
            return items.map { "- \($0)" }.joined(separator: "\n")
        case .numbered:
            return items.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        }
    }

    private static func replaceWholePhrase(
        in text: String,
        phrase: String,
        replacement: String
    ) -> (text: String, replacementCount: Int) {
        let pattern = "(?<![a-z0-9])" + NSRegularExpression.escapedPattern(for: phrase) + "(?![a-z0-9])"
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return (text, 0)
        }

        let range = NSRange(text.startIndex..., in: text)
        let replacementCount = expression.numberOfMatches(in: text, options: [], range: range)
        guard replacementCount > 0 else {
            return (text, 0)
        }

        let replacedText = expression.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: NSRegularExpression.escapedTemplate(for: replacement)
        )
        return (replacedText, replacementCount)
    }

    private static func countWholePhrase(_ phrase: String, in text: String) -> Int {
        replaceWholePhrase(in: text, phrase: phrase, replacement: phrase).replacementCount
    }

    private static func removeWholePhrases(
        in text: String,
        phrases: [String],
        replacement: String
    ) -> String {
        var workingText = text
        for phrase in phrases {
            workingText = replaceWholePhrase(
                in: workingText,
                phrase: phrase,
                replacement: replacement
            ).text
        }
        return normalizeWhitespace(workingText)
    }

    private static func shouldApplyLineBreakFormatting(in normalizedText: String) -> Bool {
        let newLineCount = countWholePhrase("new line", in: normalizedText)
        let newParagraphCount = countWholePhrase("new paragraph", in: normalizedText)

        // Single occurrences of phrases like "new line" are often natural prose
        // (for example: "a new line of business"), so require stronger intent
        // before converting them into structural line-break commands.
        if newLineCount + newParagraphCount >= 2 {
            return true
        }

        let commandCandidate = normalizedText.trimmingCharacters(
            in: .whitespacesAndNewlines.union(trailingSpokenBoundaryPunctuation)
        )
        if commandCandidate == "new line" || commandCandidate == "new paragraph" {
            return true
        }

        return containsAnyPhrase(
            ["bullet list", "numbered list", "sorted numbered list", "make this a list", "format this as an email", "open quote", "close quote"],
            in: normalizedText
        )
    }

    private static func endsWithSpokenPunctuation(_ text: String) -> Bool {
        let lowered = text.lowercased().trimmingCharacters(
            in: .whitespacesAndNewlines.union(trailingSpokenBoundaryPunctuation)
        )
        return spokenPunctuationMap.contains { lowered.hasSuffix($0.spoken) }
    }

    private static func containsAnyPhrase(_ phrases: [String], in text: String) -> Bool {
        phrases.contains { countWholePhrase($0, in: text) > 0 }
    }

    private static func normalizeWhitespace(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tidyFormattedText(_ text: String) -> String {
        // Collapse horizontal spacing while preserving intentional boundary
        // newlines from utterances like "new line" or "new paragraph".
        let lineNormalized = text
            .replacingOccurrences(of: "[\\t ]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " *\\n *", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)

        return lineNormalized.trimmingCharacters(in: .whitespaces)
    }
}

public enum DictationActionRouter {
    public static func resolveAction(
        transcript: String,
        formatterResponse: DictationFormatterResponse,
        actions: [DictationActionDefinition]
    ) -> ResolvedDictationAction? {
        let enabledActions = actions.filter(\.enabled)
        guard enabledActions.isEmpty == false else {
            return nil
        }

        // Action execution is intentionally anchored to the raw spoken
        // transcript only. Snippet expansions, deterministic formatting output,
        // formatter cleanup, and model-proposed candidates can describe text to
        // insert, but they cannot create action authority.
        let normalizedTranscript = normalize(transcript)
        guard normalizedTranscript.isEmpty == false else {
            return nil
        }

        for action in enabledActions {
            let matchedTrigger = action.triggers.first { trigger in
                normalize(trigger) == normalizedTranscript
            }

            if let matchedTrigger {
                if formatterResponse.detectedMode == .mixed, action.allowMixedMode == false {
                    continue
                }

                return ResolvedDictationAction(
                    definition: action,
                    matchedTrigger: matchedTrigger,
                    candidateConfidence: 1.0
                )
            }
        }

        return nil
    }

    static func normalize(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public actor DictationPipeline {
    private static let formatterFallbackNote = "Formatter fallback: Ollama structured cleanup failed, so VoiceBar inserted the snippet-expanded transcript without model cleanup. Action routing stayed on exact allowlisted trigger matching only."
    private static let plainTextBypassNote = "Plain Text mode: VoiceBar skipped model cleanup and inserted the deterministic snippet-expanded transcript for lowest latency."

    private let formatterService: DictationFormatterService
    private let snippetStore: DictationSnippetStore
    private let actionStore: DictationActionRegistryStore
    private var rollingContext: [String] = []

    public init(
        formatterService: DictationFormatterService,
        snippetStore: DictationSnippetStore,
        actionStore: DictationActionRegistryStore
    ) {
        self.formatterService = formatterService
        self.snippetStore = snippetStore
        self.actionStore = actionStore
    }

    public func processTranscript(
        _ transcript: String,
        formattingMode: DictationFormattingMode,
        formatterModelIdentifier: String,
        frontmostBundleIdentifier: String?
    ) async throws -> DictationPipelineResult {
        let resolvedFormatterModel = formatterService.resolvedModelIdentifier(for: formatterModelIdentifier)
        let snippets = try await snippetStore.loadSnippets()
        let actions = try await actionStore.loadActions()

        let snippetExpansionStartedAt = DispatchTime.now().uptimeNanoseconds
        let snippetExpansion = DictationTextExpander.applySnippets(
            to: transcript,
            snippets: snippets
        )
        let snippetExpansionMilliseconds = elapsedMilliseconds(since: snippetExpansionStartedAt)

        let deterministicFormattingStartedAt = DispatchTime.now().uptimeNanoseconds
        let deterministicResult = DictationDeterministicFormatter.apply(
            to: snippetExpansion.text
        )
        let deterministicFormattingMilliseconds = elapsedMilliseconds(since: deterministicFormattingStartedAt)

        let formattingRequest = DictationFormattingRequest(
            transcript: deterministicResult.text,
            formattingMode: formattingMode,
            formatterModelIdentifier: resolvedFormatterModel,
            frontmostBundleIdentifier: frontmostBundleIdentifier,
            rollingContext: rollingContext,
            appliedSnippets: snippetExpansion.applications
        )

        let formatterResponse: DictationFormatterResponse
        let formatterStatusNote: String?
        let formatterPath: DictationFormatterPath
        let formatterUsedFallback: Bool
        let formatterMilliseconds: Int

        if deterministicResult.shouldBypassModel || formattingMode == .plainText {
            formatterResponse = Self.makeDeterministicFormatterResponse(
                transcript: deterministicResult.text,
                rawTranscript: transcript,
                snippetApplications: snippetExpansion.applications,
                actions: actions
            )
            formatterStatusNote = deterministicResult.statusNote ?? (formattingMode == .plainText ? Self.plainTextBypassNote : nil)
            formatterPath = .deterministicBypass
            formatterUsedFallback = false
            formatterMilliseconds = 0
        } else {
            let formatterStartedAt = DispatchTime.now().uptimeNanoseconds
            do {
                formatterResponse = try await formatterService.format(formattingRequest)
                formatterStatusNote = nil
                formatterPath = .ollama
                formatterUsedFallback = false
                formatterMilliseconds = elapsedMilliseconds(since: formatterStartedAt)
            } catch {
                // Keep local dictation usable even when the structured formatter is
                // too slow on the operator Mac. In fallback mode, only exact
                // allowlisted action phrases can still fire.
                formatterResponse = Self.makeFormatterFallbackResponse(
                    transcript: deterministicResult.text,
                    rawTranscript: transcript,
                    snippetApplications: snippetExpansion.applications,
                    actions: actions
                )
                formatterStatusNote = Self.formatterFallbackNote
                formatterPath = .fallback
                formatterUsedFallback = true
                formatterMilliseconds = elapsedMilliseconds(since: formatterStartedAt)
            }
        }

        let actionRoutingStartedAt = DispatchTime.now().uptimeNanoseconds
        let resolvedAction = DictationActionRouter.resolveAction(
            transcript: transcript,
            formatterResponse: formatterResponse,
            actions: actions
        )
        let actionRoutingMilliseconds = elapsedMilliseconds(since: actionRoutingStartedAt)

        // Shape: an exact raw-transcript action match is command authority.
        // Never also insert formatter text for the same utterance.
        let shouldInsertText = resolvedAction == nil && formatterResponse.shouldInsertText
        let insertionText = shouldInsertText
            ? formatterResponse.formattedText.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""

        let contextEntry = insertionText.isEmpty
            ? formatterResponse.cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            : insertionText

        if contextEntry.isEmpty == false {
            rollingContext.append(contextEntry)
            if rollingContext.count > 3 {
                rollingContext.removeFirst(rollingContext.count - 3)
            }
        }

        // Preserve stage truth: this field is snippet-expansion output only,
        // not post-deterministic formatting text.
        let snippetExpandedTranscript = snippetExpansion.text

        return DictationPipelineResult(
            rawTranscript: transcript,
            snippetExpandedTranscript: snippetExpandedTranscript,
            formatterResponse: formatterResponse,
            resolvedAction: resolvedAction,
            insertionText: insertionText,
            formatterStatusNote: formatterStatusNote,
            formatterModelIdentifier: resolvedFormatterModel,
            formatterPath: formatterPath,
            formatterUsedFallback: formatterUsedFallback,
            latencyBreakdown: DictationPipelineLatencyBreakdown(
                snippetExpansionMilliseconds: snippetExpansionMilliseconds,
                deterministicFormattingMilliseconds: deterministicFormattingMilliseconds,
                formatterMilliseconds: formatterMilliseconds,
                actionRoutingMilliseconds: actionRoutingMilliseconds
            )
        )
    }

    public func currentRollingContext() -> [String] {
        rollingContext
    }

    private static func makeFormatterFallbackResponse(
        transcript: String,
        rawTranscript: String,
        snippetApplications: [DictationSnippetApplication],
        actions: [DictationActionDefinition]
    ) -> DictationFormatterResponse {
        let normalizedTranscript = DictationActionRouter.normalize(rawTranscript)
        let hasExactActionMatch = actions
            .filter(\.enabled)
            .contains { action in
                action.triggers
                    .map(DictationActionRouter.normalize)
                    .contains(normalizedTranscript)
            }

        return DictationFormatterResponse(
            cleanedText: transcript,
            formattedText: hasExactActionMatch ? "" : transcript,
            detectedMode: hasExactActionMatch ? .command : .dictation,
            snippetApplications: snippetApplications,
            actionCandidates: [],
            shouldInsertText: hasExactActionMatch == false,
            confidence: nil
        )
    }

    private static func makeDeterministicFormatterResponse(
        transcript: String,
        rawTranscript: String,
        snippetApplications: [DictationSnippetApplication],
        actions: [DictationActionDefinition]
    ) -> DictationFormatterResponse {
        let normalizedTranscript = DictationActionRouter.normalize(rawTranscript)
        let hasExactActionMatch = actions
            .filter(\.enabled)
            .contains { action in
                action.triggers
                    .map(DictationActionRouter.normalize)
                    .contains(normalizedTranscript)
            }

        return DictationFormatterResponse(
            cleanedText: transcript,
            formattedText: hasExactActionMatch ? "" : transcript,
            detectedMode: hasExactActionMatch ? .command : .dictation,
            snippetApplications: snippetApplications,
            actionCandidates: [],
            shouldInsertText: hasExactActionMatch == false,
            confidence: nil
        )
    }

    private func elapsedMilliseconds(since startNanoseconds: UInt64) -> Int {
        Int((DispatchTime.now().uptimeNanoseconds - startNanoseconds) / 1_000_000)
    }
}
