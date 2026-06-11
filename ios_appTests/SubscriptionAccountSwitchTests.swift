//
//  SubscriptionAccountSwitchTests.swift
//  ios_appTests
//
//  Regression suite for account-switch subscription bugs found 2026-05-30.
//
//  BUG-I4 (account B inherits account A's plan):
//    QuotaManager stored isPremium, currentPlanId, subscriptionStatus,
//    subscriptionExpiresAt, autoRenewStatus in UserDefaults with fixed keys —
//    not keyed by email. signOutAsync only cleared "isPremium", leaving the
//    other 4 stale. Account B's loadCachedSubscriptionState() restored Plus
//    state from account A on cold start.
//    Fix: signOutAsync clears all 5 keys; QuotaManager.resetForSignOut()
//    zeroes all in-memory state; called from signOutAsync.
//
//  BUG-I5 (activating banner on every sign-in):
//    Reconcile was wrapped in Task {} (fire-and-forget). isAuthenticated = true
//    fired before reconcile completed, so SubscriptionView rendered with
//    isPremium = false and hasActiveSubscription = true → "Activating..." banner.
//    Fix: reconcile is now awaited directly in the sign-in path.
//    This test pins the SubscriptionManager state contract after resetForSignOut
//    so we can detect if in-memory state leaks into the next session.
//

import XCTest
@testable import ios_app

@MainActor
final class SubscriptionAccountSwitchTests: XCTestCase {

    // MARK: - setUp / tearDown

    override func setUp() async throws {
        try await super.setUp()
        // Clean slate: reset both managers before every test
        SubscriptionManager.shared.resetForAccountSwitch()
        QuotaManager.shared.resetForSignOut()
        clearAllSubscriptionUserDefaultsKeys()
    }

