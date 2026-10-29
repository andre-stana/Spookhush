import AVFoundation
import Foundation

/// Procedural Halloween sound synthesizer: dry autumn leaf rustles, ember crackles,
/// hollow pumpkin thuds on burst, and an eerie wind howl when clearing the screen.
/// Uses an `AVAudioSourceNode` so it needs no audio files and sleeps when silent.
final class SoundEngine {
    static let shared = SoundEngine()

    var isEnabled: Bool = Preferences.soundEffects {
        didSet {
            if !isEnabled {
                lock.lock()
                rustleTarget = 0
                rustleLevel = 0
                gustRemain = 0
                thuds.removeAll()
                crackles.removeAll()
                chimes.removeAll()
                lock.unlock()
            }
        }
    }

    private let lock = NSLock()
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var sampleRate: Float = 44100
    private var isRunning = false
    private var idleTime: Float = 0

    // Synthesis state
    private var rngState: UInt64 = 0x853C_49E6_748F_EA9B
    private var rustleLevel: Float = 0
    private var rustleTarget: Float = 0
    private var lpState1: Float = 0
    private var lpState2: Float = 0
    private var bpState1: Float = 0
    private var bpState2: Float = 0
    private var gustRemain: Float = 0
    private var gustDuration: Float = 2.2
    private var gustPhase: Float = 0

    private struct Thud {
        var age: Float = 0
        var duration: Float
        var startFreq: Float
        var endFreq: Float
        var amp: Float
        var phase: Float = 0
    }

    private struct Crackle {
        var age: Float = 0
        var duration: Float
        var freq: Float
        var amp: Float
        var phase: Float = 0
    }

    private struct Chime {
        var age: Float = 0
        var duration: Float
        var freq: Float
        var amp: Float
        var phase: Float = 0
    }

    private var thuds: [Thud] = []
    private var crackles: [Crackle] = []
    private var chimes: [Chime] = []
    private var lastRustleTime: CFTimeInterval = 0
    private var lastBurstTime: CFTimeInterval = 0

    private init() {}

    private func ensureRunning() {
        guard isEnabled else { return }
        if engine == nil {
            setupEngine()
        }
        if let engine, !engine.isRunning {
            do {
                try engine.start()
                isRunning = true
            } catch {
                isRunning = false
            }
        }
    }

