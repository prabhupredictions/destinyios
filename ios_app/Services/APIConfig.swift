import Foundation

struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:8000"
    static let apiVersion = ""
    static let apiKey = "astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic"
    #else
    static let baseURL = "https://astroapi-v2-668639087682.asia-south1.run.app"
    static let apiVersion = "/api/v1"
    static let apiKey = "" // Set via environment or keychain
    #endif
    
    // Astrology Endpoints
    static let predict = "/vedic/api/predict/"
    static let predictStream = "/vedic/api/predict/stream"
    static let compatibility = "/vedic/api/compatibility/analyze"
    static let compatibilityStream = "/vedic/api/compatibility/analyze/stream"
    static let compatibilityFollowUp = "/vedic/api/compatibility/follow-up"
    static let chatHistory = "/chat-history"
    static let feedback = "/feedback/submit"
    
    // Subscription Endpoints
    static let subscriptionRegister = "/subscription/register"
    static let subscriptionStatus = "/subscription/status"
    static let subscriptionRecord = "/subscription/record"
    static let subscriptionUpgrade = "/subscription/upgrade"
    static let subscriptionVerify = "/subscription/verify"
}

