import SwiftUI

struct SynergyGaugeView: View {
    let score: Double
    let maxScore: Double
    let boyName: String
    let girlName: String
    let size: CGFloat // New
    let showAvatars: Bool // New
    
    init(score: Double, maxScore: Double = 36, boyName: String, girlName: String, size: CGFloat = 200, showAvatars: Bool = true) {
        self.score = score
        self.maxScore = maxScore
        self.boyName = boyName
        self.girlName = girlName
        self.size = size
        self.showAvatars = showAvatars
    }
    
    @State private var appear = false
    
    // Calculate progress (0.0 to 1.0)
    var progress: CGFloat {
        guard maxScore > 0 else { return 0 }
        return min(CGFloat(score) / CGFloat(maxScore), 1.0)
    }
    
    var body: some View {
        VStack(spacing: -15) { // Negative spacing for overlap effect
            
            // 1. The Gauge Ring
            ZStack {
                // Background Track
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        AppTheme.Colors.gold.opacity(0.15),
                        style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .frame(width: size, height: size)
                
                // Active Progress
                Circle()
                    .trim(from: 0, to: 0.75 * (appear ? progress : 0))
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.Colors.gold, AppTheme.Colors.gold.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .frame(width: size, height: size)
                    .animation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2), value: appear)
                
                // Score Text (Centered)
                VStack(spacing: 2) {
                    Text("\(Int(score))")
                        .font(AppTheme.Fonts.premiumDisplay(size: size * 0.32))
                        .foregroundColor(AppTheme.Colors.gold)
                        .shadow(color: AppTheme.Colors.gold.opacity(0.5), radius: 10)
                    
                    Text("/ \(Int(maxScore))")
                        .font(AppTheme.Fonts.body(size: size * 0.08).weight(.medium))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    VStack(spacing: 0) {
                        Text("Compatibility")
                            .font(AppTheme.Fonts.caption(size: size * 0.05))
                            .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(1)
                        Text("Score")
                            .font(AppTheme.Fonts.caption(size: size * 0.05))
                            .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    .padding(.top, 4)
                }
                
                // Partner Names removed (Moved to Header)
            }
            .padding(.bottom, showAvatars ? 20 : 0)
            
            // 2. Overlapping Avatars (The Connection)
            if showAvatars {
                HStack(spacing: -15) {
                    // Partner 1 (Boy)
                    CircleAvatar(name: boyName, isPrimary: true)
                        .zIndex(1) // On top
                    
                    // Partner 2 (Girl)
                    CircleAvatar(name: girlName, isPrimary: false)
                }
            }
        }
        .padding(.vertical, showAvatars ? 30 : 0)
        .onAppear {
            appear = true
        }
    }
    
    // Helper to extract first name
    private func firstName(_ fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? fullName
    }
}

// Helper Avatar View
struct CircleAvatar: View {
    let name: String
    let isPrimary: Bool
    
    var initial: String {
        guard !name.isEmpty else { return "?" }
        return String(name.prefix(1)).uppercased()
    }
    
    var body: some View {
        ZStack {
            // Glow for primary
            if isPrimary {
                Circle()
                    .fill(AppTheme.Colors.gold.opacity(0.2))
                    .frame(width: 68, height: 68)
                    .blur(radius: 10)
            }
            
            // Border
            Circle()
                .fill(AppTheme.Colors.mainBackground)
                .frame(width: 64, height: 64)
            
            // Content
            Circle()
                .fill(
                    LinearGradient(
                        colors: isPrimary 
                            ? [AppTheme.Colors.gold.opacity(0.2), AppTheme.Colors.gold.opacity(0.05)]
                            : [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(
                            isPrimary ? AppTheme.Colors.gold.opacity(0.5) : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
            
            Text(initial)
                .font(AppTheme.Fonts.premiumDisplay(size: 24))
                .foregroundColor(isPrimary ? AppTheme.Colors.gold : .white)
        }
    }
}
