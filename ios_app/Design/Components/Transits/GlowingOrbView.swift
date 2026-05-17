import SwiftUI

struct GlowingOrbView: View {
    let symbol: String
    
    
    // Golden Colors
    private let goldBase = Color(red: 212/255, green: 175/255, blue: 55/255) // #D4AF37
    private let goldLight = Color(red: 232/255, green: 212/255, blue: 160/255) // #E8D4A0
    
    var body: some View {
        ZStack {
            // 1. Core Background: Radial Gradient
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: goldBase.opacity(0.4), location: 0.0),       // Center glow
                    .init(color: goldBase.opacity(0.2), location: 0.4),     // Mid fade
                    .init(color: Color(red: 80/255, green: 70/255, blue: 40/255).opacity(0.1), location: 0.7), // Outer fade
                    .init(color: .clear, location: 1.0)                     // Transparent edge
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 28 // Half of 56px size
            )
            .frame(width: 56, height: 56)
            
            // 2. Golden Border
            Circle()
                .stroke(goldBase.opacity(0.6), lineWidth: 2)
                .frame(width: 56, height: 56)
            
            // 3. Inner 3D Highlight (Top sheen)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: 54, height: 54) // Inside border
                .blur(radius: 1)
            
            // 4. Symbol Text
            Text(symbol)
                .font(.system(size: 28)) // 28-32px spec
                .foregroundColor(goldLight)
                .shadow(color: goldBase.opacity(0.8), radius: 6, x: 0, y: 0) // Text glow
                .shadow(color: goldBase.opacity(0.4), radius: 12, x: 0, y: 0) // Text outer glow
        }
        // 5. Static Outer Glow (pulse animation removed for battery optimization)
        .shadow(color: goldBase.opacity(0.5), radius: 25)
        .scaleEffect(1.02)
    }
}

#Preview {
    ZStack {
        Color.black
        GlowingOrbView(symbol: "☉")
    }
}
