import SwiftUI
import UIKit
import CoreHaptics

/// Centralized Haptic Feedback Manager
/// Upgraded to Core Haptics for "Living App" textures (Heartbeat, Shimmer)
class HapticManager {
    static let shared = HapticManager()
    
    // Core Haptics Engine
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    private init() {
        setupHaptics()
    }
    
    // MARK: - Setup
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        supportsHaptics = true
        
        do {
            engine = try CHHapticEngine()
            // Handle interrupt (backgrounding)
            engine?.resetHandler = { [weak self] in
                print("HapticManager: Engine reset")
                // Try restarting
                do {
                    try self?.engine?.start()
                } catch {
                    print("HapticManager: Failed to restart engine: \(error)")
                }
            }
        } catch {
            print("HapticManager: Engine error: \(error)")
        }
    }
    
    // MARK: - Premium Textures ("The Real Feeling")
    
    /// Simulates a living "Heartbeat" (Lub-Dub)
    /// Used during AI processing or deep analysis
    func playHeartbeat() {
        guard supportsHaptics, let engine = engine else {
            notify(.warning) // Fallback
            return
        }
        
        // Ensure engine is running
        do { try engine.start() } catch { return }
        
        // Define "Lub-Dub" Pattern
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1) // Lower sharpness = "Thud" feel
        
        // Lub (First beat)
        let beat1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        // Dub (Second beat, slightly weaker and delayed)
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let beat2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity2, sharpness], relativeTime: 0.12)
        
        let pattern = try? CHHapticPattern(events: [beat1, beat2], parameters: [])
        let player = try? engine.makePlayer(with: pattern!)
        try? player?.start(atTime: 0)
    }
    
    /// Simulates a "Golden Shimmer" or "Purr"
    /// High frequency, continuous vibration. Used for success/unlocking.
    func playShimmer() {
        guard supportsHaptics, let engine = engine else {
            notify(.success)
            return
        }
        
        do { try engine.start() } catch { return }
        
        // Continuous event for 0.4 seconds
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8) // High sharpness = "Buzz/Purr"
        
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.4)
        
        let pattern = try? CHHapticPattern(events: [continuousEvent], parameters: [])
        let player = try? engine.makePlayer(with: pattern!)
        try? player?.start(atTime: 0)
    }
    
    /// Simulates "Heavy Impact" (Gold Tablet drop)
    /// Strong, low-end thud.
    func playHeavyImpact() {
        guard supportsHaptics, let engine = engine else {
            play(.heavy)
            return
        }
        
        do { try engine.start() } catch { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.0) // Zero sharpness = dull thud
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        let pattern = try? CHHapticPattern(events: [event], parameters: [])
        let player = try? engine.makePlayer(with: pattern!)
        try? player?.start(atTime: 0)
    }
    
    // MARK: - Legacy / Standard Feedback (UIKit)
    
    func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Choreographed Patterns
    
    func premiumButtonPress() {
        play(.soft)
    }
    
    func premiumContinue() {
        play(.medium)
        // Delayed secondary tap for "depth"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.play(.soft)
        }
    }
    
    func premiumSuccess() {
        // Upgrade to Core Haptics Shimmer if available
        if supportsHaptics {
            playShimmer()
        } else {
            notify(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.play(.heavy)
            }
        }
    }
    
    func premiumSlideTransition() {
        selection()
    }
    
    func premiumCardSelect() {
        play(.light)
    }
    
    // MARK: - Semantic Aliases (Soul of the App)
    func playButtonTap() {
        premiumButtonPress()
    }
    
    func playSuccess() {
        premiumSuccess()
    }
}
