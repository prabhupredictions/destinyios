import Foundation

/// Fetches gate config from backend on launch.
/// Drives: guest button visibility, gate mode awareness.
@Observable
final class AppStartupService {
    static let shared = AppStartupService()

    var gateMode: String = "off"
    var allowGuest: Bool = false

    private var lastFetchedAt: Date?
    private let cacheTTL: TimeInterval = 900 // 15 min

    private struct ConfigResponse: Decodable {
        let gateMode: String
        let allowGuest: Bool
        enum CodingKeys: String, CodingKey {
            case gateMode = "gate_mode"
            case allowGuest = "allow_guest"
        }
    }

    private struct AppConfigDTO: Decodable {
        let gate_mode: String?
        let allow_guest: Bool?
        let streaming_enabled: Bool?
        let streaming_cohort_percent: Int?
        let streaming_min_app_version: String?
    }

    func fetchConfig() async {
        if let last = lastFetchedAt, Date().timeIntervalSince(last) < cacheTTL {
            return
        }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/v2/app/config") else { return }
        var request = URLRequest(url: url)
        request.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
        request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let config = try JSONDecoder().decode(ConfigResponse.self, from: data)
            await MainActor.run {
                self.gateMode = config.gateMode
                self.allowGuest = config.allowGuest
                self.lastFetchedAt = Date()
            }
        } catch {
            // Leave prior cached values intact on transient network failure.
            // On first launch with no cache, defaults ("off", false) remain — safe.
        }
    }

    func refreshAppConfig() async {
        // C-1: This is the explicit force-fresh entry (foreground / kill-switch).
        // No TTL guard — kill-switch SLA is ≤60s, must always hit the network.
        // fetchConfig() retains its TTL for launch-time dedupe.
        do {
            let url = URL(string: "\(APIConfig.baseURL)/api/v2/app/config")!
            var req = URLRequest(url: url)
            // I-2b: include Authorization header matching fetchConfig() pattern.
            req.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
            req.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
            // I-1: URLSession I/O is off-main; only writes happen inside MainActor.run.
            let (data, _) = try await URLSession.shared.data(for: req)
            let dto = try JSONDecoder().decode(AppConfigDTO.self, from: data)
            await MainActor.run {
                // I-2a: write to both AppConfig.shared (streaming/cohort fields) and
                // self (gateMode/allowGuest) so AuthView/AppRootView see the update.
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
        }
    }
}
