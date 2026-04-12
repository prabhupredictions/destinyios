import Foundation
import SwiftUI

// MARK: - Response Length (controls verbosity: concise vs detailed)
// Shown in chat input bar as "Response Length". Maps to backend `response_length` field.

enum ResponseLength: String, CaseIterable, Identifiable {
    case concise = "concise"
    case detailed = "detailed"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .concise: return NSLocalizedString("response_length_concise", value: "Concise", comment: "")
        case .detailed: return NSLocalizedString("response_length_expanded", value: "Expanded", comment: "")
        }
    }

    var description: String {
        switch self {
        case .concise: return NSLocalizedString("response_length_concise_desc", value: "Short, focused insights", comment: "")
        case .detailed: return NSLocalizedString("response_length_expanded_desc", value: "More context and explanation", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .concise: return "bolt.fill"
        case .detailed: return "text.alignleft"
        }
    }
}

/// Manages the user's preferred response length persistently.
/// Persisted under "userResponseLength". Sent to backend as `response_length`.
@MainActor
@Observable
final class ResponseLengthManager {
    static let shared = ResponseLengthManager()

    private(set) var currentLength: ResponseLength

    private init() {
        let saved = UserDefaults.standard.string(forKey: "userResponseLength") ?? ResponseLength.detailed.rawValue
        self.currentLength = ResponseLength(rawValue: saved) ?? .detailed
    }

    func setLength(_ length: ResponseLength) {
        currentLength = length
        UserDefaults.standard.set(length.rawValue, forKey: "userResponseLength")
    }
}

// MARK: - Content Style (controls tone: essentials vs complete chart details)
// Shown in onboarding and Settings. Maps to backend `response_style` field.

enum ContentStyle: String, CaseIterable, Identifiable {
    case essentials = "guidance"        // warm, practical — Essentials card
    case completeChart = "astrology"    // technical, degrees & placements

    var id: String { rawValue }

    var label: String {
        switch self {
        case .essentials: return NSLocalizedString("content_style_essentials", value: "Essentials", comment: "")
        case .completeChart: return NSLocalizedString("content_style_complete", value: "Complete Chart Details", comment: "")
        }
    }

    var tagline: String {
        switch self {
        case .essentials:
            return NSLocalizedString(
                "content_style_essentials_tagline",
                value: "Responses with key astrological details such as planets and transits.",
                comment: ""
            )
        case .completeChart:
            return NSLocalizedString(
                "content_style_complete_tagline",
                value: "Responses with full planetary positions, degrees, house placements, and classical references.",
                comment: ""
            )
        }
    }

    var exampleResponse: String {
        switch self {
        case .essentials:
            return NSLocalizedString(
                "content_style_essentials_example",
                value: "This is not the best time to switch. Saturn is putting pressure on your career house right now, making transitions harder and riskier than usual.\n\nBetter window: April to June 2027, when Jupiter supports your career house and your career planet activates.\n\nUntil then: Build skills, grow your network, and prepare so you're ready when the window opens.",
                comment: ""
            )
        case .completeChart:
            return NSLocalizedString(
                "content_style_complete_example",
                value: "This is not the best time to switch. Saturn (retrograde, 8° Pisces) is transiting your 10th house, creating friction around career authority and professional recognition. Your 10th-lord Mars (14° Gemini) is in the 3rd house, weakening its directional strength for career matters.\n\nBetter window: Jupiter transits your 10th house from April 2027, conjunct natal Midheaven at 12° Aries. Mars antardasha begins June 2027, activating your career lord.\n\nUntil then: Use this period for strategic positioning rather than action. Current dasha-antardasha does not support major career moves.",
                comment: ""
            )
        }
    }

    var icon: String {
        switch self {
        case .essentials: return "sparkles"
        case .completeChart: return "chart.xyaxis.line"
        }
    }
}

/// Manages the user's preferred content style persistently.
/// Persisted under "userContentStyle". Sent to backend as `response_style`.
@MainActor
@Observable
final class ContentStyleManager {
    static let shared = ContentStyleManager()

    private(set) var currentStyle: ContentStyle

    private init() {
        let saved = UserDefaults.standard.string(forKey: "userContentStyle") ?? ContentStyle.essentials.rawValue
        self.currentStyle = ContentStyle(rawValue: saved) ?? .essentials
    }

    func setStyle(_ style: ContentStyle) {
        currentStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: "userContentStyle")
    }
}