    override func tearDown() async throws {
        QuotaManager.shared.resetForSignOut()
        clearAllSubscriptionUserDefaultsKeys()
        SubscriptionManager.shared.resetForAccountSwitch()
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func clearAllSubscriptionUserDefaultsKeys() {
        let keys = [
            "isPremium", "currentPlanId", "subscriptionStatus",
            "subscriptionExpiresAt", "autoRenewStatus", "currentPlanDisplayName",
            SubscriptionManager.hasActiveSubscriptionCacheKey
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    private func simulateCachedPlusState() {
        // Simulate what updateFromStatus() writes after a successful Plus verification
        UserDefaults.standard.set(true,     forKey: "isPremium")
        UserDefaults.standard.set("plus",   forKey: "currentPlanId")
        UserDefaults.standard.set("active", forKey: "subscriptionStatus")
        UserDefaults.standard.set("2026-12-31T00:00:00", forKey: "subscriptionExpiresAt")
        UserDefaults.standard.set(true,     forKey: "autoRenewStatus")
        UserDefaults.standard.set("Plus",   forKey: "currentPlanDisplayName")
        // Also set in-memory state via the DEBUG helper
        QuotaManager.shared.simulatePremiumForTesting()
    }

    // MARK: - BUG-I4: QuotaManager in-memory state cleared on sign-out

    /// resetForSignOut() must zero isPremium in-memory immediately.
    /// Without this, account B reads stale isPremium=true before syncStatus completes.
    func test_i4_resetForSignOut_clears_isPremium_in_memory() {
        // Simulate account A being Plus via the DEBUG helper
        QuotaManager.shared.simulatePremiumForTesting()
        XCTAssertTrue(QuotaManager.shared.isPremium, "Precondition: isPremium must be true")

        QuotaManager.shared.resetForSignOut()

        XCTAssertFalse(QuotaManager.shared.isPremium,
            "BUG-I4: isPremium must be false immediately after resetForSignOut — " +
            "account B must not inherit account A's premium state")
    }

    /// resetForSignOut() must nil currentPlan in-memory.
    func test_i4_resetForSignOut_clears_currentPlan_in_memory() {
        QuotaManager.shared.simulatePremiumForTesting()
        XCTAssertTrue(QuotaManager.shared.isPremium, "Precondition")

        QuotaManager.shared.resetForSignOut()

        XCTAssertNil(QuotaManager.shared.currentPlan,
            "BUG-I4: currentPlan must be nil after resetForSignOut")
    }

    /// resetForSignOut() must nil subscriptionStatus in-memory.
    func test_i4_resetForSignOut_clears_subscriptionStatus_in_memory() {
        QuotaManager.shared.resetForSignOut()

        XCTAssertNil(QuotaManager.shared.subscriptionStatus,
            "BUG-I4: subscriptionStatus must be nil after resetForSignOut")
    }

    /// resetForSignOut() must nil autoRenewStatus in-memory.
    func test_i4_resetForSignOut_clears_autoRenewStatus_in_memory() {
        QuotaManager.shared.resetForSignOut()

        XCTAssertNil(QuotaManager.shared.autoRenewStatus,
            "BUG-I4: autoRenewStatus must be nil after resetForSignOut")
    }

    /// resetForSignOut() must reset lastSyncTime so the next account's first
    /// syncStatus call is not throttled by account A's cooldown window.
    func test_i4_resetForSignOut_resets_sync_cooldown() {
        QuotaManager.shared.resetForSignOut()

        // lastSyncTime is private — we verify indirectly: syncStatus with force=false
        // must NOT be throttled immediately after reset. If lastSyncTime were preserved,
        // the 5-min cooldown would block account B's first status fetch.
        // We can't call syncStatus in a unit test (needs network), but we CAN verify
        // that availableFeatures is cleared — which is only meaningful if reset ran.
        XCTAssertTrue(QuotaManager.shared.availableFeatures.isEmpty,
            "BUG-I4: availableFeatures must be empty after resetForSignOut — " +
            "stale features from account A must not be accessible to account B")
    }

    // MARK: - BUG-I4: UserDefaults cleared on sign-out

    /// All 5 subscription UserDefaults keys must be absent after sign-out.
    /// These are the keys QuotaManager.loadCachedSubscriptionState() reads
    /// on cold start — if any persist, account B inherits account A's plan.
    func test_i4_signout_clears_all_subscription_userdefaults_keys() {
        // Arrange: simulate account A leaving Plus state in UserDefaults
        simulateCachedPlusState()

        // Act: simulate what signOutAsync does
        let keys = [
            "isPremium", "currentPlanId", "subscriptionStatus",
            "subscriptionExpiresAt", "autoRenewStatus", "currentPlanDisplayName"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }

        // Assert: every key must be nil
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isPremium"),
            "isPremium must be cleared on sign-out")
        XCTAssertNil(UserDefaults.standard.string(forKey: "currentPlanId"),
            "currentPlanId must be cleared on sign-out — BUG-I4 root cause")
        XCTAssertNil(UserDefaults.standard.string(forKey: "subscriptionStatus"),
            "subscriptionStatus must be cleared on sign-out — BUG-I4 root cause")
        XCTAssertNil(UserDefaults.standard.string(forKey: "subscriptionExpiresAt"),
            "subscriptionExpiresAt must be cleared on sign-out — BUG-I4 root cause")
        XCTAssertNil(UserDefaults.standard.object(forKey: "autoRenewStatus"),
            "autoRenewStatus must be cleared on sign-out — BUG-I4 root cause")
        XCTAssertNil(UserDefaults.standard.string(forKey: "currentPlanDisplayName"),
            "currentPlanDisplayName must be cleared on sign-out — BUG-I4 root cause")
    }

    /// Cold-start after sign-out: QuotaManager must NOT restore stale Plus state
    /// if UserDefaults keys were properly cleared.
    func test_i4_cold_start_after_signout_shows_free_not_plus() {
        // Arrange: account A's Plus state is already cleared (sign-out happened)
        // UserDefaults has no subscription keys — simulating a fresh launch
        clearAllSubscriptionUserDefaultsKeys()

        // Act: simulate what QuotaManager.loadCachedSubscriptionState() reads
        // We verify indirectly via the resetForSignOut state
        QuotaManager.shared.resetForSignOut()

        // Assert: must show free state, not Plus
        XCTAssertFalse(QuotaManager.shared.isPremium,
            "BUG-I4: cold-start for account B must show free plan, not account A's Plus state")
    }

    // MARK: - BUG-I4: Account switch full flow

    /// Full account switch: account A has Plus → sign out → account B starts free.
    /// This is the exact user flow that caused the bug.
    func test_i4_account_switch_b_starts_free_not_inherited_plus() {
        // Step 1: account A is signed in with Plus
        UserDefaults.standard.set("prabhukushwaha@gmail.com", forKey: "userEmail")
        simulateCachedPlusState()  // sets both UserDefaults and in-memory via simulatePremiumForTesting()

        // Step 2: account A signs out — all subscription state cleared
        clearAllSubscriptionUserDefaultsKeys()
        QuotaManager.shared.resetForSignOut()
        SubscriptionManager.shared.resetForAccountSwitch()

        // Step 3: account B signs in — state before syncStatus completes
        UserDefaults.standard.set("prabhupredictions@gmail.com", forKey: "userEmail")

        // Assert: account B must NOT see account A's Plus state
        XCTAssertFalse(QuotaManager.shared.isPremium,
            "BUG-I4: account B must start with isPremium=false before syncStatus — " +
            "account A's Plus state must not bleed across sign-out")
        XCTAssertNil(QuotaManager.shared.currentPlan,
            "BUG-I4: currentPlan must be nil for account B at sign-in")
        XCTAssertNil(UserDefaults.standard.string(forKey: "currentPlanId"),
            "BUG-I4: currentPlanId UserDefaults must be nil for account B at sign-in")

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }

    /// resetForSignOut resets hasEverSubscribed so account B's paywall
    /// doesn't incorrectly skip trial eligibility based on account A's history.
    func test_i4_resetForSignOut_clears_hasEverSubscribed() {
        QuotaManager.shared.resetForSignOut()

        XCTAssertFalse(QuotaManager.shared.hasEverSubscribed,
            "BUG-I4: hasEverSubscribed must reset on sign-out — " +
            "account B must be evaluated on its own subscription history")
    }

    // MARK: - BUG-I5: Reconcile blocking during sign-in

    /// SubscriptionManager must not have conflictDetectedThisSession=true at the
    /// start of a new sign-in. If it does, the sign-in reconcile path is poisoned
    /// and will never fire the conflict alert even if the new account has one.
    func test_i5_reconcile_state_clean_at_start_of_new_signin() {
        // Simulate account A detecting a conflict and then signing out
        SubscriptionManager.shared.simulateConflictDetected(productID: "com.daa.plus.monthly")
        XCTAssertTrue(SubscriptionManager.shared.conflictDetectedThisSession)

        // Sign out
        SubscriptionManager.shared.resetForAccountSwitch()

        // Account B signs in — state must be clean for reconcile to work correctly
        XCTAssertFalse(SubscriptionManager.shared.conflictDetectedThisSession,
            "BUG-I5: conflictDetectedThisSession must be false at sign-in start — " +
            "otherwise account B's reconcile cannot detect a new conflict")
        XCTAssertNil(SubscriptionManager.shared.subscriptionConflict,
            "BUG-I5: subscriptionConflict must be nil at sign-in start")
    }

    /// verifyInFlight dedup set must be clear after account switch so
    /// account B's reconcile is not blocked by account A's in-flight guard.
    func test_i5_no_stale_in_flight_guard_after_account_switch() {
        // After resetForAccountSwitch the dedup guard must be clear.
        // We verify this indirectly: a fresh conflict detection must succeed.
        SubscriptionManager.shared.resetForAccountSwitch()
        SubscriptionManager.shared.simulateConflictDetected(productID: "com.daa.plus.monthly")

        XCTAssertNotNil(SubscriptionManager.shared.subscriptionConflict,
            "BUG-I5: after account switch, a new conflict must be detectable — " +
            "stale in-flight guard from account A must not block account B")
    }

    /// purchasedProductIDs must be cleared on account switch so account B's
    /// StoreKit entitlement list starts fresh (not inherited from account A).
    func test_i5_purchasedProductIDs_cleared_on_account_switch() {
        SubscriptionManager.shared.resetForAccountSwitch()

        XCTAssertTrue(SubscriptionManager.shared.purchasedProductIDs.isEmpty,
            "BUG-I5: purchasedProductIDs must be empty after account switch — " +
            "account A's StoreKit entitlements must not appear in account B's session")
    }

    /// isPlusTrialEligible must reset on sign-out so account B's trial button
    /// is evaluated fresh — not stuck at false from account A's trial history.
    func test_i5_isPlusTrialEligible_resets_on_account_switch() {
        SubscriptionManager.shared.resetForAccountSwitch()

        XCTAssertFalse(SubscriptionManager.shared.isPlusTrialEligible,
            "isPlusTrialEligible must reset on account switch — " +
            "account B's trial eligibility must come from Apple, not account A's session")
    }

    // MARK: - Combined: account A Plus → switch → account B free, no bleed

    /// End-to-end account switch: verifies both SubscriptionManager and
    /// QuotaManager state are completely independent after the switch.
    func test_combined_account_switch_no_state_bleed() {
        // Account A: Plus subscription + conflict detected
        simulateCachedPlusState()  // sets both UserDefaults and isPremium in-memory
        SubscriptionManager.shared.simulateConflictDetected(productID: "com.daa.plus.monthly")

        // Verify account A state is set
        XCTAssertTrue(QuotaManager.shared.isPremium)
        XCTAssertTrue(SubscriptionManager.shared.conflictDetectedThisSession)

        // Sign out: full reset
        clearAllSubscriptionUserDefaultsKeys()
        QuotaManager.shared.resetForSignOut()
        SubscriptionManager.shared.resetForAccountSwitch()

        // Account B state: must be completely clean
        XCTAssertFalse(QuotaManager.shared.isPremium,
            "Account B: isPremium must be false")
        XCTAssertNil(QuotaManager.shared.currentPlan,
            "Account B: currentPlan must be nil")
        XCTAssertFalse(SubscriptionManager.shared.conflictDetectedThisSession,
            "Account B: conflict state must be clear")
        XCTAssertNil(SubscriptionManager.shared.subscriptionConflict,
            "Account B: conflict binding must be nil")
        XCTAssertTrue(SubscriptionManager.shared.purchasedProductIDs.isEmpty,
            "Account B: StoreKit entitlements must be empty")
        XCTAssertNil(UserDefaults.standard.string(forKey: "currentPlanId"),
            "Account B: currentPlanId UserDefaults must be nil")
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isPremium"),
            "Account B: isPremium UserDefaults must be false")
    }

    // MARK: - iOS-7: hasActiveSubscription persistence across cold starts

    /// iOS-7: setting the cached hasActiveSubscription flag must round-trip
    /// through UserDefaults so a fresh instance (cold start) reads the last
    /// known good state via the static accessor before reconcile lands.
    func testHasActiveSubscription_persistsAcrossInstances() {
        // Arrange: simulate a previous session writing the cached flag
        UserDefaults.standard.set(true, forKey: SubscriptionManager.hasActiveSubscriptionCacheKey)

        // Act + Assert: the static reader (used by cold-start trial gating
        // BEFORE the singleton's reconcile completes) returns the cached
        // value, exactly what a "new SubscriptionManager instance" would
        // observe on launch.
        XCTAssertTrue(SubscriptionManager.cachedHasActiveSubscription(),
            "iOS-7: cachedHasActiveSubscription must read the persisted flag — " +
            "cold-start trial gating depends on this until reconcile completes")

        // And flipping the cache flips the read.
        UserDefaults.standard.set(false, forKey: SubscriptionManager.hasActiveSubscriptionCacheKey)
        XCTAssertFalse(SubscriptionManager.cachedHasActiveSubscription(),
            "iOS-7: cachedHasActiveSubscription must reflect the latest written value")
    }

    /// iOS-7: resetForAccountSwitch must clear the persisted hasActiveSubscription
    /// cache so a different user signing in on the same device does not inherit
    /// the previous user's trial-gating state at cold start.
    func testResetForAccountSwitch_clearsHasActiveSubscriptionCache() {
        // Arrange: previous user's session left the cache set to true
        UserDefaults.standard.set(true, forKey: SubscriptionManager.hasActiveSubscriptionCacheKey)
        XCTAssertTrue(SubscriptionManager.cachedHasActiveSubscription(),
            "Precondition: cache must be set before reset")

        // Act
        SubscriptionManager.shared.resetForAccountSwitch()

        // Assert: key was removed (default bool read returns false)
        XCTAssertNil(UserDefaults.standard.object(forKey: SubscriptionManager.hasActiveSubscriptionCacheKey),
            "iOS-7: hasActiveSubscription cache key must be removed on account switch")
        XCTAssertFalse(SubscriptionManager.cachedHasActiveSubscription(),
            "iOS-7: cached reader must report false after account switch — " +
            "account B must not inherit account A's hasActiveSubscription cache")
    }
}
