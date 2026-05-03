import Foundation

public enum TextHandlingMode: String, Codable, Sendable, CaseIterable {
    case proseFirst
    case readEverything
    case headingsOnly

    public var displayName: String {
        switch self {
        case .proseFirst:
            return "Prose First"
        case .readEverything:
            return "Read Everything"
        case .headingsOnly:
            return "Headings Only"
        }
    }
}

public struct NormalizationOptions: Equatable, Codable, Sendable {
    public var handlingMode: TextHandlingMode
    public var headingsOnly: Bool
    public var skipCodeBlocks: Bool
    public var skipInlineCode: Bool

    public init(
        handlingMode: TextHandlingMode = .proseFirst,
        headingsOnly: Bool = false,
        skipCodeBlocks: Bool = true,
        skipInlineCode: Bool = false
    ) {
        self.handlingMode = headingsOnly ? .headingsOnly : handlingMode
        self.headingsOnly = headingsOnly
        self.skipCodeBlocks = skipCodeBlocks
        self.skipInlineCode = skipInlineCode
    }

    public var resolvedHandlingMode: TextHandlingMode {
        headingsOnly ? .headingsOnly : handlingMode
    }

    public static func == (
        lhs: NormalizationOptions,
        rhs: NormalizationOptions
    ) -> Bool {
        lhs.resolvedHandlingMode == rhs.resolvedHandlingMode
            && lhs.skipCodeBlocks == rhs.skipCodeBlocks
            && lhs.skipInlineCode == rhs.skipInlineCode
    }

    private enum CodingKeys: String, CodingKey {
        case handlingMode
        case headingsOnly
        case skipCodeBlocks
        case skipInlineCode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let headingsOnly = try container.decodeIfPresent(Bool.self, forKey: .headingsOnly) ?? false
        let decodedHandlingMode = try container.decodeIfPresent(
            TextHandlingMode.self,
            forKey: .handlingMode
        ) ?? .proseFirst

        self.handlingMode = headingsOnly ? .headingsOnly : decodedHandlingMode
        self.headingsOnly = headingsOnly
        self.skipCodeBlocks = try container.decodeIfPresent(Bool.self, forKey: .skipCodeBlocks) ?? true
        self.skipInlineCode = try container.decodeIfPresent(Bool.self, forKey: .skipInlineCode) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let resolvedHandlingMode = self.resolvedHandlingMode

        // Canonicalize headings-only payloads so legacy boolean flags and enum
        // construction serialize the same shape for override comparisons.
        try container.encode(resolvedHandlingMode, forKey: .handlingMode)
        try container.encode(
            resolvedHandlingMode == .headingsOnly,
            forKey: .headingsOnly
        )
        try container.encode(skipCodeBlocks, forKey: .skipCodeBlocks)
        try container.encode(skipInlineCode, forKey: .skipInlineCode)
    }
}
