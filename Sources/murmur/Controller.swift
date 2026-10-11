import AppKit

final class Controller {
    enum State { case idle, recording, transcribing }

    private let recorder = Recorder()
    private let transcriber = Transcriber()
    private let queue = DispatchQueue(label: "murmur.transcribe")
    private(set) var state: State = .idle { didSet { onState?(state) } }
    var onState: ((State) -> Void)?

    func start() {
        let model = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("models/ggml-base.en.bin").path
        queue.async { self.transcriber.load(path: model); print("controller: model loaded") }
        Hotkey.install { [weak self] in self?.toggle() }
    }

    func toggle() {
        switch state {
        case .idle:
            state = .recording
            recorder.start()
        case .recording:
            let samples = recorder.stop()
            guard samples.count >= 8000 else { state = .idle; return } // under 0.5 s
            state = .transcribing
            queue.async {
                let text = self.transcriber.transcribe(samples)
                DispatchQueue.main.async {
                    if !text.isEmpty { Paster.paste(text) }
                    self.state = .idle
                }
            }
        case .transcribing:
            break
        }
    }
}
