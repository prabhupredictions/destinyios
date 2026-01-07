
import SwiftUI

/// Centralized Theme System for Destiny AI Astrology App
/// Defines a premium dark aesthetic with Navy/Gold palette.
///
/// # THE SOUL OF THE APP (Sensory Philosophy)
/// This app is not just software; it is a "Living Organism" designed to connect with the user's subconscious.
/// Future development MUST adhere to this 5-Sense Sensory Stack:
///
/// ## 1. SEE (Visual) 👁️
///   - **Aesthetic:** Divine Luxury. Deep Space Navy + Living Gold.
///   - **Holography:** Use `Tilt3DModifier` to make icons rotate in 3D space based on device tilt.
///   - **Materials:** UI elements are not pixels; they are heavy gold/glass slabs.
///   - **Typography:** `Playfair Display` (Serif) for Soul/Titles, `San Francisco` for Brain/Body.
///
/// ## 2. HEAR (Sound) 👂
///   - **Philosophy:** "Spiritual Connection" over "Notification".
///   - **Frequencies:** Use 432Hz (Healing) and 528Hz (Miracle).
///   - **Synthesis:** Use `SoundManager`'s Tibetan Bowl synthesizer (Additive Synthesis). NO generic beeps.
///   - **Subliminal:** The app emits a silent 10Hz Alpha Wave (Binaural Drone) at 3% volume to induce flow state.
///   - **Envelope:** Attack times > 40ms. Sounds should feel like "touching a cloud" or "tapping water".
///
/// ## 3. TOUCH (Haptics) 🫳
///   - **Philosophy:** "Physicality".
///   - **Heartbeat:** Use `HapticManager.playHeartbeat()` (Core Haptics) during AI processing. The phone must throb like a heart.
///   - **Texture:** Use `playShimmer()` for success. It feels like a high-frequency electric purr.
///   - **Mechanism:** Taps are soft thuds, not sharp clicks.
///
/// ## 4. PROPRIOCEPTION (Weight) ⚖️
///   - **Philosophy:** "Mass".
///   - **Inertia:** Use `.premiumInertia()` modifier. Content must "lag" behind device tilt.
///   - **Illusion:** This tricks the brain into feeling the data has physical weight (Gold Tablet Effect).
///
/// ## 5. BIO-SYNC (Rhythm) 💓
///   - **Rate:** 60 BPM (Resting Heart Rate).
///   - **Coherence:** Visual scales, Audio Drones, and Haptics must pulse in sync to calm the user.
///
/// ## 6. ATMOSPHERE (Environment) 🌌
///   - **Philosophy:** "Cosmic Context".
///   - **Particles:** Use Parallax Star Fields (`ParallaxStarField`) to provide depth.
///   - **Fluidity:** Backgrounds should be `LiquidGoldBackground` or similar animated shaders. Never static.
///
/// ## 7. MOTION (Physics) 🌊
///   - **Philosophy:** "Water".
///   - **Springs:** No linear animations. Use `interpolatingSpring(stiffness: 100, damping: 10)` for organic movement.
///   - **Transitions:** Elements should float into place, not snap.
///
struct AppTheme {
    
    // MARK: - Colors
    struct Colors {
        // Main Backgrounds
        static let mainBackground = Color(hex: "0B0F19") // Deep space navy
        static let cardBackground = Color(hex: "151A29") // Slightly lighter navy for cards
        static let secondaryBackground = Color(hex: "1C2235") // Interactive elements
        
        // Inputs & Surfaces
        static let inputBackground = Color(hex: "121620") // Darker navy for text inputs
        static let surfaceBackground = Color(hex: "151A29") // Standard surface/modal color
        static let separator = Color(hex: "2D3748").opacity(0.5) // Subtle divider
        
        // Accents
        static let gold = Color(hex: "D4AF37") // Classic Gold
        static let goldLight = Color(hex: "F2D06B") // Highlight Gold
        static let goldDim = Color(hex: "8A7638") // Muted Gold for borders/dividers
        static let goldChampagne = Color(hex: "FFF8E1") // Light Champagne Gold
        static let goldDeep = Color(hex: "8B7226") // Deep gold for shadows
        
        // Additional Accents
        static let purpleAccent = Color(hex: "4A148C") // Deep purple for decorative elements
        static let darkNavyContrast = Color(hex: "1A1E3C") // Dark navy for contrast text
        
        // Status Colors
        static let success = Color(hex: "4CAF50")
        static let warning = Color(hex: "FFC107")
        static let error = Color(hex: "FF5252")
        static let info = Color(hex: "2196F3")
        
