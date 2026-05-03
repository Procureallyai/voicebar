import Carbon.HIToolbox
import CoreGraphics
import Foundation
import VoiceBarCore

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case dictation
    case voicesStyle
    case textHandling
    case perAppProfiles
    case hotkeys
    case diagnostics
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .dictation:
            return "Dictation"
        case .voicesStyle:
            return "Voices & Style"
        case .textHandling:
            return "Text Handling"
        case .perAppProfiles:
            return "Per-App Profiles"
        case .hotkeys:
            return "Hotkeys"
        case .diagnostics:
            return "Diagnostics"
        case .advanced:
            return "Advanced"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            return "gearshape"
        case .dictation:
            return "mic"
        case .voicesStyle:
            return "waveform.and.person.filled"
        case .textHandling:
            return "textformat.alt"
        case .perAppProfiles:
            return "rectangle.stack.person.crop"
        case .hotkeys:
            return "command"
        case .diagnostics:
            return "stethoscope"
        case .advanced:
            return "slider.horizontal.3"
        }
    }
}

enum HotkeyAction: String, CaseIterable, Codable, Identifiable, Sendable {
    case toggleDictation
    case readSelection
    case readClipboard
    case pauseResume
    case stopPlayback
    case replayLast
    case toggleFloatingController

    var id: String { rawValue }

    var title: String {
        switch self {
        case .toggleDictation:
            return "Start / Stop Dictation"
        case .readSelection:
            return "Read Selection"
        case .readClipboard:
            return "Read Clipboard"
        case .pauseResume:
            return "Pause / Resume"
        case .stopPlayback:
            return "Stop"
        case .replayLast:
            return "Replay Last"
        case .toggleFloatingController:
            return "Toggle Controller"
        }
    }

    var registrationIdentifier: UInt32 {
        UInt32(Self.allCases.firstIndex(of: self) ?? 0) + 1
    }

    var defaultShortcut: HotkeyShortcut {
        switch self {
        case .toggleDictation:
            return Self.defaultToggleDictationShortcut
        case .readSelection:
            return HotkeyShortcut(
                keyCode: UInt32(kVK_ANSI_R),
                command: true,
                option: true,
                control: true
            )
        case .readClipboard:
            return HotkeyShortcut(
                keyCode: UInt32(kVK_ANSI_C),
                command: true,
                option: true,
                control: true
            )
        case .pauseResume:
            return HotkeyShortcut(
                keyCode: UInt32(kVK_ANSI_P),
                command: true,
                option: true,
                control: true
            )
        case .stopPlayback:
            return HotkeyShortcut(
                keyCode: UInt32(kVK_ANSI_S),
                command: true,
                option: true,
                control: true
            )
        case .replayLast:
            return HotkeyShortcut(
                keyCode: UInt32(kVK_ANSI_L),
                command: true,
                option: true,
                control: true
            )
        case .toggleFloatingController:
            return HotkeyShortcut(
                keyCode: UInt32(kVK_ANSI_V),
                command: true,
                option: true,
                control: true
            )
        }
    }

    static func from(registrationIdentifier: UInt32) -> HotkeyAction? {
        allCases.first { $0.registrationIdentifier == registrationIdentifier }
    }

    /// A simpler two-key dictation toggle used for V2 validation. The earlier
    /// Control+Option+Command+D chord was too cumbersome for repeated operator tests.
    static let defaultToggleDictationShortcut = HotkeyShortcut(
        keyCode: UInt32(kVK_ANSI_Slash),
        command: false,
        option: true,
        control: false
    )

    static let legacyToggleDictationShortcut = HotkeyShortcut(
        keyCode: UInt32(kVK_ANSI_D),
        command: true,
        option: true,
        control: true
    )
}

