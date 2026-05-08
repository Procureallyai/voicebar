import Foundation

public enum DictationFormattingMode: String, Codable, Sendable, CaseIterable {
    case automatic = "Automatic"
    case plainText = "Plain Text"
    case email = "Email"
    case bulletList = "Bullet List"
    case notes = "Notes"
}

public enum DictationFormatterQualityMode: String, Codable, Sendable, CaseIterable {
    case fast = "Fast"
    case balanced = "Balanced"
    case quality = "Quality"

    public var timeoutSeconds: TimeInterval {
        switch self {
        case .fast:
            return 2
        case .balanced:
            return 4
        case .quality:
            return 8
        }
    }

    public var operatorSummary: String {
        switch self {
        case .fast:
            return "Fast: shortest formatter timeout, strongest deterministic fallback."
        case .balanced:
            return "Balanced: more time for punctuation, capitalization, and light structure."
        case .quality:
            return "Quality: longest local formatter window for polished writing."
        }
    }
}

public enum DictationDetectedMode: String, Codable, Sendable {
    case dictation
    case command
    case mixed
}

public struct DictationServiceAvailability: Equatable, Codable, Sendable {
    public var isAvailable: Bool
    public var reason: String?

    public init(isAvailable: Bool, reason: String? = nil) {
        self.isAvailable = isAvailable
        self.reason = reason
    }
}

public enum DictationFormatterPath: String, Codable, Sendable {
    case ollama
    case deterministicBypass
    case fallback
}

public struct DictationPipelineLatencyBreakdown: Equatable, Sendable {
    public var snippetExpansionMilliseconds: Int
    public var deterministicFormattingMilliseconds: Int
    public var formatterMilliseconds: Int
    public var actionRoutingMilliseconds: Int

    public init(
        snippetExpansionMilliseconds: Int,
        deterministicFormattingMilliseconds: Int,
        formatterMilliseconds: Int,
        actionRoutingMilliseconds: Int
    ) {
        self.snippetExpansionMilliseconds = snippetExpansionMilliseconds
        self.deterministicFormattingMilliseconds = deterministicFormattingMilliseconds
        self.formatterMilliseconds = formatterMilliseconds
        self.actionRoutingMilliseconds = actionRoutingMilliseconds
    }
}

public struct DictationFormatterWarmUpResult: Equatable, Sendable {
    public var modelIdentifier: String
    public var didSucceed: Bool
    public var elapsedMilliseconds: Int
    public var detail: String

    public init(
        modelIdentifier: String,
        didSucceed: Bool,
        elapsedMilliseconds: Int,
        detail: String
    ) {
        self.modelIdentifier = modelIdentifier
        self.didSucceed = didSucceed
        self.elapsedMilliseconds = elapsedMilliseconds
        self.detail = detail
    }
}

public struct DictationSnippet: Identifiable, Equatable, Codable, Sendable {
    public var id: String
    public var label: String?
    public var triggers: [String]
    public var expansion: String
    public var enabled: Bool
    public var importMetadata: DictationSnippetImportMetadata?

    public init(
        id: String,
        label: String? = nil,
        triggers: [String],
        expansion: String,
        enabled: Bool = true,
        importMetadata: DictationSnippetImportMetadata? = nil
    ) {
        self.id = id
        self.label = label
        self.triggers = triggers
        self.expansion = expansion
        self.enabled = enabled
        self.importMetadata = importMetadata
    }
}

public struct DictationSnippetImportMetadata: Equatable, Codable, Sendable {
    public var sourceApplication: String
    public var sourceIdentifier: String?
    public var sourceKind: String?
    public var category: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var lastUsedAt: String?
    public var frequencyUsed: Int?
    public var observedSource: String?
    public var isStarred: Bool?
    public var importedAt: String?

    public init(
        sourceApplication: String,
        sourceIdentifier: String? = nil,
        sourceKind: String? = nil,
        category: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        lastUsedAt: String? = nil,
        frequencyUsed: Int? = nil,
        observedSource: String? = nil,
        isStarred: Bool? = nil,
        importedAt: String? = nil
    ) {
        self.sourceApplication = sourceApplication
        self.sourceIdentifier = sourceIdentifier
        self.sourceKind = sourceKind
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.frequencyUsed = frequencyUsed
        self.observedSource = observedSource
        self.isStarred = isStarred
        self.importedAt = importedAt
    }
}

