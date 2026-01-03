import SwiftUI
import UIKit

/// Centralized manager for Haptic Feedback (Sensory Delight)
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Trigger a standard UI impact
    func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger a notification feedback (success, warning, error)
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Light tap for selection (tab bar, picker)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
