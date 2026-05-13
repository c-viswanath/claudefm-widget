import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // no dock icon — widget only
let delegate = AppDelegate()
app.delegate = delegate
app.run()