struct HotkeyShortcut: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var command: Bool
    var option: Bool
    var control: Bool
    var shift: Bool
    var isEnabled: Bool

    init(
        keyCode: UInt32,
        command: Bool = false,
        option: Bool = false,
        control: Bool = false,
        shift: Bool = false,
        isEnabled: Bool = true
    ) {
        self.keyCode = keyCode
        self.command = command
        self.option = option
        self.control = control
        self.shift = shift
        self.isEnabled = isEnabled
    }

    var carbonModifiers: UInt32 {
        var modifiers: UInt32 = 0

        if command {
            modifiers |= UInt32(cmdKey)
        }

        if option {
            modifiers |= UInt32(optionKey)
        }

        if control {
            modifiers |= UInt32(controlKey)
        }

        if shift {
            modifiers |= UInt32(shiftKey)
        }

        return modifiers
    }

    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []

        if command {
            flags.insert(.maskCommand)
        }

        if option {
            flags.insert(.maskAlternate)
        }

        if control {
            flags.insert(.maskControl)
        }

        if shift {
            flags.insert(.maskShift)
        }

        return flags
    }

    var requiresEventTapCapture: Bool {
        option && command == false && control == false
    }

    var displayString: String {
        if isEnabled == false {
            return "Disabled"
        }

        let modifierGlyphs = [
            control ? "⌃" : nil,
            option ? "⌥" : nil,
            shift ? "⇧" : nil,
            command ? "⌘" : nil
        ]
        .compactMap { $0 }
        .joined()

        return modifierGlyphs + HotkeyCatalog.label(for: keyCode)
    }
}

enum HoldToTalkMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case optionShortcut
    case functionKeyExperimental

    var id: String { rawValue }

    var title: String {
        switch self {
        case .optionShortcut:
            return "Option Shortcut"
        case .functionKeyExperimental:
            return "Function key (Fn) experimental"
        }
    }
}

struct ConfiguredHotkey: Codable, Equatable, Sendable {
    var action: HotkeyAction
    var shortcut: HotkeyShortcut
}

struct HotkeyKeyOption: Identifiable, Hashable {
    var id: UInt32 { keyCode }
    var keyCode: UInt32
    var label: String
}

enum HotkeyCatalog {
    static let options: [HotkeyKeyOption] = [
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_A), label: "A"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_B), label: "B"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_C), label: "C"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_D), label: "D"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_E), label: "E"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_F), label: "F"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_G), label: "G"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_H), label: "H"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_I), label: "I"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_J), label: "J"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_K), label: "K"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_L), label: "L"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_M), label: "M"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_N), label: "N"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_O), label: "O"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_P), label: "P"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Q), label: "Q"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_R), label: "R"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_S), label: "S"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_T), label: "T"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_U), label: "U"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_V), label: "V"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_W), label: "W"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_X), label: "X"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Y), label: "Y"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Z), label: "Z"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_0), label: "0"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_1), label: "1"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_2), label: "2"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_3), label: "3"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_4), label: "4"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_5), label: "5"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_6), label: "6"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_7), label: "7"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_8), label: "8"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_9), label: "9"),
        // Punctuation keys - safer with Option (don't produce special chars like letters)
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Minus), label: "Minus (-)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Equal), label: "Equal (=)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_LeftBracket), label: "Left Bracket ([)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_RightBracket), label: "Right Bracket (])"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Backslash), label: "Backslash (\\)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Semicolon), label: "Semicolon (;)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Quote), label: "Quote (')"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Comma), label: "Comma (,)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Period), label: "Period (.)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Slash), label: "Slash (/)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Grave), label: "Grave (`)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_Space), label: "Space"),
        // F-keys (F13-F20 are safer as they're not used by macOS for system functions)
        HotkeyKeyOption(keyCode: UInt32(kVK_F13), label: "F13"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F14), label: "F14"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F15), label: "F15"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F16), label: "F16"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F17), label: "F17"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F18), label: "F18"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F19), label: "F19"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F1), label: "F1"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F2), label: "F2"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F3), label: "F3"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F4), label: "F4"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F5), label: "F5"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F6), label: "F6"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F7), label: "F7"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F8), label: "F8"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F9), label: "F9"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F10), label: "F10"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F11), label: "F11"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F12), label: "F12")
    ]

    static let holdToTalkOptions: [HotkeyKeyOption] = [
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Period), label: "Period (recommended)"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Comma), label: "Comma"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Slash), label: "Slash"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Semicolon), label: "Semicolon"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Quote), label: "Quote"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Minus), label: "Minus"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_Equal), label: "Equal"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_LeftBracket), label: "Left Bracket"),
        HotkeyKeyOption(keyCode: UInt32(kVK_ANSI_RightBracket), label: "Right Bracket"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F13), label: "F13"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F14), label: "F14"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F15), label: "F15"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F16), label: "F16"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F17), label: "F17"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F18), label: "F18"),
        HotkeyKeyOption(keyCode: UInt32(kVK_F19), label: "F19")
    ]

    static let holdToTalkKeyCodes = Set(holdToTalkOptions.map(\.keyCode))

    static func label(for keyCode: UInt32) -> String {
        options.first { $0.keyCode == keyCode }?.label ?? "Key \(keyCode)"
    }

    static func isAllowedHoldToTalkKey(_ keyCode: UInt32) -> Bool {
        holdToTalkKeyCodes.contains(keyCode)
    }
}

