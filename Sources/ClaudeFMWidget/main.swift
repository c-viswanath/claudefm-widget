import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.regular)   // shows Dock icon so users can re-open the widget
let delegate = AppDelegate()
app.delegate = delegate
app.run()
