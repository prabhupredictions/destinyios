import SwiftUI

// MARK: - Orbital Background
/// Stylized rotating planets in orbits - perfect for an astrology app
/// Creates an orrery-like effect with planets moving at different speeds

struct OrbitalBackground: View {
    var showOrbits: Bool = true
    var orbitOpacity: Double = 0.08
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
            let maxRadius = min(geometry.size.width, geometry.size.height) * 0.45
            
            ZStack {
                // Base gradient
                // Base gradient (Midnight Gold)
                AppTheme.Colors.mainBackground
                    .ignoresSafeArea()
                
                // Central sun/glow
                CentralSun(center: center)
                
                // Orbits and planets
                // Mercury - innermost, fastest
                OrbitRing(center: center, radius: maxRadius * 0.25, opacity: orbitOpacity, show: showOrbits)
                OrbitingPlanet(
                    center: center,
                    radius: maxRadius * 0.25,
                    planetSize: 6,
                    planetColor: Color(red: 0.7, green: 0.6, blue: 0.5), // Gray-brown
                    orbitDuration: 8,
                    startAngle: 45
                )
                
                // Venus
                OrbitRing(center: center, radius: maxRadius * 0.4, opacity: orbitOpacity, show: showOrbits)
                OrbitingPlanet(
                    center: center,
                    radius: maxRadius * 0.4,
                    planetSize: 10,
                    planetColor: Color(red: 0.9, green: 0.7, blue: 0.4), // Orange-yellow
                    orbitDuration: 12,
                    startAngle: 120
                )
                
                // Mars
                OrbitRing(center: center, radius: maxRadius * 0.55, opacity: orbitOpacity, show: showOrbits)
                OrbitingPlanet(
                    center: center,
                    radius: maxRadius * 0.55,
                    planetSize: 8,
                    planetColor: Color(red: 0.85, green: 0.35, blue: 0.25), // Red
                    orbitDuration: 18,
                    startAngle: 200
                )
                
                // Jupiter - large
                OrbitRing(center: center, radius: maxRadius * 0.72, opacity: orbitOpacity, show: showOrbits)
                OrbitingPlanet(
                    center: center,
                    radius: maxRadius * 0.72,
                    planetSize: 16,
                    planetColor: Color(red: 0.85, green: 0.75, blue: 0.6), // Tan/cream
                    orbitDuration: 28,
                    startAngle: 280,
                    hasRing: false
                )
                
                // Saturn - with ring
                OrbitRing(center: center, radius: maxRadius * 0.88, opacity: orbitOpacity, show: showOrbits)
                OrbitingPlanet(
                    center: center,
                    radius: maxRadius * 0.88,
                    planetSize: 14,
                    planetColor: AppTheme.Colors.gold, // Gold for Saturn
                    orbitDuration: 40,
                    startAngle: 330,
                    hasRing: true
                )
                
                // Moon - small, fast, close
                OrbitingPlanet(
                    center: center,
                    radius: maxRadius * 0.15,
                    planetSize: 5,
                    planetColor: Color.white.opacity(0.9),
                    orbitDuration: 5,
                    startAngle: 0,
                    glowColor: Color.white
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Central Sun
struct CentralSun: View {
    let center: CGPoint
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("GoldAccent").opacity(0.3),
                            Color("GoldAccent").opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 60
                    )
                )
                .frame(width: 120 * pulse, height: 120 * pulse)
                .position(center)
            
            // Inner core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("GoldAccent"),
                            Color("GoldAccent").opacity(0.8)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 15
                    )
                )
                .frame(width: 30, height: 30)
                .position(center)
                .shadow(color: Color("GoldAccent").opacity(0.5), radius: 10)
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)
            ) {
                pulse = 1.15
            }
        }
    }
}

// MARK: - Orbit Ring
struct OrbitRing: View {
    let center: CGPoint
    let radius: CGFloat
    let opacity: Double
    let show: Bool
    
    var body: some View {
        if show {
            Circle()
                .stroke(AppTheme.Colors.gold.opacity(opacity), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2)
                .position(center)
        }
    }
}

