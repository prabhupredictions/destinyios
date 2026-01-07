import SwiftUI


/// Tier 4 Visionary Splash Screen (SwiftUI Canvas Version)
/// Features: Animated fluid background, cinematic blur-in reveal, pulsing glow, shimmer, parallax stars, haptics
struct SplashView: View {
    // MARK: - Animation States
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleBlur: CGFloat = 10
    @State private var subtitleOpacity: Double = 0
    @State private var orbitRotation: Double = 0
    @State private var starsOpacity: Double = 0

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Liquid Gold Fluid Background (Canvas-based)
                LiquidGoldBackground()
                
                // Layer 2: Animated Stars (3-layer parallax)
                ParallaxStarField()
                    .opacity(starsOpacity)
                
                // Layer 3: Orbital rings (decorative)
                OrbitalRingsView(rotation: orbitRotation)
                    .opacity(0.3)
                
                // Layer 4: Main content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo with premium pulsing glow and shimmer
                    ZStack {
                        // Outer pulsing glow
                        PulsingGlowView(
                            color: AppTheme.Colors.gold.opacity(0.2),
                            size: AppTheme.Splash.glowOuterSize,
                            blurRadius: AppTheme.Splash.glowBlurOuter
                        )
                        
                        // Inner pulsing glow
                        PulsingGlowView(
                            color: AppTheme.Colors.gold.opacity(0.4),
                            size: AppTheme.Splash.glowInnerSize,
                            blurRadius: AppTheme.Splash.glowBlurInner
                        )
                        
                        // Logo container with shimmer
                        ZStack {
                            // Golden circle background
                            Circle()
                                .fill(AppTheme.Colors.gold)
                                .frame(width: AppTheme.Splash.logoContainerSize, height: AppTheme.Splash.logoContainerSize)
                                .shadow(color: AppTheme.Colors.gold.opacity(0.6), radius: 25, y: 5)
                            
                            // Logo image
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: AppTheme.Splash.logoImageSize, height: AppTheme.Splash.logoImageSize)
                        }
                        .overlay(
                            // Shimmer sweep effect
                            ShimmerOverlayView()
                                .mask(Circle().frame(width: AppTheme.Splash.logoContainerSize))
                        )
                        .bioRhythm(bpm: 60, active: true) // Living heartbeat
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .premiumInertia(intensity: 20) // Heavy gold object feel
                    
                    Spacer()
                        .frame(height: AppTheme.Splash.logoToTitleSpacing)
                    
                    // App name - Cinematic blur-in typography
                    VStack(spacing: 16) {
                        // Main title with blur-in effect
                        Text("destiny_app_title".localized)
                            .font(AppTheme.Fonts.display(size: 42))
                            .foregroundColor(.white)
                            .tracking(AppTheme.Splash.titleTracking)
                            .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                            .blur(radius: titleBlur)
                            .opacity(titleOpacity)
                        
                        // Subtitle
                        Text("ai_astrology_subtitle".localized)
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(AppTheme.Colors.gold)
                            .tracking(AppTheme.Splash.subtitleTracking)
                            .opacity(subtitleOpacity)
                        
                        // Tagline
                        Text("worlds_advanced_ai".localized)
                            .font(AppTheme.Fonts.body(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(AppTheme.Splash.taglineTracking)
                            .padding(.top, 8)
                            .opacity(subtitleOpacity)
                    }
                    
                    Spacer()
                    
                    // Loading indicator with animated dots
                    VStack(spacing: 20) {
                        HStack(spacing: AppTheme.Splash.loaderDotSpacing) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(AppTheme.Colors.gold)
                                    .frame(width: AppTheme.Splash.loaderDotSize, height: AppTheme.Splash.loaderDotSize)
                                    .scaleEffect(subtitleOpacity > 0.5 ? 1.0 : 0.5)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                        value: subtitleOpacity
                                    )
                            }
                        }
                        
                        Text("aligning_stars".localized)
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .italic()
                    }
                    .opacity(subtitleOpacity)
                    .padding(.bottom, AppTheme.Splash.loaderBottomPadding)
                }
            }

        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
            // Bio-Sync Start: Heartbeat + Sound
            SoundManager.shared.playSuccess() // "Ascension" chime
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Logo spring animation
        withAnimation(.spring(response: AppTheme.Splash.logoAnimationDuration, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Title blur-in (cinematic reveal)
        withAnimation(.easeOut(duration: 1.5).delay(AppTheme.Splash.titleFadeDelay)) {
            titleOpacity = 1.0
            titleBlur = 0
        }
        
        // Subtitle fade in
        withAnimation(.easeOut(duration: 0.5).delay(AppTheme.Splash.subtitleFadeDelay)) {
            subtitleOpacity = 1.0
        }
        
        // Stars fade in
        withAnimation(.easeIn(duration: 1.0).delay(AppTheme.Splash.starsFadeDelay)) {
            starsOpacity = 1.0
        }
        
        // Continuous orbit rotation
        withAnimation(.linear(duration: AppTheme.Splash.orbitRotationDuration).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }
    }
}

// MARK: - Parallax Star Field (3-layer depth)
struct ParallaxStarField: View {
    var body: some View {
        ZStack {
            StarLayer(starCount: 25, minSize: 1, maxSize: 1.5, opacityRange: 0.2...0.4)  // Far
            StarLayer(starCount: 20, minSize: 1.5, maxSize: 2.5, opacityRange: 0.4...0.6) // Mid
            StarLayer(starCount: 15, minSize: 2, maxSize: 3, opacityRange: 0.6...0.9)     // Near
        }
    }
}

struct StarLayer: View {
    let starCount: Int
    let minSize: CGFloat
    let maxSize: CGFloat
    let opacityRange: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<starCount, id: \.self) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: minSize...maxSize))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
                    .opacity(Double.random(in: opacityRange))
            }
        }
    }
}

// MARK: - Orbital Rings (Using AppTheme Constants)
struct OrbitalRingsView: View {
    let rotation: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                .frame(width: AppTheme.Splash.ringInnerSize, height: AppTheme.Splash.ringInnerSize)
                .rotationEffect(.degrees(rotation))
            
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(0.1), lineWidth: 1)
                .frame(width: AppTheme.Splash.ringMiddleSize, height: AppTheme.Splash.ringMiddleSize)
                .rotationEffect(.degrees(-rotation * 0.5))
            
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: AppTheme.Splash.ringOuterSize, height: AppTheme.Splash.ringOuterSize)
                .rotationEffect(.degrees(rotation * 0.3))
        }
    }
}

#Preview {
    SplashView()
}
