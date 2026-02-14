//
//  ios_appApp.swift
//  ios_app
//
//  Created by I074917 on 17/12/25.
//

import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
import UserNotifications

@main
struct ios_appApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Configure Google Sign-In on app launch
        #if canImport(GoogleSignIn)
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
            print("🔹 [App] Configuring Google Sign-In with ClientID: \(clientID)")
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        } else {
            print("❌ [App] GIDClientID not found in Info.plist")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .onOpenURL { url in
                    // Handle Google Sign-In callback
                    #if canImport(GoogleSignIn)
                    GIDSignIn.sharedInstance.handle(url)
                    #endif
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                BackgroundTaskHelper.shared.beginTask()
            case .active:
                BackgroundTaskHelper.shared.endTask()
            default:
                break
            }
        }
    }
}

// MARK: - Background Task Helper
/// Keeps all in-flight network requests alive when the app enters background.
/// iOS grants ~30 seconds of extra execution time before suspending.
final class BackgroundTaskHelper {
    static let shared = BackgroundTaskHelper()
    private var taskID: UIBackgroundTaskIdentifier = .invalid
    
    func beginTask() {
        guard taskID == .invalid else { return } // Already running
        taskID = UIApplication.shared.beginBackgroundTask(withName: "app-keep-alive") { [weak self] in
            // Expiration handler — iOS is about to suspend, clean up
            print("[Background] ⚠️ Background time expiring")
            self?.endTask()
        }
        let remaining = UIApplication.shared.backgroundTimeRemaining
        print("[Background] 📱 App entered background — task started (remaining: \(String(format: "%.0f", remaining))s)")
    }
    
    func endTask() {
        guard taskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(taskID)
        taskID = .invalid
        print("[Background] ✅ Background task ended")
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Set notification center delegate for foreground notifications
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Forward token to our push notification service for backend registration
        PushNotificationService.shared.handleDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // Handle foreground notifications - show banner even when app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification tap - navigate to relevant content
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("🔔 Notification tapped: \(userInfo)")
        
        // Post notification for navigation (deep linking)
        if let eventType = userInfo["type"] as? String {
             print("➡️ Navigating to event: \(eventType)")
        }
        completionHandler()
    }
}
// Build trigger - 2026-02-07T08:58:23Z
// Build trigger - 2026-02-07T10:47:14Z

// Trigger rebuild: 20260207212846

// Prod Sync: 20260207222132
