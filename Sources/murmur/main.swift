import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let controller = Controller()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "murmur")
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit murmur", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        controller.start()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
