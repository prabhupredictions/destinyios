import SwiftUI

/// Card displaying today's personalized astrological insight
struct InsightCard: View {
    let insight: String
    var icon: String = "sun.max.fill"
    var title: String = "Today's Insight"
    var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("GoldAccent"))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
                
                Spacer()
            }
            
            // Content
            if isLoading {
                // Skeleton loading
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLine(width: 0.9)
                    SkeletonLine(width: 0.75)
                    SkeletonLine(width: 0.5)
                }
            } else {
                Text(insight)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("NavyPrimary"))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("NavyPrimary").opacity(0.03),
                            Color("GoldAccent").opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("NavyPrimary").opacity(0.08), lineWidth: 1)
        )
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
