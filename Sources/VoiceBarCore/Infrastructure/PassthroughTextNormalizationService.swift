public struct PassthroughTextNormalizationService: TextNormalizationService {
    public init() {}

    public func normalize(
        _ capturedText: CapturedText,
        options: NormalizationOptions,
        profile: AppProfile?
    ) async -> String {
        _ = options
        _ = profile
        return capturedText.text
    }
}
