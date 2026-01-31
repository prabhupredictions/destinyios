import Foundation

// MARK: - AstroData Request

struct UserAstroDataRequest: Codable {
    let birthData: UserBirthData
    let userEmail: String?
    
    init(birthData: UserBirthData, userEmail: String? = nil) {
        // Round coordinates to 6 decimal places to satisfy backend validation
        let roundedLat = (birthData.latitude * 1_000_000).rounded() / 1_000_000
        let roundedLong = (birthData.longitude * 1_000_000).rounded() / 1_000_000
        
        self.birthData = UserBirthData(
            dob: birthData.dob,
            time: birthData.time,
            latitude: roundedLat,
            longitude: roundedLong,
            ayanamsa: birthData.ayanamsa,
            houseSystem: birthData.houseSystem,
            cityOfBirth: birthData.cityOfBirth,
            gender: birthData.gender,
            birthTimeUnknown: birthData.birthTimeUnknown
        )
        self.userEmail = userEmail
    }
    
    enum CodingKeys: String, CodingKey {
        case birthData = "birth_data"
        case userEmail = "user_email"
    }
}

struct UserBirthData: Codable {
    let dob: String
    let time: String
    let latitude: Double
    let longitude: Double
    let ayanamsa: String
    let houseSystem: String
    let cityOfBirth: String?
    let gender: String?
    let birthTimeUnknown: Bool?
    
    enum CodingKeys: String, CodingKey {
        case dob, time, latitude, longitude
        case ayanamsa, houseSystem = "house_system"
        case cityOfBirth = "city_of_birth"
        case gender
        case birthTimeUnknown = "birth_time_unknown"
    }
    
    /// Round a coordinate to 6 decimal places (backend validation requirement)
    private static func roundCoordinate(_ value: Double) -> Double {
        (value * 1_000_000).rounded() / 1_000_000
    }
    
    init(dob: String, time: String, latitude: Double, longitude: Double, ayanamsa: String, houseSystem: String, cityOfBirth: String?, gender: String? = nil, birthTimeUnknown: Bool? = nil) {
        self.dob = dob
        self.time = time
        self.latitude = Self.roundCoordinate(latitude)
        self.longitude = Self.roundCoordinate(longitude)
        self.ayanamsa = ayanamsa
        self.houseSystem = houseSystem
        self.cityOfBirth = cityOfBirth
        self.gender = gender
        self.birthTimeUnknown = birthTimeUnknown
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dob = try container.decode(String.self, forKey: .dob)
        time = try container.decode(String.self, forKey: .time)
        latitude = Self.roundCoordinate(try container.decode(Double.self, forKey: .latitude))
        longitude = Self.roundCoordinate(try container.decode(Double.self, forKey: .longitude))
        ayanamsa = try container.decode(String.self, forKey: .ayanamsa)
        houseSystem = try container.decode(String.self, forKey: .houseSystem)
        cityOfBirth = try container.decodeIfPresent(String.self, forKey: .cityOfBirth)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        birthTimeUnknown = try container.decodeIfPresent(Bool.self, forKey: .birthTimeUnknown)
    }
}

// MARK: - AstroData Response

// MARK: - AstroData Response

struct UserAstroDataResponse: Codable {
    let birthDetails: AstroBirthDetails
    let planets: [String: PlanetData]
    let nakshatra: [String: NakshatraData]
    let divisionalCharts: [String: DivisionalPlanetData]  // Flat: Planet -> {sign, house}
    let houses: [String: HouseData]
    let strength: StrengthData
    let states: StatesData
    let analysis: AstroAnalysisData
    let other: OtherData
    
    enum CodingKeys: String, CodingKey {
        case birthDetails = "birth_details"
        case planets, nakshatra
        case divisionalCharts = "divisional_charts"
        case houses, strength, states, analysis, other
    }
}

// MARK: - Core Data Models

struct AstroBirthDetails: Codable {
    let dob: String
    let time: String
    let timezone: String
    let latitude: Double
    let longitude: Double
}

struct PlanetData: Codable {
    let sign: String
    let degree: Double
    let house: Int
    let isRetrograde: Bool?
    let isCombust: Bool?
    let vargottama: Bool?
    let conjunctWith: [String]?
    let aspectedBy: [String]?
    let code: String
    
    enum CodingKeys: String, CodingKey {
        case sign, degree, house, code, vargottama
        case isRetrograde = "is_retrograde"
        case isCombust = "is_combust"
        case conjunctWith = "conjunct_with"
        case aspectedBy = "aspected_by"
    }
}

struct NakshatraData: Codable {
    let nakshatra: String
    let nakshatraNum: Int
    let pada: Int
    let lord: String
    let padaLord: String
    
    enum CodingKeys: String, CodingKey {
        case nakshatra, pada, lord
        case nakshatraNum = "nakshatra_num"
        case padaLord = "pada_lord"
    }
}

struct DivisionalPlanetData: Codable {
    let sign: String?   // Made optional - API may return empty or missing
    let house: String?  // Made optional - API may return empty or missing
}

