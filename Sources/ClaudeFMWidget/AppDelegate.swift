import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        setupWindow()
    }

    private func setupMenu() {
        let mainMenu = NSMenu()
        let item = NSMenuItem()
        mainMenu.addItem(item)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(
            title: "Quit Claude FM",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        item.submenu = appMenu
        NSApp.mainMenu = mainMenu
    }

    private func setupWindow() {
        let width: CGFloat = 380
        let videoHeight: CGFloat = (width * 9 / 16).rounded()   // 213
        let barHeight: CGFloat = 54
        let totalHeight = videoHeight + barHeight                // 267

        // Position: top-right corner, inset from edge
        let screen = NSScreen.main?.visibleFrame ?? .zero
        let origin = CGPoint(
            x: screen.maxX - width - 20,
            y: screen.maxY - totalHeight - 20
        )

        window = NSPanel(
            contentRect: NSRect(origin: origin, size: CGSize(width: width, height: totalHeight)),
            // .borderless removes the title bar entirely (no black bar)
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.hasShadow = true
        // Prevent the panel from hiding when it loses focus (fixes right-click close)
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hosting = NSHostingView(rootView: ContentView())
        window.contentView = hosting

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
