import XCTest
@testable import ios_app

/// Tests for QuotaErrorInfo.isFairUseViolation
///
/// iOS-13 client-side fix coverage: when the backend supplies a real upgrade
/// target (suggested_plan != "plus"), we must defer to it instead of routing
/// the user to Contact Support. The server-side `is_fair_use_violation`
/// flag fix is tracked as iOS-13b in `docs/subscription_architecture.md`.
final class QuotaErrorInfoTests: XCTestCase {

    // MARK: - Helpers

    private func makeInfo(
        reason: String?,
        planId: String?,
        suggestedPlan: String? = nil
    ) -> QuotaErrorInfo {
        return QuotaErrorInfo(
            reason: reason,
            planId: planId,
            featureId: "ai_questions",
            message: nil,
            action: nil,
            suggestedPlan: suggestedPlan,
            supportEmail: nil,
            resetAt: nil
        )
    }

    // MARK: - Tests

    /// Plus user at overall limit, backend supplied no upgrade target → fair-use flow.
    func testIsFairUseViolation_plusOverallNoUpgradeCta_isTrue() {
        let info = makeInfo(reason: "overall_limit_reached", planId: "plus", suggestedPlan: nil)
        XCTAssertTrue(info.isFairUseViolation)
    }

    /// Plus user at overall limit, but backend supplied core as upgrade target →
    /// NOT fair use; respect the server-supplied upgrade path.
    func testIsFairUseViolation_plusOverallWithCoreUpgradeCta_isFalse() {
        let info = makeInfo(reason: "overall_limit_reached", planId: "plus", suggestedPlan: "core")
        XCTAssertFalse(info.isFairUseViolation)
    }

    /// Core user at overall limit → never fair use (only Plus can hit fair-use).
    func testIsFairUseViolation_corePlanOverall_isFalse() {
        let info = makeInfo(reason: "overall_limit_reached", planId: "core", suggestedPlan: "plus")
        XCTAssertFalse(info.isFairUseViolation)
    }

    /// Plus user hit daily limit (not overall) → never fair use.
    func testIsFairUseViolation_dailyLimitReached_isFalse() {
        let info = makeInfo(reason: "daily_limit_reached", planId: "plus", suggestedPlan: nil)
        XCTAssertFalse(info.isFairUseViolation)
    }

    // MARK: - Edge cases

    /// Plus user at overall limit, backend echoed back "plus" as suggested → still fair use.
    func testIsFairUseViolation_plusOverallSuggestedPlanIsPlus_isTrue() {
        let info = makeInfo(reason: "overall_limit_reached", planId: "plus", suggestedPlan: "plus")
        XCTAssertTrue(info.isFairUseViolation)
    }

    /// Plus user at overall limit with empty suggested_plan string → still fair use.
    func testIsFairUseViolation_plusOverallEmptySuggestedPlan_isTrue() {
        let info = makeInfo(reason: "overall_limit_reached", planId: "plus", suggestedPlan: "")
        XCTAssertTrue(info.isFairUseViolation)
    }
}