struct HouseData: Codable {
    let signNum: Int
    let lord: String
    let occupants: [String]
    let bhavaBala: Double
    let rank: Int
    let ashtakavarga: Int // House SAV score
    
    enum CodingKeys: String, CodingKey {
        case signNum = "sign_num"
        case lord, occupants, rank, ashtakavarga
        case bhavaBala = "bhava_bala"
    }
}

// MARK: - Strength & States

struct StrengthData: Codable {
    let shadbala: [String: ShadbalaDetails]?
    let dignity: [String: DignityData]?
    let vimsopaka: [String: VimsopakaDetails]?
    let shodasvarga: [String: ShodasvargaDetails]?
}

struct ShadbalaDetails: Codable {
    let rupas: Double
    let virupas: Double
    let pct: Double
    let category: String
}

struct DignityData: Codable {
    let dignity: String
    let score: Double
    let sign: String?
    let vargottama: Bool?
}

struct VimsopakaDetails: Codable {
    let score: Double
}

struct ShodasvargaDetails: Codable {
    let level: Int
    let name: String
    let strongCharts: [String]
    
    enum CodingKeys: String, CodingKey {
        case level, name
        case strongCharts = "strong_charts"
    }
}

struct StatesData: Codable {
    let avasthas: [String: AvasthaDetails]?
    let functionalNature: FunctionalNatureResponse? 
    
    enum CodingKeys: String, CodingKey {
        case avasthas
        case functionalNature = "functional_nature"
    }
}

struct AvasthaDetails: Codable {
    let jagratadi: String
    let baladi: String
    let sayanadi: String
    let sayanadiIndex: Int
    let chestha: String
    let lajjitadi: String?
    let deeptadi: [String]
    
    enum CodingKeys: String, CodingKey {
        case jagratadi, baladi, sayanadi, chestha, lajjitadi, deeptadi
        case sayanadiIndex = "sayanadi_index"
    }
}

struct FunctionalNatureResponse: Codable {
    let benefics: [String]
    let malefics: [String]
    let yogakaraka: [String]
    let neutrals: [String]
}

// MARK: - Analysis (Yogas/Doshas)

// MARK: - Analysis (Yogas/Doshas)

struct AstroAnalysisData: Codable {
    let yogas: YogasContainer?  // API returns {yogas: [], doshas: []}
    let mangalDosha: AstroMangalDoshaResult?
    let kalaSarpa: AstroKalaSarpaResult?
    
    enum CodingKeys: String, CodingKey {
        case yogas
        case mangalDosha = "mangal_dosha"
        case kalaSarpa = "kala_sarpa"
    }
}

struct YogasContainer: Codable {
    let yogas: [YogaDetail]?
    let doshas: [YogaDetail]?
}

struct YogaDetail: Codable {
    let name: String
    let planets: String
    let houses: String
    let status: String
    let strength: Double
    let isDosha: Bool
    let category: String? // Added for filtering
    let formation: String? // How the yoga is formed
    let reason: String? // Why cancelled/reduced (if applicable)
    
    enum CodingKeys: String, CodingKey {
        case name, planets, houses, status, strength, category, formation, reason
        case isDosha = "is_dosha"
    }
    
    // Helper to clean name (removes suffix numbers/ID)
    var displayName: String {
        // 1. If contains "Yoga" or "Dosha", truncate everything after it
        if let range = name.range(of: "Yoga", options: .caseInsensitive) {
            return String(name[..<range.upperBound])
        }
        if let range = name.range(of: "Dosha", options: .caseInsensitive) {
            return String(name[..<range.upperBound])
        }
        
        // 2. Fallback: Remove trailing numbers/parens
        return name.replacingOccurrences(of: "\\s*\\(?\\d+\\)?\\s*$", with: "", options: .regularExpression)
    }
}

struct AstroMangalDoshaResult: Codable {
    let hasDosha: Bool
    let severity: String
    let score: Double
    let exceptions: Bool
    let marsPosition: AstroMarsPosition?
    
    enum CodingKeys: String, CodingKey {
        case hasDosha = "has_mangal_dosha"
        case severity, exceptions
        case score = "dosha_score"
        case marsPosition = "mars_position"
    }
}

struct AstroMarsPosition: Codable {
    // Define if needed, or use [String: Any] decoding if strictness not required (but Codable requires types)
    // Assuming simple dict or specific structure. 
    // For now, making it generic or skipping specific nesting if not critical for UI yet.
    // If tools returns complex object, we need struct. 
    // Adapter L842: `raw.get("mars_position", {})`. 
    // It's likely dict with 'house', 'sign'.
    let house: Int?
    let sign: String?
}

struct AstroKalaSarpaResult: Codable {
    let yogaPresent: Bool
    let yogaType: String?
    let doshaName: String?
    let severity: String
    let completeness: String?  // API can return null
    let peakPeriod: String?
    
    enum CodingKeys: String, CodingKey {
        case yogaPresent = "yoga_present"
        case yogaType = "yoga_type"
        case doshaName = "dosha_name"
        case severity, completeness
        case peakPeriod = "peak_period"
    }
}

