import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation

private let accessibilityPromptOptionKey = "AXTrustedCheckOptionPrompt"

public struct ClipboardItemSnapshot: Equatable, Sendable {
    public var typeData: [String: Data]

    public init(typeData: [String: Data]) {
        self.typeData = typeData
    }
}

public struct ClipboardSnapshot: Equatable, Sendable {
    public var items: [ClipboardItemSnapshot]

    public init(items: [ClipboardItemSnapshot]) {
        self.items = items
    }
}

public struct CopyFallbackCaptureResult: Equatable, Sendable {
    public var capturedText: CapturedText
    public var didRestoreClipboard: Bool

    public init(
        capturedText: CapturedText,
        didRestoreClipboard: Bool
    ) {
        self.capturedText = capturedText
        self.didRestoreClipboard = didRestoreClipboard
    }
}

public struct AccessibilityCaptureClient: Sendable {
    public var isTrusted: @Sendable () -> Bool
    public var promptForTrust: @Sendable () -> Bool
    public var selectedText: @Sendable () throws -> String?
    public var performCopyShortcut: @Sendable () throws -> Void
    public var frontmostBundleIdentifier: @Sendable () -> String?

    public init(
        isTrusted: @escaping @Sendable () -> Bool,
        promptForTrust: @escaping @Sendable () -> Bool,
        selectedText: @escaping @Sendable () throws -> String?,
        performCopyShortcut: @escaping @Sendable () throws -> Void,
        frontmostBundleIdentifier: @escaping @Sendable () -> String?
    ) {
        self.isTrusted = isTrusted
        self.promptForTrust = promptForTrust
        self.selectedText = selectedText
        self.performCopyShortcut = performCopyShortcut
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
    }

    public static let live = AccessibilityCaptureClient(
        isTrusted: {
            AXIsProcessTrusted()
        },
        promptForTrust: {
            let options = [accessibilityPromptOptionKey: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        },
        selectedText: {
            try liveSelectedText()
        },
        performCopyShortcut: {
            try livePerformCopyShortcut()
        },
        frontmostBundleIdentifier: {
            NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        }
    )

    private static func liveSelectedText() throws -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(systemWideElement, 0.4)

        guard let focusedElement = try copyElementAttribute(
            kAXFocusedUIElementAttribute,
            from: systemWideElement
        ) else {
            throw TextCaptureError.inaccessibleSelection(
                "VoiceBar could not find a focused UI element to inspect."
            )
        }

        if let directSelection = try copyStringAttribute(
            kAXSelectedTextAttribute,
            from: focusedElement
        ) {
            return normalizedText(directSelection)
        }

        // Some apps only expose the selected range plus the parameterized
        // "string for range" attribute, which keeps us from over-reading an
        // entire document value just to recover the selected substring.
        guard
            let selectedRangeValue = try copySelectedRangeValue(from: focusedElement),
            let rangedSelection = try copyStringForRange(
                selectedRangeValue,
                from: focusedElement
            )
        else {
            return nil
        }

        return normalizedText(rangedSelection)
    }

    private static func copyElementAttribute(
        _ attribute: String,
        from element: AXUIElement
    ) throws -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        switch result {
        case .success:
            return value as! AXUIElement?
        case .attributeUnsupported, .noValue:
            return nil
        case .apiDisabled:
            throw TextCaptureError.accessibilityPermissionRequired
        case .cannotComplete, .notImplemented:
            throw TextCaptureError.inaccessibleSelection(
                "The focused app would not return accessibility data in time."
            )
        default:
            throw TextCaptureError.inaccessibleSelection(
                "Accessibility failed while reading the focused selection (\(result.rawValue))."
            )
        }
    }

    private static func copyStringAttribute(
        _ attribute: String,
        from element: AXUIElement
    ) throws -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        switch result {
        case .success:
            if let stringValue = value as? String {
                return stringValue
            }

            if let attributedValue = value as? NSAttributedString {
                return attributedValue.string
            }

            return nil
        case .attributeUnsupported, .noValue:
            return nil
        case .apiDisabled:
            throw TextCaptureError.accessibilityPermissionRequired
        case .cannotComplete, .notImplemented:
            throw TextCaptureError.inaccessibleSelection(
                "The focused app would not return accessibility data in time."
            )
        default:
            throw TextCaptureError.inaccessibleSelection(
                "Accessibility failed while reading the focused selection (\(result.rawValue))."
            )
        }
    }

    private static func copySelectedRangeValue(from element: AXUIElement) throws -> AXValue? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &value
        )

        switch result {
        case .success:
            guard let value else {
                return nil
            }

            guard CFGetTypeID(value) == AXValueGetTypeID() else {
                return nil
            }

            let axValue = unsafeDowncast(value, to: AXValue.self)

            guard AXValueGetType(axValue) == .cfRange else {
                return nil
            }
            return axValue
        case .attributeUnsupported, .noValue:
            return nil
        case .apiDisabled:
            throw TextCaptureError.accessibilityPermissionRequired
        case .cannotComplete, .notImplemented:
            throw TextCaptureError.inaccessibleSelection(
                "The focused app would not return accessibility data in time."
            )
        default:
            throw TextCaptureError.inaccessibleSelection(
                "Accessibility failed while reading the focused selection (\(result.rawValue))."
            )
        }
    }

    private static func copyStringForRange(
        _ rangeValue: AXValue,
        from element: AXUIElement
    ) throws -> String? {
        var rawValue: CFTypeRef?
        let result = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &rawValue
        )

        switch result {
        case .success:
            if let stringValue = rawValue as? String {
                return stringValue
            }

            if let attributedValue = rawValue as? NSAttributedString {
                return attributedValue.string
            }

            return nil
        case .attributeUnsupported, .noValue:
            return nil
        case .apiDisabled:
            throw TextCaptureError.accessibilityPermissionRequired
        case .cannotComplete, .notImplemented:
            throw TextCaptureError.inaccessibleSelection(
                "The focused app would not return the selected text range in time."
            )
        default:
            throw TextCaptureError.inaccessibleSelection(
                "Accessibility failed while reading the selected range (\(result.rawValue))."
            )
        }
    }

    private static func livePerformCopyShortcut() throws {
        guard
            let eventSource = CGEventSource(stateID: .combinedSessionState),
            let keyDown = CGEvent(
                keyboardEventSource: eventSource,
                virtualKey: CGKeyCode(kVK_ANSI_C),
                keyDown: true
            ),
            let keyUp = CGEvent(
                keyboardEventSource: eventSource,
                virtualKey: CGKeyCode(kVK_ANSI_C),
                keyDown: false
            )
        else {
            throw TextCaptureError.copyFallbackUnavailable(
                "VoiceBar could not synthesize the copy shortcut on this machine."
            )
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private static func normalizedText(_ text: String?) -> String? {
        guard let trimmedText = text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }

        return trimmedText.isEmpty ? nil : trimmedText
    }
}