// MARK: - Orbiting Planet
struct OrbitingPlanet: View {
    let center: CGPoint
    let radius: CGFloat
    let planetSize: CGFloat
    let planetColor: Color
    let orbitDuration: Double
    let startAngle: Double
    var hasRing: Bool = false
    var glowColor: Color? = nil
    
    @State private var angle: Double = 0
    
    private var planetPosition: CGPoint {
        let radians = (angle + startAngle) * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians) * 0.4 // Elliptical orbit (perspective)
        )
    }
    
    var body: some View {
        ZStack {
            // Glow
            if let glow = glowColor {
                Circle()
                    .fill(glow.opacity(0.4))
                    .frame(width: planetSize * 2, height: planetSize * 2)
                    .blur(radius: planetSize * 0.4)
                    .position(planetPosition)
            }
            
            // Planet body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetColor,
                            planetColor.opacity(0.7)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: planetSize
                    )
                )
                .frame(width: planetSize, height: planetSize)
                .shadow(color: planetColor.opacity(0.5), radius: planetSize * 0.3)
                .position(planetPosition)
            
            // Ring for Saturn
            if hasRing {
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [
                                planetColor.opacity(0.6),
                                planetColor.opacity(0.3),
                                planetColor.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: planetSize * 2.2, height: planetSize * 0.6)
                    .rotationEffect(.degrees(-15))
                    .position(planetPosition)
            }
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: orbitDuration)
                    .repeatForever(autoreverses: false)
            ) {
                angle = 360
            }
        }
    }
}

// MARK: - Minimal Orbital Background (fewer elements for lighter look)
struct MinimalOrbitalBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.3)
            let maxRadius = min(geometry.size.width, geometry.size.height) * 0.4
            
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.95, blue: 0.98),
                        Color(red: 0.94, green: 0.93, blue: 0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle center glow
                Circle()
                    .fill(Color("GoldAccent").opacity(0.15))
                    .frame(width: 80, height: 80)
                    .blur(radius: 30)
                    .position(center)
                
                // Just 3 subtle orbiting dots
                ForEach(0..<3, id: \.self) { index in
                    SubtleOrbit(
                        center: center,
                        radius: maxRadius * (0.4 + Double(index) * 0.25),
                        dotSize: 6 + CGFloat(index) * 2,
                        duration: 15 + Double(index) * 10,
                        startAngle: Double(index) * 120
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Subtle Orbit
struct SubtleOrbit: View {
    let center: CGPoint
    let radius: CGFloat
    let dotSize: CGFloat
    let duration: Double
    let startAngle: Double
    
    @State private var angle: Double = 0
    @State private var opacity: Double = 0.4
    
    private var position: CGPoint {
        let radians = (angle + startAngle) * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians) * 0.35
        )
    }
    
    var body: some View {
        ZStack {
            // Orbit path (very subtle)
            Circle()
                .stroke(Color("GoldAccent").opacity(0.06), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2 * 0.35)
                .position(center)
            
            // Orbiting dot with glow
            ZStack {
                Circle()
                    .fill(Color("GoldAccent").opacity(0.3))
                    .frame(width: dotSize * 2.5, height: dotSize * 2.5)
                    .blur(radius: dotSize * 0.5)
                
                Circle()
                    .fill(Color("GoldAccent"))
                    .frame(width: dotSize, height: dotSize)
            }
            .position(position)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: duration)
                    .repeatForever(autoreverses: false)
            ) {
                angle = 360
            }
            
            withAnimation(
                Animation.easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
            ) {
                opacity = 0.8
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func orbitalBackground() -> some View {
        ZStack {
            OrbitalBackground()
            self
        }
    }
    
    func minimalOrbitalBackground() -> some View {
        ZStack {
            MinimalOrbitalBackground()
            self
        }
    }
}

// MARK: - Previews
#Preview("Orbital Background") {
    VStack {
        Text("✨ Destiny AI")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(Color("NavyPrimary"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .orbitalBackground()
}

#Preview("Minimal Orbital") {
    VStack {
        Text("Minimal Version")
            .font(.title)
            .foregroundColor(Color("NavyPrimary"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .minimalOrbitalBackground()
}
