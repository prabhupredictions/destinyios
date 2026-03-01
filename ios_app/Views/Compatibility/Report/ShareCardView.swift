import SwiftUI

// MARK: - Share Card View
/// Square 1080×1080 social media card for sharing compatibility results
/// Privacy-safe: shows only verdict/score, no detailed analysis
struct ShareCardView: View {
    let boyName: String
    let girlName: String
    let totalScore: Int
    let maxScore: Int
    let percentage: Double
    var isRecommended: Bool = true
    var adjustedScore: Int? = nil
    
    private var displayScore: Int {
        adjustedScore ?? totalScore
    }
    
    private var displayPercentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(displayScore) / Double(maxScore)
    }
    
    private var ratingText: String {
        if !isRecommended { return "not_recommended".localized }
        let pct = percentage * 100
        if pct >= 90 { return "excellent".localized }
        else if pct >= 75 { return "very_good".localized }
        else if pct >= 60 { return "good".localized }
        else if pct >= 50 { return "average".localized }
        else { return "not_recommended".localized }
    }
    
    private var starCount: Int {
        if !isRecommended { return 1 }
        let pct = percentage * 100
        if pct >= 90 { return 5 }
        else if pct >= 75 { return 4 }
        else if pct >= 60 { return 3 }
        else if pct >= 50 { return 2 }
        else { return 1 }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.10),  // #0B0F19
                    Color(red: 0.08, green: 0.10, blue: 0.18),
                    Color(red: 0.04, green: 0.06, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle radial glow behind score
            RadialGradient(
                colors: [
                    Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 260
            )
            
            // Corner decorations
            VStack {
                HStack {
                    cornerOrnament(rotation: 0)
                    Spacer()
                    cornerOrnament(rotation: 90)
                }
                Spacer()
                HStack {
                    cornerOrnament(rotation: 270)
                    Spacer()
                    cornerOrnament(rotation: 180)
                }
            }
            .padding(30)
            
            // Main content
            VStack(spacing: 0) {
                Spacer().frame(height: 100)
                
                // Logo
                Image("logo_gold")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                
                Text("DESTINY AI ASTROLOGY")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    .tracking(6)
                    .padding(.top, 8)
                
                Spacer().frame(height: 50)
                
                // Names
                Text(boyName.uppercased())
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    goldLine
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    goldLine
                }
                .frame(width: 220)
                .padding(.vertical, 8)
                
                Text(girlName.uppercased())
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Spacer().frame(height: 40)
                
                // Score circle
                ZStack {
                    Circle()
                        .stroke(
                            Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.2),
                            lineWidth: 4
                        )
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .trim(from: 0, to: displayPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.83, green: 0.69, blue: 0.22),
                                    Color(red: 0.95, green: 0.85, blue: 0.55)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(displayScore)")
                            .font(.system(size: 48, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        Text("/\(maxScore)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    }
                }
                
                Spacer().frame(height: 20)
                
                // Star rating
                HStack(spacing: 6) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < starCount ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    }
                }
                
                Text(ratingText.uppercased())
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(!isRecommended ? Color(red: 0.95, green: 0.35, blue: 0.35) : Color(red: 0.83, green: 0.69, blue: 0.22))
                    .tracking(4)
                    .padding(.top, 8)
                
                // Transparency: show original & adjusted scores
                if let adj = adjustedScore, adj != totalScore {
                    Text("Ashtakoot: \(totalScore)/\(maxScore) · Adjusted: \(adj)/\(maxScore)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 4)
                    
                    if !isRecommended {
                        Text("Overridden due to dosha incompatibility")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.95, green: 0.35, blue: 0.35).opacity(0.6))
                            .padding(.top, 2)
                    }
                } else {
                    Text("Ashtakoot Score: \(totalScore)/\(maxScore)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 4)
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0),
                                    Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.5),
                                    Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 60)
                    
                    Text("destinyaiastrology.com")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.6))
                        .tracking(2)
                }
                .padding(.bottom, 40)
            }
        }
        .frame(width: 1080, height: 1080)
    }
    
    // MARK: - Helper Views
    
    private var goldLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0),
                        Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.6),
                        Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
    
    private func cornerOrnament(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 30, y: 0))
        }
        .stroke(
            Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.4),
            lineWidth: 2
        )
        .frame(width: 30, height: 30)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    ShareCardView(
        boyName: "Prabhu",
        girlName: "Asma",
        totalScore: 27,
        maxScore: 36,
        percentage: 0.75
    )
    .previewLayout(.fixed(width: 540, height: 540))
}