// MARK: - Other Data

struct OtherData: Codable {
    let upgrahas: [String: UpgrahaData]?
    let d60Amsa: [String: D60Data]?
    let ashtakavarga: AshtakavargaData?
    let aspects: [String: String]?  // Empty dict from API - placeholder
    let bhavatBhavam: [String: BhavatBhavamData]?
    
    enum CodingKeys: String, CodingKey {
        case upgrahas, ashtakavarga, aspects
        case d60Amsa = "d60_amsa"
        case bhavatBhavam = "bhavat_bhavam"
    }
}

struct BhavatBhavamData: Codable {
    let bhavatBhavamHouse: Int
    let lossHouse: Int
    let primaryCondition: String
    let bbCondition: String
    let lordRelationship: String
    let supportScore: Int
    
    enum CodingKeys: String, CodingKey {
        case bhavatBhavamHouse = "bhavat_bhavam_house"
        case lossHouse = "loss_house"
        case primaryCondition = "primary_condition"
        case bbCondition = "bb_condition"
        case lordRelationship = "lord_relationship"
        case supportScore = "support_score"
    }
}

struct UpgrahaData: Codable {
    let house: String
    let sign: String
    let longitude: Double
}

struct D60Data: Codable {
    let sign: String
    let amsaNumber: Int
    let devata: String
    let nature: String
    let isPretaPurisha: Bool
    
    enum CodingKeys: String, CodingKey {
        case sign, devata, nature
        case amsaNumber = "amsa_number"
        case isPretaPurisha = "is_preta_purisha"
    }
}

struct AshtakavargaData: Codable {
    let bav: [String: [Int]]?  // Planet -> List of 12 scores
    let sav: [Int]?            // List of 12 scores (Aries to Pisces)
    let pav: [Int]?            // Prastarashtakavarga if present
}

// MARK: - Time Based Models (Dasha/Transits)

struct DashaResponse: Codable {
    let year: Int
    let periods: [DashaPeriod]
    
    enum CodingKeys: String, CodingKey {
        case year
        case periods = "dasha_periods"
    }
}

struct DashaPeriod: Codable {
    let mahadasha: String
    let antardasha: String
    let pratyantardasha: String
    let start: String
    let end: String
    
    enum CodingKeys: String, CodingKey {
        case mahadasha = "mahadasha_lord"
        case antardasha = "antardasha_lord"
        case pratyantardasha = "pratyantardasha_lord"
        case start, end
    }
}

struct TransitResponse: Codable {
    let year: Int
    let transits: [String: [TransitEvent]] // Planet -> [Event]
}

struct TransitEvent: Codable {
    let date: String
    let sign: String
    let houseFromLagna: Int
    let favorable: Bool
    
    
    enum CodingKeys: String, CodingKey {
        case date, sign, favorable
        case houseFromLagna = "house_from_lagna"
    }
}

// MARK: - Today's Prediction

// NEW: Dasha Insight from API
struct DashaInsight: Codable {
    let period: String
    let quality: String  // "Good" | "Steady" | "Caution"
    let theme: String
    let endDate: String?
    let meaning: String?
    
    enum CodingKeys: String, CodingKey {
        case period, quality, theme, meaning
        case endDate = "end_date"
    }
}

// NEW: Transit Influence card data
struct TransitInfluence: Codable, Identifiable {
    let planet: String
    let sign: String
    let house: Int
    let description: String
    let badge: String
    let badgeType: String  // "positive" | "caution" | "warning" | "neutral"
    
    var id: String { planet }
    
    enum CodingKeys: String, CodingKey {
        case planet, sign, house, description, badge
        case badgeType = "badge_type"
    }
}

struct TodaysPredictionResponse: Codable {
    let predictionId: String
    let targetDate: String
    let currentDasha: String
    let dashaInsight: DashaInsight?  // NEW
    let lifeAreas: [String: LifeAreaStatus]
    let mindQuestions: [String]
    let todaysInsight: String
    let transitInfluences: [TransitInfluence]?  // NEW
    let timingAdvice: TimingAdvice?
    let currentTransits: [String: TransitPosition]?
    
    enum CodingKeys: String, CodingKey {
        case predictionId = "prediction_id"
        case targetDate = "target_date"
        case currentDasha = "current_dasha"
        case dashaInsight = "dasha_insight"
        case lifeAreas = "life_areas"
        case mindQuestions = "mind_questions"
        case todaysInsight = "todays_insight"
        case transitInfluences = "transit_influences"
        case timingAdvice = "timing_advice"
        case currentTransits = "current_transits"
    }
}

struct LifeAreaStatus: Codable {
    let status: String
    let brief: String
}

struct TimingAdvice: Codable {
    let auspicious: [String]
    let inauspicious: [String]
    let note: String?
}

struct TransitPosition: Codable {
    let date: String
    let sign: String
    let houseFromLagna: Int
    let houseFromMoon: Int
    
    enum CodingKeys: String, CodingKey {
        case date, sign
        case houseFromLagna = "house_from_lagna"
        case houseFromMoon = "house_from_moon"
    }
}