struct VoiceBarPreferences: Codable, Equatable, Sendable {
    var selectedMode: SpeechMode
    var selectedStylePresetName: String
    var customStyleInstruction: String
    var selectedVoiceIdentifier: String
    var formatterModelIdentifier: String
    var dictationFormattingMode: DictationFormattingMode
    var insertDictationAtCursor: Bool
    var autoRunTrustedActions: Bool
    var dictationAudioConfirmationEnabled: Bool
    var copyFallbackEnabled: Bool
    var preloadPremiumEngine: Bool
    var floatingControllerEnabled: Bool
    var hotkeysEnabled: Bool
    var configuredHotkeys: [ConfiguredHotkey]
    var holdToTalkEnabled: Bool
    var holdToTalkMode: HoldToTalkMode
    var holdToTalkShortcut: HotkeyShortcut

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case selectedMode
        case selectedStylePresetName
        case customStyleInstruction
        case selectedVoiceIdentifier
        case formatterModelIdentifier
        case dictationFormattingMode
        case insertDictationAtCursor
        case autoRunTrustedActions
        case dictationAudioConfirmationEnabled
        case copyFallbackEnabled
        case preloadPremiumEngine
        case floatingControllerEnabled
        case hotkeysEnabled
        case configuredHotkeys
        case holdToTalkEnabled
        case holdToTalkMode
        case holdToTalkShortcut
    }

    private static let currentSchemaVersion = 7

    init(
        selectedMode: SpeechMode,
        selectedStylePresetName: String,
        customStyleInstruction: String,
        selectedVoiceIdentifier: String,
        formatterModelIdentifier: String,
        dictationFormattingMode: DictationFormattingMode,
        insertDictationAtCursor: Bool,
        autoRunTrustedActions: Bool,
        dictationAudioConfirmationEnabled: Bool,
        copyFallbackEnabled: Bool,
        preloadPremiumEngine: Bool,
        floatingControllerEnabled: Bool,
        hotkeysEnabled: Bool,
        configuredHotkeys: [ConfiguredHotkey],
        holdToTalkEnabled: Bool,
        holdToTalkMode: HoldToTalkMode,
        holdToTalkShortcut: HotkeyShortcut
    ) {
        self.selectedMode = selectedMode
        self.selectedStylePresetName = selectedStylePresetName
        self.customStyleInstruction = customStyleInstruction
        self.selectedVoiceIdentifier = selectedVoiceIdentifier
        self.formatterModelIdentifier = formatterModelIdentifier
        self.dictationFormattingMode = dictationFormattingMode
        self.insertDictationAtCursor = insertDictationAtCursor
        self.autoRunTrustedActions = autoRunTrustedActions
        self.dictationAudioConfirmationEnabled = dictationAudioConfirmationEnabled
        self.copyFallbackEnabled = copyFallbackEnabled
        self.preloadPremiumEngine = preloadPremiumEngine
        self.floatingControllerEnabled = floatingControllerEnabled
        self.hotkeysEnabled = hotkeysEnabled
        self.configuredHotkeys = Self.normalizedConfiguredHotkeys(from: configuredHotkeys)
        self.holdToTalkEnabled = holdToTalkEnabled
        self.holdToTalkMode = holdToTalkMode
        self.holdToTalkShortcut = holdToTalkShortcut
    }

    static var defaults: VoiceBarPreferences {
        VoiceBarPreferences(
            selectedMode: .quick,
            selectedStylePresetName: SpeechStyleCatalog.defaultPresetName,
            customStyleInstruction: "",
            selectedVoiceIdentifier: SpeechVoiceCatalog.defaultVoiceIdentifier,
            formatterModelIdentifier: OllamaFormatterService.defaultModel,
            dictationFormattingMode: .automatic,
            insertDictationAtCursor: true,
            autoRunTrustedActions: false,
            dictationAudioConfirmationEnabled: false,
            copyFallbackEnabled: false,
            preloadPremiumEngine: false,
            floatingControllerEnabled: true,
            hotkeysEnabled: true,
            configuredHotkeys: HotkeyAction.allCases.map { action in
                ConfiguredHotkey(
                    action: action,
                    shortcut: action.defaultShortcut
                )
            },
            holdToTalkEnabled: false,
            holdToTalkMode: .optionShortcut,
            holdToTalkShortcut: HotkeyShortcut(
                // Changed from Space to Period to avoid common global shortcut conflicts.
                // Punctuation keys do not produce special characters with Option like letters do.
                keyCode: UInt32(kVK_ANSI_Period),
                command: false,
                option: true,
                control: false,
                shift: false
            )
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaults

        // Missing keys in older saved payloads should fall back field-by-field instead of resetting the entire settings blob.
        let schemaVersion = (try? container.decode(Int.self, forKey: .schemaVersion)) ?? 0
        selectedMode = (try? container.decode(SpeechMode.self, forKey: .selectedMode)) ?? defaults.selectedMode
        selectedStylePresetName = (try? container.decode(String.self, forKey: .selectedStylePresetName)) ?? defaults.selectedStylePresetName
        customStyleInstruction = (try? container.decode(String.self, forKey: .customStyleInstruction)) ?? defaults.customStyleInstruction
        selectedVoiceIdentifier = (try? container.decode(String.self, forKey: .selectedVoiceIdentifier)) ?? defaults.selectedVoiceIdentifier
        formatterModelIdentifier = (try? container.decode(String.self, forKey: .formatterModelIdentifier)) ?? defaults.formatterModelIdentifier
        dictationFormattingMode = (try? container.decode(DictationFormattingMode.self, forKey: .dictationFormattingMode)) ?? defaults.dictationFormattingMode
        insertDictationAtCursor = (try? container.decode(Bool.self, forKey: .insertDictationAtCursor)) ?? defaults.insertDictationAtCursor
        autoRunTrustedActions = (try? container.decode(Bool.self, forKey: .autoRunTrustedActions)) ?? defaults.autoRunTrustedActions
        dictationAudioConfirmationEnabled = (try? container.decode(Bool.self, forKey: .dictationAudioConfirmationEnabled)) ?? defaults.dictationAudioConfirmationEnabled
        copyFallbackEnabled = (try? container.decode(Bool.self, forKey: .copyFallbackEnabled)) ?? defaults.copyFallbackEnabled
        preloadPremiumEngine = (try? container.decode(Bool.self, forKey: .preloadPremiumEngine)) ?? defaults.preloadPremiumEngine
        floatingControllerEnabled = (try? container.decode(Bool.self, forKey: .floatingControllerEnabled)) ?? defaults.floatingControllerEnabled
        hotkeysEnabled = (try? container.decode(Bool.self, forKey: .hotkeysEnabled)) ?? defaults.hotkeysEnabled
        configuredHotkeys = Self.normalizedConfiguredHotkeys(
            from: (try? container.decode([ConfiguredHotkey].self, forKey: .configuredHotkeys)) ?? defaults.configuredHotkeys
        )
        if schemaVersion < 6 {
            configuredHotkeys = configuredHotkeys.map { configuredHotkey in
                guard
                    configuredHotkey.action == .toggleDictation,
                    configuredHotkey.shortcut == HotkeyAction.legacyToggleDictationShortcut
                else {
                    return configuredHotkey
                }

                return ConfiguredHotkey(
                    action: configuredHotkey.action,
                    shortcut: HotkeyAction.defaultToggleDictationShortcut
                )
            }
        }
        holdToTalkEnabled = (try? container.decode(Bool.self, forKey: .holdToTalkEnabled)) ?? defaults.holdToTalkEnabled
        holdToTalkMode = (try? container.decode(HoldToTalkMode.self, forKey: .holdToTalkMode)) ?? defaults.holdToTalkMode
        let decodedHoldToTalkShortcut = (try? container.decode(HotkeyShortcut.self, forKey: .holdToTalkShortcut)) ?? defaults.holdToTalkShortcut
        // Sanitize: persisted shortcuts with letters/digits or non-Option-only
        // modifiers can leak characters into focused apps or fail registration.
        holdToTalkShortcut = Self.isValidHoldToTalkShortcut(decodedHoldToTalkShortcut)
            ? decodedHoldToTalkShortcut
            : defaults.holdToTalkShortcut

        // Prevent persisted payloads from assigning the same shortcut to both
        // toggle dictation and hold-to-talk, which creates ambiguous behavior.
        let toggleShortcut = shortcut(for: .toggleDictation)
        if Self.shortcutsConflict(holdToTalkShortcut, toggleShortcut) {
            holdToTalkShortcut = defaults.holdToTalkShortcut
        }

        // Keep the Ryan -> Serena migration pinned to pre-v2 payloads so later
        // schema bumps do not silently overwrite an explicit voice choice.
        if
            schemaVersion < 2,
            selectedVoiceIdentifier == SpeechVoiceCatalog.legacyDefaultVoiceIdentifier
        {
            selectedVoiceIdentifier = SpeechVoiceCatalog.defaultVoiceIdentifier
        }

        if schemaVersion < 3 {
            // Prompt 016 makes Kokoro-backed Quick the truthful primary path on
            // this operator Mac. Migrate earlier Premium/Auto-first defaults
            // forward so older saved payloads stop steering new reads into the
            // broken Qwen-first path by default.
            if selectedMode != .quick {
                selectedMode = .quick
            }

            if preloadPremiumEngine {
                preloadPremiumEngine = false
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentSchemaVersion, forKey: .schemaVersion)
        try container.encode(selectedMode, forKey: .selectedMode)
        try container.encode(selectedStylePresetName, forKey: .selectedStylePresetName)
        try container.encode(customStyleInstruction, forKey: .customStyleInstruction)
        try container.encode(selectedVoiceIdentifier, forKey: .selectedVoiceIdentifier)
        try container.encode(formatterModelIdentifier, forKey: .formatterModelIdentifier)
        try container.encode(dictationFormattingMode, forKey: .dictationFormattingMode)
        try container.encode(insertDictationAtCursor, forKey: .insertDictationAtCursor)
        try container.encode(autoRunTrustedActions, forKey: .autoRunTrustedActions)
        try container.encode(dictationAudioConfirmationEnabled, forKey: .dictationAudioConfirmationEnabled)
        try container.encode(copyFallbackEnabled, forKey: .copyFallbackEnabled)
        try container.encode(preloadPremiumEngine, forKey: .preloadPremiumEngine)
        try container.encode(floatingControllerEnabled, forKey: .floatingControllerEnabled)
        try container.encode(hotkeysEnabled, forKey: .hotkeysEnabled)
        try container.encode(Self.normalizedConfiguredHotkeys(from: configuredHotkeys), forKey: .configuredHotkeys)
        try container.encode(holdToTalkEnabled, forKey: .holdToTalkEnabled)
        try container.encode(holdToTalkMode, forKey: .holdToTalkMode)
        try container.encode(holdToTalkShortcut, forKey: .holdToTalkShortcut)
    }

    /// The default Option+Period shortcut used as a fallback when the persisted
    /// hold-to-talk shortcut is invalid (e.g., uses non-Option-only modifiers).
    /// Period avoids common Option+Space conflicts and Option-letter text input.
    static let defaultHoldToTalkShortcut = HotkeyShortcut(
        keyCode: UInt32(kVK_ANSI_Period),
        command: false,
        option: true,
        control: false,
        shift: false
    )

    /// Returns the hold-to-talk shortcut, sanitized to the Option-only constraint
    /// required for event-tap keyUp capture. If the persisted shortcut is unsafe
    /// (e.g., Option+D producing text input), the default Option+Period is returned.
    var sanitizedHoldToTalkShortcut: HotkeyShortcut {
        guard Self.isValidHoldToTalkShortcut(holdToTalkShortcut) else {
            return Self.defaultHoldToTalkShortcut
        }

        return holdToTalkShortcut
    }

    static func sanitizedHoldToTalkShortcut(_ shortcut: HotkeyShortcut) -> HotkeyShortcut {
        isValidHoldToTalkShortcut(shortcut) ? shortcut : defaultHoldToTalkShortcut
    }

    static func shortcutsConflict(
        _ lhs: HotkeyShortcut,
        _ rhs: HotkeyShortcut
    ) -> Bool {
        guard lhs.isEnabled, rhs.isEnabled else {
            return false
        }

        return lhs.keyCode == rhs.keyCode
            && lhs.command == rhs.command
            && lhs.option == rhs.option
            && lhs.control == rhs.control
            && lhs.shift == rhs.shift
    }

    private static func isValidHoldToTalkShortcut(_ shortcut: HotkeyShortcut) -> Bool {
        shortcut.requiresEventTapCapture
            && shortcut.shift == false
            && HotkeyCatalog.isAllowedHoldToTalkKey(shortcut.keyCode)
    }

    func shortcut(for action: HotkeyAction) -> HotkeyShortcut {
        configuredHotkeys.first { $0.action == action }?.shortcut ?? action.defaultShortcut
    }

    mutating func setShortcut(
        _ shortcut: HotkeyShortcut,
        for action: HotkeyAction
    ) {
        if let index = configuredHotkeys.firstIndex(where: { $0.action == action }) {
            configuredHotkeys[index].shortcut = shortcut
        } else {
            configuredHotkeys.append(
                ConfiguredHotkey(
                    action: action,
                    shortcut: shortcut
                )
            )
        }
    }

    private static func normalizedConfiguredHotkeys(
        from configuredHotkeys: [ConfiguredHotkey]
    ) -> [ConfiguredHotkey] {
        var shortcutsByAction: [HotkeyAction: HotkeyShortcut] = [:]

        for action in HotkeyAction.allCases {
            shortcutsByAction[action] = action.defaultShortcut
        }

        for configuredHotkey in configuredHotkeys {
            shortcutsByAction[configuredHotkey.action] = configuredHotkey.shortcut
        }

        return HotkeyAction.allCases.compactMap { action in
            guard let shortcut = shortcutsByAction[action] else {
                return nil
            }

            return ConfiguredHotkey(
                action: action,
                shortcut: shortcut
            )
        }
    }
}

@MainActor
final class VoiceBarPreferencesStore {
    private static let stableDefaultsDomain = "ai.procureally.voicebar"
    private static let legacyDefaultsDomains = ["VoiceBarApp"]

    private let userDefaults: UserDefaults
    private let legacyUserDefaults: [UserDefaults]
    private let key = "voicebar.preferences"

    init(
        userDefaults: UserDefaults? = nil,
        legacyUserDefaults: [UserDefaults]? = nil
    ) {
        self.userDefaults = userDefaults
            ?? UserDefaults(suiteName: Self.stableDefaultsDomain)
            ?? .standard
        self.legacyUserDefaults = legacyUserDefaults
            ?? Self.legacyDefaultsDomains.compactMap { UserDefaults(suiteName: $0) }
    }

    func load() -> VoiceBarPreferences {
        if let preferences = decodePreferences(from: userDefaults) {
            return preferences
        }

        for legacyDefaults in legacyUserDefaults {
            guard var legacyPreferences = decodePreferences(from: legacyDefaults) else {
                continue
            }

            // The wrapped `.app` bundle is the operator-facing identity, so a
            // one-time migration out of the raw `VoiceBarApp` domain should
            // restore the current Kokoro-first default instead of carrying old
            // Premium/Auto-first behavior forward implicitly.
            if legacyPreferences.selectedMode != .quick {
                legacyPreferences.selectedMode = .quick
            }

            if legacyPreferences.preloadPremiumEngine {
                legacyPreferences.preloadPremiumEngine = false
            }

            save(legacyPreferences)
            return legacyPreferences
        }

        return .defaults
    }

    func save(_ preferences: VoiceBarPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }

    private func decodePreferences(from userDefaults: UserDefaults) -> VoiceBarPreferences? {
        guard
            let data = userDefaults.data(forKey: key),
            let preferences = try? JSONDecoder().decode(
                VoiceBarPreferences.self,
                from: data
            )
        else {
            return nil
        }

        // Persist the normalized schema back once so future reads no longer
        // depend on fallback decode behavior for older payloads.
        if
            let normalizedData = try? JSONEncoder().encode(preferences),
            normalizedData != data
        {
            userDefaults.set(normalizedData, forKey: key)
        }

        return preferences
    }
}
