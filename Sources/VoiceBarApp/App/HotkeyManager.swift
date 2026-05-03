import Carbon
import Foundation
import OSLog

struct HotkeyRegistrationFailure: Equatable, Sendable {
    var action: HotkeyAction
    var status: OSStatus
}

struct HoldToTalkRegistrationFailure: Equatable, Sendable {
    var reason: String
}

struct HoldToTalkRegistrationStatus: Equatable, Sendable {
    var mode: HoldToTalkMode
    var needsRuntimeProof: Bool
    var detail: String
}

extension Notification.Name {
    static let voiceBarEventTapHotkeyTriggered = Notification.Name("voicebar.eventTapHotkeyTriggered")
    static let voiceBarHoldToTalkPressed = Notification.Name("voicebar.holdToTalkPressed")
    static let voiceBarHoldToTalkReleased = Notification.Name("voicebar.holdToTalkReleased")
}

private final class HotkeyEventTapController {
    private static let logger = Logger(
        subsystem: "ai.procureally.voicebar",
        category: "HotkeyEventTapController"
    )
    private static let debounceIntervalSeconds: CFAbsoluteTime = 0.6

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var shortcutsByAction: [HotkeyAction: HotkeyShortcut] = [:]
    private var lastTriggerTimeByAction: [HotkeyAction: CFAbsoluteTime] = [:]

    func updateRegistrations(
        using shortcutsByAction: [HotkeyAction: HotkeyShortcut]
    ) -> Bool {
        self.shortcutsByAction = shortcutsByAction

        guard shortcutsByAction.isEmpty == false else {
            uninstall()
            return true
        }

        guard eventTap != nil else {
            let installed = install()

            if installed {
                Self.logger.info("Installed event-tap hotkeys for Option-only shortcuts.")
            } else {
                Self.logger.warning("Failed to install event-tap hotkeys for Option-only shortcuts.")
            }

            return installed
        }

        CGEvent.tapEnable(tap: eventTap!, enable: true)
        Self.logger.info("Re-enabled event-tap hotkeys for Option-only shortcuts.")
        return true
    }

    func uninstall() {
        if let runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                runLoopSource,
                .commonModes
            )
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }

        runLoopSource = nil
        eventTap = nil
        shortcutsByAction.removeAll()
        lastTriggerTimeByAction.removeAll()
        Self.logger.info("Uninstalled event-tap hotkeys.")
    }

    private func install() -> Bool {
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, type, event, userData in
                // Defensive: validate userData before use to prevent crash
                guard let userData else {
                    return Unmanaged.passUnretained(event)
                }
                let controller = Unmanaged<HotkeyEventTapController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                return controller.handleEvent(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        )

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            runLoopSource,
            .commonModes
        )
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        return true
    }

    private func handleEvent(
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }

            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        // Defensive: validate keyCode is in valid range
        let rawKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard rawKeyCode >= 0 && rawKeyCode <= 127 else {
            return Unmanaged.passUnretained(event)
        }
        let keyCode = UInt32(rawKeyCode)
        let flags = sanitizedFlags(from: event.flags)

        guard
            let action = shortcutsByAction.first(where: { _, shortcut in
                shortcut.keyCode == keyCode &&
                sanitizedFlags(from: shortcut.cgEventFlags) == flags
            })?.key
        else {
            return Unmanaged.passUnretained(event)
        }

        let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        if isAutoRepeat {
            Self.logger.info("Ignored auto-repeat for Option-only hotkey action \(action.rawValue, privacy: .public).")
            return nil
        }

        let now = CFAbsoluteTimeGetCurrent()
        if let lastTriggerTime = lastTriggerTimeByAction[action],
           now - lastTriggerTime < Self.debounceIntervalSeconds
        {
            Self.logger.info("Debounced a rapid repeat for Option-only hotkey action \(action.rawValue, privacy: .public).")
            return nil
        }
        lastTriggerTimeByAction[action] = now

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .voiceBarEventTapHotkeyTriggered,
                object: nil,
                userInfo: ["action": action.rawValue]
            )
        }

        Self.logger.info("Matched Option-only hotkey for action \(action.rawValue, privacy: .public).")

        // Consume Option-letter shortcuts like Option+S before the target app
        // turns them into alternate glyph input such as "ß".
        return nil
    }

    private func sanitizedFlags(from flags: CGEventFlags) -> CGEventFlags {
        flags.intersection([.maskCommand, .maskAlternate, .maskControl, .maskShift])
    }
}

