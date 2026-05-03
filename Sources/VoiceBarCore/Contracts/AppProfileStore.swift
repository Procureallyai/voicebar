public protocol AppProfileStore: Sendable {
    func loadProfiles() async throws -> [AppProfile]
    func profile(for bundleIdentifier: String?) async -> AppProfile?
    func upsert(_ profile: AppProfile) async throws
}
