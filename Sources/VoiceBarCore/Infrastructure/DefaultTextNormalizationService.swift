import Foundation

public struct DefaultTextNormalizationService: TextNormalizationService {
    public init() {}

    public func normalize(
        _ capturedText: CapturedText,
        options: NormalizationOptions,
        profile: AppProfile?
    ) async -> String {
        _ = profile

        let normalizedInput = capturedText.text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let lines = normalizedInput.components(separatedBy: "\n")
        let speakableLines = extractSpeakableLines(
            from: lines,
            options: options
        )

        return joinParagraphs(from: speakableLines)
    }

    private func extractSpeakableLines(
        from lines: [String],
        options: NormalizationOptions
    ) -> [String] {
        let mode = options.resolvedHandlingMode
        let shouldSkipCodeBlocks = options.skipCodeBlocks && mode != .readEverything
        var results: [String] = []
        var isInsideFence = false

        for rawLine in lines {
            let trimmedLine = rawLine.trimmingCharacters(in: .whitespaces)

            if isFenceMarker(trimmedLine) {
                if mode == .readEverything {
                    results.append("")
                }

                isInsideFence.toggle()
                continue
            }

            if trimmedLine.isEmpty {
                results.append("")
                continue
            }

            if isInsideFence, shouldSkipCodeBlocks {
                continue
            }

            if isInsideFence {
                if mode == .headingsOnly {
                    continue
                }

                // Read-everything mode should keep code lines literal instead of
                // reinterpreting them as markdown headings or list items.
                let normalizedCodeLine = normalizeInlineContent(
                    trimmedLine,
                    skipInlineCode: options.skipInlineCode
                )

                if normalizedCodeLine.isEmpty == false {
                    results.append(normalizedCodeLine)
                }

                continue
            }

            if mode == .headingsOnly {
                if let heading = headingContent(for: trimmedLine) {
                    let normalizedHeading = normalizeInlineContent(
                        heading.text,
                        skipInlineCode: options.skipInlineCode
                    )

                    if normalizedHeading.isEmpty == false {
                        results.append("\(heading.label): \(normalizedHeading)")
                        results.append("")
                    }
                }

                continue
            }

            let normalizedLine: String
            let forceParagraphBreakAfter: Bool

            if mode == .readEverything {
                normalizedLine = normalizeInlineContent(
                    trimmedLine,
                    skipInlineCode: options.skipInlineCode
                )
                forceParagraphBreakAfter = false
            } else if let heading = headingContent(for: trimmedLine) {
                normalizedLine = "\(heading.label): \(normalizeInlineContent(heading.text, skipInlineCode: options.skipInlineCode))"
                forceParagraphBreakAfter = true
            } else if let bulletContent = bulletContent(for: trimmedLine) {
                normalizedLine = "Bullet: \(normalizeInlineContent(bulletContent, skipInlineCode: options.skipInlineCode))"
                forceParagraphBreakAfter = true
            } else if let numberedItem = numberedListContent(for: trimmedLine) {
                normalizedLine = "Item \(numberedItem.number): \(normalizeInlineContent(numberedItem.text, skipInlineCode: options.skipInlineCode))"
                forceParagraphBreakAfter = true
            } else {
                normalizedLine = normalizeInlineContent(
                    trimmedLine,
                    skipInlineCode: options.skipInlineCode
                )
                forceParagraphBreakAfter = false
            }

            if normalizedLine.isEmpty {
                continue
            }

            results.append(normalizedLine)

            if forceParagraphBreakAfter {
                results.append("")
            }
        }

        return results
    }

    private func joinParagraphs(from lines: [String]) -> String {
        var paragraphs: [String] = []
        var currentParagraphLines: [String] = []

        for line in lines {
            if line.isEmpty {
                flushParagraph(
                    currentParagraphLines,
                    into: &paragraphs
                )
                currentParagraphLines.removeAll(keepingCapacity: true)
                continue
            }

            currentParagraphLines.append(line)
        }

        flushParagraph(currentParagraphLines, into: &paragraphs)
        return paragraphs.joined(separator: "\n\n")
    }

