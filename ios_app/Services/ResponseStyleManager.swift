import Foundation
import SwiftUI

/// Defines the detail level for AI responses
enum ResponseStyle: String, CaseIterable, Identifiable {
    case concise = "concise"
    case detailed = "detailed"
    
    var id: String { self.rawValue }
    
    var label: String {
        switch self {
        case .concise: return "Concise"
        case .detailed: return "Detailed"
        }
    }
    
    var localizedLabel: String {
        NSLocalizedString("response_style_\(self.rawValue)", comment: "")
    }
    
    var description: String {
        switch self {
        case .concise: return NSLocalizedString("response_style_concise_desc", value: "Short, focused insights", comment: "")
        case .detailed: return NSLocalizedString("response_style_detailed_desc", value: "In-depth analysis with planetary context", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .concise: return "bolt.fill"
        case .detailed: return "text.alignleft"
        }
    }
}

/// Manages the user's preferred response style persistently
@MainActor
@Observable
final class ResponseStyleManager {
    static let shared = ResponseStyleManager()
    
    private(set) var currentStyle: ResponseStyle
    
    private init() {
        let savedValue = UserDefaults.standard.string(forKey: "userResponseStyle") ?? ResponseStyle.detailed.rawValue
        self.currentStyle = ResponseStyle(rawValue: savedValue) ?? .detailed
    }
    
    func setStyle(_ style: ResponseStyle) {
        currentStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: "userResponseStyle")
    }
}
