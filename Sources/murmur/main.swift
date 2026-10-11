import AppKit
import AVFoundation

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    let controller = Controller()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "murmur")
        let menu = NSMenu()
        menu.delegate = self
        for _ in 0..<3 { let i = NSMenuItem(title: "", action: nil, keyEquivalent: ""); i.isEnabled = false; menu.addItem(i) }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit murmur", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        controller.onState = { [weak self] state in
            let name = ["idle": "mic", "recording": "mic.fill", "transcribing": "ellipsis.circle"]["\(state)"] ?? "mic"
            self?.statusItem.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: "murmur")
        }
        controller.start()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let mic = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let ax = AXIsProcessTrusted()
        menu.items[0].title = (mic ? "✓" : "✗") + " Microphone permission"
        menu.items[1].title = (ax ? "✓" : "✗") + " Accessibility permission (paste)"
        menu.items[2].title = (controller.modelLoaded ? "✓" : "…") + " Model loaded (whisper base.en)"
    }
}

setvbuf(stdout, nil, _IONBF, 0)
if Transcriber.run(args: CommandLine.arguments) { exit(0) }

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
