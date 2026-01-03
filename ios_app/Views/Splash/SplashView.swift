import SwiftUI

/// Premium splash screen with animated logo and cosmic theme
struct SplashView: View {
    // MARK: - Animation States
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var orbitRotation: Double = 0
    @State private var starsOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.Colors.mainBackground.ignoresSafeArea()
            
            // Animated stars background
            StarsBackgroundView()
                .opacity(starsOpacity)
            
            // Orbital rings (decorative)
            OrbitalRingsView(rotation: orbitRotation)
                .opacity(0.3)
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo with premium glow effect
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(AppTheme.Colors.gold.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .blur(radius: 50)
                    
                    // Inner glow
                    Circle()
                        .fill(AppTheme.Colors.gold.opacity(0.4))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)
                    
                    // Logo container
                    ZStack {
                        // Golden circle background with gradient
                        Circle()
                            .fill(AppTheme.Colors.gold)
                            .frame(width: 140, height: 140)
                            .shadow(color: AppTheme.Colors.gold.opacity(0.6), radius: 25, y: 5)
                        
                        // Logo image - properly fitted (78% of circle)
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                Spacer()
                    .frame(height: 40)
                
                // App name - Premium typography
                VStack(spacing: 16) {
                    // Main title
                    Text("destiny_app_title".localized)
                        .font(AppTheme.Fonts.display(size: 42))
                        .foregroundColor(.white)
                        .tracking(12)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                    
                    // Subtitle
                    Text("ai_astrology_subtitle".localized)
                        .font(AppTheme.Fonts.title(size: 16))
                        .foregroundColor(AppTheme.Colors.gold)
                        .tracking(8)
                    
                    // Tagline
                    Text("worlds_advanced_ai".localized)
                        .font(AppTheme.Fonts.body(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(2)
                        .padding(.top, 8)
                }
                .opacity(titleOpacity)
                
                Spacer()
                
                // Loading indicator - minimal and elegant
                VStack(spacing: 20) {
                    // Custom loader dots
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(AppTheme.Colors.gold)
                                .frame(width: 6, height: 6)
                                .opacity(subtitleOpacity)
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
                .padding(.bottom, 70)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Title fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            titleOpacity = 1.0
        }
        
        // Subtitle fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            subtitleOpacity = 1.0
        }
        
        // Stars fade in
        withAnimation(.easeIn(duration: 1.0).delay(0.2)) {
            starsOpacity = 1.0
        }
        
        // Continuous orbit rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }
    }
}

// MARK: - Supporting Views

/// Animated stars background
struct StarsBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<30, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
                    .opacity(Double.random(in: 0.3...0.8))
            }
        }
    }
}

/// Decorative orbital rings
struct OrbitalRingsView: View {
    let rotation: Double
    
    var body: some View {
        ZStack {
            // Inner ring
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(rotation))
            
            // Outer ring
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(0.1), lineWidth: 1)
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(-rotation * 0.5))
            
            // Outermost ring
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: 400, height: 400)
                .rotationEffect(.degrees(rotation * 0.3))
        }
    }
}

#Preview {
    SplashView()
}
