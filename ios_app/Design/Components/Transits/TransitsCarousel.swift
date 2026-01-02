import SwiftUI
import Combine

struct TransitsCarousel: View {
    // Dark Navy Background Colors
    private let darkNavyStart = Color(red: 10/255, green: 14/255, blue: 26/255) // #0a0e1a
    private let darkNavyEnd = Color(red: 21/255, green: 25/255, blue: 34/255)   // #151922
    
    // Sample Data based on Spec
    private let transits: [(planet: String, sign: String)] = [
        ("☉", "♌"), // Sun in Leo
        ("☽", "♑"), // Moon in Capricorn
        ("♂", "♏"), // Mars in Scorpio
        ("♀", "♎"), // Venus in Libra
        ("♃", "♓")  // Jupiter in Pisces
    ]
    
    // Infinite Auto-Scroll State
    @State private var offsetX: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    private let speed: CGFloat = 0.5 // Pixels per tick
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect() // ~60fps
    
    var body: some View {
        ZStack {
            // Background Container: REMOVED for seamless blending
            // Content now floats directly on main background

            
            // Marquee Content
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Repeat content 3 times for seamless looping
                    // 1. Original
                    transitGroup
                    // 2. Duplicate 1 (Buffer)
                    transitGroup
                    // 3. Duplicate 2 (Buffer)
                    transitGroup
                }
                .background(
                    GeometryReader { contentGeo in
                        Color.clear
                            .onAppear {
                                contentWidth = contentGeo.size.width / 3 // Width of one set
                            }
                    }
                )
                .offset(x: offsetX)
                .onReceive(timer) { _ in
                    // Move left continuously
                    offsetX -= speed
                    
                    // Reset when first set finishes
                    if abs(offsetX) >= contentWidth {
                        offsetX += contentWidth
                    }
                }
            }
            .mask(RoundedRectangle(cornerRadius: 12))
            
            // Subtle Fade Mask on Edges
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: darkNavyStart, location: 0),
                    .init(color: .clear, location: 0.1),
                    .init(color: .clear, location: 0.9),
                    .init(color: darkNavyStart, location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .allowsHitTesting(false)
        }
        .frame(height: 110) // Reduced height for compact fit
    }
    
    // Extracted Transit Group View (Triplicated)
    private var transitGroup: some View {
        HStack(spacing: 0) {
            ForEach(0..<transits.count, id: \.self) { index in
                let transit = transits[index]
                
                HStack(spacing: 0) {
                    // 1. Grouped Pair (Planet + Sign)
                    TransitPairView(planet: transit.planet, sign: transit.sign)
                    
                    // 2. Separator between groups
                    SparkleSeparator()
                        .padding(.horizontal, 2)
                }
            }
        }
    }
}

// New Component: Grouped Planet & Sign
struct TransitPairView: View {
    let planet: String
    let sign: String
    
    var body: some View {
        ZStack {
            // Shared Radial Golden Glow (Background)
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "D4AF37").opacity(0.25), location: 0.0), // Center Gold
                    .init(color: Color(hex: "D4AF37").opacity(0.1), location: 0.5),  // Fade
                    .init(color: .clear, location: 0.8)                              // Edge
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 70
            )
            .frame(width: 140, height: 100)
            
            // Constellation Elements (Decorative Lines)
            Path { path in
                path.move(to: CGPoint(x: 40, y: 50))
                path.addLine(to: CGPoint(x: 100, y: 50))
            }
            .stroke(
                LinearGradient(
                    colors: [.clear, Color(hex: "D4AF37").opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )
            .frame(width: 140, height: 100)
            
            // Symbols
            HStack(spacing: 20) {
                // Planet
                Text(planet)
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "E8D4A0"))
                    .shadow(color: Color(hex: "D4AF37").opacity(0.6), radius: 8)
                
                // Sign
                Text(sign)
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "E8D4A0"))
                    .shadow(color: Color(hex: "D4AF37").opacity(0.6), radius: 8)
            }
        }
        .frame(width: 140, height: 100)
    }
}
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TransitsCarousel()
    }
}
