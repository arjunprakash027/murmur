import Foundation

final class Transcriber {
    func load(path: String) {
        // TODO: whisper_init_from_file
        print("transcriber: load \(path) (stub)")
    }

    func transcribe(_ samples: [Float]) -> String {
        // TODO: whisper_full
        print("transcriber: transcribe \(samples.count) samples (stub)")
        return ""
    }
}
