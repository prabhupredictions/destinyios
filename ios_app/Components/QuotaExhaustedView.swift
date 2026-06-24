import SwiftUI
import StoreKit

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
    /// Authoritative server-set flag. When non-nil, takes precedence over
    /// the heuristic fallback below. Server returns true ONLY when the
    /// effective plan is Plus AND a feature's overall lifetime cap is hit.
    /// `var` (not `let`) so the synthesized memberwise init exposes it as
    /// a parameter — Swift doesn't synthesize init params for `let` fields
    /// with default values.
    var serverIsFairUseViolation: Bool? = nil

    /// True when the user has hit a fair-use ceiling — render Contact
    /// Support flow instead of an upgrade paywall.
    ///
    /// Source-of-truth order:
    ///   1. Server-set `serverIsFairUseViolation` (added 2026-06-16)
    ///   2. Heuristic (back-compat for older API responses): plan_id == plus
    ///      AND reason == overall_limit_reached AND no upgrade target
    var isFairUseViolation: Bool {
        if let server = serverIsFairUseViolation {
            return server
        }
        // Heuristic fallback for older API responses without the flag.
        guard reason == "overall_limit_reached", planId == "plus" else { return false }
        if let suggested = suggestedPlan, !suggested.isEmpty, suggested != "plus" {
            return false
        }
        return true
    }
    
    /// Determine if user should see sign in option (guest only)
    var isGuest: Bool {
        return planId == "free_guest"
    }
    
    /// Display message (prefer backend message, fallback to localized).
    /// Backend returns null `upgrade_cta.message` for the lifetime-cap case
    /// (count == 1) so users see translated text instead of raw counts like
    /// "You need 1 but only have 0 remaining" — see quota_service.py.
    var displayMessage: String {
        if let msg = message, !msg.isEmpty {
            return msg
        }
        // Fallback messages — all 13 locales
        if isFairUseViolation {
            return "quota_fallback_fair_use".localized
        }
        switch reason {
        case "subscription_expired":
            return "subscription_expired_body".localized
        case "daily_limit_reached":
            return "quota_fallback_daily_limit".localized
        case "overall_limit_reached":
            return "quota_fallback_overall_limit".localized
        default:
            return "quota_fallback_default".localized
        }
    }
    
    /// Button text for upgrade
    var upgradeButtonText: String {
        // Subscription_expired = user has history; CTA says "Renew" not
        // "Upgrade". The button still leads to StoreKit (purchasePlusDirect)
        // but the copy reflects intent.
        if reason == "subscription_expired" {
            return "subscription_expired_cta".localized
        }
        // Generic "Upgrade to Premium" for all other quota-exhausted
        // states (free, billing_retry, etc.). Showing the server's
        // suggested_plan name (Core/Plus) here gaslit users — e.g. a
        // user whose billing failed on Plus saw "Upgrade to Core",
        // implying a downgrade. Generic copy avoids that and lets the
        // sheet itself surface the plan picker. Keys still localized
        // in every .lproj bundle (paywall localization Phase 6).
        return "paywall_cta_upgrade_premium".localized
    }
}