public struct ClipboardClient: Sendable {
    public var string: @Sendable () -> String?
    public var changeCount: @Sendable () -> Int
    public var snapshot: @Sendable () -> ClipboardSnapshot
    public var restore: @Sendable (ClipboardSnapshot) throws -> Void
    public var waitForChange: @Sendable (_ initialChangeCount: Int, _ timeoutNanoseconds: UInt64) async -> Bool

    public init(
        string: @escaping @Sendable () -> String?,
        changeCount: @escaping @Sendable () -> Int,
        snapshot: @escaping @Sendable () -> ClipboardSnapshot,
        restore: @escaping @Sendable (ClipboardSnapshot) throws -> Void,
        waitForChange: @escaping @Sendable (_ initialChangeCount: Int, _ timeoutNanoseconds: UInt64) async -> Bool
    ) {
        self.string = string
        self.changeCount = changeCount
        self.snapshot = snapshot
        self.restore = restore
        self.waitForChange = waitForChange
    }

    public static let live = ClipboardClient(
        string: {
            NSPasteboard.general.string(forType: .string)
        },
        changeCount: {
            NSPasteboard.general.changeCount
        },
        snapshot: {
            snapshot(of: .general)
        },
        restore: { snapshot in
            try restore(snapshot, to: .general)
        },
        waitForChange: { initialChangeCount, timeoutNanoseconds in
            let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds

            while DispatchTime.now().uptimeNanoseconds < deadline {
                if Task.isCancelled {
                    return false
                }

                if NSPasteboard.general.changeCount != initialChangeCount {
                    return true
                }

                do {
                    try await Task.sleep(nanoseconds: 50_000_000)
                } catch {
                    return false
                }
            }

            return NSPasteboard.general.changeCount != initialChangeCount
        }
    )

    private static func snapshot(of pasteboard: NSPasteboard) -> ClipboardSnapshot {
        // NSPasteboardItem lets us preserve concrete representations rather than
        // silently flattening rich clipboard entries down to just one string.
        let items: [ClipboardItemSnapshot] = pasteboard.pasteboardItems?.map { item in
            let typeData = item.types.reduce(into: [String: Data]()) { partialResult, type in
                if let data = item.data(forType: type) {
                    partialResult[type.rawValue] = data
                }
            }

            return ClipboardItemSnapshot(typeData: typeData)
        } ?? []

        return ClipboardSnapshot(items: items)
    }

    private static func restore(
        _ snapshot: ClipboardSnapshot,
        to pasteboard: NSPasteboard
    ) throws {
        pasteboard.clearContents()

        guard snapshot.items.isEmpty == false else {
            return
        }

        let restoredItems = snapshot.items.map { snapshotItem -> NSPasteboardItem in
            let item = NSPasteboardItem()

            for (typeIdentifier, data) in snapshotItem.typeData {
                item.setData(data, forType: NSPasteboard.PasteboardType(typeIdentifier))
            }

            return item
        }

        let didRestore = pasteboard.writeObjects(restoredItems)
        guard didRestore else {
            throw TextCaptureError.copyFallbackUnavailable(
                "VoiceBar captured the selection, but could not restore the prior clipboard contents safely."
            )
        }
    }
}

