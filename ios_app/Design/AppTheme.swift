
import SwiftUI

/// Centralized Theme System for Destiny AI Astrology App
/// Defines a premium dark aesthetic with Navy/Gold palette.
struct AppTheme {
    
    // MARK: - Colors
    struct Colors {
        // Main Backgrounds
        static let mainBackground = Color(hex: "0B0F19") // Deep space navy
        static let cardBackground = Color(hex: "151A29") // Slightly lighter navy for cards
        static let secondaryBackground = Color(hex: "1C2235") // Interactive elements
        
        // Accents
        static let gold = Color(hex: "D4AF37") // Classic Gold
        static let goldLight = Color(hex: "F2D06B") // Highlight Gold
        static let goldDim = Color(hex: "8A7638") // Muted Gold for borders/dividers
        
        // Status Colors
        static let success = Color(hex: "4CAF50")
        static let warning = Color(hex: "FFC107")
        static let error = Color(hex: "FF5252")
        
        // Text Colors
        static let textPrimary = Color(hex: "FFFFFF")
        static let textSecondary = Color(hex: "A0AEC0")
        static let textTertiary = Color(hex: "718096")
        
        // Gradients
        static let premiumGradient = LinearGradient(
            gradient: Gradient(colors: [goldLight, gold]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let backgroundGradient = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "0F1422"), Color(hex: "0B0F19")]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    struct Fonts {
        static func display(size: CGFloat) -> Font {
            return .system(size: size, weight: .bold, design: .serif)
        }
        
        static func title(size: CGFloat) -> Font {
            return .system(size: size, weight: .semibold, design: .default)
        }
        
        static func body(size: CGFloat) -> Font {
            return .system(size: size, weight: .regular, design: .default)
        }
    }
    
    // MARK: - Styles
    struct Styles {
        static let cornerRadius: CGFloat = 16
        static let cardShadow = ShadowStyle(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        static let goldBorder = OverlayStyle(stroke: Colors.gold.opacity(0.3), width: 1)
    }
}

// MARK: - Helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ShadowStyle {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
}

struct OverlayStyle {
    var stroke: Color
    var width: CGFloat
}
