import Foundation
import ServiceManagement

struct LaunchAtLoginStatus: Equatable {
    var isEnabled: Bool
    var canToggle: Bool
    var detail: String

    static let unverifiedBundleRequirement = LaunchAtLoginStatus(
        isEnabled: false,
        canToggle: false,
        detail: "Launch at login needs a real `.app` bundle. This `swift run` launch path cannot validate or toggle it truthfully on this machine."
    )
}

@MainActor
final class LaunchAtLoginManager {
    func currentStatus() -> LaunchAtLoginStatus {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            return .unverifiedBundleRequirement
        }

        let service = SMAppService.mainApp

        switch service.status {
        case .enabled:
            return LaunchAtLoginStatus(
                isEnabled: true,
                canToggle: true,
                detail: "VoiceBar is registered to launch at login."
            )
        case .notRegistered:
            return LaunchAtLoginStatus(
                isEnabled: false,
                canToggle: true,
                detail: "VoiceBar is not registered to launch at login."
            )
        case .requiresApproval:
            return LaunchAtLoginStatus(
                isEnabled: false,
                canToggle: true,
                detail: "macOS still needs you to approve VoiceBar as a login item in System Settings."
            )
        case .notFound:
            return LaunchAtLoginStatus(
                isEnabled: false,
                canToggle: false,
                detail: "macOS could not find the app bundle metadata required for launch-at-login registration."
            )
        @unknown default:
            return LaunchAtLoginStatus(
                isEnabled: false,
                canToggle: false,
                detail: "Unverified: macOS reported an unknown launch-at-login state."
            )
        }
    }

    func setEnabled(_ isEnabled: Bool) throws -> LaunchAtLoginStatus {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            return .unverifiedBundleRequirement
        }

        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }

        return currentStatus()
    }
}
