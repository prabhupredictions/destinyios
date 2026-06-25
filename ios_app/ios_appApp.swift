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
        // C3 (1.7) — First-launch keychain wipe. iOS keychain SURVIVES app uninstall,
        // but UserDefaults does not. Without this guard, a reinstalled app inherits
        // stale session JWTs / appAccountTokens / Apple Sign-In credentials from the
        // previous install, leading to weird auth/Storekit states that even sign-out
        // can't reach.
        //
        // We only wipe when ALL of the following indicate a true fresh install:
        //   - hasLaunchedBefore == false
        //   - userEmail UserDefault is nil
        //   - w7_current_session_email UserDefault is nil
        //   - no keychain keys with prefix "w7_session_jwt::"
        //   - no keychain keys with prefix "appAccountToken::"
        //   - no keychain keys with prefix "appleEmail_" or "appleName_"
        //     (Apple Sign-In writes these once and Apple returns nil on subsequent
        //     sign-ins for the same Apple ID — wiping them would lock the user out.)
        //
        // If ANY probe is .indeterminate (keychain locked at launch), we DO NOT wipe
        // and DO NOT set hasLaunchedBefore so a future unlocked launch can re-evaluate.
        Self.performFirstLaunchKeychainWipeIfNeeded()

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

    private static func performFirstLaunchKeychainWipeIfNeeded() {
        let ud = UserDefaults.standard
        guard !ud.bool(forKey: "hasLaunchedBefore") else { return }

        let keychain = KeychainService.shared

        // Probe every signal that survives uninstall.
        let prefixesToProbe = [
            "w7_session_jwt::",
            "appAccountToken::",
            "appleEmail_",
            "appleName_"
        ]

        var sawPresent = false
        var sawIndeterminate = false
        for prefix in prefixesToProbe {
            switch keychain.probeAnyKey(withPrefix: prefix) {
            case .present:
                sawPresent = true
            case .indeterminate:
                sawIndeterminate = true
            case .absent:
                break
            }
        }

        // UserDefaults signals (cannot survive uninstall, but cover the
        // sign-out-then-relaunch case where keychain has been cleared).
        if let s = ud.string(forKey: "userEmail"), !s.isEmpty { sawPresent = true }
        if let s = ud.string(forKey: "w7_current_session_email"), !s.isEmpty { sawPresent = true }

        if sawIndeterminate && !sawPresent {
            // Keychain locked + no other definitive signal — DEFER. Do not wipe,
            // do not latch hasLaunchedBefore, so we can re-evaluate next launch.
            print("⏸ [App] First launch but keychain probe indeterminate — deferring first-launch wipe decision")
            return
        }

        // Latch the flag BEFORE the wipe so a crash mid-wipe doesn't loop us.
        ud.set(true, forKey: "hasLaunchedBefore")

        if sawPresent {
            print("✅ [App] First launch but prior state detected — preserving keychain")
        } else {
            print("🧹 [App] First launch with no prior state — clearing keychain")
            keychain.clearAll()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Crash fix (1.8.x): the legacy `GIDSignIn.handle(url)`
                    // call has been removed. This app uses the modern
                    // `signIn(withPresenting:)` API (see AppleAuthService.swift)
                    // which manages its own URL callback through
                    // ASWebAuthenticationSession — no manual URL forwarding
                    // is required. The previous unconditional call forwarded
                    // to AppAuth's OIDAuthorizationSession, which raises an
                    // NSException ("resumeExternalUserAgentFlowWithURL must
                    // be called while a flow is in progress.") when no
                    // sign-in is pending — killing the app via SIGABRT.
                    // Seen in production (1.7 build 418) when iOS delivered
                    // a stale OAuth callback URL after the app was relaunched.
                    //
                    // If we add other URL-scheme features (deep links, magic
                    // links), route them here with a scheme guard — never
                    // forward unconditionally to a third-party SDK.
                    print("🔗 [App] Received URL: \(url.scheme ?? "?") \(url.host ?? "")")
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                BackgroundTaskHelper.shared.beginTask()
                // Stop the foreground sync timer to save resources.
                SubscriptionManager.shared.stopForegroundSyncTimer()
            case .active:
                BackgroundTaskHelper.shared.endTask()
                // Warm up Cloud Run and refresh subscription state when returning from background
                if oldPhase != .active {
                    BackendWarmUpService.shared.ping()
                    // Reconcile StoreKit entitlements with backend on every foreground.
                    // Catches offer-code redemptions that happened while app was killed
                    // (Transaction.updates may not fire for those). Idempotent.
                    Task { await SubscriptionManager.shared.reconcileEntitlementsWithBackend() }
                    // Force-sync quota on every foreground so external changes
                    // (App Store cancellation, auto-renew toggle, offer code
                    // redemption while app was backgrounded) reflect immediately.
                    // Bypasses the 5-min cooldown which would otherwise leave
                    // the UI showing stale subscription state.
                    let email = DataManager.shared.getCurrentUserProfile()?.email
                        ?? UserDefaults.standard.string(forKey: "userEmail")
                    if let email {
                        Task { try? await QuotaManager.shared.syncStatus(email: email, force: true) }
                    }
                    // Start the periodic sync timer (INV-2 Gap A) — keeps UI fresh
                    // during long foreground sessions. Stops when app backgrounds.
                    SubscriptionManager.shared.startForegroundSyncTimer()
                    // Sync app icon badge to server unread count on every foreground.
                    Task { await NotificationInboxService.shared.fetchUnreadCount() }
                }
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
            // Expiration handler — iOS is about to suspend, cancel streaming cleanly
            print("[Background] ⚠️ Background time expiring — cancelling any in-flight stream")
            NotificationCenter.default.post(name: .streamingBackgroundExpired, object: nil)
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
        let eventType  = userInfo["type"]        as? String ?? ""
        let chatPrompt = userInfo["chat_prompt"] as? String ?? ""
        NotificationRouter.shared.route(type: eventType, prefill: chatPrompt)
        completionHandler()
    }
}

extension Notification.Name {
    static let streamingBackgroundExpired = Notification.Name("streamingBackgroundExpired")
}

// MARK: - Backend Warm-Up Service
/// Sends a lightweight GET /health ping when the app returns to foreground.
/// Cloud Run scales to zero after ~15 minutes of inactivity. The ping fires
/// immediately on foreground so the cold start (20–60s) completes before the
/// user finishes typing their first query.
final class BackendWarmUpService {
    static let shared = BackendWarmUpService()
    private var lastPingDate: Date = .distantPast
    private let minInterval: TimeInterval = 60  // don't ping more than once per minute

    func ping() {
        guard Date().timeIntervalSince(lastPingDate) > minInterval else { return }
        lastPingDate = Date()

        guard let url = URL(string: "\(APIConfig.baseURL)/health") else { return }

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        let session = URLSession(configuration: config)

        var request = URLRequest(url: url)
        // W7 — send session JWT when available, else fall back to bundled API key.
        request.setValue(NetworkClient.authBearer(), forHTTPHeaderField: "Authorization")
        request.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")

        let task = session.dataTask(with: request) { _, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("[WarmUp] /health ping → \(status)")
        }
        task.resume()
    }
}
// Build trigger - 2026-02-07T08:58:23Z
// Build trigger - 2026-02-07T10:47:14Z

// Trigger rebuild: 20260207212846

// Prod Sync: 20260207222132
