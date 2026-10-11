import AVFoundation

final class Recorder {
    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var samples: [Float] = []

    func start() {
        lock.lock(); samples = []; lock.unlock()
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: startEngine()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { ok in
                if ok { self.startEngine() } else { print("recorder: mic permission denied") }
            }
        default: print("recorder: mic permission denied")
        }
    }

    private func startEngine() {
        let input = engine.inputNode
        let fmt = input.outputFormat(forBus: 0)
        guard let target = Self.target, let conv = AVAudioConverter(from: fmt, to: target) else {
            print("recorder: no converter"); return
        }
        input.installTap(onBus: 0, bufferSize: 4096, format: fmt) { [weak self] buf, _ in
            guard let self else { return }
            let out = Self.convert(buffer: buf, using: conv)
            self.lock.lock(); self.samples += out; self.lock.unlock()
        }
        do { try engine.start() } catch { print("recorder: engine start failed: \(error)") }
    }

    func stop() -> [Float] {
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        lock.lock(); defer { lock.unlock() }
        return samples
    }

    static let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)

    /// Converts any PCM buffer to 16 kHz mono Float32. Pass a shared converter when streaming
    /// to keep resampler state across chunks. Checked with 1 s of 48 kHz stereo sine: 48000 -> ~16000 samples (ratio 1/3).
    static func convert(buffer: AVAudioPCMBuffer, using converter: AVAudioConverter? = nil) -> [Float] {
        guard let target, let conv = converter ?? AVAudioConverter(from: buffer.format, to: target) else { return [] }
        let cap = AVAudioFrameCount(Double(buffer.frameLength) * 16000 / buffer.format.sampleRate) + 32
        guard let out = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: cap) else { return [] }
        var fed = false
        var err: NSError?
        conv.convert(to: out, error: &err) { _, status in
            if fed { status.pointee = converter == nil ? .endOfStream : .noDataNow; return nil }
            fed = true; status.pointee = .haveData; return buffer
        }
        if let err { print("recorder: convert error \(err)"); return [] }
        return Array(UnsafeBufferPointer(start: out.floatChannelData![0], count: Int(out.frameLength)))
    }

    /// Writes mono 16 kHz 16-bit PCM WAV for listening tests.
    static func debugDumpWAV(samples: [Float], path: String) {
        var d = Data()
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
        let bytes = UInt32(samples.count * 2)
        d.append(contentsOf: Array("RIFF".utf8)); u32(36 + bytes)
        d.append(contentsOf: Array("WAVEfmt ".utf8)); u32(16); u16(1); u16(1); u32(16000); u32(32000); u16(2); u16(16)
        d.append(contentsOf: Array("data".utf8)); u32(bytes)
        for s in samples { u16(UInt16(bitPattern: Int16(max(-1, min(1, s)) * 32767))) }
        try? d.write(to: URL(fileURLWithPath: path))
    }
}