// MARK: - Hold-to-Talk Controller

/// Handles press-and-hold dictation shortcuts through event-tap transitions.
/// Option mode uses normal keyDown/keyUp events; Function key (Fn) mode uses
/// maskSecondaryFn flagsChanged transitions when macOS exposes them.
private final class HoldToTalkController {
    private static let logger = Logger(
        subsystem: "ai.procureally.voicebar",
        category: "HoldToTalkController"
    )

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var configuredShortcut: HotkeyShortcut?
    private var configuredMode: HoldToTalkMode = .optionShortcut
    private var isPressed = false

    func updateRegistration(
        mode: HoldToTalkMode,
        shortcut: HotkeyShortcut?
    ) -> Bool {
        guard mode == .functionKeyExperimental || shortcut?.isEnabled == true else {
            uninstall()
            configuredShortcut = nil
            return true
        }

        if mode == .optionShortcut {
            guard let shortcut, shortcut.requiresEventTapCapture else {
                Self.logger.warning("Hold-to-talk shortcut must use Option-only modifier for event-tap capture.")
                return false
            }
        }

        if configuredMode != mode, eventTap != nil {
            uninstall()
        }

        configuredMode = mode
        configuredShortcut = shortcut

        guard eventTap != nil else {
            let installed = install(for: mode)
            if installed {
                Self.logger.info("Installed hold-to-talk event tap for \(mode.title, privacy: .public).")
            } else {
                Self.logger.warning("Failed to install hold-to-talk event tap for \(mode.title, privacy: .public).")
            }
            return installed
        }

        CGEvent.tapEnable(tap: eventTap!, enable: true)
        Self.logger.info("Re-enabled hold-to-talk event tap for \(mode.title, privacy: .public).")
        return true
    }

    func uninstall() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
        configuredShortcut = nil
        configuredMode = .optionShortcut
        isPressed = false
        Self.logger.info("Uninstalled hold-to-talk event tap.")
    }

    private func install(for mode: HoldToTalkMode) -> Bool {
        let eventMask: Int
        switch mode {
        case .optionShortcut:
            eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        case .functionKeyExperimental:
            // Function key (Fn) has no normal keyCode on many Apple keyboards;
            // the observable shape, when available, is maskSecondaryFn changing.
            eventMask = (1 << CGEventType.flagsChanged.rawValue)
        }

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, type, event, userData in
                // Defensive: validate userData before use to prevent crash.
                guard let userData else {
                    return Unmanaged.passUnretained(event)
                }
                let controller = Unmanaged<HoldToTalkController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                return controller.handleEvent(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        return true
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        switch configuredMode {
        case .optionShortcut:
            return handleOptionShortcutEvent(type: type, event: event)
        case .functionKeyExperimental:
            return handleFunctionKeyEvent(type: type, event: event)
        }
    }

    private func handleFunctionKeyEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .flagsChanged else {
            logFunctionKeyFilterDecision(type: type, event: event, accepted: false)
            return Unmanaged.passUnretained(event)
        }

        let functionKeyIsDown = event.flags.contains(.maskSecondaryFn)

        if functionKeyIsDown, isPressed == false {
            isPressed = true
            logFunctionKeyFilterDecision(type: type, event: event, accepted: true)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .voiceBarHoldToTalkPressed, object: nil)
            }
            Self.logger.info("functionKey.press.detected flagsChanged maskSecondaryFn=true")
            return nil
        }

        if functionKeyIsDown == false, isPressed {
            isPressed = false
            logFunctionKeyFilterDecision(type: type, event: event, accepted: true)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .voiceBarHoldToTalkReleased, object: nil)
            }
            Self.logger.info("functionKey.release.detected flagsChanged maskSecondaryFn=false")
            return nil
        }

        logFunctionKeyFilterDecision(type: type, event: event, accepted: false)
        return Unmanaged.passUnretained(event)
    }

    private func logFunctionKeyFilterDecision(type: CGEventType, event: CGEvent, accepted: Bool) {
        let rawKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let hasSecondaryFunctionFlag = event.flags.contains(.maskSecondaryFn)
        Self.logger.info(
            "functionKey.event.filtered type=\(Self.eventTypeName(type), privacy: .public) keyCode=\(rawKeyCode, privacy: .public) maskSecondaryFn=\(hasSecondaryFunctionFlag, privacy: .public) accepted=\(accepted, privacy: .public)"
        )
    }

    private static func eventTypeName(_ type: CGEventType) -> String {
        switch type {
        case .flagsChanged:
            return "flagsChanged"
        case .keyDown:
            return "keyDown"
        case .keyUp:
            return "keyUp"
        default:
            return "other"
        }
    }

    private func handleOptionShortcutEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        guard let shortcut = configuredShortcut, shortcut.isEnabled else {
            return Unmanaged.passUnretained(event)
        }

        let rawKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard rawKeyCode >= 0 && rawKeyCode <= 127 else {
            return Unmanaged.passUnretained(event)
        }
        let keyCode = UInt32(rawKeyCode)
        let flags = sanitizedFlags(from: event.flags)
        let expectedFlags = sanitizedFlags(from: shortcut.cgEventFlags)

        guard keyCode == shortcut.keyCode else {
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .keyDown:
            guard flags == expectedFlags else {
                return Unmanaged.passUnretained(event)
            }
        case .keyUp:
            guard flags == expectedFlags || isPressed else {
                return Unmanaged.passUnretained(event)
            }
        default:
            return Unmanaged.passUnretained(event)
        }

        let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

        switch type {
        case .keyDown:
            if isAutoRepeat {
                Self.logger.debug("Ignored auto-repeat for hold-to-talk keyDown.")
                return nil
            }

            if isPressed == false {
                isPressed = true
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .voiceBarHoldToTalkPressed, object: nil)
                }
                Self.logger.info("holdToTalk.press")
            }
            return nil

        case .keyUp:
            if isPressed {
                isPressed = false
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .voiceBarHoldToTalkReleased, object: nil)
                }
                Self.logger.info("holdToTalk.release")
            }
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func sanitizedFlags(from flags: CGEventFlags) -> CGEventFlags {
        flags.intersection([.maskCommand, .maskAlternate, .maskControl, .maskShift])
    }
}

