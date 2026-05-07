import Foundation

enum NotificationDeepLink {
    case home, chat, match, settings
}

@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()
    private init() {}

    var pendingDeepLink: NotificationDeepLink?

    func route(type: String) {
        switch type.uppercased() {
        case "DAILY_PREDICTION_READY", "DAILY_PREDICTION",
             "TRANSIT_ALERT", "LIFE_ALERT", "CUSTOM_ALERT",
             "WELCOME":
            pendingDeepLink = .home
        case "COMPATIBILITY_READY":
            pendingDeepLink = .match
        case "SUBSCRIPTION_EXPIRING":
            pendingDeepLink = .settings
        default:
            pendingDeepLink = .home
        }
    }
}
