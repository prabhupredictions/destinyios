import Foundation
import Combine

/// ViewModel for Notification Preferences (Plus-only feature).
/// Handles CRUD against `GET/PUT /notifications/preferences`.
@MainActor
final class NotificationPreferencesViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isEnabled: Bool = true
    @Published var emailEnabled: Bool = true
    @Published var pushEnabled: Bool = true
    @Published var inAppEnabled: Bool = true
    @Published var customInstruction: String = ""
    @Published var frequency: NotificationFrequency = .daily
    @Published var frequencyDay: Int? = nil
    @Published var preferredTimeUTC: String = "00:30"
    @Published var timezone: String = TimeZone.current.identifier
    
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showSaveSuccess: Bool = false
    
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
            case .daily: return "sun.max.fill"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar"
            }
        }
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
            
            let body = PreferencesUpdateRequest(
                is_enabled: isEnabled,
                email_enabled: emailEnabled,
                push_enabled: pushEnabled,
                in_app_enabled: inAppEnabled,
                custom_instruction: customInstruction.isEmpty ? nil : customInstruction,
                frequency: frequency.rawValue,
                frequency_day: frequencyDay,
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
        customInstruction = (prefs["custom_instruction"]?.value as? String) ?? ""
        timezone = (prefs["timezone"]?.value as? String) ?? TimeZone.current.identifier
        preferredTimeUTC = (prefs["preferred_time_utc"]?.value as? String) ?? "00:30"
        
        if let freqStr = prefs["frequency"]?.value as? String,
           let freq = NotificationFrequency(rawValue: freqStr) {
            frequency = freq
        }
        
        frequencyDay = prefs["frequency_day"]?.value as? Int
    }
}

// MARK: - API Models

private struct PreferencesUpdateRequest: Encodable {
    let is_enabled: Bool
    let email_enabled: Bool
    let push_enabled: Bool
    let in_app_enabled: Bool
    let custom_instruction: String?
    let frequency: String
    let frequency_day: Int?
    let preferred_time_utc: String
    let timezone: String
}

struct PreferencesAPIResponse: Decodable {
    let success: Bool
    let preferences: [String: AnyCodable]
}
