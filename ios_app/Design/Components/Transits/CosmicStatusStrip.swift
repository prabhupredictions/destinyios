import SwiftUI
import Combine

/// Combined Dasha + Transit status strip - seamless design matching original carousel
struct CosmicStatusStrip: View {
    let currentDasha: String      // e.g., "Saturn-Saturn-Moon"
    let transits: [(planet: String, sign: String)]
    
    // Dark Navy Background (matches main background)
    private let darkNavyStart = Color(red: 10/255, green: 14/255, blue: 26/255) // #0a0e1a
    private let darkNavyEnd = Color(red: 21/255, green: 25/255, blue: 34/255)   // #151922
    
    // Planet name to symbol mapping
    private let planetSymbols: [String: String] = [
        "sun": "☉", "moon": "☽", "mars": "♂", "mercury": "☿",
        "jupiter": "♃", "venus": "♀", "saturn": "♄",
        "rahu": "☊", "ketu": "☋"
    ]
    
    // Zodiac sign to symbol mapping (handles all formats)
    // Appended \u{FE0E} to force text presentation (monochrome) instead of colored emoji
    private let signSymbols: [String: String] = [
        // Full lowercase names
        "aries": "♈\u{FE0E}", "taurus": "♉\u{FE0E}", "gemini": "♊\u{FE0E}", "cancer": "♋\u{FE0E}",
        "leo": "♌\u{FE0E}", "virgo": "♍\u{FE0E}", "libra": "♎\u{FE0E}", "scorpio": "♏\u{FE0E}",
        "sagittarius": "♐\u{FE0E}", "capricorn": "♑\u{FE0E}", "aquarius": "♒\u{FE0E}", "pisces": "♓\u{FE0E}",
        // Short codes (2-3 letters)
        "ar": "♈\u{FE0E}", "ta": "♉\u{FE0E}", "ge": "♊\u{FE0E}", "cn": "♋\u{FE0E}", "ca": "♋\u{FE0E}",
        "le": "♌\u{FE0E}", "vi": "♍\u{FE0E}", "li": "♎\u{FE0E}", "sc": "♏\u{FE0E}",
        "sg": "♐\u{FE0E}", "sag": "♐\u{FE0E}", "cp": "♑\u{FE0E}", "cap": "♑\u{FE0E}", "aq": "♒\u{FE0E}", "pi": "♓\u{FE0E}"
    ]
    
    // Auto-scroll state
    @State private var offsetX: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    private let speed: CGFloat = 0.5
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Seamless - no background box, blends with main BG
            
            // Marquee Content
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Dasha Badge (Static, overlaid on left)
                    dashaBadge
                        .padding(.trailing, 12)
                    
                    // Transit content - triplicated for seamless loop
                    transitGroup
                    transitGroup
                    transitGroup
                }
                .background(
                    GeometryReader { contentGeo in
                        Color.clear.onAppear {
                            contentWidth = (contentGeo.size.width - 120) / 3 // Exclude dasha width
                        }
                    }
                )
                .offset(x: offsetX)
                .onReceive(timer) { _ in
                    offsetX -= speed
                    if contentWidth > 0 && abs(offsetX) >= contentWidth {
                        offsetX += contentWidth
                    }
                }
            }
            .mask(RoundedRectangle(cornerRadius: 12))
            
            // Subtle Fade Mask on Edges (seamless blend)
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: darkNavyStart, location: 0),
                    .init(color: .clear, location: 0.15),
                    .init(color: .clear, location: 0.85),
                    .init(color: darkNavyStart, location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .allowsHitTesting(false)
        }
        .frame(height: 90) // Compact height
    }
    
    // MARK: - Dasha Badge (Static on left)
    private var dashaBadge: some View {
        ZStack {
            // Subtle glow background
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "D4AF37").opacity(0.15), location: 0.0),
                    .init(color: .clear, location: 0.8)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 50
            )
            
            HStack(spacing: 6) {
                Text("⏱️")
                    .font(.system(size: 20))
                
                Text(dashaPlanetSymbols)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(hex: "E8D4A0"))
                    .shadow(color: Color(hex: "D4AF37").opacity(0.5), radius: 6)
            }
        }
        .frame(width: 120, height: 80)
    }
    
    // Convert "Saturn-Saturn-Moon" to "♄-♄-☽"
    private var dashaPlanetSymbols: String {
        let parts = currentDasha.components(separatedBy: "-")
        let symbols = parts.map { part in
            planetSymbols[part.lowercased().trimmingCharacters(in: .whitespaces)] ?? String(part.prefix(2))
        }
        return symbols.joined(separator: "-")
    }
    
    // MARK: - Transit Group (matching original carousel style)
    private var transitGroup: some View {
        HStack(spacing: 0) {
            // Transit indicator at start
            Text("🌐")
                .font(.system(size: 18))
                .padding(.horizontal, 8)
            
            ForEach(0..<transits.count, id: \.self) { index in
                HStack(spacing: 0) {
                    transitPairView(planet: transits[index].planet, sign: transits[index].sign)
                    
                    SparkleSeparator()
                        .padding(.horizontal, 2)
                }
            }
        }
    }
    
    // Transit pair with radial glow and constellation lines (like original)
    private func transitPairView(planet: String, sign: String) -> some View {
        ZStack {
            // Radial Golden Glow
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "D4AF37").opacity(0.25), location: 0.0),
                    .init(color: Color(hex: "D4AF37").opacity(0.1), location: 0.5),
                    .init(color: .clear, location: 0.8)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 50
            )
            .frame(width: 100, height: 80)
            
            // Constellation line
            Path { path in
                path.move(to: CGPoint(x: 25, y: 40))
                path.addLine(to: CGPoint(x: 75, y: 40))
            }
            .stroke(
                LinearGradient(
                    colors: [.clear, Color(hex: "D4AF37").opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )
            .frame(width: 100, height: 80)
            
            // Planet + Sign symbols
            HStack(spacing: 12) {
                Text(planetSymbol(for: planet))
                    .font(.system(size: 26))
                    .foregroundColor(Color(hex: "E8D4A0"))
                    .shadow(color: Color(hex: "D4AF37").opacity(0.6), radius: 8)
                
                Text(signSymbol(for: sign))
                    .font(.system(size: 26))
                    .foregroundColor(Color(hex: "E8D4A0"))
                    .shadow(color: Color(hex: "D4AF37").opacity(0.6), radius: 8)
            }
        }
        .frame(width: 100, height: 80)
    }
    
    private func planetSymbol(for name: String) -> String {
        planetSymbols[name.lowercased()] ?? name.prefix(1).uppercased()
    }
    
    private func signSymbol(for name: String) -> String {
        signSymbols[name.lowercased()] ?? name.prefix(1).uppercased()
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(red: 10/255, green: 14/255, blue: 26/255).ignoresSafeArea()
        CosmicStatusStrip(
            currentDasha: "Saturn-Saturn-Moon",
            transits: [
                ("Sun", "Leo"),
                ("Moon", "Capricorn"),
                ("Mars", "Scorpio"),
                ("Venus", "Libra"),
                ("Jupiter", "Pisces")
            ]
        )
        .padding()
    }
}
