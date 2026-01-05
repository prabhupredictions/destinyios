import SwiftUI

/// Quota error information passed from backend
struct QuotaErrorInfo {
    let reason: String?          // "daily_limit_reached", "overall_limit_reached"
    let planId: String?          // "free_guest", "free_registered", "core", "plus"
    let featureId: String?       // "ai_questions", "compatibility"
    let message: String?         // User-friendly message from backend
    let action: String?          // "upgrade", "wait", "contact_support"
    let suggestedPlan: String?   // "core", "plus"
    let supportEmail: String?    // "support@destinyaiastrology.com"
    let resetAt: String?         // ISO datetime for daily reset
    
    /// Determine if this is a fair use violation (Plus user at overall limit)
    var isFairUseViolation: Bool {
        return reason == "overall_limit_reached" && planId == "plus"
    }
    
    /// Determine if user should see sign in option (guest only)
    var isGuest: Bool {
        return planId == "free_guest"
    }
    
    /// Display message (prefer backend message, fallback to generated)
    var displayMessage: String {
        if let msg = message, !msg.isEmpty {
            return msg
        }
        // Fallback messages
        if isFairUseViolation {
            return "Fair use violation. Your usage has been restricted. Please contact support@destinyaiastrology.com for assistance."
        }
        switch reason {
        case "daily_limit_reached":
            return "You've been busy today! Come back tomorrow at 12:00 AM UTC, or upgrade for higher limits."
        case "overall_limit_reached":
            return "You've reached your limit. Upgrade to continue your cosmic journey."
        default:
            return "Upgrade to unlock unlimited access."
        }
    }
    
    /// Button text for upgrade
    var upgradeButtonText: String {
        if let plan = suggestedPlan?.capitalized {
            return "Upgrade to \(plan)"
        }
        return "Upgrade Now"
    }
}

/// Paywall popup shown when user's quota is exhausted
/// Dynamic messages based on plan, feature, and limit type
struct QuotaExhaustedView: View {
    @Environment(\.dismiss) private var dismiss
    
    // New: Dynamic quota error info from backend
    var quotaError: QuotaErrorInfo?
    
    // Legacy: Keep for backward compatibility
    var isGuest: Bool = false
    var customMessage: String?
    var onSignIn: (() -> Void)?
    var onUpgrade: (() -> Void)?
    
    // Computed properties using new error info or legacy props
    private var showSignIn: Bool {
        quotaError?.isGuest ?? isGuest
    }
    
    private var showContactSupport: Bool {
        quotaError?.isFairUseViolation ?? false
    }
    
    private var showUpgrade: Bool {
        !showContactSupport && (quotaError?.action != "wait" || quotaError == nil)
    }
    
    private var displayMessage: String {
        quotaError?.displayMessage ?? customMessage ?? "To continue exploring your cosmic path, choose an option below"
    }
    
    private var upgradeText: String {
        quotaError?.upgradeButtonText ?? "Upgrade to Premium"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header illustration - different for fair use violation
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (showContactSupport ? Color.red : AppTheme.Colors.gold).opacity(0.3),
                                        (showContactSupport ? Color.red : AppTheme.Colors.gold).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: showContactSupport ? "exclamationmark.triangle.fill" : "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(showContactSupport ? .red : AppTheme.Colors.gold)
                    }
                    .padding(.top, 24)
                    
                    // Title - different for fair use
                    VStack(spacing: 12) {
                        Text(showContactSupport ? "Usage Restricted" : "You've Unlocked Great Insights!")
                            .font(AppTheme.Fonts.title(size: 24))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(displayMessage)
                            .font(AppTheme.Fonts.body(size: 16))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Benefits - hide for fair use violation
                    if !showContactSupport {
                        VStack(alignment: .leading, spacing: 16) {
                            benefitRow(icon: "infinity", text: "Unlimited questions")
                            benefitRow(icon: "heart.fill", text: "Unlimited Destiny Matching™")
                            benefitRow(icon: "person.3.fill", text: "Multiple profiles")
                            benefitRow(icon: "sparkles", text: "Early access to new features")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.Colors.cardBackground)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Upgrade button (hide for fair use violation)
                        if showUpgrade {
                            Button(action: { 
                                onUpgrade?()
                                dismiss()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 16))
                                    Text(upgradeText)
                                        .font(AppTheme.Fonts.title(size: 17))
                                }
                                .foregroundColor(AppTheme.Colors.textOnGold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppTheme.Colors.premiumGradient)
                                .cornerRadius(16)
                                .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 10, y: 5)
                            }
                        }
                        
                        // Contact Support button (fair use violation only)
                        if showContactSupport {
                            Button(action: { 
                                openSupportEmail()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 16))
                                    Text("Contact Support")
                                        .font(AppTheme.Fonts.title(size: 17))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue)
                                .cornerRadius(16)
                            }
                        }
                        
                        // Sign in button (for guests only)
                        if showSignIn && !showContactSupport {
                            Button(action: { 
                                onSignIn?()
                                dismiss()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                    Text("Sign In for More")
                                        .font(AppTheme.Fonts.title(size: 17))
                                }
                                .foregroundColor(AppTheme.Colors.gold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.Colors.gold, lineWidth: 2)
                                )
                            }
                        }
                        
                        // Maybe later
                        Button(action: { dismiss() }) {
                            Text("Maybe Later")
                                .font(AppTheme.Fonts.body(size: 15))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .background(AppTheme.Colors.mainBackground)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.Colors.gold)
                .frame(width: 24)
            
            Text(text)
                .font(AppTheme.Fonts.body(size: 15))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
        }
    }
    
    private func openSupportEmail() {
        let email = quotaError?.supportEmail ?? "support@destinyaiastrology.com"
        if let url = URL(string: "mailto:\(email)?subject=Fair%20Use%20Support%20Request") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

#Preview("Normal Quota") {
    QuotaExhaustedView(isGuest: false)
}

#Preview("Guest") {
    QuotaExhaustedView(isGuest: true)
}

#Preview("Fair Use Violation") {
    QuotaExhaustedView(
        quotaError: QuotaErrorInfo(
            reason: "overall_limit_reached",
            planId: "plus",
            featureId: "ai_questions",
            message: "Fair use violation. Your usage has been restricted. Please contact support@destinyaiastrology.com for assistance.",
            action: "contact_support",
            suggestedPlan: nil,
            supportEmail: "support@destinyaiastrology.com",
            resetAt: nil
        )
    )
}
