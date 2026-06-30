import XCTest
import Foundation
@testable import ios_app

final class AppConfigCohortHashTests: XCTestCase {
    func testCohortHashStableAcrossCalls() async {
        let cfg = AppConfig.testInstance(
            streamingEnabled: true,
            streamingCohortPercent: 50,
            streamingMinAppVersion: "1.0.0"
        )
        let userId = "prabhukushwaha@gmail.com"
        let h1 = cfg.inCohort(userId)
        let h2 = cfg.inCohort(userId)
        XCTAssertEqual(h1, h2, "Cohort decision must be stable across calls")
    }

    func testCohortZeroIncludesNoOne() async {
        let cfg = AppConfig.testInstance(
            streamingEnabled: true,
            streamingCohortPercent: 0,
            streamingMinAppVersion: "1.0.0"
        )
        for id in ["a", "b", "c", "d", "test@example.com"] {
            XCTAssertFalse(cfg.inCohort(id))
        }
    }

    func testCohortHundredIncludesEveryone() async {
        let cfg = AppConfig.testInstance(
            streamingEnabled: true,
            streamingCohortPercent: 100,
            streamingMinAppVersion: "1.0.0"
        )
        for id in ["a", "b", "c", "d", "test@example.com"] {
            XCTAssertTrue(cfg.inCohort(id))
        }
    }

    func testCohortFiftyApproximatelyHalf() async {
        let cfg = AppConfig.testInstance(
            streamingEnabled: true,
            streamingCohortPercent: 50,
            streamingMinAppVersion: "1.0.0"
        )
        // Sample 1000 stable-ish ids — expect 35–65% inclusion (loose bound).
        var included = 0
        for i in 0..<1000 {
            if cfg.inCohort("user\(i)@example.com") { included += 1 }
        }
        XCTAssertGreaterThan(included, 350)
        XCTAssertLessThan(included, 650)
    }

    func testVersionGate() async {
        let lower = AppConfig.testInstance(
            streamingEnabled: true,
            streamingCohortPercent: 100,
            streamingMinAppVersion: "1.10.0"
        )
        // Bundle short version is hardcoded in test target; we assume < 1.10.0.
        // If the test target's bundle version is >= 1.10.0, this assertion
        // should be inverted — but for now it locks the comparison direction.
        XCTAssertEqual(lower.compareVersions("1.9.0", "1.10.0"), Foundation.ComparisonResult.orderedAscending)
        XCTAssertEqual(lower.compareVersions("2.0.0", "1.10.0"), Foundation.ComparisonResult.orderedDescending)
        XCTAssertEqual(lower.compareVersions("1.10.0", "1.10.0"), Foundation.ComparisonResult.orderedSame)
    }

    func testStreamingDisabledShortCircuits() async {
        let cfg = AppConfig.testInstance(
            streamingEnabled: false,
            streamingCohortPercent: 100,
            streamingMinAppVersion: "0.0.1"
        )
        XCTAssertFalse(cfg.shouldStreamFor(userId: "anyone"))
    }
}
