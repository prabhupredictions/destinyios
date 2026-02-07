import SwiftUI
import Combine
import UserNotifications

/// Push Notification Service using native APNs (no Firebase dependency)
/// Registers device token with backend API for push notification delivery
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var deviceToken: String?
    @Published var notificationPermissionGranted = false
    
    // MARK: - Request Permission
    
    /// Request notification permission from user
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("✅ Push permission granted, registering for remote notifications")
                } else {
                    print("⚠️ Push permission denied")
                }
            }
            if let error = error {
                print("❌ Push permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Handle Device Token
    
    /// Called by AppDelegate when APNs token is received
    func handleDeviceToken(_ tokenData: Data) {
        // Convert token data to hex string
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        
        DispatchQueue.main.async {
            self.deviceToken = tokenString
        }
        
        print("🔔 APNs Token received: \(tokenString.prefix(20))...")
        
        // Register with our backend
        registerToken(tokenString)
    }
    
    // MARK: - Register Token with Backend
    
    /// Register APNs token with backend API
    func registerToken(_ token: String) {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else {
            print("⚠️ Cannot register token: no userEmail in UserDefaults")
            return
        }
        
        // Get app version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        // Prepare request body
        let body: [String: Any] = [
            "user_email": userEmail,
            "token": token,
            "platform": "ios",
            "app_version": appVersion
        ]
        
        // Async API call
        Task {
            do {
                guard let url = URL(string: "\(APIConfig.baseURL)/notifications/device-token") else {
                    print("❌ Invalid URL for token registration")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ Device token registered with backend")
                        UserDefaults.standard.set(token, forKey: "pushToken")
                    } else {
                        print("⚠️ Token registration returned status: \(httpResponse.statusCode)")
                    }
                }
            } catch {
                print("❌ Token registration failed: \(error)")
            }
        }
    }
}
