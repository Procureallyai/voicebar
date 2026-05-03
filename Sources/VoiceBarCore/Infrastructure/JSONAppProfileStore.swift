import Foundation

public actor JSONAppProfileStore: AppProfileStore {
    private let storageURL: URL
    private var cachedProfilesByBundleIdentifier: [String: AppProfile]?
    private var cachedStoredOverridesByBundleIdentifier: [String: AppProfile]?

    public init(
        storageURL: URL = VoiceBarStorageLocation.fileURL(
            named: "app-profiles.json"
        )
    ) {
        self.storageURL = storageURL
    }

    public func loadProfiles() async throws -> [AppProfile] {
        try loadProfileMap()
            .values
            .sorted { $0.bundleIdentifier < $1.bundleIdentifier }
    }

    public func profile(for bundleIdentifier: String?) async -> AppProfile? {
        guard let bundleIdentifier else {
            return nil
        }

        let normalizedBundleIdentifier = normalize(bundleIdentifier)

        if let cachedProfilesByBundleIdentifier {
            return cachedProfilesByBundleIdentifier[normalizedBundleIdentifier]
        }

        do {
            return try loadProfileMap()[normalizedBundleIdentifier]
        } catch {
            return seededProfileMap()[normalizedBundleIdentifier]
        }
    }

    public func upsert(_ profile: AppProfile) async throws {
        var storedOverrides = try loadStoredOverrides()
        let normalizedBundleIdentifier = normalize(profile.bundleIdentifier)
        let defaultsByBundleIdentifier = seededProfileMap()

        // Persist only explicit user-facing deviations so shipped defaults can
        // evolve across upgrades without being frozen on disk after first launch.
        if matchesSeededDefault(
            profile,
            normalizedBundleIdentifier: normalizedBundleIdentifier,
            defaultsByBundleIdentifier: defaultsByBundleIdentifier
        ) {
            storedOverrides.removeValue(forKey: normalizedBundleIdentifier)
        } else {
            storedOverrides[normalizedBundleIdentifier] = profile
        }

        // Persist the sorted override list before updating the hot caches so a
        // failed write cannot leave the current process in a false-success state.
        let persistedProfiles = Array(storedOverrides.values)
            .sorted { $0.bundleIdentifier < $1.bundleIdentifier }

        try persist(persistedProfiles)
        cachedStoredOverridesByBundleIdentifier = storedOverrides
        cachedProfilesByBundleIdentifier = merge(
            defaults: seededProfileMap(),
            overrides: storedOverrides
        )
    }

    private func loadProfileMap() throws -> [String: AppProfile] {
        if let cachedProfilesByBundleIdentifier {
            return cachedProfilesByBundleIdentifier
        }

        let mergedProfiles = merge(
            defaults: seededProfileMap(),
            overrides: try loadStoredOverrides()
        )

        cachedProfilesByBundleIdentifier = mergedProfiles
        return mergedProfiles
    }

    private func merge(
        defaults: [String: AppProfile],
        overrides: [String: AppProfile]
    ) -> [String: AppProfile] {
        var merged = defaults

        for (bundleIdentifier, profile) in overrides {
            merged[bundleIdentifier] = profile
        }

        return merged
    }

    private func loadStoredOverrides() throws -> [String: AppProfile] {
        if let cachedStoredOverridesByBundleIdentifier {
            return cachedStoredOverridesByBundleIdentifier
        }

        let storedProfiles: [AppProfile]

        if FileManager.default.fileExists(atPath: storageURL.path) {
            let data = try Data(contentsOf: storageURL)
            storedProfiles = try JSONDecoder().decode([AppProfile].self, from: data)
        } else {
            storedProfiles = []
            try persist(storedProfiles)
        }

        let defaultsByBundleIdentifier = seededProfileMap()

        // Legacy Prompt 005 builds persisted the full seeded profile list. Drop
        // those copies from the hot override map so future shipped defaults still
        // flow through without forcing a destructive file migration.
        let explicitOverrides = Dictionary(
            storedProfiles.compactMap { profile -> (String, AppProfile)? in
                let normalizedBundleIdentifier = normalize(profile.bundleIdentifier)

                if matchesSeededDefault(
                    profile,
                    normalizedBundleIdentifier: normalizedBundleIdentifier,
                    defaultsByBundleIdentifier: defaultsByBundleIdentifier
                ) {
                    return nil
                }

                return (normalizedBundleIdentifier, profile)
            },
            uniquingKeysWith: { _, newest in newest }
        )

        cachedStoredOverridesByBundleIdentifier = explicitOverrides
        return explicitOverrides
    }

    private func persist(_ profiles: [AppProfile]) throws {
        try VoiceBarStorageLocation.ensureDirectoryExists(for: storageURL)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(profiles)
        try data.write(to: storageURL, options: .atomic)
    }

    private func normalize(_ bundleIdentifier: String) -> String {
        bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func matchesSeededDefault(
        _ profile: AppProfile,
        normalizedBundleIdentifier: String,
        defaultsByBundleIdentifier: [String: AppProfile]
    ) -> Bool {
        guard let defaultProfile = defaultsByBundleIdentifier[normalizedBundleIdentifier] else {
            return false
        }

        // Treat bundle identifiers as case-insensitive and rely on the
        // normalized `NormalizationOptions` equality so default-shape overrides
        // do not get frozen on disk just because their persisted form differs.
        return normalize(defaultProfile.bundleIdentifier) == normalize(profile.bundleIdentifier)
            && defaultProfile.preferredMode == profile.preferredMode
            && defaultProfile.stylePreset == profile.stylePreset
            && defaultProfile.normalizationOptions == profile.normalizationOptions
            && defaultProfile.pacingMultiplier == profile.pacingMultiplier
            && defaultProfile.allowClipboardFallback == profile.allowClipboardFallback
    }

    private func seededProfileMap() -> [String: AppProfile] {
        Dictionary(
            AppProfile.bootstrapDefaults.map {
                (normalize($0.bundleIdentifier), $0)
            },
            uniquingKeysWith: { _, newest in newest }
        )
    }
}
