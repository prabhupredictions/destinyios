import XCTest
import SwiftUI
@testable import ios_app

/// Paywall v2 (Phase 7): Group K — QuotaExhaustedView coverage.
///
/// The view's body relies on private computed properties (`showSignIn`,
/// `showContactSupport`, `showUpgrade`, `shouldShowTrialCTA`, `v2Headline`,
/// `v2Subheadline`, `displayMessage`) plus the pure-function gate
/// `SubscriptionManager.shouldShowTrialButton`. We can't reach the private
/// derivations from a unit test, so the K tests reproduce the same conditional
/// logic in private helpers and assert the resolved strings/state per scenario
/// — same pattern the iOS-5 tests used.
///
/// Existing tests rewritten for v2 copy (paywall_v2_*):
///   K4  testV2KeysWiredUp
///   K5  testGuestRetainsSignUpHeadline
///   K7  testTrialEligibleHeadlineIsV2_AndCtaIsStartFreeWeek
///   K8  testFreeRegisteredEligibleSeesStartFreeWeek_IneligibleSeesUpgrade
///   K10 testNoMaybeLater_OnlyXButtonDismisses
///   K11 testBackendUpgradeMessageOverridesV2Headline
///   K12 testGuestNeverSeesStartFreeWeek
///   K13 testPlusOverallLimitSeesContactSupport_NotTrialCta
///
/// New tests added in Phase 7:
///   K7b  testActiveSubscriberDoesNotSeeTrialCta_ColdStart
///   K10b testInteractiveDismissDisabled_AndCloseButtonHasA11yLabel
///   K13b testFairUsePrecedesTrialCta_EvenIfGateWouldOpen
///   K14  testTrialIneligibleRegisteredUser_FallsBackToUpgradeCopy
///   K15  testSeeCoreLink_RendersOnlyWhenTrialCtaActive
///   K17  testProfileFreeUpgradeCardLabel_TrialAware
///   K18  testLocalizationParity_AllLocalesHave9PaywallV2Keys
///
/// (K16 SubscriptionView Plus-first ordering lives in
/// `SubscriptionViewPlanOrderTests.swift`; K19 buffer-replay-after-direct-purchase
/// lives in `ChatViewModelTests` because it exercises the ChatViewModel buffer.)
final class QuotaExhaustedViewTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.set("en", forKey: "appLanguageCode")
    }

    // MARK: - Helpers that mirror QuotaExhaustedView's private derivations

    /// Mirrors `QuotaExhaustedView.showSignIn`.
    private func showSignIn(quotaError: QuotaErrorInfo?, isGuest: Bool) -> Bool {
        quotaError?.isGuest ?? isGuest
    }

    /// Mirrors `QuotaExhaustedView.showContactSupport`.
    private func showContactSupport(quotaError: QuotaErrorInfo?) -> Bool {
        quotaError?.isFairUseViolation ?? false
    }

    /// Mirrors `QuotaExhaustedView.showUpgrade`.
    private func showUpgrade(quotaError: QuotaErrorInfo?, isGuest: Bool) -> Bool {
        if showSignIn(quotaError: quotaError, isGuest: isGuest) { return false }
        let fair = showContactSupport(quotaError: quotaError)
        return !fair && (quotaError?.action != "wait" || quotaError == nil)
    }

    /// Mirrors `QuotaExhaustedView.shouldShowTrialCTA` but with the trial gate
    /// passed in (since SubscriptionManager state isn't easily injectable).
    private func shouldShowTrialCTA(
        quotaError: QuotaErrorInfo?,
        isGuest: Bool,
        trialGateOpen: Bool
    ) -> Bool {
        guard !showSignIn(quotaError: quotaError, isGuest: isGuest) else { return false }
        guard !showContactSupport(quotaError: quotaError) else { return false }
        return trialGateOpen
    }

    /// Mirrors `QuotaExhaustedView.v2Headline`.
    private func v2Headline(
        quotaError: QuotaErrorInfo?,
        isGuest: Bool,
        trialGateOpen: Bool
    ) -> String {
        if let msg = quotaError?.message, !msg.isEmpty { return msg }
        if shouldShowTrialCTA(quotaError: quotaError, isGuest: isGuest, trialGateOpen: trialGateOpen) {
            return "paywall_v2_headline".localized
        }
        return showSignIn(quotaError: quotaError, isGuest: isGuest)
            ? "quota_signup_title".localized
            : "quota_limit_reached_title".localized
    }

    /// Mirrors the upgrade button label resolution at QuotaExhaustedView body line ~294.
    private func ctaLabel(
        quotaError: QuotaErrorInfo?,
        isGuest: Bool,
        trialGateOpen: Bool
    ) -> String {
        let trial = shouldShowTrialCTA(quotaError: quotaError, isGuest: isGuest, trialGateOpen: trialGateOpen)
        if trial { return "paywall_v2_cta_start_trial".localized }
        return quotaError?.upgradeButtonText ?? "choose_plan_title".localized
    }

    private func makePlusOverallNoUpgradeCta() -> QuotaErrorInfo {
        QuotaErrorInfo(
            reason: "overall_limit_reached",
            planId: "plus",
            featureId: "ai_questions",
            message: nil,
            action: "contact_support",
            suggestedPlan: nil,
            supportEmail: "support@destinyaiastrology.com",
            resetAt: nil
        )
    }

    // MARK: - K4: v2 strings wired up (English baseline)

    func testV2KeysWiredUp() {
        XCTAssertEqual("paywall_v2_headline".localized, "There's more in your chart")
        XCTAssertEqual("paywall_v2_subheadline".localized,
                       "Try Premium free for 7 days and keep asking.")
        XCTAssertEqual("paywall_v2_cta_start_trial".localized, "Start my free week")
        XCTAssertEqual("paywall_v2_bullet_unlimited_questions".localized,
                       "Ask unlimited questions")
        XCTAssertEqual("paywall_v2_bullet_unlimited_matching".localized,
                       "Unlimited Destiny Matching™")
        XCTAssertEqual("paywall_v2_bullet_profiles".localized,
                       "Create profiles for your partner, family, and friends")
        XCTAssertEqual("paywall_v2_bullet_alerts".localized,
                       "Personalized alerts, like \"good day to invest\"")
        XCTAssertEqual("paywall_v2_see_core_link".localized,
                       "Prefer a lighter plan? See Core")
        // Format string keeps a %@ placeholder for currency-adaptive price.
        XCTAssertTrue("paywall_v2_pricing_disclaimer".localized.contains("%@"))
    }

    // MARK: - K5: guest path keeps sign-up headline (no v2 trial copy)

    func testGuestRetainsSignUpHeadline() {
        // Guest, trial gate would (irrelevantly) be open — the showSignIn
        // guard slams it shut.
        let headline = v2Headline(
            quotaError: nil,
            isGuest: true,
            trialGateOpen: true
        )
        XCTAssertEqual(headline, "Sign up to continue!")
        // CTA is not the trial CTA either.
        let cta = ctaLabel(quotaError: nil, isGuest: true, trialGateOpen: true)
        XCTAssertNotEqual(cta, "Start my free week")
    }

    // MARK: - K7: trial-eligible registered user → v2 headline + Start my free week

    func testTrialEligibleHeadlineIsV2_AndCtaIsStartFreeWeek() {
        // Trial gate open: Plus, Apple intro-eligible, no active sub, no conflict.
        let gate = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: true,
            hasActiveSubscription: false
        )
        XCTAssertTrue(gate)

        let headline = v2Headline(
            quotaError: nil,
            isGuest: false,
            trialGateOpen: gate
        )
        XCTAssertEqual(headline, "There's more in your chart")

        let cta = ctaLabel(quotaError: nil, isGuest: false, trialGateOpen: gate)
        XCTAssertEqual(cta, "Start my free week")
    }

    // MARK: - K8: free_registered trial-eligibility branches

    /// Eligible free_registered (Plus card, intro-eligible, no active sub) sees
    /// the trial CTA. (Replaces the prior upgrade_to_keep_going expectation —
    /// v2 promotes this user straight to the trial path.)
    func testFreeRegisteredEligibleSeesStartFreeWeek_IneligibleSeesUpgrade() {
        // Eligible — gate open.
        let openGate = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: true,
            hasActiveSubscription: false
        )
        XCTAssertEqual(
            ctaLabel(quotaError: nil, isGuest: false, trialGateOpen: openGate),
            "Start my free week"
        )

        // Ineligible (Apple says no — already used the intro) — gate closed,
        // CTA falls back to the upgrade copy. Without a quotaError, the
        // fallback is the localized "choose_plan_title".
        let closedGate = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: false,
            hasActiveSubscription: false
        )
        XCTAssertFalse(closedGate)
        let fallback = ctaLabel(quotaError: nil, isGuest: false, trialGateOpen: closedGate)
        XCTAssertNotEqual(fallback, "Start my free week")
        XCTAssertEqual(fallback, "choose_plan_title".localized)
    }

    // MARK: - K10: no Maybe Later / Not now button — only X dismisses

    /// The view body (lines 348-372 of QuotaExhaustedView.swift) renders
    /// exactly three candidate primary buttons (Upgrade, Contact Support,
    /// Sign up) plus the X close button in the header. There is no
    /// "Maybe Later" / "Not now" affordance — this test pins the source so
    /// nobody silently re-adds it.
    func testNoMaybeLater_OnlyXButtonDismisses() throws {
        let path = #file.replacingOccurrences(
            of: "/ios_appTests/Views/QuotaExhaustedViewTests.swift",
            with: "/ios_app/Components/QuotaExhaustedView.swift"
        )
        let source = try String(contentsOfFile: path, encoding: .utf8)
        // Strip single-line comments — we only care about renderable strings.
        let nonCommentLines = source.split(separator: "\n").filter {
            !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//")
        }
        let nonCommentSource = nonCommentLines.joined(separator: "\n")
        XCTAssertFalse(
            nonCommentSource.range(of: #"Maybe Later"#, options: .caseInsensitive) != nil,
            "QuotaExhaustedView must not render a 'Maybe Later' button"
        )
        XCTAssertFalse(
            nonCommentSource.range(of: #"Not now"#, options: .caseInsensitive) != nil,
            "QuotaExhaustedView must not render a 'Not now' button"
        )
        // X button is still present.
        XCTAssertTrue(source.contains("xmark.circle.fill"))
        XCTAssertTrue(source.contains("a11y_close"))
    }

    // MARK: - K11: backend upgrade_cta.message overrides v2 headline (active path)

    /// Promotes K11 from latent → active. When the server passes a non-empty
    /// `upgrade_cta.message` (mapped onto `QuotaErrorInfo.message`), the v2
    /// headline must be that string, NOT `paywall_v2_headline`.
    func testBackendUpgradeMessageOverridesV2Headline() {
        let serverMessage = "Upgrade to Premium for 500 questions/month."
        let info = QuotaErrorInfo(
            reason: "overall_limit_reached",
            planId: "free_registered",
            featureId: "ai_questions",
            message: serverMessage,
            action: "upgrade",
            suggestedPlan: "plus",
            supportEmail: nil,
            resetAt: nil
        )

        // Trial gate open, but backendUpgradeMessage wins.
        let headline = v2Headline(
            quotaError: info,
            isGuest: false,
            trialGateOpen: true
        )
        XCTAssertEqual(headline, serverMessage)
        XCTAssertNotEqual(headline, "paywall_v2_headline".localized)
    }

    // MARK: - K12: guest never sees Start my free week

    func testGuestNeverSeesStartFreeWeek() {
        // Guest via legacy `isGuest: true`.
        let cta1 = ctaLabel(quotaError: nil, isGuest: true, trialGateOpen: true)
        XCTAssertNotEqual(cta1, "Start my free week")

        // Guest via QuotaErrorInfo.planId == "free_guest".
        let guestInfo = QuotaErrorInfo(
            reason: "daily_limit_reached",
            planId: "free_guest",
            featureId: "ai_questions",
            message: nil,
            action: "upgrade",
            suggestedPlan: "core",
            supportEmail: nil,
            resetAt: nil
        )
        let cta2 = ctaLabel(quotaError: guestInfo, isGuest: false, trialGateOpen: true)
        XCTAssertNotEqual(cta2, "Start my free week")
        // Guest CTA path renders Sign up (sign_up_button), not trial.
        XCTAssertTrue(showSignIn(quotaError: guestInfo, isGuest: false))
    }

    // MARK: - K13: Plus overall_limit_reached → Contact Support, NOT trial CTA

    func testPlusOverallLimitSeesContactSupport_NotTrialCta() {
        let info = makePlusOverallNoUpgradeCta()
        XCTAssertTrue(info.isFairUseViolation)
        // Even if trial gate were open, fair-use guard slams it shut.
        let trialActive = shouldShowTrialCTA(
            quotaError: info,
            isGuest: false,
            trialGateOpen: true
        )
        XCTAssertFalse(trialActive)
        // Headline branch is the contact-support title (mirrors body line ~217).
        XCTAssertEqual("quota_usage_restricted_title".localized, "Usage Restricted")
        XCTAssertTrue(showContactSupport(quotaError: info))
        XCTAssertFalse(showUpgrade(quotaError: info, isGuest: false))
    }

    // MARK: - K7b: cold-start active subscriber must NOT see trial CTA

    /// Cold-start scenario: `hasActiveSubscription` is read from UserDefaults
    /// before any reconcile. INV-3 closed the offer-code-redeemed bug here —
    /// pin it again at the QuotaExhaustedView entry point so a regression in
    /// the trial-CTA gate would surface in this file.
    func testActiveSubscriberDoesNotSeeTrialCta_ColdStart() {
        // Simulate cold-start: cache says active, Apple isEligibleForIntroOffer
        // would still answer true (offer-code case).
        let gate = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: true,
            hasActiveSubscription: true
        )
        XCTAssertFalse(gate, "Active subscriber must never see trial CTA")

        let cta = ctaLabel(quotaError: nil, isGuest: false, trialGateOpen: gate)
        XCTAssertNotEqual(cta, "Start my free week")
        let headline = v2Headline(quotaError: nil, isGuest: false, trialGateOpen: gate)
        XCTAssertNotEqual(headline, "There's more in your chart")
    }

    // MARK: - K10b: regression guard for dismiss block + close-button a11y

    /// Pin two things in source:
    ///   1. `.interactiveDismissDisabled()` is wired on the QuotaExhausted
    ///      sheet at ChatView (iOS-10 fix).
    ///   2. The X close button in QuotaExhaustedView keeps its localized
    ///      a11y label so UI tests can find it.
    func testInteractiveDismissDisabled_AndCloseButtonHasA11yLabel() throws {
        let viewPath = #file.replacingOccurrences(
            of: "/ios_appTests/Views/QuotaExhaustedViewTests.swift",
            with: "/ios_app/Components/QuotaExhaustedView.swift"
        )
        let chatPath = #file.replacingOccurrences(
            of: "/ios_appTests/Views/QuotaExhaustedViewTests.swift",
            with: "/ios_app/Views/Chat/ChatView.swift"
        )
        let viewSource = try String(contentsOfFile: viewPath, encoding: .utf8)
        let chatSource = try String(contentsOfFile: chatPath, encoding: .utf8)

        // a11y label on the X close button must be the localized key.
        XCTAssertTrue(
            viewSource.contains(".accessibilityLabel(\"a11y_close\".localized)"),
            "X close button must keep its localized a11y label"
        )

        // .interactiveDismissDisabled() must remain on the QuotaExhausted sheet.
        XCTAssertTrue(
            chatSource.contains(".interactiveDismissDisabled()"),
            "ChatView quota sheet must keep .interactiveDismissDisabled() (iOS-10)"
        )
    }

    // MARK: - K13b: fair-use precedes trial CTA even if gate would open

    /// If somehow `shouldShowTrialButton` would return true (e.g. cache out
    /// of sync) but the user is a Plus user at overall limit with no upgrade
    /// target, fair-use guard must still win and route to Contact Support.
    func testFairUsePrecedesTrialCta_EvenIfGateWouldOpen() {
        let info = makePlusOverallNoUpgradeCta()
        // Pretend the gate function returned true (impossible in practice for
        // an active Plus user, but we test the ordering at the view level).
        let trialActive = shouldShowTrialCTA(
            quotaError: info,
            isGuest: false,
            trialGateOpen: true
        )
        XCTAssertFalse(trialActive,
            "Fair-use guard must close the trial gate before the SubscriptionManager check")
        XCTAssertTrue(showContactSupport(quotaError: info))
    }

    // MARK: - K14: trial-ineligible registered user → upgrade copy + plan picker

    /// Apple's `isEligibleForIntroOffer` is false (user already consumed the
    /// intro on a prior account or device). The v2 popup must:
    ///   - NOT render `paywall_v2_cta_start_trial`
    ///   - Render the legacy `upgradeButtonText` (defers to backend
    ///     `suggestedPlan`, falls back to localized "choose_plan_title")
    ///   - Route through the existing plan-picker SubscriptionView (handled
    ///     in ChatView's onUpgrade closure — pinned by source check).
    func testTrialIneligibleRegisteredUser_FallsBackToUpgradeCopy() throws {
        let gate = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: false,       // Apple says no
            hasActiveSubscription: false
        )
        XCTAssertFalse(gate)

        let info = QuotaErrorInfo(
            reason: "overall_limit_reached",
            planId: "free_registered",
            featureId: "ai_questions",
            message: nil,
            action: "upgrade",
            suggestedPlan: "plus",
            supportEmail: nil,
            resetAt: nil
        )
        let cta = ctaLabel(quotaError: info, isGuest: false, trialGateOpen: gate)
        // 1.7 — production returns the generic "Upgrade to Premium" label here.
        // Showing the server's suggested_plan name (Core/Plus) gaslit users
        // whose billing failed on Plus by saying "Upgrade to Core" (implies
        // downgrade); QuotaExhaustedView.upgradeButtonText now returns
        // "paywall_cta_upgrade_premium" for ALL non-expired reasons. The
        // sheet itself surfaces the plan picker for tier selection.
        XCTAssertEqual(cta, "Upgrade to Premium")
        XCTAssertNotEqual(cta, "Start my free week")

        // ChatView source must still wire the trial-ineligible branch through
        // the existing SubscriptionView plan picker (showSubscription = true).
        let chatPath = #file.replacingOccurrences(
            of: "/ios_appTests/Views/QuotaExhaustedViewTests.swift",
            with: "/ios_app/Views/Chat/ChatView.swift"
        )
        let chatSource = try String(contentsOfFile: chatPath, encoding: .utf8)
        XCTAssertTrue(
            chatSource.contains("showSubscription = true"),
            "Trial-ineligible branch must route through SubscriptionView plan picker"
        )
    }

    // MARK: - K15: See Core link visibility

    /// The "Prefer a lighter plan? See Core" link is rendered ONLY when the
    /// trial CTA gate is open AND the consumer supplied an `onSeeCore`
    /// closure. Tap calls the closure (verified via flag).
    func testSeeCoreLink_RendersOnlyWhenTrialCtaActive() throws {
        let viewPath = #file.replacingOccurrences(
            of: "/ios_appTests/Views/QuotaExhaustedViewTests.swift",
            with: "/ios_app/Components/QuotaExhaustedView.swift"
        )
        let viewSource = try String(contentsOfFile: viewPath, encoding: .utf8)
        // Source must guard the link with both shouldShowTrialCTA AND let
        // onSeeCore = onSeeCore. If either guard is dropped, the link
        // would show up in scenarios it shouldn't.
        XCTAssertTrue(
            viewSource.contains("if shouldShowTrialCTA, let onSeeCore = onSeeCore"),
            "See Core link must be guarded by `shouldShowTrialCTA && onSeeCore != nil`"
        )

        // Closure invocation: flag flips when the view's tap handler fires.
        var seeCoreFired = false
        let view = QuotaExhaustedView(
            isGuest: false,
            onSeeCore: { seeCoreFired = true }
        )
        XCTAssertNotNil(view.onSeeCore)
        view.onSeeCore?()
        XCTAssertTrue(seeCoreFired)
    }

    // MARK: - K17: ProfileView freeUpgradeCard label is trial-aware

    /// The label resolution at ProfileView.swift line ~600 maps to:
    ///   - guest → sign_up_button
    ///   - trial-eligible (gate open) → paywall_v2_cta_start_trial
    ///   - else → upgrade_to_premium
    /// We can't render ProfileView in isolation (depends on @StateObject
    /// graph), but the underlying decision tree is pure on the trial gate.
    func testProfileFreeUpgradeCardLabel_TrialAware() {
        func label(isGuest: Bool, gate: Bool) -> String {
            if isGuest { return "sign_up_button".localized }
            if gate { return "paywall_v2_cta_start_trial".localized }
            return "upgrade_to_premium".localized
        }

        XCTAssertEqual(label(isGuest: true,  gate: true),  "sign_up_button".localized)
        XCTAssertEqual(label(isGuest: true,  gate: false), "sign_up_button".localized)
        XCTAssertEqual(label(isGuest: false, gate: true),  "Start my free week")
        XCTAssertEqual(label(isGuest: false, gate: false), "upgrade_to_premium".localized)

        // Source pin: ProfileView must reference all three keys.
        let profilePath = #file.replacingOccurrences(
            of: "/ios_appTests/Views/QuotaExhaustedViewTests.swift",
            with: "/ios_app/Views/Profile/ProfileView.swift"
        )
        guard let profileSource = try? String(contentsOfFile: profilePath, encoding: .utf8) else {
            XCTFail("ProfileView.swift not found at \(profilePath)")
            return
        }
        XCTAssertTrue(profileSource.contains("paywall_v2_cta_start_trial"))
        XCTAssertTrue(profileSource.contains("upgrade_to_premium"))
        XCTAssertTrue(profileSource.contains("sign_up_button"))
        // And it must use the central gate, not a private duplicate of the logic.
        XCTAssertTrue(profileSource.contains("SubscriptionManager.shouldShowTrialButton("))
    }

    // MARK: - K18: localization parity — every locale has all paywall_v2_* keys

    /// CI gate: every .lproj/Localizable.strings must contain all 9
    /// paywall_v2_* keys. (The audit said 8; the headline+subheadline+CTA
    /// + 4 bullets + see-core link + pricing-disclaimer = 9 keys.) If we
    /// add or remove a v2 key, this test pins the parity check.
    func testLocalizationParity_AllLocalesHave9PaywallV2Keys() throws {
        let projectRoot = #file.replacingOccurrences(
            of: "/ios_appTests/Views/QuotaExhaustedViewTests.swift",
            with: "/ios_app"
        )
        let fm = FileManager.default
        let entries = try fm.contentsOfDirectory(atPath: projectRoot)
        let lprojDirs = entries.filter { $0.hasSuffix(".lproj") }
        XCTAssertGreaterThanOrEqual(lprojDirs.count, 13,
            "Expected at least 13 .lproj directories under \(projectRoot)")

        let expectedKeys = [
            "paywall_v2_headline",
            "paywall_v2_subheadline",
            "paywall_v2_bullet_unlimited_questions",
            "paywall_v2_bullet_unlimited_matching",
            "paywall_v2_bullet_profiles",
            "paywall_v2_bullet_alerts",
            "paywall_v2_cta_start_trial",
            "paywall_v2_pricing_disclaimer",
            "paywall_v2_see_core_link"
        ]

        for dir in lprojDirs {
            let path = "\(projectRoot)/\(dir)/Localizable.strings"
            guard fm.fileExists(atPath: path) else {
                XCTFail("Missing Localizable.strings in \(dir)")
                continue
            }
            let source = try String(contentsOfFile: path, encoding: .utf8)
            for key in expectedKeys {
                XCTAssertTrue(
                    source.contains("\"\(key)\""),
                    "\(dir)/Localizable.strings is missing key \(key)"
                )
            }
        }
    }
}
