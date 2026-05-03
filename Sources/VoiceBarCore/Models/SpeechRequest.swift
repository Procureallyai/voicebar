import Foundation

public enum SpeechMode: String, Codable, Sendable, CaseIterable {
    case premium = "Premium"
    case quick = "Quick"
    case auto = "Auto"
}

public struct SpeechRequest: Equatable, Codable, Sendable {
    public var text: String
    public var preferredMode: SpeechMode
    public var styleInstruction: String?
    public var voiceIdentifier: String?
    public var bundleIdentifier: String?

    public init(
        text: String,
        preferredMode: SpeechMode,
        styleInstruction: String? = nil,
        voiceIdentifier: String? = nil,
        bundleIdentifier: String? = nil
    ) {
        self.text = text
        self.preferredMode = preferredMode
        self.styleInstruction = styleInstruction
        self.voiceIdentifier = voiceIdentifier
        self.bundleIdentifier = bundleIdentifier
    }
}

public struct SpeechChunk: Equatable, Codable, Sendable {
    public var textFragment: String
    public var sequenceNumber: Int
    public var audioSamples: [Float]
    public var sampleRate: Int?
    public var isParagraphPause: Bool
    public var prebufferLeadDuration: TimeInterval?

    public init(
        textFragment: String,
        sequenceNumber: Int,
        audioSamples: [Float] = [],
        sampleRate: Int? = nil,
        isParagraphPause: Bool = false,
        prebufferLeadDuration: TimeInterval? = nil
    ) {
        self.textFragment = textFragment
        self.sequenceNumber = sequenceNumber
        self.audioSamples = audioSamples
        self.sampleRate = sampleRate
        self.isParagraphPause = isParagraphPause
        self.prebufferLeadDuration = prebufferLeadDuration
    }
}

public struct SpeechEngineAvailability: Equatable, Codable, Sendable {
    public var isAvailable: Bool
    public var reason: String?

    public init(isAvailable: Bool, reason: String? = nil) {
        self.isAvailable = isAvailable
        self.reason = reason
    }
}

public enum SpeechEngineWarmState: String, Codable, Sendable {
    case cold
    case warm
}

public struct SpeechEngineRuntimeSnapshot: Equatable, Codable, Sendable {
    public var identifier: String
    public var warmState: SpeechEngineWarmState
    public var lastFailureDescription: String?

    public init(
        identifier: String,
        warmState: SpeechEngineWarmState,
        lastFailureDescription: String? = nil
    ) {
        self.identifier = identifier
        self.warmState = warmState
        self.lastFailureDescription = lastFailureDescription
    }
}
