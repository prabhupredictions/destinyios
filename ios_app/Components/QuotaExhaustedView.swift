import SwiftUI

/// Paywall popup shown when user's quota is exhausted
/// Follows modern UX best practices (OpenAI/Gemini style):
/// - Appears only when quota is exhausted (not before)
/// - Uses Loss Aversion psychology - user has already invested time
/// - Offers clear upgrade path with value proposition
struct QuotaExhaustedView: View {
    @Environment(\.dismiss) private var dismiss
    
    var isGuest: Bool = false
    var onSignIn: (() -> Void)?
    var onUpgrade: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header illustration
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("GoldAccent").opacity(0.3), Color("GoldAccent").opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(Color("GoldAccent"))
                    }
                    .padding(.top, 24)
                    
                    // Title
                    VStack(spacing: 12) {
                        Text("You've Unlocked Great Insights!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color("NavyPrimary"))
                            .multilineTextAlignment(.center)
                        
                        Text("To continue exploring your cosmic path, choose an option below")
                            .font(.system(size: 16))
                            .foregroundColor(Color("TextDark").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        benefitRow(icon: "infinity", text: "Unlimited questions with Premium")
                        benefitRow(icon: "clock.fill", text: "24/7 access to your astrologer")
                        benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Detailed life predictions")
                        benefitRow(icon: "heart.fill", text: "Compatibility analysis")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("NavyPrimary").opacity(0.03))
                    )
                    .padding(.horizontal, 20)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Premium button
                        Button(action: { 
                            onUpgrade?()
                            dismiss()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 16))
                                Text("Upgrade to Premium")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color("NavyPrimary"), Color("NavyPrimary").opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color("NavyPrimary").opacity(0.3), radius: 10, y: 5)
                        }
                        
                        // Sign in button (for guests only)
                        if isGuest {
                            Button(action: { 
                                onSignIn?()
                                dismiss()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                    Text("Sign In for More Questions")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(Color("NavyPrimary"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color("NavyPrimary"), lineWidth: 2)
                                )
                            }
                        }
                        
                        // Maybe later
                        Button(action: { dismiss() }) {
                            Text("Maybe Later")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("TextDark").opacity(0.5))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .background(Color.white)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color("GoldAccent"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
            
            Spacer()
        }
    }
}

#Preview {
    QuotaExhaustedView(isGuest: true)
}