@MainActor
final class HotkeyManager {
    private static let logger = Logger(
        subsystem: "ai.procureally.voicebar",
        category: "HotkeyManager"
    )

    private let signature = OSType(0x56424152)
    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [HotkeyAction: EventHotKeyRef] = [:]
    private let eventTapController = HotkeyEventTapController()
    private let holdToTalkController = HoldToTalkController()
    private var eventTapObserver: NSObjectProtocol?
    private var holdToTalkPressObserver: NSObjectProtocol?
    private var holdToTalkReleaseObserver: NSObjectProtocol?

    var onAction: (@MainActor (HotkeyAction) -> Void)?
    var onHoldToTalkPressed: (@MainActor () -> Void)?
    var onHoldToTalkReleased: (@MainActor () -> Void)?

    init() {
        installEventHandlerIfNeeded()
        eventTapObserver = NotificationCenter.default.addObserver(
            forName: .voiceBarEventTapHotkeyTriggered,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let rawValue = notification.userInfo?["action"] as? String,
                let action = HotkeyAction(rawValue: rawValue)
            else {
                return
            }

            Task { @MainActor [weak self] in
                self?.onAction?(action)
            }
        }

        holdToTalkPressObserver = NotificationCenter.default.addObserver(
            forName: .voiceBarHoldToTalkPressed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.onHoldToTalkPressed?()
            }
        }

