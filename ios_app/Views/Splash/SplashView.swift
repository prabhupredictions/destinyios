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
            LinearGradient(
                colors: [
                    Color("NavyPrimary").opacity(0.95),
                    Color("NavyPrimary"),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated stars background
            StarsBackgroundView()
                .opacity(starsOpacity)
            
            // Orbital rings (decorative)
            OrbitalRingsView(rotation: orbitRotation)
                .opacity(0.3)
            
            // Main content
            VStack(spacing: 24) {
                Spacer()
                
                // Logo with glow effect
                ZStack {
                    // Glow
                    Circle()
                        .fill(Color("GoldAccent").opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                    
                    // Logo container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .shadow(color: Color("GoldAccent").opacity(0.5), radius: 20)
                        
                        Text("D")
                            .font(.system(size: 56, weight: .light, design: .serif))
                            .foregroundColor(Color("NavyPrimary"))
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name
                VStack(spacing: 8) {
                    Text("destiny")
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(4)
                    
                    Text("AI ASTROLOGY")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("GoldAccent"))
                        .tracking(6)
                }
                .opacity(titleOpacity)
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("GoldAccent")))
                        .scaleEffect(1.2)
                    
                    Text("Aligning the stars...")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(subtitleOpacity)
                .padding(.bottom, 60)
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
                .stroke(Color("GoldAccent").opacity(0.2), lineWidth: 1)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(rotation))
            
            // Outer ring
            Circle()
                .stroke(Color("GoldAccent").opacity(0.1), lineWidth: 1)
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
