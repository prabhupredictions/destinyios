import SwiftUI
import Combine
import CoreMotion

/// Manages device motion for premium parallax effects
/// Uses CoreMotion to detect device tilt and provides smooth offset values
final class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    @Published var xOffset: CGFloat = 0
    @Published var yOffset: CGFloat = 0
    
    private let sensitivity: CGFloat
    private let smoothing: Double
    
    init(
        sensitivity: CGFloat = AppTheme.Onboarding.tiltSensitivity,
        smoothing: Double = AppTheme.Onboarding.tiltSmoothing
    ) {
        self.sensitivity = sensitivity
        self.smoothing = smoothing
    }
    
    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: self.smoothing)) {
                    // Safety Clamp (Prevent uncontrolled spinning)
                    let clampedRoll = min(1.0, max(-1.0, roll))
                    let clampedPitch = min(1.0, max(-1.0, pitch))
                    
                    self.xOffset = CGFloat(clampedRoll) * self.sensitivity
                    self.yOffset = CGFloat(clampedPitch) * self.sensitivity
                }
            }
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    deinit {
        stop()
    }
}

/// View modifier that applies motion-based parallax offset
struct MotionParallaxModifier: ViewModifier {
    @StateObject private var motionManager = MotionManager()
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: motionManager.xOffset * intensity,
                y: motionManager.yOffset * intensity
            )
            .onAppear { motionManager.start() }
            .onDisappear { motionManager.stop() }
    }
}

extension View {
    /// Applies motion-based parallax effect
    /// - Parameter intensity: Multiplier for the offset effect (default 1.0)
    func motionParallax(intensity: CGFloat = 1.0) -> some View {
        modifier(MotionParallaxModifier(intensity: intensity))
    }
}
