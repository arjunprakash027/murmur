import AppKit

/// Small floating pill at the bottom of the screen showing what murmur is doing.
final class HUD {
    static let shared = HUD()

    private let panel: NSPanel
    private let dot = NSView()
    private let label = NSTextField(labelWithString: "")
    private var hideWork: DispatchWorkItem?

    private init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 190, height: 44),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let bg = NSVisualEffectView(frame: panel.contentView!.bounds)
        bg.material = .hudWindow
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 22
        bg.layer?.masksToBounds = true
        panel.contentView = bg

        dot.frame = NSRect(x: 18, y: 16, width: 12, height: 12)
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 6
        label.frame = NSRect(x: 40, y: 12, width: 140, height: 20)
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        bg.addSubview(dot)
        bg.addSubview(label)
    }

    /// Shows `text` with a colored dot. `hideAfter` nil keeps it up until the next call.
    func show(_ text: String, color: NSColor, hideAfter: TimeInterval? = nil) {
        hideWork?.cancel()
        label.stringValue = text
        dot.layer?.backgroundColor = color.cgColor
        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: f.midX - panel.frame.width / 2, y: f.minY + 70))
        }
        panel.orderFrontRegardless()
        if let hideAfter {
            let work = DispatchWorkItem { [weak self] in self?.panel.orderOut(nil) }
            hideWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + hideAfter, execute: work)
        }
    }

    func hide() { hideWork?.cancel(); panel.orderOut(nil) }
}
