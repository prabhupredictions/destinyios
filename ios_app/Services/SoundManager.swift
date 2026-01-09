import SwiftUI
import AVFoundation
import Combine

/// Centralized manager for Programmatic Sound Effects (Sensory Delight)
/// Generates "astrological" sine-wave chimes programmatically using AVAudioEngine
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    // Audio Engine Components
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode() // Foreground sounds (UI)
    private let ambientNode = AVAudioPlayerNode() // Background healing drone
    private let mixer: AVAudioMixerNode
    
    // Persistent User Preference
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "isSoundEnabled")
            updateAmbientState()
        }
    }
    
    // Cached Buffers
    private var tapBuffer: AVAudioPCMBuffer?
    private var chimeBuffer: AVAudioPCMBuffer?
    private var successBuffer: AVAudioPCMBuffer?
    private var healingDroneBuffer: AVAudioPCMBuffer?
    
    private init() {
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? false
        mixer = engine.mainMixerNode
        setupEngine()
        prepareBuffers()
        
        // Start healing frequencies automatically if sound is enabled
        updateAmbientState()
    }
    
    private func setupEngine() {
        // Attach nodes
        engine.attach(playerNode)
        engine.attach(ambientNode)
        
        // Connect taking mixer's native format
        let format = mixer.outputFormat(forBus: 0)
        engine.connect(playerNode, to: mixer, format: format)
        engine.connect(ambientNode, to: mixer, format: format)
        
        // Configure Volume
        // Foreground sounds regular volume
        playerNode.volume = 1.0 
        
        // Ambient Drone: Subliminal Volume (User shouldn't "hear" it, just "feel" it)
        // Extremely low volume for subconscious effect
        ambientNode.volume = 0.03
        
        do {
            try engine.start()
        } catch {
            print("SoundManager: Failed to start engine: \(error)")
        }
    }
    
    private func updateAmbientState() {
        if isSoundEnabled {
            if !ambientNode.isPlaying {
                // Ensure engine is running
                if !engine.isRunning { try? engine.start() }
                
                // Infinite Loop for Healing Drone
                if let drone = healingDroneBuffer {
                    ambientNode.scheduleBuffer(drone, at: nil, options: .loops, completionHandler: nil)
                    ambientNode.play()
                }
            }
        } else {
            ambientNode.stop()
        }
    }
    
    // MARK: - Procedural Sound Generation (The "Wow" Factor)
    
    /// Pre-calculates audio buffers for low-latency playback
    private func prepareBuffers() {
        let format = mixer.outputFormat(forBus: 0)
        
        // 1. Interaction Tap: "Cloud Touch"
        // Base: 432Hz (Healing)
        // Attack: 40ms (Very soft start, no click)
        tapBuffer = generateTibetanBowlBuffer(
            baseFrequency: 432.0,
            partials: [1.0, 2.0, 4.0], // Octaves for clarity but softness
            amplitudes: [0.4, 0.1, 0.05],
            duration: 0.4,
            decay: 6.0,
            attackTime: 0.04, // SUPER SOFT ATTACK
            format: format
        )
        
        // 2. Success Chime: "Divine Chord" (Soft Healing)
        successBuffer = generateDivineChordBuffer(
            duration: 1.5,
            format: format
        )
        
        // 3. Selection Drop: "Deep Grounding"
        chimeBuffer = generateTibetanBowlBuffer(
            baseFrequency: 396.0, // Root Chakra
            partials: [1.0, 1.5], // Perfect fifth
            amplitudes: [0.3, 0.1],
            duration: 0.2,
            decay: 10.0,
            attackTime: 0.05, // Very soft
            format: format
        )
        
        // 4. Subliminal Healing Drone (The Silent Feature)
        // Generates a 10Hz Alpha Binaural Beat (528Hz Left, 538Hz Right)
        healingDroneBuffer = generateBinauralDroneBuffer(
            baseFrequency: 528.0,
            beatFrequency: 10.0, // 10Hz Alpha Wave (Relaxation/Creativity)
            duration: 5.0, // 5 second loop
            format: format
        )
    }
    
    /// Generates a complex "Singing Bowl" sound
    private func generateTibetanBowlBuffer(baseFrequency: Double, partials: [Double], amplitudes: [Double], duration: Double, decay: Double, attackTime: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let beatFreq = 1.0 // Slow shimmer
        
        for channel in 0..<channelCount {
            let data = buffer.floatChannelData![channel]
            let detune = (channel == 0) ? -0.2 : 0.2 // Slight stereo width
            
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                var sample: Double = 0
                
                for (index, ratio) in partials.enumerated() {
                    let amp = amplitudes[index]
                    let freq = (baseFrequency * ratio) + detune
                    let sine = sin(2.0 * .pi * freq * t)
                    let tremolo = 1.0 + 0.05 * sin(2.0 * .pi * beatFreq * t)
                    sample += sine * amp * tremolo
                }
                
                // Envelope
                let attack = min(1.0, t / attackTime)
                let release = exp(-decay * t)
                
                data[i] = Float(sample * attack * release * 0.5)
            }
        }
        return buffer
    }
    
    /// Generates a "Divine Chord" (Solfeggio Frequencies)
    private func generateDivineChordBuffer(duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        // Frequencies: 528 (Love), 639 (Harmony), 963 (Divine)
        let freqs = [528.0, 639.0, 963.0]
        let amps = [0.4, 0.25, 0.1]
        
        for channel in 0..<channelCount {
            let data = buffer.floatChannelData![channel]
            let detune = (channel == 0) ? -0.5 : 0.5 // Subtle stereo shimmer
            
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                var sample: Double = 0
                
                for (idx, freq) in freqs.enumerated() {
                    let adjustedFreq = freq + detune
                    // Add Tremolo (4Hz modulation)
                    let tremolo = 1.0 + 0.1 * sin(2.0 * .pi * 4.0 * t)
                    sample += sin(2.0 * .pi * adjustedFreq * t) * amps[idx] * tremolo
                }
                
                // Envelope: Soft Gaussian-like swelling bell
                // Attack 0.4s, Release 1.1s
                let attackTime = 0.4
                let attack = min(1.0, t / attackTime)
                
                let releaseTime = duration - 0.8
                let release = (t > releaseTime) ? max(0, 1.0 - (t - releaseTime) / 0.8) : 1.0
                
                data[i] = Float(sample * attack * release * 0.25)
            }
        }
        return buffer
    }

    /// Generates the Subliminal Binaural Drone (Loopable)
    private func generateBinauralDroneBuffer(baseFrequency: Double, beatFrequency: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        // Left Ear: Base Frequency
        // Right Ear: Base + Beat Frequency (Difference = Beat)
        let leftFreq = baseFrequency
        let rightFreq = baseFrequency + beatFrequency
        
        for channel in 0..<channelCount {
            let data = buffer.floatChannelData![channel]
            let freq = (channel == 0) ? leftFreq : rightFreq
            
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                
                // Pure Sine Wave for healing
                let sample = sin(2.0 * .pi * freq * t)
                
                // No decay, flat envelope (it's a drone loop)
                // Slight fade in/out at edges to avoid click on loop wrap
                let fadeLen = 0.1
                let fadeIn = min(1.0, t / fadeLen)
                let fadeOut = (t > duration - fadeLen) ? max(0, (duration - t) / fadeLen) : 1.0
                
                data[i] = Float(sample * fadeIn * fadeOut * 0.01)
            }
        }
        return buffer
    }
    
    /// Generates a lush "Cosmic Pad" chord with slow swell
    private func generateCosmicPadBuffer(frequencies: [Double], duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // ... (Same as before, simplified for diff clarity only if needed, but keeping full implementation)
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        for channel in 0..<channelCount {
            let data = buffer.floatChannelData![channel]
            let detune = (channel == 0) ? -1.0 : 1.0
            
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                var sample: Double = 0
                for freq in frequencies {
                    let adjustedFreq = freq + detune
                    sample += sin(2.0 * .pi * adjustedFreq * t)
                }
                sample /= Double(frequencies.count)
                let attackTime = 0.6 // Even slower swell
                let attack = min(1.0, t / attackTime)
                let releaseTime = duration - 0.5
                let release = (t > releaseTime) ? max(0, 1.0 - (t - releaseTime) / 0.5) : 1.0
                data[i] = Float(sample * attack * release * 0.3)
            }
        }
        return buffer
    }
    
    // MARK: - Public API
    
    func toggleSound() {
        isSoundEnabled.toggle()
        if isSoundEnabled {
            playButtonTap()
        }
        // updateAmbientState() called via didSet
    }
    
    func playButtonTap() { play(tapBuffer) }
    func playSuccess() { play(successBuffer) }
    func playCardSelect() { play(chimeBuffer) }
    func playSlideTransition() { } // Silent
    
    // Compatibility Shim
    func premiumContinue() { playCardSelect() }
    func premiumSuccess() { playSuccess() }
    
    private func play(_ buffer: AVAudioPCMBuffer?) {
        guard isSoundEnabled, let buffer = buffer else { return }
        if !engine.isRunning { try? engine.start() }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
    }
}

// MARK: - AppTheme Sound Constants

extension AppTheme {
    /// Sound-related constants for consistent audio experience
    struct Sounds {
        static let buttonVolume: Float = 0.3
        static let transitionVolume: Float = 0.2
        static let successVolume: Float = 0.4
    }
}
