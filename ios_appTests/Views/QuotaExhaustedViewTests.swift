import XCTest
import SwiftUI
@testable import ios_app

/// iOS-5: QuotaExhaustedView localization regression tests.
///
/// Verifies the title-resolution logic for guest vs registered vs fair-use cases
/// hits the expected localization keys with their English values. The view body
/// is a SwiftUI tree (no host XCUI surface here), so we assert against the
/// localized-string resolution and the computed properties that gate which
/// branch is taken — not the rendered text node.
///
/// Translations to the other 12 locales are deferred and tracked as iOS-5b.
final class QuotaExhaustedViewTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Force English bundle for deterministic title resolution.
        UserDefaults.standard.set("en", forKey: "appLanguageCode")
    }

    // MARK: - Localized string presence

    func testEnglishLocalizedStringsAreWiredUp() {
        XCTAssertEqual("quota_signup_title".localized, "Sign up to continue!")
        XCTAssertEqual("quota_limit_reached_title".localized, "You have reached your limit")
        XCTAssertEqual("quota_create_account_fallback".localized,
                       "Create an account to keep going and save your progress")
        XCTAssertEqual("quota_usage_restricted_title".localized, "Usage Restricted")
    }

    // MARK: - Title selection (matches the ternary at QuotaExhaustedView body)

    /// The view body picks the title with:
    ///   showContactSupport ? "quota_usage_restricted_title"
    ///                      : (showSignIn ? "quota_signup_title"
    ///                                    : "quota_limit_reached_title")
    /// We re-evaluate that expression here against each scenario.
    private func resolvedTitle(showContactSupport: Bool, showSignIn: Bool) -> String {
        if showContactSupport {
            return "quota_usage_restricted_title".localized
        }
        return showSignIn
            ? "quota_signup_title".localized
            : "quota_limit_reached_title".localized
    }

    func testGuestTitleIsSignUpToContinue() {
        let view = QuotaExhaustedView(isGuest: true)
        // Guest path: showSignIn true, showContactSupport false.
        let title = resolvedTitle(
            showContactSupport: view.quotaError?.isFairUseViolation ?? false,
            showSignIn: view.quotaError?.isGuest ?? view.isGuest
        )
        XCTAssertEqual(title, "Sign up to continue!")
    }

    func testRegisteredUserTitleIsYouHaveReachedYourLimit() {
        let view = QuotaExhaustedView(isGuest: false)
        let title = resolvedTitle(
            showContactSupport: view.quotaError?.isFairUseViolation ?? false,
            showSignIn: view.quotaError?.isGuest ?? view.isGuest
        )
        XCTAssertEqual(title, "You have reached your limit")
    }

    func testFairUseViolationTitleIsUsageRestricted() {
        let info = QuotaErrorInfo(
            reason: "overall_limit_reached",
            planId: "plus",
            featureId: "ai_questions",
            message: nil,
            action: "contact_support",
            suggestedPlan: nil,
            supportEmail: "support@destinyaiastrology.com",
            resetAt: nil
        )
        let view = QuotaExhaustedView(quotaError: info)
        let title = resolvedTitle(
            showContactSupport: view.quotaError?.isFairUseViolation ?? false,
            showSignIn: view.quotaError?.isGuest ?? view.isGuest
        )
        XCTAssertEqual(title, "Usage Restricted")
    }

    // MARK: - Fallback message wiring

    func testGuestDisplayMessageUsesLocalizedFallback() {
        // No quotaError, no customMessage, isGuest=true → quota_create_account_fallback.
        let view = QuotaExhaustedView(isGuest: true)
        XCTAssertNil(view.quotaError)
        XCTAssertNil(view.customMessage)
        // Re-derive what the view's `displayMessage` would produce.
        let showSignIn = view.quotaError?.isGuest ?? view.isGuest
        let msg = showSignIn
            ? "quota_create_account_fallback".localized
            : "upgrade_to_keep_going".localized
        XCTAssertEqual(msg, "Create an account to keep going and save your progress")
    }
}
