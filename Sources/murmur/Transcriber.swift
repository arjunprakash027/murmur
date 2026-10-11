import Foundation
import whisper

final class Transcriber {
    /// Model inside the app bundle (distributed build), else models/ next to the .app (dev build).
    static var defaultModelPath: String {
        if let bundled = Bundle.main.url(forResource: "ggml-base.en", withExtension: "bin") { return bundled.path }
        return Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("models/ggml-base.en.bin").path
    }

    private var context: OpaquePointer?
    var isLoaded: Bool { context != nil }

    deinit {
        if let context { whisper_free(context) }
    }

    func load(path: String) {
        if let context { whisper_free(context) }
        var params = whisper_context_default_params()
        params.use_gpu = true
        params.flash_attn = true
        context = path.withCString { whisper_init_from_file_with_params($0, params) }
        if context == nil { fputs("transcriber: could not load \(path)\n", stderr) }
    }

    func transcribe(_ samples: [Float]) -> String {
        guard let context, !samples.isEmpty else { return "" }
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.no_timestamps = true
        params.single_segment = true
        params.print_special = false
        params.print_progress = false
        params.print_realtime = false
        params.print_timestamps = false
        params.n_threads = 4
        let result = "en".withCString { language in
            params.language = language
            return samples.withUnsafeBufferPointer {
                whisper_full(context, params, $0.baseAddress, Int32($0.count))
            }
        }
        guard result == 0 else { return "" }
        return (0..<whisper_full_n_segments(context))
            .compactMap { whisper_full_get_segment_text(context, $0).map(String.init(cString:)) }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func selfTest(wavPath: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: wavPath)),
              data.count >= 44,
              String(data: data[0..<4], encoding: .ascii) == "RIFF",
              String(data: data[8..<12], encoding: .ascii) == "WAVE" else {
            fputs("transcriber: invalid WAV\n", stderr)
            return
        }
        func u16(_ i: Int) -> Int { Int(data[i]) | Int(data[i + 1]) << 8 }
        func u32(_ i: Int) -> Int { u16(i) | u16(i + 2) << 16 }
        var offset = 12
        var validFormat = false
        var pcm: [Float] = []
        while offset + 8 <= data.count {
            let size = u32(offset + 4)
            let start = offset + 8
            guard size <= data.count - start else { break }
            let name = String(data: data[offset..<(offset + 4)], encoding: .ascii)
            if name == "fmt ", size >= 16 {
                validFormat = u16(start) == 1 && u16(start + 2) == 1 &&
                    u32(start + 4) == 16_000 && u16(start + 14) == 16
            } else if name == "data" {
                pcm = stride(from: start, to: start + size - size % 2, by: 2).map {
                    Float(Int16(bitPattern: UInt16(u16($0)))) / 32768
                }
            }
            offset = start + size + size % 2
        }
        guard validFormat, !pcm.isEmpty else {
            fputs("transcriber: expected 16 kHz mono 16-bit PCM WAV\n", stderr)
            return
        }
        let transcriber = Transcriber()
        transcriber.load(path: defaultModelPath)
        let start = Date()
        let text = transcriber.transcribe(pcm)
        print("\(text)\n\(Int(Date().timeIntervalSince(start) * 1000)) ms")
    }

    static func run(args: [String]) -> Bool {
        guard let index = args.firstIndex(of: "--transcribe") else { return false }
        guard index + 1 < args.count else {
            fputs("usage: --transcribe file.wav\n", stderr)
            return true
        }
        selfTest(wavPath: args[index + 1])
        return true
    }
}
