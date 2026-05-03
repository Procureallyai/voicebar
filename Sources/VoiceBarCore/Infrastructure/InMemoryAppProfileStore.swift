public actor InMemoryAppProfileStore: AppProfileStore {
    private var profilesByBundleIdentifier: [String: AppProfile]

    public init(seedProfiles: [AppProfile] = AppProfile.bootstrapDefaults) {
        self.profilesByBundleIdentifier = Dictionary(
            seedProfiles.map { (Self.normalize($0.bundleIdentifier), $0) },
            uniquingKeysWith: { _, newest in newest }
        )
    }

    public func loadProfiles() async throws -> [AppProfile] {
        profilesByBundleIdentifier.values.sorted { $0.bundleIdentifier < $1.bundleIdentifier }
    }

    public func profile(for bundleIdentifier: String?) async -> AppProfile? {
        guard let bundleIdentifier else {
            return nil
        }

        return profilesByBundleIdentifier[Self.normalize(bundleIdentifier)]
    }

    public func upsert(_ profile: AppProfile) async throws {
        profilesByBundleIdentifier[Self.normalize(profile.bundleIdentifier)] = profile
    }

    private static func normalize(_ bundleIdentifier: String) -> String {
        bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
