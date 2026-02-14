import Foundation

// MARK: - Environment Configuration
enum AppEnvironment: String {
    case local = "local"
    case test = "test"
    case production = "production"
    
    static var current: AppEnvironment {
        if let envString = Bundle.main.object(forInfoDictionaryKey: "ENVIRONMENT") as? String,
           let env = AppEnvironment(rawValue: envString) {
            return env
        }
        #if DEBUG
        return .local
        #else
        return .production
        #endif
    }
}

// MARK: - API Configuration
struct APIConfig {
    
    // Base URL from Info.plist (set by xcconfig) or fallback
    static var baseURL: String {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        // Fallback based on environment
        switch AppEnvironment.current {
        case .local:
            return "http://127.0.0.1:8000"
        case .test:
            return "https://astroapi-test-dsqvza5jza-el.a.run.app"
        case .production:
            return "https://astroapi-prod-dsqvza5jza-el.a.run.app"
        }
    }
    
    // API Key from Info.plist or fallback
    static var apiKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !key.isEmpty {
            return key
        }
        switch AppEnvironment.current {
        case .local:
            return "astro_live_e7-TG6TTi14WaYxIwiyxes-aGdhlUrQ8gVUIj5STVnE"
        case .test, .production:
            return "astro_live_destinyai_production_key_2024"
        }
    }
    
    static var apiVersion: String { "" }
    
    // MARK: - Astrology Endpoints
    static let predict = "/vedic/api/predict/"
    static let predictStream = "/vedic/api/predict/stream"
    static let todaysPrediction = "/vedic/api/todays-prediction"
    static let compatibility = "/vedic/api/compatibility/analyze"
    static let compatibilityStream = "/vedic/api/compatibility/analyze/stream"
    static let compatibilityFollowUp = "/vedic/api/compatibility/follow-up"
    static let chatHistory = "/chat-history"
    static let feedback = "/feedback/submit"
    
    // MARK: - AstroData Endpoints
    static let astroDataFull = "/vedic/api/astrodata/full"
    static let astroDataDasha = "/vedic/api/astrodata/dasha"
    static let astroDataTransits = "/vedic/api/astrodata/transits"
    
    // MARK: - Subscription Endpoints
    static let subscriptionRegister = "/subscription/register"
    static let subscriptionStatus = "/subscription/status"
    static let subscriptionRecord = "/subscription/record"
    static let subscriptionUpgrade = "/subscription/upgrade"
    static let subscriptionVerify = "/subscription/verify"
}
