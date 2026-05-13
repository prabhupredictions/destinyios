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

    func fetchConfig() async {
        if let last = lastFetchedAt, Date().timeIntervalSince(last) < cacheTTL {
            return
        }
        guard let url = URL(string: "\(APIConfig.baseURL)/api/v2/app/config") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
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
}
