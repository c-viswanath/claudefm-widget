import SwiftUI

/// Drags the window from whatever area it covers. A plain click (press and
/// release without moving) calls `onClick` instead, when one is given.
///
/// `isMovableByWindowBackground` isn't enough on its own: the YouTube web view
/// swallows the mouse, so the video never dragged, and over SwiftUI content
/// such as text it only worked in some spots.
struct WindowDragArea: NSViewRepresentable {
    var onClick: (() -> Void)? = nil

    func makeNSView(context: Context) -> DragView { DragView() }

    func updateNSView(_ view: DragView, context: Context) {
        view.onClick = onClick
    }

    final class DragView: NSView {
        var onClick: (() -> Void)?

        // We start the drag ourselves, so AppKit shouldn't also try to.
        override var mouseDownCanMoveWindow: Bool { false }
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            // Peek (without consuming) at what follows the press:
            // a release means it was a click, movement means a drag.
            let next = window.nextEvent(
                matching: [.leftMouseUp, .leftMouseDragged],
                until: .distantFuture,
                inMode: .eventTracking,
                dequeue: false
            )
            if next?.type == .leftMouseUp {
                onClick?()
            } else {
                window.performDrag(with: event)
            }
        }
    }
}
