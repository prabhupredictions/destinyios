import SwiftUI

/// Card displaying today's personalized astrological insight
struct InsightCard: View {
    let insight: String
    var icon: String = "sun.max.fill"
    var title: String = "Today's Insight"
    var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon glow
            HStack(spacing: 10) {
                // Icon with subtle glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color("GoldAccent").opacity(0.3))
                        .frame(width: 28, height: 28)
                        .blur(radius: 6)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("GoldAccent"))
                }
                
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                    .tracking(1.2)
                
                Spacer()
                
                // Decorative dots
                HStack(spacing: 4) {
                    Circle().fill(Color("GoldAccent").opacity(0.6)).frame(width: 4, height: 4)
                    Circle().fill(Color("GoldAccent").opacity(0.3)).frame(width: 4, height: 4)
                }
            }
            
            // Content
            if isLoading {
                // Skeleton loading
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonLine(width: 0.95)
                    SkeletonLine(width: 0.8)
                    SkeletonLine(width: 0.55)
                }
            } else {
                Text(insight)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color("NavyPrimary"))
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.97, blue: 0.94),  // #FDF8F0 warm ivory
                            Color(red: 0.98, green: 0.95, blue: 0.90)   // #FAF2E6 soft cream
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.35),  // #D4AF37 gold
                            Color(red: 0.91, green: 0.84, blue: 0.72).opacity(0.2)    // #E8D5B7 champagne
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Skeleton Line
struct SkeletonLine: View {
    let width: CGFloat  // 0.0 to 1.0
    @State private var shimmer = false
    
    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("NavyPrimary").opacity(0.1))
                .frame(width: geo.size.width * width, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.5),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmer ? geo.size.width : -geo.size.width)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(height: 16)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmer = true
            }
        }
    }
}

// MARK: - Preview
#Preview("With Content") {
    InsightCard(
        insight: "You're more sensitive to tone than words today. Mercury's position in your 3rd house heightens your intuition about communication."
    )
    .padding()
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}

#Preview("Loading") {
    InsightCard(
        insight: "",
        isLoading: true
    )
    .padding()
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}