    private func setupEngine() {
        let engine = AVAudioEngine()
        let outputFormat = engine.outputNode.inputFormat(forBus: 0)
        let sr = Float(outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44100)
        sampleRate = sr

        let renderFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sr), channels: 2)!
        let node = AVAudioSourceNode(format: renderFormat) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            self.render(frames: Int(frameCount), buffers: abl)
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: renderFormat)
        engine.mainMixerNode.outputVolume = 0.55
        self.engine = engine
        self.sourceNode = node
    }

    // MARK: - Triggers

    /// Called when the cursor sweeps through leaves/embers.
    func noteCursorRustle(intensity: Float) {
        guard isEnabled, intensity > 0.01 else { return }
        let now = CACurrentMediaTime()
        ensureRunning()
        lock.lock()
        idleTime = 0
        let clamped = min(max(intensity, 0), 1)
        rustleTarget = max(rustleTarget, clamped * 0.42)
        if now - lastRustleTime > 0.035 && crackles.count < 16 {
            lastRustleTime = now
            let count = Int(1 + clamped * 2)
            for _ in 0..<count where crackles.count < 16 {
                crackles.append(Crackle(
                    duration: nextRange(0.008, 0.028),
                    freq: nextRange(1200, 4200),
                    amp: nextRange(0.06, 0.18) * (0.4 + 0.6 * clamped)
                ))
            }
        }
        lock.unlock()
    }

    /// Called when a lump or mini-pumpkin hits a surface and bursts into leaves and sparks.
    func noteBurst(size: Float, force: Float, isPumpkin: Bool) {
        guard isEnabled else { return }
        let now = CACurrentMediaTime()
        guard now - lastBurstTime > 0.04 else { return }
        lastBurstTime = now
        ensureRunning()
        lock.lock()
        idleTime = 0
        let scale = min(max(size / 9.0, 0.3), 1.4) * min(max(force, 0.35), 1.3)
        if thuds.count < 8 {
            thuds.append(Thud(
                duration: isPumpkin ? 0.16 : 0.11,
                startFreq: isPumpkin ? nextRange(125, 165) : nextRange(95, 130),
                endFreq: isPumpkin ? 42 : 36,
                amp: min(0.32, (isPumpkin ? 0.24 : 0.15) * scale)
            ))
        }
        let crackleCount = isPumpkin ? 4 : 2
        for _ in 0..<crackleCount where crackles.count < 16 {
            crackles.append(Crackle(
                duration: nextRange(0.012, 0.035),
                freq: nextRange(900, 3400),
                amp: nextRange(0.08, 0.18) * scale
            ))
        }
        if isPumpkin && chimes.count < 6 {
            let notes: [Float] = [523.25, 587.33, 622.25, 698.46, 783.99, 830.61] // C minor / spooky hexatonic
            let base = notes[Int(nextFloat() * Float(notes.count)) % notes.count]
            chimes.append(Chime(
                duration: 0.45,
                freq: base,
                amp: 0.07 * scale
            ))
        }
        lock.unlock()
    }

    /// Called when "Clear Leaves" blows everything away in a Halloween gust.
    func noteGust() {
        guard isEnabled else { return }
        ensureRunning()
        lock.lock()
        idleTime = 0
        gustDuration = 2.2
        gustRemain = gustDuration
        // Add a faint ghostly chord shimmer
        let freqs: [Float] = [392.0, 466.16, 587.33]
        for f in freqs where chimes.count < 8 {
            chimes.append(Chime(
                duration: 1.6,
                freq: f + nextRange(-3, 3),
                amp: 0.035
            ))
        }
        lock.unlock()
    }

    // MARK: - Audio Render Loop

    private func render(frames: Int, buffers: UnsafeMutableAudioBufferListPointer) {
        lock.lock()
        defer { lock.unlock() }

        let dt = 1.0 / sampleRate
        let hasActive = rustleLevel > 0.0005 || rustleTarget > 0.0005 || gustRemain > 0 || !thuds.isEmpty || !crackles.isEmpty || !chimes.isEmpty

        if !hasActive || !isEnabled {
            for buf in buffers {
                guard let ptr = buf.mData?.assumingMemoryBound(to: Float.self) else { continue }
                memset(ptr, 0, frames * MemoryLayout<Float>.size)
            }
            idleTime += Float(frames) * dt
            return
        }

        let leftPtr = buffers[0].mData?.assumingMemoryBound(to: Float.self)
        let rightPtr = (buffers.count > 1 ? buffers[1].mData : buffers[0].mData)?.assumingMemoryBound(to: Float.self)

        for frame in 0..<frames {
            var sample: Float = 0

            // 1. Continuous dry leaf rustle
            rustleLevel += (rustleTarget - rustleLevel) * min(1, dt * 18)
            rustleTarget *= max(0, 1 - dt * 14)
            let white = nextNoise()
            if rustleLevel > 0.0005 {
                // Band-pass filtered noise for dry autumn leaves
                lpState1 += (white - lpState1) * 0.32
                bpState1 += (lpState1 - bpState1) * 0.045
                let leafBand = lpState1 - bpState1
                sample += leafBand * rustleLevel
            }

            // 2. Eerie Halloween wind gust
            if gustRemain > 0 {
                let age = gustDuration - gustRemain
                gustRemain = max(0, gustRemain - dt)
                let env = sin(min(1, age / 0.35) * (.pi * 0.5)) * pow(max(0, gustRemain / gustDuration), 0.8)
                gustPhase += dt * 2.3
                let sweep = 0.025 + 0.035 * (0.5 + 0.5 * sin(gustPhase))
                lpState2 += (white - lpState2) * sweep
                bpState2 += (lpState2 - bpState2) * (sweep * 0.35)
                let wind = (lpState2 - bpState2) * 1.8
                // Faint whistling overtone
                let whistle = sin(gustPhase * 190 + sin(gustPhase * 3.1) * 4.0) * 0.045
                sample += (wind + whistle) * env * 0.45
            }

            // 3. Leaf & Ember Crackles
            var ci = crackles.count - 1
            while ci >= 0 {
                var c = crackles[ci]
                c.age += dt
                if c.age >= c.duration {
                    crackles.swapAt(ci, crackles.count - 1)
                    crackles.removeLast()
                } else {
                    let t = c.age / c.duration
                    let env = (1 - t) * (1 - t)
                    c.phase += 2 * .pi * c.freq * dt
                    sample += sin(c.phase) * (0.5 + 0.5 * white) * c.amp * env
                    crackles[ci] = c
                }
                ci -= 1
            }

            // 4. Pumpkin / Pile Thuds
            var ti = thuds.count - 1
            while ti >= 0 {
                var th = thuds[ti]
                th.age += dt
                if th.age >= th.duration {
                    thuds.swapAt(ti, thuds.count - 1)
                    thuds.removeLast()
                } else {
                    let t = th.age / th.duration
                    let freq = th.startFreq + (th.endFreq - th.startFreq) * pow(t, 0.6)
                    th.phase += 2 * .pi * freq * dt
                    let env = pow(1 - t, 1.8)
                    sample += sin(th.phase) * th.amp * env
                    thuds[ti] = th
                }
                ti -= 1
            }

            // 5. Eerie Chimes
            var chi = chimes.count - 1
            while chi >= 0 {
                var ch = chimes[chi]
                ch.age += dt
                if ch.age >= ch.duration {
                    chimes.swapAt(chi, chimes.count - 1)
                    chimes.removeLast()
                } else {
                    let t = ch.age / ch.duration
                    let env = min(1, ch.age / 0.015) * pow(1 - t, 2.2)
                    ch.phase += 2 * .pi * ch.freq * dt
                    sample += (sin(ch.phase) + 0.25 * sin(ch.phase * 2.01)) * ch.amp * env
                    chimes[chi] = ch
                }
                chi -= 1
            }

            // Soft clip
            let out = tanh(sample)
            leftPtr?[frame] = out
            rightPtr?[frame] = out
        }
    }

    private func nextFloat() -> Float {
        rngState ^= rngState << 13
        rngState ^= rngState >> 7
        rngState ^= rngState << 17
        return Float(rngState >> 40) / Float(1 << 24)
    }

    private func nextNoise() -> Float {
        nextFloat() * 2 - 1
    }

    private func nextRange(_ lower: Float, _ upper: Float) -> Float {
        lower + (upper - lower) * nextFloat()
    }
}
