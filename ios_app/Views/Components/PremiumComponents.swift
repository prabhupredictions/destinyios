import SwiftUI

// MARK: - Floating Icon
/// Wrapper that adds a gentle floating animation to its content
struct FloatingIcon<Content: View>: View {
    @State private var isFloating = false
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Glow behind icon
            Circle()
                .fill(AppTheme.CosmicGradients.iconGlow)
                .frame(
                    width: AppTheme.Onboarding.iconContainerSize,
                    height: AppTheme.Onboarding.iconContainerSize
                )
                .blur(radius: AppTheme.Onboarding.iconGlowRadius)
                .opacity(AppTheme.Onboarding.iconGlowOpacity)
            
            content
                .offset(y: isFloating ? -AppTheme.Onboarding.floatAmplitude : AppTheme.Onboarding.floatAmplitude)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: AppTheme.Onboarding.floatDuration)
                .repeatForever(autoreverses: true)
            ) {
                isFloating = true
            }
        }
    }
}

// MARK: - Shimmer Button
/// Premium button with animated shimmer effect
struct ShimmerButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var shimmerOffset: CGFloat = -200
    
    init(title: String, icon: String? = "arrow.right", action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(AppTheme.Fonts.title(size: 17))
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(AppTheme.Colors.textOnGold)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    // Base gradient
                    AppTheme.Colors.premiumCardGradient
                    
                    // Top highlight
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        Spacer()
                    }
                    
                    // Shimmer overlay
                    shimmerOverlay
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppTheme.Colors.gold.opacity(0.4), radius: 15, y: 6)
        }
        .onAppear {
            startShimmer()
        }
    }
    
    private var shimmerOverlay: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: AppTheme.Onboarding.shimmerWidth)
                .rotationEffect(.degrees(AppTheme.Onboarding.shimmerAngle))
                .offset(x: shimmerOffset)
                .mask(Rectangle())
        }
    }
    
    private func startShimmer() {
        // Start from off-screen left
        shimmerOffset = -200
        
        // Animate to off-screen right
        withAnimation(
            .linear(duration: AppTheme.Onboarding.shimmerDuration)
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 500
        }
    }
}

// MARK: - Gold Gradient Text
/// View modifier to apply premium gold gradient to text
struct GoldGradientText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppTheme.Colors.premiumGradient)
            .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 4, y: 2)
    }
}

extension View {
    func goldGradient() -> some View {
        modifier(GoldGradientText())
    }
}

// MARK: - Scroll Transition Effects
/// Custom scroll transition for parallax and fade effects
extension View {
    /// Applies premium scroll transition effects for onboarding
    func onboardingScrollTransition() -> some View {
        self.scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : AppTheme.Onboarding.fadeThreshold)
                .scaleEffect(phase.isIdentity ? 1 : 0.95)
                .offset(y: phase.value * -30 * AppTheme.Onboarding.parallaxIntensity)
        }
    }
}

// MARK: - Typewriter Text (Kinetic Typography)
/// Animates text letter-by-letter like a typewriter
struct TypewriterText: View {
    let fullText: String
    let font: Font
    let color: Color
    
    @State private var displayedText = ""
    @State private var showCursor = true
    @State private var isComplete = false
    
    init(_ text: String, font: Font = AppTheme.Fonts.display(size: 30), color: Color = .white) {
        self.fullText = text
        self.font = font
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(displayedText)
                .font(font)
                .foregroundColor(color)
            
            // Blinking cursor
            if !isComplete {
                Rectangle()
                    .fill(AppTheme.Colors.gold)
                    .frame(width: AppTheme.Visionary.Typewriter.cursorWidth, height: font.lineHeight)
                    .opacity(showCursor ? 1 : 0)
            }
        }
        .onAppear {
            startTyping()
            startCursorBlink()
        }
    }
    
    private func startTyping() {
        displayedText = ""
        let characters = Array(fullText)
        
        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + AppTheme.Visionary.Typewriter.startDelay + (Double(index) * AppTheme.Visionary.Typewriter.characterDelay)
            ) {
                displayedText += String(character)
                
                if index == characters.count - 1 {
                    isComplete = true
                }
            }
        }
    }
    
    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: AppTheme.Visionary.Typewriter.cursorBlinkDuration, repeats: true) { _ in
            showCursor.toggle()
        }
    }
}

