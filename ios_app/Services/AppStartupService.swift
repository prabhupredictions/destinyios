import Foundation

/// Fetches gate config from backend on launch and foreground.
/// Drives: guest button visibility, gate mode awareness, streaming kill-switch.
@Observable
final class AppStartupService {
    static let shared = AppStartupService()

    var gateMode: String = "off"
    var allowGuest: Bool = false

    private var lastFetchedAt: Date?
    private let cacheTTL: TimeInterval = 900 // 15 min

    private struct AppConfigDTO: Decodable {
        let gate_mode: String?
        let allow_guest: Bool?
        let streaming_enabled: Bool?
        let streaming_cohort_percent: Int?
        let streaming_min_app_version: String?
    }

    /// Internal — performs the network fetch + writes to both sinks.
    /// Caller decides whether to gate on TTL.
    private func _fetch() async {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/v2/app/config") else { return }
        var req = URLRequest(url: url)
        req.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
        req.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        req.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let dto = try JSONDecoder().decode(AppConfigDTO.self, from: data)
            await MainActor.run {
                // Dual-sink writes (I-2a from review): self.* for AuthView/AppRootView,
                // AppConfig.shared for ChatViewModel streaming gate.
                if let gate = dto.gate_mode {
                    AppConfig.shared.gateMode = gate
                    self.gateMode = gate
                }
                if let guest = dto.allow_guest {
                    AppConfig.shared.allowGuest = guest
                    self.allowGuest = guest
                }
                if let enabled = dto.streaming_enabled { AppConfig.shared.streamingEnabled = enabled }
                if let cohort = dto.streaming_cohort_percent { AppConfig.shared.streamingCohortPercent = cohort }
                if let minV = dto.streaming_min_app_version { AppConfig.shared.streamingMinAppVersion = minV }
                self.lastFetchedAt = Date()
            }
        } catch {
            // Defaults are conservative — streaming stays off on network failure.
            // Leave prior cached values intact.
        }
    }

    /// Launch-time fetch — TTL-guarded (15 min) to avoid duplicate hits during cold start.
    func fetchConfig() async {
        if let last = lastFetchedAt, Date().timeIntervalSince(last) < cacheTTL {
            return
        }
        await _fetch()
    }

    /// Force-fresh fetch — used by scenePhase → .active foreground transitions and
    /// the kill-switch SLA path. No TTL guard (C-1 fix from final review):
    /// kill-switch propagation must be bounded by client poll cadence (≤60s),
    /// not by the launch-time dedup window.
    func refreshAppConfig() async {
        await _fetch()
    }
}
