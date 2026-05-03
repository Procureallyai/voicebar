public protocol PronunciationService: Sendable {
    func applyOverrides(
        to text: String,
        profile: AppProfile?
    ) async -> String
}