        holdToTalkReleaseObserver = NotificationCenter.default.addObserver(
            forName: .voiceBarHoldToTalkReleased,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.onHoldToTalkReleased?()
            }
        }
    }

    deinit {
        MainActor.assumeIsolated {
            if let eventHandler {
                RemoveEventHandler(eventHandler)
            }

            for hotKeyRef in hotKeyRefs.values {
                UnregisterEventHotKey(hotKeyRef)
            }

            if let eventTapObserver {
                NotificationCenter.default.removeObserver(eventTapObserver)
            }
            if let holdToTalkPressObserver {
                NotificationCenter.default.removeObserver(holdToTalkPressObserver)
            }
            if let holdToTalkReleaseObserver {
                NotificationCenter.default.removeObserver(holdToTalkReleaseObserver)
            }

            hotKeyRefs.removeAll()
            eventTapController.uninstall()
            holdToTalkController.uninstall()
        }
    }

    func updateRegistrations(
        using preferences: VoiceBarPreferences
    ) -> (
        failures: [HotkeyRegistrationFailure],
        holdToTalkFailure: HoldToTalkRegistrationFailure?,
        holdToTalkStatus: HoldToTalkRegistrationStatus?
    ) {
        unregisterAll()

        guard preferences.hotkeysEnabled else {
            return ([], nil, nil)
        }

        var failures: [HotkeyRegistrationFailure] = []
        var eventTapShortcuts: [HotkeyAction: HotkeyShortcut] = [:]

        for action in HotkeyAction.allCases {
            let shortcut = preferences.shortcut(for: action)

            guard shortcut.isEnabled else {
                continue
            }

            if shortcut.requiresEventTapCapture {
                eventTapShortcuts[action] = shortcut
                continue
            }

            let hotKeyID = EventHotKeyID(
                signature: signature,
                id: action.registrationIdentifier
            )
            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.carbonModifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                // Claim the shortcut exclusively so macOS speech/services do
                // not continue firing alongside the VoiceBar handler when the
                // operator intentionally assigns the same combo here.
                OptionBits(kEventHotKeyExclusive),
                &hotKeyRef
            )

            if status == noErr, let hotKeyRef {
                hotKeyRefs[action] = hotKeyRef
            } else {
                failures.append(
                    HotkeyRegistrationFailure(
                        action: action,
                        status: status
                    )
                )
            }
        }

        if eventTapController.updateRegistrations(using: eventTapShortcuts) == false {
            for action in eventTapShortcuts.keys {
                failures.append(
                    HotkeyRegistrationFailure(
                        action: action,
                        status: OSStatus(paramErr)
                    )
                )
            }
        }

        // Register hold-to-talk shortcut if enabled; surface failure so the
        // caller can update status and diagnostics instead of silently swallowing it.
        var holdToTalkFailure: HoldToTalkRegistrationFailure?
        var holdToTalkStatus: HoldToTalkRegistrationStatus?
        if preferences.holdToTalkEnabled {
            let holdToTalkMode = preferences.holdToTalkMode
            let holdToTalkShortcut = holdToTalkMode == .optionShortcut
                ? preferences.sanitizedHoldToTalkShortcut
                : nil

            if holdToTalkController.updateRegistration(
                mode: holdToTalkMode,
                shortcut: holdToTalkShortcut
            ) == false {
                let reason: String
                switch holdToTalkMode {
                case .optionShortcut:
                    reason = "Hold-to-talk event tap could not be installed. Check that VoiceBar has Accessibility access in System Settings."
                case .functionKeyExperimental:
                    reason = "Function key (Fn) event capture could not be installed. Check that VoiceBar has Accessibility access in System Settings."
                }
                holdToTalkFailure = HoldToTalkRegistrationFailure(reason: reason)
                Self.logger.warning("Hold-to-talk registration failed: \(reason)")
            } else if holdToTalkMode == .functionKeyExperimental {
                holdToTalkStatus = HoldToTalkRegistrationStatus(
                    mode: holdToTalkMode,
                    needsRuntimeProof: true,
                    detail: "Function key (Fn) capture is installed but still needs physical press and release proof on this Mac."
                )
            }
        } else {
            holdToTalkController.uninstall()
        }

        return (failures, holdToTalkFailure, holdToTalkStatus)
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else {
                    return OSStatus(eventNotHandledErr)
                }

                let manager = Unmanaged<HotkeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                return manager.handle(event: event)
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
    }

    private func handle(event: EventRef?) -> OSStatus {
        guard let event else {
            return OSStatus(eventNotHandledErr)
        }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            OSType(kEventParamDirectObject),
            OSType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard
            status == noErr,
            hotKeyID.signature == signature,
            let action = HotkeyAction.from(registrationIdentifier: hotKeyID.id)
        else {
            return status == noErr ? OSStatus(eventNotHandledErr) : status
        }

        onAction?(action)
        return noErr
    }

    private func unregisterAll() {
        for hotKeyRef in hotKeyRefs.values {
            UnregisterEventHotKey(hotKeyRef)
        }

        hotKeyRefs.removeAll()
        eventTapController.uninstall()
        holdToTalkController.uninstall()
    }
}