        // Text Colors
        static let textPrimary = Color(hex: "FFFFFF")
        static let textSecondary = Color(hex: "A0AEC0")
        static let textTertiary = Color(hex: "718096")
        static let textOnGold = Color(hex: "0B0F19") // Dark text for gold backgrounds
        
        // Tab Bar
        static let tabBarBackground = Color(hex: "0A0E1A") // Tab bar navy
        static let tabInactive = Color.white.opacity(0.5)
        
        // Gradients
        static let premiumGradient = LinearGradient(
            gradient: Gradient(colors: [goldLight, gold]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let backgroundGradient = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "0F1422"), mainBackground]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let premiumCardGradient = LinearGradient(
            stops: [
                .init(color: Color(hex: "FFFDE7"), location: 0.0),
                .init(color: Color(hex: "F5D580"), location: 0.3),
                .init(color: gold, location: 0.6),
                .init(color: Color(hex: "B8962C"), location: 0.85),
                .init(color: goldDeep, location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let tabGlowGradient = RadialGradient(
            colors: [gold.opacity(0.5), Color.clear],
            center: .center,
            startRadius: 0,
            endRadius: 30
        )
    }
    
    // MARK: - Typography
    struct Fonts {
        // Custom font family names (must match font family name, not PostScript name for variable fonts)
        private static let playfairDisplay = "Playfair Display"
        
        /// Premium display font (Playfair Display) - for headlines that need luxury feel
        static func premiumDisplay(size: CGFloat) -> Font {
            if let _ = UIFont(name: playfairDisplay, size: size) {
                return .custom(playfairDisplay, size: size)
            }
            // Fallback to system serif if custom font fails to load
            return .system(size: size, weight: .bold, design: .serif)
        }
        
        /// Standard display font (System Serif) - for general headlines
        static func display(size: CGFloat) -> Font {
            return .system(size: size, weight: .bold, design: .serif)
        }
        
        static func title(size: CGFloat) -> Font {
            return .system(size: size, weight: .semibold, design: .default)
        }
        
        static func body(size: CGFloat) -> Font {
            return .system(size: size, weight: .regular, design: .default)
        }
        
        static func caption(size: CGFloat = 12) -> Font {
            return .system(size: size, weight: .regular, design: .default)
        }
    }
    
    // MARK: - Styles
    struct Styles {
        static let cornerRadius: CGFloat = 16
        static let inputHeight: CGFloat = 52
        static let cardShadow = ShadowStyle(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        static let goldBorder = OverlayStyle(stroke: Colors.gold.opacity(0.3), width: 1)
        static let inputBorder = OverlayStyle(stroke: Colors.gold.opacity(0.15), width: 1)
    }
    
    // MARK: - Splash Screen (Tier 4 Visionary)
    struct Splash {
        // Logo Sizes
        static let logoContainerSize: CGFloat = 140
        static let logoImageSize: CGFloat = 110
        static let glowOuterSize: CGFloat = 200
        static let glowInnerSize: CGFloat = 160
        
        // Glow Effects
        static let glowBlurOuter: CGFloat = 50
        static let glowBlurInner: CGFloat = 30
        static let glowPulseMin: CGFloat = 0.9
        static let glowPulseMax: CGFloat = 1.1
        
        // Orbital Rings
        static let ringInnerSize: CGFloat = 200
        static let ringMiddleSize: CGFloat = 300
        static let ringOuterSize: CGFloat = 400
        
        // Loader
        static let loaderDotSize: CGFloat = 6
        static let loaderDotSpacing: CGFloat = 8
        
        // Typography Tracking
        static let titleTracking: CGFloat = 12
        static let subtitleTracking: CGFloat = 8
        static let taglineTracking: CGFloat = 2
        
        // Animation Timings
        static let logoAnimationDuration: Double = 0.8
        static let titleFadeDelay: Double = 0.3
        static let subtitleFadeDelay: Double = 0.6
        static let starsFadeDelay: Double = 0.2
        static let orbitRotationDuration: Double = 30
        static let glowPulseDuration: Double = 2.0
        static let shimmerDuration: Double = 1.5
        
        // Spacing
        static let logoToTitleSpacing: CGFloat = 40
        static let loaderBottomPadding: CGFloat = 70
    }
    
    // MARK: - Language Selection (Premium)
    struct LanguageSelection {
        // Card dimensions
        static let cardHeight: CGFloat = 72
        static let cardCornerRadius: CGFloat = 16
        static let cardSpacing: CGFloat = 10
        
        // Glassmorphism
        static let glassOpacity: Double = 0.08
        static let glassBorderOpacity: Double = 0.12
        static let glassBlur: CGFloat = 0.5
        
        // Selection state
        static let selectedGlowRadius: CGFloat = 15
        static let selectedBorderWidth: CGFloat = 1.5
        static let selectedBackgroundOpacity: Double = 0.18
        
        // Animation timings
        static let staggerDelay: Double = 0.04
        static let entranceDuration: Double = 0.5
        static let selectionSpring: Animation = .spring(response: 0.35, dampingFraction: 0.7)
        
        // Particle effect
        static let particleCount: Int = 12
        static let particleSize: CGFloat = 4
        static let particleDuration: Double = 0.6
        
        // Celestial icon
        static let iconSize: CGFloat = 50
        static let iconGlowRadius: CGFloat = 25
        static let iconRotationDuration: Double = 20.0
    }
    
    // MARK: - Premium Onboarding
    struct Onboarding {
        // Cosmic Background
        static let nebulaSize: CGFloat = 500
        static let nebulaBlur: CGFloat = 100
        static let nebulaRotationDuration: Double = 60.0
        static let starCount: Int = 30
        static let starMinSize: CGFloat = 1.5
        static let starMaxSize: CGFloat = 3.5
        static let starTwinkleDuration: Double = 2.0
        
        // Tilt Parallax (CoreMotion)
        static let tiltSensitivity: CGFloat = 25.0
        static let tiltSmoothing: Double = 0.15
        
        // Floating Icon Animation
        static let floatAmplitude: CGFloat = 8.0
        static let floatDuration: Double = 3.0
        
        // Shimmer Button
        static let shimmerDuration: Double = 2.5
        static let shimmerAngle: Double = 25.0
        static let shimmerWidth: CGFloat = 80.0
        
        // Scroll Transition
        static let parallaxIntensity: CGFloat = 0.3
        static let fadeThreshold: CGFloat = 0.7
        
        // Icon Container
        static let iconContainerSize: CGFloat = 140
        static let iconSize: CGFloat = 100
        static let iconGlowRadius: CGFloat = 30
        static let iconGlowOpacity: Double = 0.4
        
        // Typography
        static let titleSize: CGFloat = 30
        static let subtitleSize: CGFloat = 17
        static let descriptionSize: CGFloat = 16
        
        // Spacing
        static let contentTopPadding: CGFloat = 60
        static let iconToTitleSpacing: CGFloat = 36
        static let titleToDescriptionSpacing: CGFloat = 16
    }
    
    // MARK: - Cosmic Gradients
    struct CosmicGradients {
        static let nebulaGold = RadialGradient(
            colors: [Colors.gold.opacity(0.25), Colors.gold.opacity(0.05), Color.clear],
            center: .center,
            startRadius: 50,
            endRadius: 250
        )
        
        static let nebulaPurple = RadialGradient(
            colors: [Colors.purpleAccent.opacity(0.3), Colors.purpleAccent.opacity(0.05), Color.clear],
            center: .center,
            startRadius: 30,
            endRadius: 200
        )
        
        static let iconGlow = RadialGradient(
            colors: [Colors.gold.opacity(0.5), Colors.gold.opacity(0.1), Color.clear],
            center: .center,
            startRadius: 20,
            endRadius: 70
        )
    }
    
    // MARK: - Visionary UI (2025 Trends)
    struct Visionary {
        // Bento Grid Layout
        struct BentoGrid {
            static let spacing: CGFloat = 10
            static let largeCellHeight: CGFloat = 120
            static let smallCellHeight: CGFloat = 100
            static let cornerRadius: CGFloat = 16
            static let iconSize: CGFloat = 22
            static let iconContainerSize: CGFloat = 40
            static let titleSize: CGFloat = 14
            static let descriptionSize: CGFloat = 11
            static let horizontalPadding: CGFloat = 16
        }
        
        // Glass Button (Crystal Effect)
        struct GlassButton {
            static let height: CGFloat = 56
            static let cornerRadius: CGFloat = 18
            static let borderWidth: CGFloat = 1.5
            static let borderOpacity: Double = 0.4
            static let shadowRadius: CGFloat = 20
            static let shadowOpacity: Double = 0.4
            static let innerHighlightOpacity: Double = 0.15
        }
        
        // Typewriter Text Animation
        struct Typewriter {
            static let characterDelay: Double = 0.04
            static let cursorBlinkDuration: Double = 0.5
            static let cursorWidth: CGFloat = 2
            static let startDelay: Double = 0.3
        }
        
        // Glass Card (Bento Cells)
        struct GlassCard {
            static let backgroundOpacity: Double = 0.08
            static let borderOpacity: Double = 0.2
            static let borderWidth: CGFloat = 1
            static let blurRadius: CGFloat = 0.5
        }
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
