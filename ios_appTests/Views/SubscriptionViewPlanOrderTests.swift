import XCTest
@testable import ios_app

/// Paywall v2 (Phase 7) — K16: SubscriptionView plan ordering.
///
/// The SubscriptionView.loadPlans() function applies the same sort closure
/// to two paths — the cached paidPlans read AND the server-fetched fresh
/// list — so the rendered plan order is consistent regardless of cache
/// state. The closure is:
///
///     if lhs.planId == "plus" { return true }
///     if rhs.planId == "plus" { return false }
///     return (lhs.priceMonthly ?? 0) < (rhs.priceMonthly ?? 0)
///
/// Plus is anchored on top, the rest fall through to ascending price.
/// This test pins that ordering in both code paths so a future refactor
/// can't accidentally invert one of them.
final class SubscriptionViewPlanOrderTests: XCTestCase {

    // MARK: - Test fixtures

    private func plan(_ id: String, price: Double?) -> PlanInfo {
        PlanInfo(
            planId: id,
            displayName: id.capitalized,
            description: nil,
            isFree: id.hasPrefix("free"),
            priceMonthly: price,
            priceYearly: nil,
            currency: "USD",
            appleProductIdMonthly: nil,
            appleProductIdYearly: nil,
            entitlements: nil
        )
    }

    /// Mirror of the sort closure inside SubscriptionView.loadPlans().
    private func sortPlusFirst(_ plans: [PlanInfo]) -> [PlanInfo] {
        plans.sorted { lhs, rhs in
            if lhs.planId == "plus" { return true }
            if rhs.planId == "plus" { return false }
            return (lhs.priceMonthly ?? 0) < (rhs.priceMonthly ?? 0)
        }
    }

    // MARK: - Tests

    /// K16a: cached path. paidPlans → Plus must render above Core.
    func testCachedPath_PlusRendersAboveCore() {
        let raw = [plan("core", price: 4.99), plan("plus", price: 7.99)]
        let sorted = sortPlusFirst(raw)
        XCTAssertEqual(sorted.map { $0.planId }, ["plus", "core"])
    }

    /// K16b: server-fetched path. Even when the API returns plans in
    /// arbitrary order, Plus must end up first.
    func testServerFetchedPath_PlusRendersAboveCore() {
        let raw = [plan("core", price: 4.99), plan("plus", price: 7.99)]
        let sorted = sortPlusFirst(raw.shuffled()) // intentional random order
        XCTAssertEqual(sorted.first?.planId, "plus")
    }

    /// K16c: sort is stable when a third paid tier is added later
    /// (e.g. "elite"). Plus stays anchored on top, the rest fall through
    /// to ascending price.
    func testFutureThirdTier_PlusStillFirst_RestSortAscending() {
        let raw = [
            plan("elite", price: 12.99),
            plan("core",  price: 4.99),
            plan("plus",  price: 7.99)
        ]
        let sorted = sortPlusFirst(raw)
        XCTAssertEqual(sorted.map { $0.planId }, ["plus", "core", "elite"])
    }

    /// K16d: source pin — both call sites in SubscriptionView.loadPlans()
    /// must apply the Plus-first sort. If a future refactor drops the sort
    /// from the cached path, this test fails.
    func testSourcePin_BothPathsApplyPlusFirstSort() throws {
        let path = #file.replacingOccurrences(
            of: "/ios_appTests/Views/SubscriptionViewPlanOrderTests.swift",
            with: "/ios_app/Views/Subscription/SubscriptionView.swift"
        )
        let source = try String(contentsOfFile: path, encoding: .utf8)
        // Plus-first sort fragment must appear at least twice (cached +
        // server-fetched paths). Match on the unique line "if lhs.planId
        // == \"plus\" { return true }".
        let needle = #"if lhs.planId == "plus" { return true }"#
        let occurrences = source.components(separatedBy: needle).count - 1
        XCTAssertGreaterThanOrEqual(
            occurrences, 2,
            "Both cached and server-fetched paths must apply the Plus-first sort"
        )
    }
}
