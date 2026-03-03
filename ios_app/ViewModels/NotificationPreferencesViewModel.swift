import Foundation
import Combine

// MARK: - Alert Item Model

struct AlertItem: Identifiable, Equatable {
    let id: String
    var text: String
    var frequency: NotificationPreferencesViewModel.NotificationFrequency
    var frequencyDay: Int?
    
    init(id: String = UUID().uuidString, text: String, frequency: NotificationPreferencesViewModel.NotificationFrequency = .daily, frequencyDay: Int? = nil) {
        self.id = id
        self.text = text
        self.frequency = frequency
        self.frequencyDay = frequencyDay
    }
}

/// ViewModel for Personalized Alerts (Plus-only feature).
/// Handles CRUD against `GET/PUT /notifications/preferences`.
/// Supports multiple alert items (max 5), each with independent frequency.
@MainActor
final class NotificationPreferencesViewModel: ObservableObject {
    
    static let maxAlerts = 5
    
    // MARK: - Published State
    
    @Published var isEnabled: Bool = true
    @Published var emailEnabled: Bool = true
    @Published var pushEnabled: Bool = true
    @Published var inAppEnabled: Bool = true
    @Published var alertItems: [AlertItem] = []
    @Published var preferredTimeUTC: String = "00:30"
    @Published var timezone: String = TimeZone.current.identifier
    
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSaveSuccess: Bool = false
    
    var canAddMore: Bool { alertItems.count < Self.maxAlerts }
    
    enum NotificationFrequency: String, CaseIterable, Identifiable {
        case daily = "DAILY"
        case weekly = "WEEKLY"
        case monthly = "MONTHLY"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            }
        }
        
        var icon: String {
            switch self {
            case .daily: return "calendar.day.timeline.left"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar.badge.checkmark"
            }
        }
    }
    
    // MARK: - Alert CRUD
    
    func addAlert(_ item: AlertItem) {
        guard canAddMore else { return }
        alertItems.append(item)
    }
    
    func updateAlert(_ item: AlertItem) {
        if let idx = alertItems.firstIndex(where: { $0.id == item.id }) {
            alertItems[idx] = item
        }
    }
    
    func deleteAlert(id: String) {
        alertItems.removeAll { $0.id == id }
    }
    
    // MARK: - Load
    
    func loadPreferences(email: String) async {
        guard !email.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let urlString = "\(APIConfig.baseURL)/notifications/preferences?user_email=\(email)"
            guard let url = URL(string: urlString) else { return }
            
            var request = URLRequest(url: url)
            request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to load preferences"
                isLoading = false
                return
            }
            
            let result = try JSONDecoder().decode(PreferencesAPIResponse.self, from: data)
            
            if result.success {
                applyFromAPI(result.preferences)
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Save
    
    func savePreferences(email: String) async {
        guard !email.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        
        do {
            let urlString = "\(APIConfig.baseURL)/notifications/preferences?user_email=\(email)"
            guard let url = URL(string: urlString) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
            
            let apiAlertItems = alertItems.map { item in
                AlertItemAPI(
                    id: item.id,
                    text: item.text,
                    frequency: item.frequency.rawValue,
                    frequency_day: item.frequencyDay
                )
            }
            
            let body = PreferencesUpdateRequest(
                is_enabled: isEnabled,
                email_enabled: emailEnabled,
                push_enabled: pushEnabled,
                in_app_enabled: inAppEnabled,
                alert_items: apiAlertItems,
                preferred_time_utc: preferredTimeUTC,
                timezone: timezone
            )
            
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to save preferences"
                isSaving = false
                return
            }
            
            let result = try JSONDecoder().decode(PreferencesAPIResponse.self, from: data)
            
            if result.success {
                applyFromAPI(result.preferences)
                showSaveSuccess = true
                
                // Auto-dismiss success banner after 2s
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSaveSuccess = false
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    // MARK: - Private
    
    private func applyFromAPI(_ prefs: [String: AnyCodable]) {
        isEnabled = (prefs["is_enabled"]?.value as? Bool) ?? true
        emailEnabled = (prefs["email_enabled"]?.value as? Bool) ?? true
        pushEnabled = (prefs["push_enabled"]?.value as? Bool) ?? true
        inAppEnabled = (prefs["in_app_enabled"]?.value as? Bool) ?? true
        timezone = (prefs["timezone"]?.value as? String) ?? TimeZone.current.identifier
        preferredTimeUTC = (prefs["preferred_time_utc"]?.value as? String) ?? "00:30"
        
        // Parse alert_items from API response
        alertItems = []
        if let rawItems = prefs["alert_items"]?.value as? [[String: Any]] {
            for raw in rawItems.prefix(Self.maxAlerts) {
                let id = (raw["id"] as? String) ?? UUID().uuidString
                let text = (raw["text"] as? String) ?? ""
                let freqStr = (raw["frequency"] as? String) ?? "DAILY"
                let freq = NotificationFrequency(rawValue: freqStr) ?? .daily
                let freqDay = raw["frequency_day"] as? Int
                alertItems.append(AlertItem(id: id, text: text, frequency: freq, frequencyDay: freqDay))
            }
        }
    }
}

// MARK: - API Models

private struct AlertItemAPI: Encodable {
    let id: String
    let text: String
    let frequency: String
    let frequency_day: Int?
}

private struct PreferencesUpdateRequest: Encodable {
    let is_enabled: Bool
    let email_enabled: Bool
    let push_enabled: Bool
    let in_app_enabled: Bool
    let alert_items: [AlertItemAPI]
    let preferred_time_utc: String
    let timezone: String
}

struct PreferencesAPIResponse: Decodable {
    let success: Bool
    let preferences: [String: AnyCodable]
}