// Helper for font line height
extension Font {
    var lineHeight: CGFloat { 24 }
}

// MARK: - Glass Card (Bento Cell)
/// Glassmorphic card for Bento Grid layouts
struct GlassCard<Content: View>: View {
    let content: Content
    let isLarge: Bool
    
    init(isLarge: Bool = false, @ViewBuilder content: () -> Content) {
        self.isLarge = isLarge
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: isLarge ? AppTheme.Visionary.BentoGrid.largeCellHeight : AppTheme.Visionary.BentoGrid.smallCellHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Visionary.BentoGrid.cornerRadius)
                    .fill(AppTheme.Colors.cardBackground.opacity(AppTheme.Visionary.GlassCard.backgroundOpacity))
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Visionary.BentoGrid.cornerRadius)
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Visionary.BentoGrid.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.gold.opacity(AppTheme.Visionary.GlassCard.borderOpacity),
                                AppTheme.Colors.gold.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: AppTheme.Visionary.GlassCard.borderWidth
                    )
            )
    }
}

// MARK: - Bento Grid Features View
/// Premium bento-style grid layout for features
struct BentoGridFeaturesView: View {
    let features = OnboardingFeature.features
    
    var body: some View {
        VStack(spacing: AppTheme.Visionary.BentoGrid.spacing) {
            // Row 1: Two large cells
            HStack(spacing: AppTheme.Visionary.BentoGrid.spacing) {
                if features.count > 0 {
                    featureCell(features[0], isLarge: true)
                }
                if features.count > 1 {
                    featureCell(features[1], isLarge: true)
                }
            }
            
            // Row 2: Two cells (can be smaller or equal)
            HStack(spacing: AppTheme.Visionary.BentoGrid.spacing) {
                if features.count > 2 {
                    featureCell(features[2], isLarge: false)
                }
                if features.count > 3 {
                    featureCell(features[3], isLarge: false)
                }
            }
        }
        .padding(.horizontal, AppTheme.Visionary.BentoGrid.horizontalPadding)
    }
    
    @ViewBuilder
    private func featureCell(_ feature: OnboardingFeature, isLarge: Bool) -> some View {
        GlassCard(isLarge: isLarge) {
            VStack(alignment: .leading, spacing: 6) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.Colors.gold.opacity(0.15))
                        .frame(
                            width: AppTheme.Visionary.BentoGrid.iconContainerSize,
                            height: AppTheme.Visionary.BentoGrid.iconContainerSize
                        )
                    
                    Image(systemName: feature.icon)
                        .font(.system(size: AppTheme.Visionary.BentoGrid.iconSize, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.premiumGradient)
                }
                
                Spacer(minLength: 4)
                
                // Title
                Text(feature.title)
                    .font(AppTheme.Fonts.title(size: AppTheme.Visionary.BentoGrid.titleSize))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                
                // Description - show on ALL cells
                Text(feature.description)
                    .font(AppTheme.Fonts.caption(size: AppTheme.Visionary.BentoGrid.descriptionSize))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(isLarge ? 2 : 1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 3D Tilt Modifier (Device Motion)
/// Applies 3D rotation effect based on device tilt using MotionManager
struct Tilt3DModifier: ViewModifier {
    @StateObject private var motionManager = MotionManager()
    let intensity: CGFloat
    let perspective: CGFloat
    
    init(intensity: CGFloat = 15, perspective: CGFloat = 0.5) {
        self.intensity = intensity
        self.perspective = perspective
    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(Double(motionManager.yOffset * intensity / 25)),
                axis: (x: 1, y: 0, z: 0),
                perspective: perspective
            )
            .rotation3DEffect(
                .degrees(Double(motionManager.xOffset * intensity / 25)),
                axis: (x: 0, y: 1, z: 0),
                perspective: perspective
            )
            .onAppear { motionManager.start() }
            .onDisappear { motionManager.stop() }
    }
}

// MARK: - Inertia Motion Modifier (Proprioception/Weight)
/// Simulates mass by making content "lag" behind device movement
struct InertiaModifier: ViewModifier {
    @StateObject private var motionManager = MotionManager()
    let intensity: CGFloat
    
    init(intensity: CGFloat = 10) {
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: motionManager.xOffset * intensity,
                y: motionManager.yOffset * intensity
            )
            .animation(.interpolatingSpring(stiffness: 100, damping: 10), value: motionManager.xOffset)
            .onAppear { motionManager.start() }
            .onDisappear { motionManager.stop() }
    }
}

// MARK: - Bio-Rhythm "Heartbeat" Modifier
/// Synchronizes Visual Pulse + Haptic Heartbeat + Sound Drone
struct BioRhythmModifier: ViewModifier {
    let bpm: Double
    let intensity: CGFloat // Scale factor
    let active: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var timer: Timer?
    
