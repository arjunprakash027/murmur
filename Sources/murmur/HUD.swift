import AppKit

/// Small floating pill at the bottom of the screen: live voice bars while recording,
/// dot + short text for other states.
final class HUD {
    static let shared = HUD()

    private static let barCount = 9
    private let panel: NSPanel
    private let dot = NSView()
    private let label = NSTextField(labelWithString: "")
    private let bars = NSView()
    private var barLayers: [CALayer] = []
    private var levels = [Float](repeating: 0, count: HUD.barCount)
    private var hideWork: DispatchWorkItem?

    private init() {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 96, height: 30),
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
        bg.autoresizingMask = [.width, .height]
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 15
        bg.layer?.masksToBounds = true
        panel.contentView = bg

        dot.frame = NSRect(x: 12, y: 10, width: 10, height: 10)
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 5
        label.frame = NSRect(x: 28, y: 6, width: 100, height: 18)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white

        bars.frame = NSRect(x: 14, y: 5, width: 68, height: 20)
        bars.wantsLayer = true
        for i in 0..<HUD.barCount {
            let l = CALayer()
            l.backgroundColor = NSColor.systemRed.cgColor
            l.cornerRadius = 2
            l.frame = NSRect(x: CGFloat(i) * 8, y: 8, width: 4, height: 4)
            bars.layer?.addSublayer(l)
            barLayers.append(l)
        }
        bg.addSubview(dot)
        bg.addSubview(label)
        bg.addSubview(bars)
    }

    /// Feed the live mic level (0...1) while recording. Safe to call from any thread.
    func level(_ rms: Float) {
        DispatchQueue.main.async {
            let v = min(1, sqrt(rms) * 2.2)
            self.levels.removeFirst()
            self.levels.append(v)
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.08)
            for (i, l) in self.barLayers.enumerated() {
                let h = max(4, CGFloat(self.levels[i]) * 20)
                l.frame = NSRect(x: CGFloat(i) * 8, y: (20 - h) / 2, width: 4, height: h)
            }
            CATransaction.commit()
        }
    }

    /// Voice-bars pill, shown while recording.
    func showListening() {
        levels = [Float](repeating: 0, count: HUD.barCount)
        present(width: 96, hideAfter: nil) {
            self.bars.isHidden = false; self.dot.isHidden = true; self.label.isHidden = true
        }
    }

    /// Dot + text pill. `hideAfter` nil keeps it up until the next call.
    func show(_ text: String, color: NSColor, hideAfter: TimeInterval? = nil) {
        present(width: CGFloat(text.count) * 7 + 44, hideAfter: hideAfter) {
            self.bars.isHidden = true; self.dot.isHidden = false; self.label.isHidden = false
            self.label.stringValue = text
            self.dot.layer?.backgroundColor = color.cgColor
        }
    }

    private func present(width: CGFloat, hideAfter: TimeInterval?, configure: () -> Void) {
        hideWork?.cancel()
        configure()
        panel.setContentSize(NSSize(width: width, height: 30))
        if let screen = NSScreen.main {
            let f = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: f.midX - width / 2, y: f.minY + 60))
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
