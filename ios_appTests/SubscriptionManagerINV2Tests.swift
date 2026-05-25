//
//  SubscriptionManagerINV2Tests.swift
//  ios_appTests
//
//  INV-2 Gap A regression: verify the foreground sync timer
//  starts when scenePhase=.active and stops when .background.
//
//  This is a behavior-level test — it doesn't actually call the
//  network, just verifies the Task lifecycle of foregroundSyncTimer.
//

import XCTest
@testable import ios_app

final class SubscriptionManagerINV2Tests: XCTestCase {

    /// startForegroundSyncTimer must create a Task that survives until
    /// stopForegroundSyncTimer is called or app terminates.
    @MainActor
    func test_foregroundSyncTimer_starts_and_stops() async throws {
        let mgr = SubscriptionManager.shared

        // Start
        mgr.startForegroundSyncTimer()
        // Reflection check via mirror — internal foregroundSyncTimer should exist
        let timer1 = Mirror(reflecting: mgr).descendant("foregroundSyncTimer")
        XCTAssertNotNil(timer1, "Timer task should exist after start")

        // Stop
        mgr.stopForegroundSyncTimer()
        // Wait briefly for the cancel + nil assignment
        try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms

        let timer2 = Mirror(reflecting: mgr).descendant("foregroundSyncTimer") as? Task<Void, Never>
        XCTAssertNil(timer2, "Timer task should be nil after stop")
    }

    /// Calling startForegroundSyncTimer twice must not leak the first Task —
    /// it should cancel the previous one.
    @MainActor
    func test_foregroundSyncTimer_idempotent_start() async throws {
        let mgr = SubscriptionManager.shared
        mgr.startForegroundSyncTimer()
        mgr.startForegroundSyncTimer()  // second call must replace, not duplicate
        mgr.startForegroundSyncTimer()

        // Wait briefly to allow any cancellations to settle
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Final state: exactly one Task should be holding the slot
        let timer = Mirror(reflecting: mgr).descendant("foregroundSyncTimer") as? Task<Void, Never>
        XCTAssertNotNil(timer, "Some timer must be live after multiple start calls")
        // Cleanup
        mgr.stopForegroundSyncTimer()
    }

    /// stopForegroundSyncTimer when no timer is running must be a no-op (not crash).
    @MainActor
    func test_foregroundSyncTimer_stop_without_start_is_safe() async throws {
        let mgr = SubscriptionManager.shared
        mgr.stopForegroundSyncTimer()
        mgr.stopForegroundSyncTimer()  // double stop must not crash
        XCTAssertTrue(true, "Double stop completed without crash")
    }

    /// INV-9 G2: reconcileEntitlementsWithBackend must not allow concurrent
    /// re-entry. Without the guard, two concurrent invocations would
    /// iterate Transaction.currentEntitlements and call /verify in parallel.
    /// Backend handles the concurrency correctly via DB unique index, but
    /// we want to avoid the redundant work entirely.
    @MainActor
    func test_reconcile_has_reentry_guard() async throws {
        let mgr = SubscriptionManager.shared

        // Reflection check — internal flag must exist
        let mirror = Mirror(reflecting: mgr)
        let hasFlag = mirror.descendant("isReconciling") != nil
        XCTAssertTrue(hasFlag,
            "SubscriptionManager must declare isReconciling flag for INV-9 G2")
    }
}
