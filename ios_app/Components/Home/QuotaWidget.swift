import SwiftUI

/// Widget showing remaining question quota with progress bar and upgrade prompts
struct QuotaWidget: View {
    let remaining: Int
    let total: Int
    let renewalDate: String
    var isGuest: Bool = false
    var onUpgradeTap: (() -> Void)?
    var onSignInTap: (() -> Void)?
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }
    
    private var progressColor: Color {
        if progress > 0.5 {
            return AppTheme.Colors.gold
        } else if progress > 0.2 {
            return Color.orange
        } else {
            return Color.red.opacity(0.8)
        }
    }
    
    // Progressive message based on quota
    private var quotaMessage: String? {
        if remaining == 0 {
            return isGuest 
                ? "You've used all 3 free questions. Sign in for 10 more or upgrade to Premium!"
                : "You've used all your free questions. Upgrade to Premium for unlimited access!"
        } else if remaining == 1 {
            return "⚠️ Last question remaining!"
        } else if remaining <= 2 && isGuest {
            return "Sign in for 10 questions, or go Premium for unlimited"
        }
        return nil
    }
    
    private var showUpgradeOptions: Bool {
        remaining <= 1 || (remaining <= 2 && isGuest)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("\(remaining)/\(total) questions left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
                
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("NavyPrimary").opacity(0.1))
                        .frame(height: 8)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * progress, remaining > 0 ? 8 : 0), height: 8)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 8)
            
            // Progressive upgrade message
            if let message = quotaMessage {
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(remaining == 0 ? .red : Color("NavyPrimary").opacity(0.7))
                    .lineLimit(2)
            }
            
            // Upgrade options
            if showUpgradeOptions {
                HStack(spacing: 12) {
                    if isGuest {
                        // Sign in button for guests
                        Button(action: { onSignInTap?() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                Text("Sign In")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Color("NavyPrimary"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("NavyPrimary"), lineWidth: 1.5)
                            )
                        }
                    }
                    
                    // Premium button
                    Button(action: { onUpgradeTap?() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                            Text("Go Premium")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 4)
            } else {
                // Renewal text when not showing upgrade
                Text("Renews \(renewalDate)")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(remaining == 0 ? Color.red.opacity(0.05) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(remaining == 0 ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        QuotaWidget(remaining: 3, total: 3, renewalDate: "Jan 1", isGuest: true)
        QuotaWidget(remaining: 2, total: 3, renewalDate: "Jan 1", isGuest: true)
        QuotaWidget(remaining: 1, total: 3, renewalDate: "Jan 1", isGuest: true)
        QuotaWidget(remaining: 0, total: 3, renewalDate: "Jan 1", isGuest: true)
    }
    .padding()
    .background(Color(red: 0.96, green: 0.95, blue: 0.98))
}
