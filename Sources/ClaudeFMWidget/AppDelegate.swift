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
            title: "Show Claude FM",
            action: #selector(showWindow),
            keyEquivalent: "s"
        ))
        appMenu.addItem(.separator())
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
        let videoHeight: CGFloat = (width * 9 / 16).rounded()
        let barHeight: CGFloat = 54
        let totalHeight = videoHeight + barHeight

        let screen = NSScreen.main?.visibleFrame ?? .zero
        let origin = CGPoint(
            x: screen.maxX - width - 20,
            y: screen.maxY - totalHeight - 20
        )

        window = NSPanel(
            contentRect: NSRect(origin: origin, size: CGSize(width: width, height: totalHeight)),
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
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        window.contentView = NSHostingView(rootView: ContentView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Swallow all right-mouse events so no context menu ever appears
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { _ in nil }
    }

    func hideWindow() {
        window.orderOut(nil)
    }

    @objc func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        AppState.shared.resumeVideo()
    }

    // Called when user clicks the Dock icon while app is already running
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showWindow()
        return true
    }

    // Don't quit when window is hidden — let it live in the Dock
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
