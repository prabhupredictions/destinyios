import Foundation

enum NotificationDeepLink: Equatable {
    case home
    case chat(prefill: String, autoSubmit: Bool, newThread: Bool)
    case match
    case settings
    case paywall
}

@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()
    private init() {}

    var pendingDeepLink: NotificationDeepLink?

    /// Routes by notification type, optionally prefilling the chat input.
    func route(type: String, prefill: String = "", autoSubmit: Bool = false, newThread: Bool = false) {
        switch type.uppercased() {
        case "DAILY_PREDICTION_READY", "DAILY_PREDICTION",
             "TRANSIT_ALERT", "LIFE_ALERT", "CUSTOM_ALERT",
             "WELCOME":
            pendingDeepLink = .chat(prefill: prefill, autoSubmit: autoSubmit, newThread: newThread)
        case "COMPATIBILITY_READY":
            pendingDeepLink = .match
        case "SUBSCRIPTION_EXPIRING", "SUBSCRIPTION_EXPIRED":
            // Expiry/renewal notifications must land on the paywall so the user
            // can renew — not the Home tab (the old `.settings` → tab 0 mapping
            // dropped them on Home with no renewal path, part of the
            // "infinite loop instead of paywall" complaint).
            pendingDeepLink = .paywall
        default:
            pendingDeepLink = .home
        }
    }
}
