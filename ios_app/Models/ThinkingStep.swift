import Foundation

// MARK: - Thinking Step
/// Represents a step in the AI's thinking process (like Claude's "Thinking...")
struct ThinkingStep: Identifiable {
    let id = UUID()
    let step: Int
    let type: ThinkingStepType
    let display: String
    let content: String?
    let timestamp: Date = Date()
    
    enum ThinkingStepType: String {
        case thought = "thought"
        case action = "action"
        case observation = "observation"
        
        var icon: String {
            switch self {
            case .thought: return "💭"
            case .action: return "🔧"
            case .observation: return "📊"
            }
        }
        
        var label: String {
            switch self {
            case .thought: return "Thinking"
            case .action: return "Analyzing"
            case .observation: return "Processing"
            }
        }
    }
}
