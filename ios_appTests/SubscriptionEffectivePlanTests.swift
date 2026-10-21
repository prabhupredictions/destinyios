import XCTest
@testable import ios_app

/// Single-active invariant (iOS): when a user holds more than one store
/// subscription, the paywall must resolve to ONE current plan — the highest
/// tier (Plus > Core) — deterministically, not by arbitrary Set order.
final class SubscriptionEffectivePlanTests: XCTestCase {

    func testPrefersPlusWhenBothTiersOwned() {
        let owned: Set<String> = ["com.daa.core.monthly", "com.daa.plus.monthly"]
        XCTAssertEqual(SubscriptionManager.effectivePlanId(from: owned), "plus")
    }

    func testPrefersPlusRegardlessOfPeriod() {
        let owned: Set<String> = ["com.daa.plus.yearly", "com.daa.core.yearly"]
        XCTAssertEqual(SubscriptionManager.effectivePlanId(from: owned), "plus")
    }

    func testSingleCoreReturnsCore() {
        XCTAssertEqual(SubscriptionManager.effectivePlanId(from: ["com.daa.core.yearly"]), "core")
    }

    func testSinglePlusReturnsPlus() {
        XCTAssertEqual(SubscriptionManager.effectivePlanId(from: ["com.daa.plus.monthly"]), "plus")
    }

    func testEmptyReturnsNil() {
        XCTAssertNil(SubscriptionManager.effectivePlanId(from: []))
    }
}
