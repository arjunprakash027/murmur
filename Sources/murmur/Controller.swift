import AppKit
import AVFoundation

final class Controller {
    enum State { case idle, recording, transcribing }

    private let recorder = Recorder()
    private let transcriber = Transcriber()
    private let queue = DispatchQueue(label: "murmur.transcribe")
    private(set) var state: State = .idle { didSet { onState?(state) } }
    var onState: ((State) -> Void)?
    private(set) var modelLoaded = false

    func start() {
        let model = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("models/ggml-base.en.bin").path
        queue.async { self.transcriber.load(path: model); self.modelLoaded = self.transcriber.isLoaded; print("controller: model loaded=\(self.modelLoaded)") }
        Hotkey.install { [weak self] in self?.toggle() }
    }

    func toggle() {
        print("controller: toggle in state \(state), mic auth \(AVCaptureDevice.authorizationStatus(for: .audio).rawValue), AX trusted \(AXIsProcessTrusted())")
        switch state {
        case .idle:
            state = .recording
            HUD.shared.showListening()
            recorder.start()
        case .recording:
            let samples = recorder.stop()
            print("controller: got \(samples.count) samples")
            guard samples.count >= 8000 else { // under 0.5 s
                state = .idle
                HUD.shared.show("Too short", color: .systemOrange, hideAfter: 1.0)
                return
            }
            state = .transcribing
            HUD.shared.show("Transcribing", color: .systemYellow)
            queue.async {
                let text = self.transcriber.transcribe(samples)
                print("controller: text='\(text)'")
                DispatchQueue.main.async {
                    if text.isEmpty { HUD.shared.show("Didn't catch that", color: .systemOrange, hideAfter: 1.2) }
                    else { Paster.paste(text); HUD.shared.show("Pasted", color: .systemGreen, hideAfter: 0.9) }
                    self.state = .idle
                }
            }
        case .transcribing:
            break
        }
    }
}
