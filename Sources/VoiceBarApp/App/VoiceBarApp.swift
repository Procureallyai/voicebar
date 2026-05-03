import AppKit
import SwiftUI

@main
struct VoiceBarApp: App {
    @NSApplicationDelegateAdaptor(MenuBarApplicationDelegate.self) private var appDelegate
    @State private var appState: VoiceBarAppState

    init() {
        let appState = VoiceBarAppState.live()
        _appState = State(initialValue: appState)

        Task { @MainActor in
            await appState.bootstrap()
        }
    }

    var body: some Scene {
        MenuBarExtra("VoiceBar", systemImage: appState.statusIconName) {
            MenuBarContentView(appState: appState)
        }

        Settings {
            SettingsRootView(appState: appState)
                .frame(minWidth: 860, minHeight: 620)
        }
    }
}
