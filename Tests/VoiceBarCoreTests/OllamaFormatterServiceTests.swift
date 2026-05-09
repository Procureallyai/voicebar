import XCTest
@testable import VoiceBarCore

final class OllamaFormatterServiceTests: XCTestCase {
    func testDecodeFormatterResponseAcceptsFencedJSON() throws {
        let response = try OllamaFormatterService.decodeFormatterResponse(
            from: envelopeData(
                content: """
                ```json
                {
                  "cleanedText": "hello world",
                  "formattedText": "Hello world.",
                  "detectedMode": "dictation",
                  "snippetApplications": [],
                  "actionCandidates": [],
                  "shouldInsertText": true,
                  "confidence": 0.9
                }
                ```
                """
            )
        )

        XCTAssertEqual(response.formattedText, "Hello world.")
        XCTAssertEqual(response.detectedMode, .dictation)
        XCTAssertTrue(response.shouldInsertText)
    }

    func testDecodeFormatterResponseAcceptsJSONWithSurroundingTextAndLenientDefaults() throws {
        let response = try OllamaFormatterService.decodeFormatterResponse(
            from: envelopeData(
                content: """
                Here is the corrected JSON:
                {
                  "cleaned_text": "can you send the build status",
                  "formatted_text": "Can you send the build status?",
                  "detected_mode": "Dictation",
                  "should_insert_text": "true",
                  "confidence": "0.84"
                }
                """
            )
        )

        XCTAssertEqual(response.cleanedText, "can you send the build status")
        XCTAssertEqual(response.formattedText, "Can you send the build status?")
        XCTAssertEqual(response.detectedMode, .dictation)
        XCTAssertEqual(response.snippetApplications, [])
        XCTAssertEqual(response.actionCandidates, [])
        XCTAssertTrue(response.shouldInsertText)
        XCTAssertEqual(response.confidence, 0.84)
    }

    func testAdaptiveTimeoutExtendsBalancedForLongerDictation() {
        XCTAssertEqual(
            OllamaFormatterService.requestTimeoutSeconds(
                for: .balanced,
                transcriptCharacterCount: 80
            ),
            4
        )
        XCTAssertEqual(
            OllamaFormatterService.requestTimeoutSeconds(
                for: .balanced,
                transcriptCharacterCount: 243
            ),
            6
        )
        XCTAssertEqual(
            OllamaFormatterService.requestTimeoutSeconds(
                for: .quality,
                transcriptCharacterCount: 243
            ),
            10
        )
        XCTAssertEqual(
            OllamaFormatterService.requestTimeoutSeconds(
                for: .fast,
                transcriptCharacterCount: 700
            ),
            2
        )
    }

    private func envelopeData(content: String) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: [
                "message": [
                    "content": content
                ]
            ]
        )
    }
}
