//
//  SubscriptionConflictUXTests.swift
//  ios_appTests
//
//  Pins the two conflict UX regressions found 2026-05-30:
//
//  BUG-1 (popup repeats every foreground): Every scenePhase=.active triggers
//  reconcileEntitlementsWithBackend, which calls verifyWithBackend, which gets
//  transaction_belongs_to_different_user, which previously always assigned
//  subscriptionConflict = SubscriptionConflict(id: UUID()). SwiftUI's
//  .alert(item:) fires on every nil→non-nil transition with a new Identifiable
//  value — so the "Apple ID Already Linked" popup fired on every foreground.
//  Fix: guard the assignment behind conflictDetectedThisSession — set only once
//  per session, not on every reconcile cycle.
//
//  BUG-2 (banner flickers in SubscriptionView): crossAccountConflictBanner
//  checked subscriptionConflict != nil. .alert(item:) clears subscriptionConflict
//  to nil on dismiss, so the banner vanished after OK. Next foreground reconcile
//  re-set subscriptionConflict → banner appeared again. After that OK → gone.
//  Fix: banner must use conflictDetectedThisSession, which persists until sign-out.
//

import XCTest
@testable import ios_app

@MainActor
final class SubscriptionConflictUXTests: XCTestCase {

    override func setUp() async throws {
        // Start each test from a clean slate
        SubscriptionManager.shared.resetForAccountSwitch()
    }

    // MARK: - BUG-1: alert must not re-fire after first conflict detection

    /// After a conflict is detected once (conflictDetectedThisSession=true),
    /// a subsequent reconcile must NOT create a new SubscriptionConflict value.
    /// SwiftUI's .alert(item:) fires on nil→non-nil transitions — re-assigning
    /// on every foreground caused the popup to fire repeatedly.
    func test_bug1_conflict_not_reset_after_first_detection() {
        let manager = SubscriptionManager.shared

        // First foreground: conflict detected
        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")
        XCTAssertNotNil(manager.subscriptionConflict,
            "First conflict detection must set subscriptionConflict non-nil")
        XCTAssertTrue(manager.conflictDetectedThisSession)
        let firstID = manager.subscriptionConflict?.id

        // Second reconcile (next foreground) calls simulateConflictDetected again.
        // The fix must not create a new SubscriptionConflict instance.
        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")

        XCTAssertEqual(manager.subscriptionConflict?.id, firstID,
            "BUG-1: subscriptionConflict must not be re-assigned when " +
            "conflictDetectedThisSession is already true — new UUID causes popup to re-fire")
    }

    /// After sign-out, conflict state is cleared. A fresh conflict on the new
    /// account must be able to fire once.
    func test_bug1_conflict_resets_after_signout_and_can_refire() {
        let manager = SubscriptionManager.shared

        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")
        XCTAssertTrue(manager.conflictDetectedThisSession)

        manager.resetForAccountSwitch()
        XCTAssertFalse(manager.conflictDetectedThisSession,
            "resetForAccountSwitch must clear conflictDetectedThisSession")
        XCTAssertNil(manager.subscriptionConflict,
            "resetForAccountSwitch must clear subscriptionConflict")

        // Fresh account — conflict must fire once
        manager.simulateConflictDetected(productID: "com.daa.core.monthly")
        XCTAssertNotNil(manager.subscriptionConflict,
            "After sign-out, a new conflict must be surfaceable")
    }

    /// Root case of BUG-1: alert shown → user taps OK → .alert(item:) clears
    /// binding → next foreground reconcile must NOT re-set subscriptionConflict.
    func test_bug1_no_second_popup_after_alert_dismissed() {
        let manager = SubscriptionManager.shared

        // Sign-in: conflict detected, popup fires
        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")
        XCTAssertNotNil(manager.subscriptionConflict, "Popup fires on sign-in")

        // User taps OK — SwiftUI clears the binding
        manager.simulateAlertDismissed()
        XCTAssertNil(manager.subscriptionConflict, "Binding cleared after OK")
        XCTAssertTrue(manager.conflictDetectedThisSession,
            "conflictDetectedThisSession must survive alert dismiss")

        // User backgrounds then foregrounds — reconcile fires again
        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")

        // After the fix: subscriptionConflict must stay nil — no second popup
        XCTAssertNil(manager.subscriptionConflict,
            "BUG-1: popup must not reappear on foreground after alert was dismissed")
    }

    // MARK: - BUG-2: banner must use conflictDetectedThisSession, not subscriptionConflict

    /// The conflict banner's source of truth must be conflictDetectedThisSession.
    /// After the user taps OK on the popup, .alert(item:) clears subscriptionConflict
    /// to nil. A banner keyed on subscriptionConflict would incorrectly vanish.
    func test_bug2_conflictDetectedThisSession_survives_alert_dismiss() {
        let manager = SubscriptionManager.shared

        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")
        XCTAssertTrue(manager.conflictDetectedThisSession)
        XCTAssertNotNil(manager.subscriptionConflict)

        // User taps OK
        manager.simulateAlertDismissed()

        XCTAssertNil(manager.subscriptionConflict,
            "subscriptionConflict is nil after dismiss — banner on this would vanish")
        XCTAssertTrue(manager.conflictDetectedThisSession,
            "BUG-2: conflictDetectedThisSession must remain true — banner must stay visible")
    }

    /// Banner must disappear on sign-out (new user may have a clean subscription).
    func test_bug2_banner_clears_on_signout() {
        let manager = SubscriptionManager.shared
        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")
        manager.simulateAlertDismissed()
        XCTAssertTrue(manager.conflictDetectedThisSession)

        manager.resetForAccountSwitch()
        XCTAssertFalse(manager.conflictDetectedThisSession,
            "Banner must not persist across sign-out")
    }

    /// Before the first dismiss, both popup binding and banner source are set.
    func test_bug2_both_popup_and_banner_active_before_dismiss() {
        let manager = SubscriptionManager.shared
        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")

        XCTAssertNotNil(manager.subscriptionConflict, "Alert binding set before dismiss")
        XCTAssertTrue(manager.conflictDetectedThisSession, "Banner source set before dismiss")
    }

    // MARK: - Combined regression (exact scenario from bug report)

    /// Sign in → conflict popup → OK → background → foreground → NO second popup,
    /// banner STILL visible. This is the exact user flow from the screenshots.
    func test_combined_regression_one_popup_banner_persists() {
        let manager = SubscriptionManager.shared

        // Step 1: sign-in reconcile → conflict detected
        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")
        XCTAssertNotNil(manager.subscriptionConflict, "Popup fires on sign-in")
        XCTAssertTrue(manager.conflictDetectedThisSession)

        // Step 2: user taps OK on the alert
        manager.simulateAlertDismissed()
        XCTAssertNil(manager.subscriptionConflict, "Binding cleared after OK")

        // Step 3: user opens SubscriptionView → sees conflict banner (BUG-2 check)
        XCTAssertTrue(manager.conflictDetectedThisSession,
            "BUG-2: banner must be visible after alert dismiss")

        // Step 4: user backgrounds then foregrounds app → reconcile fires
        manager.simulateConflictDetected(productID: "com.daa.plus.monthly")

        // Popup must NOT have reappeared
        XCTAssertNil(manager.subscriptionConflict,
            "BUG-1: no second popup on foreground after dismiss")

        // Banner must still be visible
        XCTAssertTrue(manager.conflictDetectedThisSession,
            "BUG-2: banner still visible on second foreground")
    }
}
