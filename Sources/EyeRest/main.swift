import Cocoa

// Strong reference prevents AppDelegate from being deallocated
private var strongDelegate: AppDelegate?

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
strongDelegate = delegate
app.delegate = delegate
app.run()
