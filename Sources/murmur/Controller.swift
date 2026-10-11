import Foundation

final class Controller {
    private var recording = false

    func start() {
        // TODO: Hotkey.install(onToggle:), Transcriber.load(path:)
        print("controller: start")
    }

    func toggle() {
        // TODO: wire Recorder -> Transcriber -> Paster
        recording.toggle()
        print("controller: toggle ->", recording ? "start" : "stop")
    }
}
