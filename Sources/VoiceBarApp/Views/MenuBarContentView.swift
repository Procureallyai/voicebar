import AppKit
import SwiftUI
import VoiceBarCore

struct MenuBarContentView: View {
    @Environment(\.openSettings) private var openSettings
    @Bindable var appState: VoiceBarAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("VoiceBar", systemImage: appState.statusIconName)
                    .font(.headline)
                Text("\(appState.playbackState.status.rawValue.capitalized) · \(appState.currentVoiceSummary)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button(dictationMenuTitle) {
                Task {
                    await appState.toggleDictation()
                }
            }
            .disabled(appState.isDictationProcessing)

            Button("Read Selection") {
                Task {
                    await appState.readSelection()
                }
            }

            Button("Read Clipboard") {
                Task {
                    await appState.readClipboard()
                }
            }

            Divider()

            Button("Copy Last Dictation") {
                appState.copyLastDictationToClipboard()
            }
            .disabled(appState.canCopyLastDictation == false)

            Button("Retry Insert Last Dictation") {
                Task {
                    await appState.retryInsertLastDictation()
                }
            }
            .disabled(appState.canRetryLastDictation == false)

            Button("Show Recent Dictations") {
                appState.selectSettingsTab(.dictation)
                openSettings()
            }

            Divider()

            Button(appState.pauseResumeTitle) {
                Task {
                    await appState.pauseOrResume()
                }
            }
            .disabled(appState.canPauseOrResume == false)

            Button("Stop") {
                Task {
                    await appState.stopPlayback()
                }
            }
            .disabled(appState.canStop == false)

            Button("Replay Last") {
                Task {
                    await appState.replayLast()
                }
            }
            .disabled(appState.canReplayLast == false)

            Divider()

            Menu("Engine") {
                ForEach(SpeechMode.allCases, id: \.self) { mode in
                    Button {
                        appState.selectMode(mode)
                    } label: {
                        if appState.preferences.selectedMode == mode {
                            Label(mode.rawValue, systemImage: "checkmark")
                        } else {
                            Text(mode.rawValue)
                        }
                    }
                }
            }

            Menu("Style Preset") {
                ForEach(appState.availableStylePresets) { preset in
                    Button {
                        appState.selectStylePreset(preset.name)
                    } label: {
                        if appState.currentStylePresetName == preset.name {
                            Label(preset.name, systemImage: "checkmark")
                        } else {
                            Text(preset.name)
                        }
                    }
                }
            }

            Menu("Voice") {
                ForEach(appState.availableVoices) { voice in
                    Button {
                        appState.selectVoice(identifier: voice.id)
                    } label: {
                        if appState.preferences.selectedVoiceIdentifier == voice.id {
                            Label("\(voice.displayName) · \(voice.nativeLanguage)", systemImage: "checkmark")
                        } else {
                            Text("\(voice.displayName) · \(voice.nativeLanguage)")
                        }
                    }
                }
            }

            Divider()

            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { appState.launchAtLoginStatus.isEnabled },
                    set: { appState.setLaunchAtLoginEnabled($0) }
                )
            )
            .disabled(appState.launchAtLoginStatus.canToggle == false)

            Button(appState.floatingControllerMenuTitle) {
                appState.toggleFloatingControllerVisibility()
            }

            Button("Open Diagnostics") {
                appState.selectSettingsTab(.diagnostics)
                openSettings()
            }

            Button("Open Settings") {
                appState.selectSettingsTab(.general)
                openSettings()
            }

            Button("Open Accessibility Settings") {
                appState.openAccessibilitySettings()
            }

            Button("Reveal VoiceBar in Finder") {
                appState.revealInstalledAppInFinder()
            }

            Button("Relaunch VoiceBar") {
                appState.relaunchInstalledApp()
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }

            Divider()

            Text(appState.accessibilitySummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(appState.launchAtLoginStatus.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(appState.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(appState.dictationStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 340)
    }

    private var dictationMenuTitle: String {
        if appState.isDictationRecording {
            return "Stop Dictation"
        }

        if appState.isDictationProcessing {
            return "Transcribing Dictation..."
        }

        return "Start Dictation"
    }
}
