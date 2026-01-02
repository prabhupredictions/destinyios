import Foundation

struct APIConfig {
    #if DEBUG
    // Using 127.0.0.1 to avoid IPv6 ::1 connection issues on Simulator
    static let baseURL = "http://127.0.0.1:8000"
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
    static let todaysPrediction = "/vedic/api/todays-prediction"
    static let compatibility = "/vedic/api/compatibility/analyze"
    static let compatibilityStream = "/vedic/api/compatibility/analyze/stream"
    static let compatibilityFollowUp = "/vedic/api/compatibility/follow-up"
    static let chatHistory = "/chat-history"
    static let feedback = "/feedback/submit"
    
    // AstroData Endpoints
    static let astroDataFull = "/vedic/api/astrodata/full"
    static let astroDataDasha = "/vedic/api/astrodata/dasha"
    static let astroDataTransits = "/vedic/api/astrodata/transits"
    
    // Subscription Endpoints
    static let subscriptionRegister = "/subscription/register"
    static let subscriptionStatus = "/subscription/status"
    static let subscriptionRecord = "/subscription/record"
    static let subscriptionUpgrade = "/subscription/upgrade"
    static let subscriptionVerify = "/subscription/verify"
}

