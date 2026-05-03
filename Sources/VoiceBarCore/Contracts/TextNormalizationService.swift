public protocol TextNormalizationService: Sendable {
    func normalize(
        _ capturedText: CapturedText,
        options: NormalizationOptions,
        profile: AppProfile?
    ) async -> String
}
