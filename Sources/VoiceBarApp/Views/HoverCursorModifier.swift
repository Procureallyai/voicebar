import AppKit
import SwiftUI

private struct HoverCursorModifier: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .onHover { nextHoverState in
                guard nextHoverState != isHovering else {
                    return
                }

                isHovering = nextHoverState

                if nextHoverState {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onDisappear {
                guard isHovering else {
                    return
                }

                isHovering = false
                NSCursor.pop()
            }
    }
}

extension View {
    func voiceBarPointingCursor() -> some View {
        modifier(HoverCursorModifier())
    }
}