public struct DictationSnippetApplication: Equatable, Codable, Sendable {
    public var snippetID: String
    public var trigger: String
    public var expansion: String

    public init(
        snippetID: String,
        trigger: String,
        expansion: String
    ) {
        self.snippetID = snippetID
        self.trigger = trigger
        self.expansion = expansion
    }
}

public struct DictationActionDefinition: Identifiable, Equatable, Codable, Sendable {
    public var id: String
    public var displayName: String
    public var triggers: [String]
    public var scriptPath: String
    public var arguments: [String]
    public var workingDirectory: String?
    public var enabled: Bool
    public var requiresConfirmation: Bool
    public var allowMixedMode: Bool

    public init(
        id: String,
        displayName: String,
        triggers: [String],
        scriptPath: String,
        arguments: [String] = [],
        workingDirectory: String? = nil,
        enabled: Bool = true,
        requiresConfirmation: Bool = true,
        allowMixedMode: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.triggers = triggers
        self.scriptPath = scriptPath
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.enabled = enabled
        self.requiresConfirmation = requiresConfirmation
        self.allowMixedMode = allowMixedMode
    }
}

public struct DictationActionCandidate: Equatable, Codable, Sendable {
    public var actionID: String?
    public var triggerPhrase: String?
    public var confidence: Double?

    public init(
        actionID: String? = nil,
        triggerPhrase: String? = nil,
        confidence: Double? = nil
    ) {
        self.actionID = actionID
        self.triggerPhrase = triggerPhrase
        self.confidence = confidence
    }
}

public struct DictationFormattingRequest: Equatable, Codable, Sendable {
    public var transcript: String
    public var formattingMode: DictationFormattingMode
    public var qualityMode: DictationFormatterQualityMode
    public var formatterModelIdentifier: String
    public var frontmostBundleIdentifier: String?
    public var rollingContext: [String]
    public var appliedSnippets: [DictationSnippetApplication]

    public init(
        transcript: String,
        formattingMode: DictationFormattingMode,
        qualityMode: DictationFormatterQualityMode = .balanced,
        formatterModelIdentifier: String,
        frontmostBundleIdentifier: String?,
        rollingContext: [String],
        appliedSnippets: [DictationSnippetApplication]
    ) {
        self.transcript = transcript
        self.formattingMode = formattingMode
        self.qualityMode = qualityMode
        self.formatterModelIdentifier = formatterModelIdentifier
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.rollingContext = rollingContext
        self.appliedSnippets = appliedSnippets
    }
}

public struct DictationFormatterResponse: Equatable, Codable, Sendable {
    public var cleanedText: String
    public var formattedText: String
    public var detectedMode: DictationDetectedMode
    public var snippetApplications: [DictationSnippetApplication]
    public var actionCandidates: [DictationActionCandidate]
    public var shouldInsertText: Bool
    public var confidence: Double?

    public init(
        cleanedText: String,
        formattedText: String,
        detectedMode: DictationDetectedMode,
        snippetApplications: [DictationSnippetApplication],
        actionCandidates: [DictationActionCandidate],
        shouldInsertText: Bool,
        confidence: Double? = nil
    ) {
        self.cleanedText = cleanedText
        self.formattedText = formattedText
        self.detectedMode = detectedMode
        self.snippetApplications = snippetApplications
        self.actionCandidates = actionCandidates
        self.shouldInsertText = shouldInsertText
        self.confidence = confidence
    }
}

public struct ResolvedDictationAction: Equatable, Sendable {
    public var definition: DictationActionDefinition
    public var matchedTrigger: String
    public var candidateConfidence: Double?

    public init(
        definition: DictationActionDefinition,
        matchedTrigger: String,
        candidateConfidence: Double?
    ) {
        self.definition = definition
        self.matchedTrigger = matchedTrigger
        self.candidateConfidence = candidateConfidence
    }
}

public struct DictationPipelineResult: Equatable, Sendable {
    public var rawTranscript: String
    public var snippetExpandedTranscript: String
    public var formatterResponse: DictationFormatterResponse
    public var resolvedAction: ResolvedDictationAction?
    public var insertionText: String
    public var formatterStatusNote: String?
    public var formatterModelIdentifier: String
    public var formatterPath: DictationFormatterPath
    public var formatterUsedFallback: Bool
    public var latencyBreakdown: DictationPipelineLatencyBreakdown?

