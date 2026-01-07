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