    private func flushParagraph(
        _ lines: [String],
        into paragraphs: inout [String]
    ) {
        let paragraph = lines.joined(separator: " ")
            .replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if paragraph.isEmpty == false {
            paragraphs.append(paragraph)
        }
    }

    private func normalizeInlineContent(
        _ text: String,
        skipInlineCode: Bool
    ) -> String {
        var output = text

        output = replaceMarkdownLinks(in: output)
        output = replaceInlineCode(
            in: output,
            skipInlineCode: skipInlineCode
        )
        output = replaceMatches(
            in: output,
            pattern: #"(?i)\bhttps?://[^\s)>\]]+"#
        ) { spokenURL(for: $0) }
        output = replaceMatches(
            in: output,
            pattern: #"(?<!\w)(?:~\/|\/|\.{1,2}\/)(?:[A-Za-z0-9._-]+(?: [A-Za-z0-9._-]+)*\/)*[A-Za-z0-9._-]+(?:\.[A-Za-z0-9._-]+)?|(?<![:\w])(?:[A-Za-z0-9._-]+\/)+[A-Za-z0-9._-]+(?:\.[A-Za-z0-9._-]+)?"#
        ) { spokenFilePath(for: $0) }
        output = stripMarkdownDecoration(from: output)
        output = normalizeIdentifiersAndAcronyms(in: output)
        output = softenPunctuationRuns(in: output)
        output = output.replacingOccurrences(
            of: "\\s+([,.;:!?])",
            with: "$1",
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func replaceMarkdownLinks(in text: String) -> String {
        replaceMatches(
            in: text,
            pattern: #"!?\[([^\]]+)\]\(([^)]+)\)"#
        ) { match in
            let fullRange = NSRange(match.startIndex..<match.endIndex, in: match)
            guard
                let regex = try? NSRegularExpression(pattern: #"!?\[([^\]]+)\]\(([^)]+)\)"#),
                let result = regex.firstMatch(in: match, range: fullRange),
                let labelRange = Range(result.range(at: 1), in: match)
            else {
                return match
            }

            return String(match[labelRange])
        }
    }

    private func replaceInlineCode(
        in text: String,
        skipInlineCode: Bool
    ) -> String {
        replaceMatches(
            in: text,
            pattern: #"`([^`]+)`"#
        ) { match in
            let fullRange = NSRange(match.startIndex..<match.endIndex, in: match)
            guard
                let regex = try? NSRegularExpression(pattern: #"`([^`]+)`"#),
                let result = regex.firstMatch(in: match, range: fullRange),
                let codeRange = Range(result.range(at: 1), in: match)
            else {
                return match
            }

            if skipInlineCode {
                return ""
            }

            return String(match[codeRange])
        }
    }

    private func stripMarkdownDecoration(from text: String) -> String {
        var output = text

        output = replaceMatches(
            in: output,
            pattern: #"(?m)^\s{0,3}>\s?"#
        ) { _ in
            ""
        }
        // Require real emphasis boundaries so technical expressions such as
        // `a * b * c` keep their literal operators in read-everything mode.
        output = output.replacingOccurrences(
            of: #"(?<![A-Za-z0-9*])\*\*\*([^\s*](?:[^\n*]*[^\s*])?)\*\*\*(?![A-Za-z0-9*])"#,
            with: "$1",
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: #"(?<![A-Za-z0-9*])\*\*([^\s*](?:[^\n*]*[^\s*])?)\*\*(?![A-Za-z0-9*])"#,
            with: "$1",
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: #"(?<![A-Za-z0-9*])\*([^\s*](?:[^\n*]*[^\s*])?)\*(?![A-Za-z0-9*])"#,
            with: "$1",
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: #"(?<![A-Za-z0-9~])~~([^\s~](?:[^\n~]*[^\s~])?)~~(?![A-Za-z0-9~])"#,
            with: "$1",
            options: .regularExpression
        )
        // Keep underscore-heavy identifiers like `__init__` and `MY__VAR`
        // intact; only strip the single-underscore emphasis form that we can
        // distinguish safely from technical names.
        output = output.replacingOccurrences(
            of: #"(?<![A-Za-z0-9_])_([^_\n]+)_(?![A-Za-z0-9_])"#,
            with: "$1",
            options: .regularExpression
        )
        return output
    }

    private func normalizeIdentifiersAndAcronyms(in text: String) -> String {
        replaceMatches(
            in: text,
            pattern: #"\b[A-Za-z0-9][A-Za-z0-9._-]*\b"#
        ) { token in
            speakableToken(for: token)
        }
    }

    private func softenPunctuationRuns(in text: String) -> String {
        text.replacingOccurrences(
            of: #"([!?.]){2,}"#,
            with: "$1",
            options: .regularExpression
        )
        .replacingOccurrences(
            of: #"(?<![A-Za-z0-9])[-=#`]{2,}(?![A-Za-z0-9])"#,
            with: " ",
            options: .regularExpression
        )
        .replacingOccurrences(
            of: #"(?<![A-Za-z0-9])_{2,}(?![A-Za-z0-9])"#,
            with: " ",
            options: .regularExpression
        )
    }

    private func speakableToken(for token: String) -> String {
        guard token.rangeOfCharacter(from: CharacterSet.letters) != nil else {
            return token
        }

        if token.contains(".") {
            let components = token.split(separator: ".").map(String.init)
            if components.count > 1 {
                return components
                    .map { speakableTokenFragment($0) }
                    .joined(separator: " dot ")
            }
        }

        return speakableTokenFragment(token)
    }

    private func speakableTokenFragment(_ token: String) -> String {
        var fragment = token
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        fragment = fragment.replacingOccurrences(
            of: #"([a-z0-9])([A-Z])"#,
            with: "$1 $2",
            options: .regularExpression
        )
        fragment = fragment.replacingOccurrences(
            of: #"([A-Z]+)([A-Z][a-z])"#,
            with: "$1 $2",
            options: .regularExpression
        )
        fragment = fragment.replacingOccurrences(
            of: #"([A-Za-z])([0-9])"#,
            with: "$1 $2",
            options: .regularExpression
        )
        fragment = fragment.replacingOccurrences(
            of: #"([0-9])([A-Za-z])"#,
            with: "$1 $2",
            options: .regularExpression
        )

        let parts = fragment.split(separator: " ").map(String.init)
        let spokenParts = parts.map { part -> String in
            if shouldSpellOutAcronym(part) {
                return part.map { String($0) }.joined(separator: " ")
            }

            return part
        }

        return spokenParts.joined(separator: " ")
    }

    private func shouldSpellOutAcronym(_ token: String) -> Bool {
        let uppercaseToken = token.uppercased()
        let explicitAcronyms: Set<String> = [
            "AI", "API", "CI", "CSV", "EU", "GPT", "HTML", "HTTP", "HTTPS",
            "ID", "JSON", "PDF", "PR", "SDK", "TTS", "UI", "URL", "UX"
        ]
        let commonUppercaseWordsToKeepLiteral: Set<String> = [
            "AID", "AND", "ARE", "CAN", "FOR", "HAS", "MAY", "NEW", "NOT",
            "OLD", "THE"
        ]

        if explicitAcronyms.contains(uppercaseToken) {
            return true
        }

        // Keep a small stop-word set literal so all-caps prose does not
        // over-trigger the generic acronym fallback.
        if commonUppercaseWordsToKeepLiteral.contains(uppercaseToken) {
            return false
        }

        return token.count >= 3
            && token.count <= 5
            && token == uppercaseToken
            && token.rangeOfCharacter(from: .letters) != nil
    }

    private func spokenURL(for rawURL: String) -> String {
        let sanitizedURL = rawURL.trimmingTrailingSentencePunctuation()

        guard let components = URLComponents(string: sanitizedURL.value) else {
            return rawURL
        }

        // Only trim the conventional leading `www.` host label so domains like
        // `mywww.example.com` still read back honestly.
        let host = {
            let rawHost = components.host ?? sanitizedURL.value
            let hostWithoutLeadingWWW = rawHost.hasPrefix("www.")
                ? String(rawHost.dropFirst(4))
                : rawHost

            return hostWithoutLeadingWWW.replacingOccurrences(of: ".", with: " dot ")
        }()

        let pathComponents = components.path
            .split(separator: "/")
            .map(String.init)
            .prefix(3)
            .map { speakableTokenFragment($0) }

        var parts = [host]

        if pathComponents.isEmpty == false {
            parts.append(pathComponents.joined(separator: " slash "))
        }

        if let query = components.percentEncodedQuery, query.isEmpty == false {
            parts.append("with query parameters")
        }

        return parts.joined(separator: " slash ") + sanitizedURL.trailingPunctuation
    }

    private func spokenFilePath(for rawPath: String) -> String {
        let components = rawPath
            .split(separator: "/")
            .map(String.init)

        guard components.isEmpty == false else {
            return rawPath
        }

        let spokenComponents = components.map { component -> String in
            if component == "~" {
                return "home"
            }

            if component == "." {
                return "current directory"
            }

            if component == ".." {
                return "parent directory"
            }

            return speakableToken(for: component)
        }

        return spokenComponents.joined(separator: " slash ")
    }

    private func replaceMatches(
        in text: String,
        pattern: String,
        transform: (String) -> String
    ) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = expression.matches(in: text, options: [], range: range)

        guard matches.isEmpty == false else {
            return text
        }

        var output = text

        for match in matches.reversed() {
            guard let matchRange = Range(match.range, in: output) else {
                continue
            }

            let original = String(output[matchRange])
            output.replaceSubrange(matchRange, with: transform(original))
        }

        return output
    }

    private func isFenceMarker(_ line: String) -> Bool {
        line.hasPrefix("```") || line.hasPrefix("~~~")
    }

    private func headingContent(for line: String) -> (label: String, text: String)? {
        let hashes = line.prefix { $0 == "#" }
        guard hashes.isEmpty == false else {
            return nil
        }

        let prefixEndIndex = line.index(line.startIndex, offsetBy: hashes.count)
        guard
            prefixEndIndex < line.endIndex,
            line[prefixEndIndex].isWhitespace
        else {
            return nil
        }

        let remainder = line[line.index(after: prefixEndIndex)...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard remainder.isEmpty == false else {
            return nil
        }

        let label: String

        switch hashes.count {
        case 1:
            label = "Title"
        case 2:
            label = "Section"
        default:
            label = "Heading"
        }

        return (label, remainder)
    }

    private func bulletContent(for line: String) -> String? {
        let bulletPrefixes = ["- ", "* ", "+ "]

        for prefix in bulletPrefixes where line.hasPrefix(prefix) {
            return String(line.dropFirst(prefix.count))
        }

        return nil
    }

    private func numberedListContent(for line: String) -> (number: String, text: String)? {
        guard
            let separatorIndex = line.firstIndex(where: { $0 == "." || $0 == ")" }),
            separatorIndex > line.startIndex,
            line[..<separatorIndex].allSatisfy(\.isNumber),
            line.index(after: separatorIndex) < line.endIndex,
            line[line.index(after: separatorIndex)].isWhitespace
        else {
            return nil
        }

        let number = String(line[..<separatorIndex])
        let text = line[line.index(after: separatorIndex)...]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard text.isEmpty == false else {
            return nil
        }

        return (number, text)
    }
}

private extension String {
    func trimmingTrailingSentencePunctuation() -> (value: String, trailingPunctuation: String) {
        let trailingPunctuationCharacters = CharacterSet(
            charactersIn: ".,!?;:"
        )
        var trimmed = self
        var trailingScalars: [Unicode.Scalar] = []

        while
            let lastScalar = trimmed.unicodeScalars.last,
            trailingPunctuationCharacters.contains(lastScalar)
        {
            trailingScalars.append(lastScalar)
            trimmed.unicodeScalars.removeLast()
        }

        return (
            value: trimmed,
            trailingPunctuation: String(String.UnicodeScalarView(trailingScalars.reversed()))
        )
    }
}
