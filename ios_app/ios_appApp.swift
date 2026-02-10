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
