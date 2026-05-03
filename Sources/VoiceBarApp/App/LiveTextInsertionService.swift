import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation
import VoiceBarCore

struct TextInsertionResult: Sendable {
    var didRestoreClipboard: Bool
    var copiedToClipboardOnly: Bool
}

@MainActor
final class LiveTextInsertionService {
    func canInsertAtCursor() -> Bool {
        AXIsProcessTrusted()
    }

    func copyToClipboard(_ text: String) throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else {
            throw DictationRuntimeError.insertionFailed(
                "VoiceBar could not copy an empty dictation result."
            )
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard pasteboard.setString(trimmedText, forType: .string) else {
            throw DictationRuntimeError.insertionFailed(
                "VoiceBar could not place the dictation result on the clipboard."
            )
        }
    }

    func insertAtCursor(_ text: String) async throws -> TextInsertionResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else {
            throw DictationRuntimeError.insertionFailed(
                "VoiceBar could not insert an empty dictation result."
            )
        }

        guard canInsertAtCursor() else {
            throw DictationRuntimeError.insertionFailed(
                "Insert-at-cursor needs Accessibility access for VoiceBar."
            )
        }

        let pasteboard = NSPasteboard.general
        let snapshot = snapshot(of: pasteboard)

        try copyToClipboard(trimmedText)

        do {
            try synthesizePasteShortcut()
        } catch {
            try? restore(snapshot, to: pasteboard)
            throw DictationRuntimeError.insertionFailed(
                "VoiceBar could not trigger Command-V for dictation insertion."
            )
        }

        try? await Task.sleep(nanoseconds: 350_000_000)

        let didRestoreClipboard: Bool

        do {
            try restore(snapshot, to: pasteboard)
            didRestoreClipboard = true
        } catch {
            didRestoreClipboard = false
        }

        return TextInsertionResult(
            didRestoreClipboard: didRestoreClipboard,
            copiedToClipboardOnly: false
        )
    }

    private func synthesizePasteShortcut() throws {
        guard
            let eventSource = CGEventSource(stateID: .combinedSessionState),
            let keyDown = CGEvent(
                keyboardEventSource: eventSource,
                virtualKey: CGKeyCode(kVK_ANSI_V),
                keyDown: true
            ),
            let keyUp = CGEvent(
                keyboardEventSource: eventSource,
                virtualKey: CGKeyCode(kVK_ANSI_V),
                keyDown: false
            )
        else {
            throw DictationRuntimeError.insertionFailed(
                "VoiceBar could not synthesize the paste shortcut on this Mac."
            )
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func snapshot(of pasteboard: NSPasteboard) -> ClipboardSnapshot {
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

    private func restore(
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

        guard pasteboard.writeObjects(restoredItems) else {
            throw DictationRuntimeError.insertionFailed(
                "VoiceBar inserted the dictation text, but could not restore the previous clipboard contents safely."
            )
        }
    }
}