    public init(
        rawTranscript: String,
        snippetExpandedTranscript: String,
        formatterResponse: DictationFormatterResponse,
        resolvedAction: ResolvedDictationAction?,
        insertionText: String,
        formatterStatusNote: String? = nil,
        formatterModelIdentifier: String = "",
        formatterPath: DictationFormatterPath = .ollama,
        formatterUsedFallback: Bool = false,
        latencyBreakdown: DictationPipelineLatencyBreakdown? = nil
    ) {
        self.rawTranscript = rawTranscript
        self.snippetExpandedTranscript = snippetExpandedTranscript
        self.formatterResponse = formatterResponse
        self.resolvedAction = resolvedAction
        self.insertionText = insertionText
        self.formatterStatusNote = formatterStatusNote
        self.formatterModelIdentifier = formatterModelIdentifier
        self.formatterPath = formatterPath
        self.formatterUsedFallback = formatterUsedFallback
        self.latencyBreakdown = latencyBreakdown
    }
}

public struct DictationHistoryEntry: Identifiable, Equatable, Codable, Sendable {
    public var id: String
    public var createdAt: Date
    public var rawTranscript: String
    public var formattedText: String
    public var formatterPath: DictationFormatterPath
    public var formatterModelIdentifier: String
    public var frontmostBundleIdentifier: String?
    public var insertionSummary: String
    public var rawTranscriptCharacterCount: Int
    public var formattedCharacterCount: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case rawTranscript
        case formattedText
        case formatterPath
        case formatterModelIdentifier
        case frontmostBundleIdentifier
        case insertionSummary
        case rawTranscriptCharacterCount
        case formattedCharacterCount
    }

    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        rawTranscript: String,
        formattedText: String,
        formatterPath: DictationFormatterPath,
        formatterModelIdentifier: String,
        frontmostBundleIdentifier: String?,
        insertionSummary: String,
        rawTranscriptCharacterCount: Int? = nil,
        formattedCharacterCount: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.rawTranscript = rawTranscript
        self.formattedText = formattedText
        self.formatterPath = formatterPath
        self.formatterModelIdentifier = formatterModelIdentifier
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.insertionSummary = insertionSummary
        self.rawTranscriptCharacterCount = rawTranscriptCharacterCount ?? rawTranscript.count
        self.formattedCharacterCount = formattedCharacterCount ?? formattedText.count
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawTranscript = try container.decode(String.self, forKey: .rawTranscript)
        let formattedText = try container.decode(String.self, forKey: .formattedText)

        id = try container.decode(String.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.rawTranscript = rawTranscript
        self.formattedText = formattedText
        formatterPath = try container.decode(DictationFormatterPath.self, forKey: .formatterPath)
        formatterModelIdentifier = try container.decode(String.self, forKey: .formatterModelIdentifier)
        frontmostBundleIdentifier = try container.decodeIfPresent(String.self, forKey: .frontmostBundleIdentifier)
        insertionSummary = try container.decode(String.self, forKey: .insertionSummary)
        rawTranscriptCharacterCount = try container.decodeIfPresent(
            Int.self,
            forKey: .rawTranscriptCharacterCount
        ) ?? rawTranscript.count
        formattedCharacterCount = try container.decodeIfPresent(
            Int.self,
            forKey: .formattedCharacterCount
        ) ?? formattedText.count
    }
}

public enum DictationRuntimeError: LocalizedError, Equatable, Sendable {
    case runtimeUnavailable(String)
    case microphonePermissionRequired
    case noAudioCaptured
    case transcriptionFailed(String)
    case formattingFailed(String)
    case actionFailed(String)
    case insertionFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .runtimeUnavailable(reason):
            return reason
        case .microphonePermissionRequired:
            return "VoiceBar needs microphone access before it can start local dictation."
        case .noAudioCaptured:
            return "VoiceBar did not capture enough audio to transcribe."
        case let .transcriptionFailed(reason):
            return reason
        case let .formattingFailed(reason):
            return reason
        case let .actionFailed(reason):
            return reason
        case let .insertionFailed(reason):
            return reason
        }
    }
}