    init(bpm: Double = 60, intensity: CGFloat = 1.05, active: Bool = true) {
        self.bpm = bpm
        self.intensity = intensity
        self.active = active
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: active) { isActive in
                if isActive {
                    startHeartbeat()
                } else {
                    stopHeartbeat()
                }
            }
            .onAppear {
                if active { startHeartbeat() }
            }
            .onDisappear {
                stopHeartbeat()
            }
    }
    
    private func startHeartbeat() {
        stopHeartbeat() // Clear existing
        
        let interval = 60.0 / bpm
        
        // Initial beat
        pulse()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            pulse()
        }
    }
    
    private func stopHeartbeat() {
        timer?.invalidate()
        timer = nil
        // Reset state
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
            opacity = 1.0
        }
    }
    
    private func pulse() {
        guard active else { return }
        
        // 1. Haptic (The "Thud")
        HapticManager.shared.playHeartbeat()
        
        // 2. Visual (Expand then Contract)
        withAnimation(.easeIn(duration: 0.15)) {
            scale = intensity
            opacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.4)) {
                scale = 1.0
                opacity = 0.95
            }
        }
    }
}

extension View {
    /// Applies 3D rotation based on device tilt (gyroscope)
    /// - Parameters:
    ///   - intensity: How much tilt affects rotation (default: 15)
    ///   - perspective: Perspective depth (default: 0.5)
    func tilt3D(intensity: CGFloat = 15, perspective: CGFloat = 0.5) -> some View {
        modifier(Tilt3DModifier(intensity: intensity, perspective: perspective))
    }
    
    /// Applies simulated mass/weight to the view (Lag on tilt)
    func premiumInertia(intensity: CGFloat = 10) -> some View {
        modifier(InertiaModifier(intensity: intensity))
    }
    
    /// Makes the view "breathe" with a bio-rhythmic heartbeat (Haptic + Visual)
    func bioRhythm(bpm: Double = 60, intensity: CGFloat = 1.03, active: Bool = true) -> some View {
        modifier(BioRhythmModifier(bpm: bpm, intensity: intensity, active: active))
    }
}

#Preview("Shimmer Button") {
    ZStack {
        AppTheme.Colors.mainBackground.ignoresSafeArea()
        
        VStack(spacing: 30) {
            FloatingIcon {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.Colors.premiumGradient)
            }
            
            Text("Premium Title")
                .font(AppTheme.Fonts.display(size: 28))
                .goldGradient()
            
            ShimmerButton(title: "Continue") {
                print("Tapped")
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview("Bento Grid") {
    ZStack {
        CosmicBackgroundView()
        BentoGridFeaturesView()
    }
}

#Preview("Typewriter") {
    ZStack {
        AppTheme.Colors.mainBackground.ignoresSafeArea()
        TypewriterText("Destiny AI")
            .goldGradient()
    }
}