/// Paywall popup shown when user's quota is exhausted
/// Dynamic messages based on plan, feature, and limit type
struct QuotaExhaustedView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    /// W5 paywall-context (added 2026-06-18): different headline/subheadline
    /// per surface that triggered the paywall. Default `.chat` keeps every
    /// pre-existing caller (legacy QuotaExhaustedView() invocations) on the
    /// "There's more in your chart" copy.
    enum Context {
        case chat
        case compatibility
    }
    var context: Context = .chat

    // New: Dynamic quota error info from backend
    var quotaError: QuotaErrorInfo?

    // Legacy: Keep for backward compatibility
    var isGuest: Bool = false
    var customMessage: String?
    var onSignIn: (() -> Void)?
    /// Paywall v2: callback receives the *rendered* trial-CTA state so the
    /// caller routes on the same snapshot the user saw. Without this, the
    /// caller would re-query SubscriptionManager and could land on the
    /// opposite branch if `hasActiveSubscription` or `isPlusTrialEligible`
    /// flipped between paint and tap (Transaction.updates fires async).
    var onUpgrade: ((Bool) -> Void)?
    /// Paywall v2: secondary "See Core" tap-target. Wired in Phase 6
    /// to push SubscriptionView so trial-eligible users can still pick the
    /// lighter plan. nil-safe — link is rendered only when the closure is
    /// supplied AND the trial-CTA gate is open.
    var onSeeCore: (() -> Void)?
    
    // Computed properties using new error info or legacy props
    private var showSignIn: Bool {
        quotaError?.isGuest ?? isGuest
    }
    
    private var showContactSupport: Bool {
        quotaError?.isFairUseViolation ?? false
    }
    
    private var showUpgrade: Bool {
        // GUEST RULE: Never show Upgrade for guests - only Sign In
        if showSignIn {
            return false
        }
        return !showContactSupport && (quotaError?.action != "wait" || quotaError == nil)
    }
    
    private var displayMessage: String {
        if let msg = quotaError?.displayMessage {
            return msg
        }
        if let custom = customMessage {
            return custom
        }
        // Different message for guests vs registered users
        return showSignIn ? "quota_create_account_fallback".localized : "upgrade_to_keep_going".localized
    }
    
    private var upgradeText: String {
        quotaError?.upgradeButtonText ?? "choose_plan_title".localized
    }

    // MARK: - Paywall v2 derivations
    //
    // shouldShowTrialCTA closes the trial gate (iOS-7 / iOS-12 / iOS-13 preserved):
    //   - never for guests (showSignIn) — guest path stays sign-up only
    //   - never for fair-use violations — Contact Support path stays
    //   - else delegate to the existing pure SubscriptionManager.shouldShowTrialButton
    //     (planId="plus", isPlusTrialEligible, hasActiveSubscription, hasConflict default)
    private var shouldShowTrialCTA: Bool {
        guard !showSignIn else { return false }
        guard !showContactSupport else { return false }
        return SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: subscriptionManager.isPlusTrialEligible,
            hasActiveSubscription: subscriptionManager.hasActiveSubscription,
            hasEverSubscribed: QuotaManager.shared.hasEverSubscribed
        )
    }

    /// Backend-supplied upgrade headline (iOS-11). Promoted to active when the
    /// upgrade-CTA payload carried a non-empty `message`.
    private var backendUpgradeMessage: String? {
        if let msg = quotaError?.message, !msg.isEmpty { return msg }
        return nil
    }

    /// True when the backend's reason is "subscription_expired" — a lapsed
    /// paid user is blocked entirely from quota features until they renew.
    /// Distinct from quota-cap reached: paywall says "ended", CTA says
    /// "Renew" (not "Choose a plan" — they already have history).
    private var isSubscriptionExpired: Bool {
        quotaError?.reason == "subscription_expired"
    }

    /// Headline shown on the upgrade path (showUpgrade && !isFairUseViolation):
    ///   1. Subscription expired → "Your subscription has ended"
    ///   2. Daily limit → "Daily limit reached" (resets at midnight UTC)
    ///   3. Backend `upgrade_cta.message` (iOS-11), if non-empty
    ///   4. Trial-eligible AND context=.compatibility → compatibility-specific headline
    ///   5. Trial-eligible → paywall_v2_headline
    ///   6. Otherwise → existing localized title (iOS-5 fallback preserved)
    private var v2Headline: String {
        // Lapsed paid user — their subscription ended, they need to renew.
        // This takes precedence over trial CTA (they have history) and
        // over the daily-limit branch (different paywall entirely).
        if isSubscriptionExpired {
            return "subscription_expired_title".localized
        }
        // Daily-reset headline takes precedence over the upgrade-CTA copy:
        // "You have reached your limit" implies permanent, but daily limits
        // reset at midnight UTC. Tell the user that explicitly.
        if quotaError?.reason == "daily_limit_reached" {
            return "quota_daily_limit_title".localized
        }
        if let msg = backendUpgradeMessage { return msg }
        if shouldShowTrialCTA {
            switch context {
            case .compatibility: return "paywall_v2_headline_compatibility".localized
            case .chat:          return "paywall_v2_headline".localized
            }
        }
        return showSignIn
            ? "quota_signup_title".localized
            : "quota_limit_reached_title".localized
    }

    /// Subheadline shown on the upgrade path:
    ///   - Subscription expired → subscription_expired_body (renew copy)
    ///   - Trial-eligible AND context=.compatibility → compatibility-specific copy
    ///   - Trial-eligible → paywall_v2_subheadline
    ///   - Otherwise → existing displayMessage (preserves daily_limit_reset_time / iOS-9)
    private var v2Subheadline: String {
        if isSubscriptionExpired { return "subscription_expired_body".localized }
        if shouldShowTrialCTA {
            switch context {
            case .compatibility: return "paywall_v2_subheadline_compatibility".localized
            case .chat:          return "paywall_v2_subheadline".localized
            }
        }
        return displayMessage
    }

    /// Currency-adaptive (Q2) display price for the trial disclaimer.
    /// Returns nil when StoreKit hasn't loaded the monthly Plus product yet
    /// (cold start / poor network). Caller picks a price-less localized
    /// disclaimer instead of a hardcoded "$7.99" that would mismatch the
    /// real StoreKit price for non-US users — App Store guideline 3.1.2.
    private var trialDisplayPrice: String? {
        subscriptionManager.monthlyProduct(for: "plus")?.displayPrice
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Drag Indicator and Close Button
            ZStack(alignment: .top) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Close Button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.8))
                    }
                    .accessibilityLabel("a11y_close".localized)
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
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
                    .padding(.top, 12)
                    
                    // Title - different for fair use, guest, and v2 trial path
                    VStack(spacing: 8) {
                        if showContactSupport {
                            Text("quota_usage_restricted_title".localized)
                                .font(AppTheme.Fonts.title(size: 24))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(displayMessage)
                                .font(AppTheme.Fonts.body(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        } else if showUpgrade {
                            // Paywall v2 path (registered users): backend message →
                            // trial headline → existing fallback. Subheadline:
                            // trial copy or existing displayMessage (iOS-9 preserved).
                            Text(v2Headline)
                                .font(AppTheme.Fonts.title(size: 24))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(v2Subheadline)
                                .font(AppTheme.Fonts.body(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        } else {
                            // Guest sign-up path (iOS-12 preserved).
                            Text(showSignIn ? "quota_signup_title".localized : "quota_limit_reached_title".localized)
                                .font(AppTheme.Fonts.title(size: 24))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(displayMessage)
                                .font(AppTheme.Fonts.body(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }

                    // Benefits - different for guests vs paid users
                    if !showContactSupport {
                        VStack(alignment: .leading, spacing: 12) {
                            if showSignIn {
                                // Guest-specific benefits (sign-up).
                                // Localized 2026-06-24: previously hardcoded
                                // English broke 12 non-English locales.
                                benefitRow(icon: "bubble.left.and.bubble.right.fill", text: "quota_guest_bullet_ask_more".localized)
                                benefitRow(icon: "person.circle.fill", text: "quota_guest_bullet_save_chart".localized)
                                benefitRow(icon: "sparkles", text: "quota_guest_bullet_daily_insights".localized)
                                benefitRow(icon: "heart.fill", text: "quota_guest_bullet_destiny_matching".localized)
                                benefitRow(icon: "arrow.turn.down.right", text: "quota_guest_bullet_followups".localized)
                            } else {
                                // Paywall v2: 4-bullet trial benefits.
                                benefitRow(icon: "infinity", text: "paywall_v2_bullet_unlimited_questions".localized)
                                benefitRow(icon: "heart.fill", text: "paywall_v2_bullet_unlimited_matching".localized)
                                benefitRow(icon: "person.3.fill", text: "paywall_v2_bullet_profiles".localized)
                                benefitRow(icon: "bell.fill", text: "paywall_v2_bullet_alerts".localized)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
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
                                // Expired user → "Renew" intent. Pass true so
                                // callers route to purchasePlusDirect() (the
                                // same StoreKit-direct path trial users take).
                                // The user already has subscription history;
                                // no plan-picker needed.
                                onUpgrade?(shouldShowTrialCTA || isSubscriptionExpired)
                                dismiss()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 16))
                                    Text(isSubscriptionExpired
                                         ? "subscription_expired_cta".localized
                                         : (shouldShowTrialCTA
                                            ? "paywall_v2_cta_start_trial".localized
                                            : upgradeText))
                                        .font(AppTheme.Fonts.title(size: 17))
                                }
                                .foregroundColor(AppTheme.Colors.textOnGold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppTheme.Colors.premiumGradient)
                                .cornerRadius(16)
                                .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 10, y: 5)
                            }

                            // Trial-only pricing disclaimer (Q2: currency-adaptive
                            // via Product.displayPrice). When StoreKit hasn't
                            // loaded yet, render a price-less localized string
                            // instead of a US-dollar fallback that would mismatch
                            // the real localized price (App Store guideline 3.1.2).
                            if shouldShowTrialCTA {
                                Text(
                                    trialDisplayPrice.map { price in
                                        String(format: "paywall_v2_pricing_disclaimer".localized, price)
                                    } ?? "paywall_v2_pricing_disclaimer_loading".localized
                                )
                                    .font(AppTheme.Fonts.body(size: 12))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }

                            // Trial-only "See Core" secondary link. Wired in Phase 6.
                            if shouldShowTrialCTA, let onSeeCore = onSeeCore {
                                Button(action: { onSeeCore() }) {
                                    Text("paywall_v2_see_core_link".localized)
                                        .font(AppTheme.Fonts.body(size: 14))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .underline()
                                }
                                .buttonStyle(.plain)
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
                                    Text("contact_support".localized)
                                        .font(AppTheme.Fonts.body(size: 16).weight(.semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue)
                                .cornerRadius(16)
                            }
                        }

                        // Sign up button (for guests only)
                        if showSignIn && !showContactSupport {
                            Button(action: {
                                onSignIn?()
                                dismiss()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                    Text("sign_up_button".localized)
                                        .font(AppTheme.Fonts.body(size: 16).weight(.semibold))
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

                        // Paywall v2: "Maybe later" / "not now" removed. The X close
                        // button (above) is the sole dismiss affordance. ChatView's
                        // .interactiveDismissDisabled() (iOS-10) is preserved.
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    Spacer(minLength: 20)
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
