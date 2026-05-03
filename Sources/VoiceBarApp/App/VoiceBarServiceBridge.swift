import AppKit

extension Notification.Name {
    static let voiceBarServiceRequestedRead = Notification.Name("voicebar.serviceRequestedRead")
}

enum VoiceBarServiceBridgeKeys {
    static let text = "text"
    static let bundleIdentifier = "bundleIdentifier"
}

@MainActor
final class VoiceBarServiceBridge: NSObject {
    static let shared = VoiceBarServiceBridge()

    @objc func readWithVoiceBar(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        _ = userData

        guard
            let text = pasteboard.string(forType: .string)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            text.isEmpty == false
        else {
            error.pointee = "VoiceBar can only read non-empty plain text from Services."
            return
        }

        NotificationCenter.default.post(
            name: .voiceBarServiceRequestedRead,
            object: nil,
            userInfo: [
                VoiceBarServiceBridgeKeys.text: text,
                VoiceBarServiceBridgeKeys.bundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier as Any
            ]
        )
    }
}