public actor LiveTextCaptureService: TextCaptureService {
    private let accessibilityClient: AccessibilityCaptureClient
    private let clipboardClient: ClipboardClient

    public init(
        accessibilityClient: AccessibilityCaptureClient = .live,
        clipboardClient: ClipboardClient = .live
    ) {
        self.accessibilityClient = accessibilityClient
        self.clipboardClient = clipboardClient
    }

    public func captureSelection() async throws -> CapturedText {
        try captureSelectionOnce()
    }

    public func captureSelection(
        retryCount: Int,
        retryDelayNanoseconds: UInt64
    ) async throws -> CapturedText {
        // Treat retryCount as retries-after-the-first-attempt so callers can
        // request "try once, then retry N more times" without off-by-one math.
        let attemptCount = max(1, retryCount + 1)
        var lastError: Error?

        for attemptIndex in 0..<attemptCount {
            do {
                return try captureSelectionOnce()
            } catch {
                lastError = error

                let shouldRetry = switch error {
                case TextCaptureError.noSelectedText,
                    TextCaptureError.inaccessibleSelection:
                    true
                default:
                    false
                }

                guard shouldRetry, attemptIndex < attemptCount - 1 else {
                    throw error
                }

                if retryDelayNanoseconds > 0 {
                    try? await Task.sleep(nanoseconds: retryDelayNanoseconds)
                }
            }
        }

        throw lastError ?? TextCaptureError.noSelectedText
    }

    private func captureSelectionOnce() throws -> CapturedText {
        guard accessibilityClient.isTrusted() else {
            throw TextCaptureError.accessibilityPermissionRequired
        }

        guard let selectedText = try accessibilityClient.selectedText() else {
            throw TextCaptureError.noSelectedText
        }

        return CapturedText(
            text: selectedText,
            source: .accessibility,
            frontmostBundleIdentifier: accessibilityClient.frontmostBundleIdentifier()
        )
    }

    public func captureClipboard() async throws -> CapturedText {
        guard
            let clipboardText = clipboardClient.string()?.trimmingCharacters(in: .whitespacesAndNewlines),
            clipboardText.isEmpty == false
        else {
            throw TextCaptureError.clipboardEmpty
        }

        return CapturedText(
            text: clipboardText,
            source: .clipboard,
            frontmostBundleIdentifier: accessibilityClient.frontmostBundleIdentifier()
        )
    }

    public func isAccessibilityTrusted() -> Bool {
        accessibilityClient.isTrusted()
    }

    @discardableResult
    public func promptForAccessibilityTrust() -> Bool {
        accessibilityClient.promptForTrust()
    }

    public func frontmostBundleIdentifier() -> String? {
        accessibilityClient.frontmostBundleIdentifier()
    }

    public func captureSelectionUsingCopyFallback() async throws -> CopyFallbackCaptureResult {
        guard accessibilityClient.isTrusted() else {
            throw TextCaptureError.accessibilityPermissionRequired
        }

        let snapshot = clipboardClient.snapshot()
        let initialChangeCount = clipboardClient.changeCount()

        try accessibilityClient.performCopyShortcut()

        let didObserveChange = await clipboardClient.waitForChange(
            initialChangeCount,
            800_000_000
        )

        guard didObserveChange else {
            try throwCopyFallbackFailure(
                "VoiceBar tried Command-C, but the clipboard did not change in time.",
                restoring: snapshot
            )
        }

        // Capture the pasteboard version that produced the copied string so we
        // can fail closed if another app mutates the clipboard before restore.
        let changeCountAfterObservedCopy = clipboardClient.changeCount()

        guard
            let copiedText = clipboardClient.string()?.trimmingCharacters(in: .whitespacesAndNewlines),
            copiedText.isEmpty == false
        else {
            try throwCopyFallbackFailure(
                "VoiceBar tried Command-C, but the copied selection did not produce plain text.",
                restoring: snapshot
            )
        }

        guard clipboardClient.changeCount() == changeCountAfterObservedCopy else {
            throw TextCaptureError.copyFallbackUnavailable(
                "VoiceBar saw another clipboard change before it could trust the copied selection, so copy fallback was skipped."
            )
        }

        let didRestoreClipboard: Bool

        do {
            try clipboardClient.restore(snapshot)
            didRestoreClipboard = true
        } catch {
            didRestoreClipboard = false
        }

        return CopyFallbackCaptureResult(
            capturedText: CapturedText(
                text: copiedText,
                source: .copyFallback,
                frontmostBundleIdentifier: accessibilityClient.frontmostBundleIdentifier()
            ),
            didRestoreClipboard: didRestoreClipboard
        )
    }

    private func throwCopyFallbackFailure(
        _ message: String,
        restoring snapshot: ClipboardSnapshot
    ) throws -> Never {
        var composedMessage = message

        do {
            try clipboardClient.restore(snapshot)
        } catch {
            composedMessage += " VoiceBar also could not restore the prior clipboard contents safely: \(describe(error))."
        }

        throw TextCaptureError.copyFallbackUnavailable(composedMessage)
    }

    private func describe(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return error.localizedDescription
    }
}
