import AppKit

final class MenuBarApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = notification
        NSApp.setActivationPolicy(.accessory)
        NSApp.servicesProvider = VoiceBarServiceBridge.shared
        NSUpdateDynamicServices()
    }
}
