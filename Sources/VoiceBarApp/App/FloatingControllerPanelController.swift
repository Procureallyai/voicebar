import AppKit
import SwiftUI

struct FloatingControllerSnapshot: Equatable {
    var statusText: String
    var detailText: String
    var engineText: String
    var voiceText: String
    var isDictationRecording: Bool
    var isDictationProcessing: Bool
    var dictationAutomaticallyStopsOnSilence: Bool
    var formatterModelText: String
    var formatterUsedFallback: Bool
    var pauseResumeTitle: String
    var canPauseResume: Bool
    var canStop: Bool
    var canReplay: Bool
}

private final class FloatingPanel: NSPanel {
    var onCloseRequest: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override func close() {
        orderOut(nil)
        onCloseRequest?()
    }
}

@MainActor
final class FloatingControllerPanelController {
    private static let panelWidth: CGFloat = 360
    private static let minimumPanelHeight: CGFloat = 280
    private static let maximumPanelHeight: CGFloat = 460

    private var panel: FloatingPanel?
    private var hostingController: NSHostingController<FloatingControllerView>?

    func update(
        snapshot: FloatingControllerSnapshot,
        isVisible: Bool,
        onPauseResume: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onReplay: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        guard isVisible else {
            panel?.orderOut(nil)
            return
        }

        let panel = ensurePanel(onDismiss: onDismiss)
        let rootView = FloatingControllerView(
            snapshot: snapshot,
            onPauseResume: onPauseResume,
            onStop: onStop,
            onReplay: onReplay,
            onDismiss: onDismiss
        )

        if let hostingController {
            hostingController.rootView = rootView
        } else {
            let hostingController = NSHostingController(rootView: rootView)
            hostingController.view.frame = NSRect(
                x: 0,
                y: 0,
                width: Self.panelWidth,
                height: Self.minimumPanelHeight
            )
            panel.contentViewController = hostingController
            self.hostingController = hostingController
        }

        if let hostingController {
            // Keep the panel height aligned with the current SwiftUI content so
            // dictation rows and controls stay visible at common font sizes.
            hostingController.view.layoutSubtreeIfNeeded()
            let fittedHeight = max(
                Self.minimumPanelHeight,
                min(
                    Self.maximumPanelHeight,
                    hostingController.view.fittingSize.height + 20
                )
            )
            panel.setContentSize(
                NSSize(
                    width: Self.panelWidth,
                    height: fittedHeight
                )
            )
        }

        if panel.isVisible == false {
            panel.center()
            panel.orderFrontRegardless()
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func ensurePanel(onDismiss: @escaping () -> Void) -> FloatingPanel {
        if let panel {
            panel.onCloseRequest = onDismiss
            return panel
        }

        let panel = FloatingPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Self.panelWidth,
                height: Self.minimumPanelHeight
            ),
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isMovableByWindowBackground = true
        panel.onCloseRequest = onDismiss

        self.panel = panel
        return panel
    }
}
