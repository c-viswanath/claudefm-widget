import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSPanel!

    private let width: CGFloat = 380
    private var fullHeight: CGFloat { (width * 9 / 16).rounded() + barHeight }
    private let originKey = "windowOrigin"

    /// Whether the stream was playing when × hid the widget.
    private var resumeOnShow = false

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
        appMenu.addItem(NSMenuItem(
            title: "Mini Player",
            action: #selector(toggleMini),
            keyEquivalent: "m"
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
        let size = CGSize(width: width, height: AppState.shared.isMini ? barHeight : fullHeight)
        let origin = savedOrigin(for: size) ?? defaultOrigin(for: size)

        window = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.isMovableByWindowBackground = false   // WindowDragArea handles dragging
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.appearance = NSAppearance(named: .darkAqua)   // dark slider/tooltips in light mode too
        window.delegate = self

        window.contentView = NSHostingView(rootView: ContentView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Swallow all right-mouse events so no context menu ever appears
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { _ in nil }
    }

    // MARK: - Position

    private func defaultOrigin(for size: CGSize) -> CGPoint {
        let screen = NSScreen.main?.visibleFrame ?? .zero
        return CGPoint(x: screen.maxX - size.width - 20, y: screen.maxY - size.height - 20)
    }

    /// Where the user last left the widget, unless that spot is no longer on
    /// any screen (e.g. an external display was unplugged).
    private func savedOrigin(for size: CGSize) -> CGPoint? {
        guard let saved = UserDefaults.standard.string(forKey: originKey) else { return nil }
        let origin = NSPointFromString(saved)
        let barCenter = CGPoint(x: origin.x + size.width / 2, y: origin.y + barHeight / 2)
        return NSScreen.screens.contains { $0.frame.contains(barCenter) } ? origin : nil
    }

    func windowDidMove(_ notification: Notification) {
        UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: originKey)
    }

    // MARK: - Mini mode

    @objc func toggleMini() {
        let mini = !AppState.shared.isMini
        AppState.shared.setMini(mini)

        // The window's origin is its bottom-left corner, so keeping it fixed
        // keeps the bar where it is and the video grows/shrinks above it.
        var frame = window.frame
        frame.size.height = mini ? barHeight : fullHeight
        if let visible = window.screen?.visibleFrame, frame.maxY > visible.maxY {
            frame.origin.y = visible.maxY - frame.height   // don't push the video off the top
        }
        window.setFrame(frame, display: true, animate: window.isVisible)
    }

    // MARK: - Hide / show

    func hideWindow() {
        resumeOnShow = AppState.shared.isPlaying
        AppState.shared.pause()
        window.orderOut(nil)
    }

    @objc func showWindow() {
        let wasHidden = !window.isVisible
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if wasHidden && resumeOnShow { AppState.shared.play() }
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
