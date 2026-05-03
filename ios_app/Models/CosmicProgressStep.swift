import Foundation

struct CosmicProgressStep: Identifiable {
    let id = UUID()
    let text: String        // Resolved via NSLocalizedString(displayKey)
    let displayKey: String  // Original key for debugging
    var isCompleted: Bool
    var isActive: Bool
}
