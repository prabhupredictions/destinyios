import Foundation
import Observation

/// Server-driven feature configuration. Refreshed on app launch and every
/// foreground transition via AppStartupService. Defaults are intentionally
/// conservative — if the network or backend fails, streaming stays off.
@Observable
final class AppConfig {
    static let shared = AppConfig()

    var gateMode: String = "off"
    var allowGuest: Bool = false

    var streamingEnabled: Bool = false
    var streamingCohortPercent: Int = 0
    var streamingMinAppVersion: String = "1.9.0"

    private init() {}

    /// Test hook — bypass the singleton in unit tests.
    static func testInstance(
        streamingEnabled: Bool,
        streamingCohortPercent: Int,
        streamingMinAppVersion: String
    ) -> AppConfig {
        let cfg = AppConfig()
        cfg.streamingEnabled = streamingEnabled
        cfg.streamingCohortPercent = streamingCohortPercent
        cfg.streamingMinAppVersion = streamingMinAppVersion
        return cfg
    }

    /// Stable cohort decision via FNV-1a hash of userId mod 100. The same
    /// userId always gets the same answer, so a user either sees streaming
    /// or doesn't — never flickering between paths between sessions.
    func inCohort(_ userId: String) -> Bool {
        guard streamingCohortPercent > 0 else { return false }
        guard streamingCohortPercent < 100 else { return true }
        let bucket = Int(fnv1a(userId) % 100)
        return bucket < streamingCohortPercent
    }

    /// Compares semantic versions (major.minor.patch). Missing components
    /// treated as 0. Returns .orderedAscending if a < b.
    func compareVersions(_ a: String, _ b: String) -> Foundation.ComparisonResult {
        let pa = a.split(separator: ".").compactMap { Int($0) }
        let pb = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(pa.count, pb.count) {
            let av = i < pa.count ? pa[i] : 0
            let bv = i < pb.count ? pb[i] : 0
            if av < bv { return .orderedAscending }
            if av > bv { return .orderedDescending }
        }
        return .orderedSame
    }

    /// True if the running app version is >= streamingMinAppVersion.
    var versionAllowed: Bool {
        let short = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
        return compareVersions(short, streamingMinAppVersion) != .orderedAscending
    }

    /// Composite gate. Used by ChatViewModel.sendMessage to route streaming
    /// vs sync. UI_TEST_MODE pins to sync regardless of cohort.
    func shouldStreamFor(userId: String) -> Bool {
        guard streamingEnabled else { return false }
        guard versionAllowed else { return false }
        guard ProcessInfo.processInfo.environment["UI_TEST_MODE"] == nil else { return false }
        return inCohort(userId)
    }

    // MARK: - FNV-1a 64-bit

    private func fnv1a(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 {
            h ^= UInt64(b)
            h &*= 0x100000001b3
        }
        return h
    }
}
