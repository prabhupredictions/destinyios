//
//  SubscriptionManagerINV3Tests.swift
//  ios_appTests
//
//  INV-3: Trial button must NEVER show if user has any active subscription.
//
//  These tests pin the gating logic at SubscriptionManager.shouldShowTrialButton(...)
//  so the prabhukivaani-style bug (offer-code-redeemed user shown trial button)
//  cannot regress.
//

import XCTest
@testable import ios_app

final class SubscriptionManagerINV3Tests: XCTestCase {

    // MARK: - The critical bug case (prabhukivaani scenario)

    /// User has active Plus from offer code. Apple's isEligibleForIntroOffer
    /// is still true (because offer code is not an "intro offer"). Trial
    /// button MUST NOT show.
    func test_inv3_offer_code_redeemed_user_does_not_see_trial_button() {
        let result = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: true,        // Apple's API still says yes
            hasActiveSubscription: true       // BUT user has active sub
        )
        XCTAssertFalse(result,
            "Trial button must be hidden when user has an active subscription, " +
            "even if Apple's isEligibleForIntroOffer returns true (offer code case)")
    }

    // MARK: - Happy paths

    /// Brand new user, no subscription, Apple confirms intro-eligible.
    /// Trial button SHOULD show.
    func test_inv3_brand_new_user_sees_trial_button() {
        let result = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: true,
            hasActiveSubscription: false
        )
        XCTAssertTrue(result,
            "Brand new user (no sub, intro-eligible) must see trial button")
    }

    // MARK: - Each gate independently rejects

    /// Trial only offered on Plus plan. Core plan must never show trial.
    func test_inv3_core_plan_never_shows_trial() {
        let result = SubscriptionManager.shouldShowTrialButton(
            planId: "core",
            isPlusTrialEligible: true,
            hasActiveSubscription: false
        )
        XCTAssertFalse(result,
            "Trial button must only render on the Plus plan card")
    }

    /// Apple says ineligible (e.g. user already used the intro offer
    /// previously). Trial button must not show.
    func test_inv3_apple_says_ineligible_hides_trial() {
        let result = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: false,       // Apple says no
            hasActiveSubscription: false
        )
        XCTAssertFalse(result,
            "Apple's isEligibleForIntroOffer=false must hide trial button")
    }

    /// User has active sub but Apple wrongly claims eligibility. Trial
    /// button must not show — defense in depth.
    func test_inv3_active_sub_with_apple_claiming_eligibility_hides_trial() {
        let result = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: true,
            hasActiveSubscription: true
        )
        XCTAssertFalse(result,
            "When user has an active sub, trial button must hide regardless of " +
            "Apple's intro-eligibility flag")
    }

    /// Both gates fail simultaneously. Should still hide.
    func test_inv3_double_negative_hides_trial() {
        let result = SubscriptionManager.shouldShowTrialButton(
            planId: "plus",
            isPlusTrialEligible: false,
            hasActiveSubscription: true
        )
        XCTAssertFalse(result, "All-no must hide")
    }

    // MARK: - Edge cases

    /// Unknown plan (e.g. "free_registered" or some new plan we add later)
    /// should default to hiding the trial button.
    func test_inv3_unknown_plan_hides_trial() {
        for planId in ["free_registered", "free_guest", "premium", "elite", ""] {
            let result = SubscriptionManager.shouldShowTrialButton(
                planId: planId,
                isPlusTrialEligible: true,
                hasActiveSubscription: false
            )
            XCTAssertFalse(result,
                "Unknown plan '\(planId)' must default to hiding the trial button")
        }
    }
}
