public struct PassthroughPronunciationService: PronunciationService {
    public init() {}

    public func applyOverrides(
        to text: String,
        profile: AppProfile?
    ) async -> String {
        _ = profile
        return text
    }
}
