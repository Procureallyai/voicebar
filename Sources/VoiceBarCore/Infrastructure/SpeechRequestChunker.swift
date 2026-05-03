import Foundation
import NaturalLanguage

public struct ChunkedSpeechSegment: Equatable, Sendable {
    public var text: String
    public var pauseAfterMilliseconds: Int

    public init(
        text: String,
        pauseAfterMilliseconds: Int = 0
    ) {
        self.text = text
        self.pauseAfterMilliseconds = pauseAfterMilliseconds
    }
}

public struct SpeechRequestChunker: Sendable {
    private static let clauseOverflowTolerance = 2

    public let paragraphPauseMilliseconds: Int
    public let maximumWordsPerSegment: Int
    public let maximumWordsPerStreamingSegment: Int

    public init(
        paragraphPauseMilliseconds: Int = 320,
        maximumWordsPerSegment: Int = 12,
        maximumWordsPerStreamingSegment: Int = 24
    ) {
        self.paragraphPauseMilliseconds = paragraphPauseMilliseconds
        self.maximumWordsPerSegment = max(4, maximumWordsPerSegment)
        self.maximumWordsPerStreamingSegment = max(
            self.maximumWordsPerSegment,
            maximumWordsPerStreamingSegment
        )
    }

    public func chunk(_ text: String) -> [ChunkedSpeechSegment] {
        let paragraphs = splitParagraphs(in: text)

        guard paragraphs.isEmpty == false else {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedText.isEmpty ? [] : [ChunkedSpeechSegment(text: trimmedText)]
        }

        var segments: [ChunkedSpeechSegment] = []

        for (paragraphIndex, paragraph) in paragraphs.enumerated() {
            let sentences = splitSentences(in: paragraph)

            guard sentences.isEmpty == false else {
                continue
            }

            for (sentenceIndex, sentence) in sentences.enumerated() {
                let isLastSentenceInParagraph = sentenceIndex == sentences.index(before: sentences.endIndex)
                let shouldPauseAfterParagraph = isLastSentenceInParagraph && paragraphIndex < paragraphs.index(before: paragraphs.endIndex)
                let subsegments = splitLongSentence(sentence)

                for (subsegmentIndex, subsegment) in subsegments.enumerated() {
                    let isLastSubsegment = subsegmentIndex == subsegments.index(before: subsegments.endIndex)
                    segments.append(
                        ChunkedSpeechSegment(
                            text: subsegment,
                            pauseAfterMilliseconds: shouldPauseAfterParagraph && isLastSubsegment
                                ? paragraphPauseMilliseconds
                                : 0
                        )
                    )
                }
            }
        }

        return segments
    }

    public func chunkForStreaming(_ text: String) -> [ChunkedSpeechSegment] {
        let baseSegments = chunk(text)
        guard baseSegments.isEmpty == false else {
            return []
        }

        var groupedSegments: [ChunkedSpeechSegment] = []
        var currentTexts: [String] = []
        var currentWordCount = 0

        func flushCurrentGroup(pauseAfterMilliseconds: Int = 0) {
            guard currentTexts.isEmpty == false else {
                return
            }

            groupedSegments.append(
                ChunkedSpeechSegment(
                    text: currentTexts.joined(separator: " "),
                    pauseAfterMilliseconds: pauseAfterMilliseconds
                )
            )
            currentTexts.removeAll(keepingCapacity: true)
            currentWordCount = 0
        }

        for segment in baseSegments {
            let trimmedText = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedText.isEmpty == false else {
                continue
            }

            let segmentWordCount = wordCount(in: trimmedText)
            let wouldOverflowCurrentGroup =
                currentTexts.isEmpty == false
                && currentWordCount + segmentWordCount > maximumWordsPerStreamingSegment

            if wouldOverflowCurrentGroup {
                flushCurrentGroup()
            }

            currentTexts.append(trimmedText)
            currentWordCount += segmentWordCount

            if segment.pauseAfterMilliseconds > 0 {
                flushCurrentGroup(pauseAfterMilliseconds: segment.pauseAfterMilliseconds)
            }
        }

        flushCurrentGroup()
        return groupedSegments
    }

    private func splitParagraphs(in text: String) -> [String] {
        text
            .split(
                separator: "\n",
                omittingEmptySubsequences: false
            )
            .reduce(into: [String]()) { partialResult, line in
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

                if trimmedLine.isEmpty {
                    if partialResult.last?.isEmpty == false {
                        partialResult.append("")
                    }
                    return
                }

                if partialResult.isEmpty || partialResult.last?.isEmpty == true {
                    partialResult.append(String(line))
                } else {
                    partialResult[partialResult.count - 1] += "\n" + line
                }
            }
            .filter { $0.isEmpty == false }
    }

    private func splitSentences(in paragraph: String) -> [String] {
        let trimmedParagraph = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedParagraph.isEmpty == false else {
            return []
        }

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = trimmedParagraph

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: trimmedParagraph.startIndex..<trimmedParagraph.endIndex) { range, _ in
            let sentence = trimmedParagraph[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.isEmpty == false {
                sentences.append(sentence)
            }
            return true
        }

        return sentences.isEmpty ? [trimmedParagraph] : sentences
    }

    private func splitLongSentence(_ sentence: String) -> [String] {
        let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedSentence.isEmpty == false else {
            return []
        }

        guard wordCount(in: trimmedSentence) > maximumWordsPerSegment else {
            return [trimmedSentence]
        }

        let clauseSegments = splitClauses(in: trimmedSentence)
        let candidateSegments = clauseSegments.count > 1 ? clauseSegments : [trimmedSentence]

        let shouldPreserveNaturalClauses = candidateSegments.count > 1

        return candidateSegments.flatMap { candidate in
            let candidateWordCount = wordCount(in: candidate)
            let allowedWordCount = shouldPreserveNaturalClauses
                ? maximumWordsPerSegment + Self.clauseOverflowTolerance
                : maximumWordsPerSegment

            guard candidateWordCount > allowedWordCount else {
                return [candidate]
            }

            return splitAtWordBoundaries(candidate)
        }
    }

    private func splitClauses(in sentence: String) -> [String] {
        var clauses: [String] = []
        var currentClause = ""

        for character in sentence {
            currentClause.append(character)

            guard [",", ";", ":", ")", "]"].contains(character) else {
                continue
            }

            let trimmedClause = currentClause.trimmingCharacters(in: .whitespacesAndNewlines)
            guard wordCount(in: trimmedClause) >= 4 else {
                continue
            }

            clauses.append(trimmedClause)
            currentClause = ""
        }

        let trailingClause = currentClause.trimmingCharacters(in: .whitespacesAndNewlines)
        if trailingClause.isEmpty == false {
            clauses.append(trailingClause)
        }

        return clauses.isEmpty ? [sentence] : clauses
    }

    private func splitAtWordBoundaries(_ sentence: String) -> [String] {
        let words = sentence.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        guard words.count > maximumWordsPerSegment else {
            return [sentence]
        }

        var segments: [String] = []
        var currentWords: [Substring] = []

        for word in words {
            currentWords.append(word)

            if currentWords.count == maximumWordsPerSegment {
                segments.append(currentWords.joined(separator: " "))
                currentWords.removeAll(keepingCapacity: true)
            }
        }

        if currentWords.isEmpty == false {
            segments.append(currentWords.joined(separator: " "))
        }

        return segments
    }

    private func wordCount(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
