import XCTest
@testable import VoiceBarApp

final class VoiceBarPreferencesTests: XCTestCase {
    func testDictationFormatterQualityModeRoundTripsThroughJSON() throws {
        var preferences = VoiceBarPreferences.defaults
        preferences.dictationFormatterQualityMode = .quality

        let encoded = try JSONEncoder().encode(preferences)
        let decoded = try JSONDecoder().decode(VoiceBarPreferences.self, from: encoded)

        XCTAssertEqual(decoded.dictationFormatterQualityMode, .quality)
    }

    func testDictationFormatterQualityModeDefaultsForLegacyPayload() throws {
        let encodedDefaults = try JSONEncoder().encode(VoiceBarPreferences.defaults)
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encodedDefaults) as? [String: Any]
        )

        payload["schemaVersion"] = 7
        payload.removeValue(forKey: "dictationFormatterQualityMode")

        let legacyPayload = try JSONSerialization.data(
            withJSONObject: payload,
            options: [.sortedKeys]
        )
        let decoded = try JSONDecoder().decode(VoiceBarPreferences.self, from: legacyPayload)

        XCTAssertEqual(decoded.dictationFormatterQualityMode, .balanced)
    }

    func testDictationHistoryRecoveryDefaultsAreEnabled() {
        let preferences = VoiceBarPreferences.defaults

        XCTAssertTrue(preferences.saveRecentDictationsForRecovery)
        XCTAssertEqual(
            preferences.dictationHistoryRetentionLimit,
            VoiceBarPreferences.defaultDictationHistoryRetentionLimit
        )
    }

    func testDictationHistoryRecoveryDefaultsForLegacyPayload() throws {
        let encodedDefaults = try JSONEncoder().encode(VoiceBarPreferences.defaults)
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encodedDefaults) as? [String: Any]
        )

        payload["schemaVersion"] = 8
        payload.removeValue(forKey: "saveRecentDictationsForRecovery")
        payload.removeValue(forKey: "dictationHistoryRetentionLimit")

        let legacyPayload = try JSONSerialization.data(
            withJSONObject: payload,
            options: [.sortedKeys]
        )
        let decoded = try JSONDecoder().decode(VoiceBarPreferences.self, from: legacyPayload)

        XCTAssertTrue(decoded.saveRecentDictationsForRecovery)
        XCTAssertEqual(
            decoded.dictationHistoryRetentionLimit,
            VoiceBarPreferences.defaultDictationHistoryRetentionLimit
        )
    }

    func testDictationHistoryRetentionLimitIsClamped() throws {
        let encodedDefaults = try JSONEncoder().encode(VoiceBarPreferences.defaults)
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encodedDefaults) as? [String: Any]
        )

        payload["dictationHistoryRetentionLimit"] = 999

        let oversizedPayload = try JSONSerialization.data(
            withJSONObject: payload,
            options: [.sortedKeys]
        )
        let decoded = try JSONDecoder().decode(VoiceBarPreferences.self, from: oversizedPayload)

        XCTAssertEqual(
            decoded.dictationHistoryRetentionLimit,
            VoiceBarPreferences.maximumDictationHistoryRetentionLimit
        )
    }
}
