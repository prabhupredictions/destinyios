//
//  DoshaModels.swift
//  ios_app
//
//  Models for Mangal Dosha, Kala Sarpa, and Yogas data from backend
//

import Foundation

// MARK: - Mangal Dosha

struct MangalDoshaData: Codable {
    let hasMangalDosha: Bool
    let severity: String
    let score: Double  // API sends "score" OR "dosha_score" depending on source
    let marsPosition: [String: AnyCodable]?  // API sends empty {} or complex object
    let exceptions: AnyCodable?  // API sends boolean OR dictionary
    let exceptionCount: Int?
    let intensityFactors: [String: Bool]?
    let intensityFactorCount: Int?
    let remedies: [String]?
    let explanation: String?
    let doshaFrom: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case hasMangalDosha = "has_mangal_dosha"
        case severity
        case score
        case doshaScore = "dosha_score"  // Alternative key from raw tool output
        case marsPosition = "mars_position"
        case exceptions
        case exceptionCount = "exception_count"
        case intensityFactors = "intensity_factors"
        case intensityFactorCount = "intensity_factor_count"
        case remedies
        case explanation
        case doshaFrom = "dosha_from"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasMangalDosha = try container.decode(Bool.self, forKey: .hasMangalDosha)
        severity = try container.decode(String.self, forKey: .severity)
        
        // Try "score" first, then "dosha_score"
        if let scoreVal = try? container.decode(Double.self, forKey: .score) {
            score = scoreVal
        } else if let doshaScoreVal = try? container.decode(Double.self, forKey: .doshaScore) {
            score = doshaScoreVal
        } else {
            score = 0.0
        }
        
        marsPosition = try container.decodeIfPresent([String: AnyCodable].self, forKey: .marsPosition)
        exceptions = try container.decodeIfPresent(AnyCodable.self, forKey: .exceptions)
        exceptionCount = try container.decodeIfPresent(Int.self, forKey: .exceptionCount)
        intensityFactors = try container.decodeIfPresent([String: Bool].self, forKey: .intensityFactors)
        intensityFactorCount = try container.decodeIfPresent(Int.self, forKey: .intensityFactorCount)
        remedies = try container.decodeIfPresent([String].self, forKey: .remedies)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        doshaFrom = try container.decodeIfPresent([String: AnyCodable].self, forKey: .doshaFrom)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasMangalDosha, forKey: .hasMangalDosha)
        try container.encode(severity, forKey: .severity)
        try container.encode(score, forKey: .score)
        try container.encodeIfPresent(marsPosition, forKey: .marsPosition)
        try container.encodeIfPresent(exceptions, forKey: .exceptions)
        try container.encodeIfPresent(exceptionCount, forKey: .exceptionCount)
        try container.encodeIfPresent(intensityFactors, forKey: .intensityFactors)
        try container.encodeIfPresent(intensityFactorCount, forKey: .intensityFactorCount)
        try container.encodeIfPresent(remedies, forKey: .remedies)
        try container.encodeIfPresent(explanation, forKey: .explanation)
        try container.encodeIfPresent(doshaFrom, forKey: .doshaFrom)
    }
    
    /// Dosha score for display (0.0 to 1.0)
    var doshaScore: Double {
        return score
    }
    
    /// Get active exceptions (only when exceptions is a dictionary)
    var activeExceptions: [String] {
        guard let excValue = exceptions?.value else { return [] }
        if let excDict = excValue as? [String: Any] {
            return excDict.compactMap { (key, val) in
                // Handle Bool directly
                if let boolVal = val as? Bool {
                    return boolVal ? key : nil
                }
                // Handle NSNumber (JSON may decode bools as 0/1)
                if let numVal = val as? NSNumber {
                    return numVal.boolValue ? key : nil
                }
                // Handle Int (some decoders use Int for bools)
                if let intVal = val as? Int {
                    return intVal != 0 ? key : nil
                }
                return nil
            }
        }
        return []
    }
    
    /// Get active intensity factors (only true values)
    var activeIntensityFactors: [String] {
        return intensityFactors?.compactMap { $0.value ? $0.key : nil } ?? []
    }
    
    /// Display severity label
    var severityLabel: String {
        return DoshaDescriptions.severity(severity)
    }
    
    /// Get exception descriptions for display
    var exceptionDescriptions: [String] {
        return activeExceptions.map { DoshaDescriptions.exception($0) }
    }
    
    /// Get intensity factor descriptions for display
    var intensityDescriptions: [String] {
        return activeIntensityFactors.map { DoshaDescriptions.intensity($0) }
    }
    
    /// Display active dosha sources from the dosha_from dictionary
    var activeDoshaSourcesDisplay: String? {
        guard let doshaDict = doshaFrom else {
            print("[DoshaSource] ❌ doshaFrom is nil — no chart source available")
            return nil
        }
        
        print("[DoshaSource] ✅ doshaFrom has \(doshaDict.count) keys: \(Array(doshaDict.keys).sorted())")
        
        // Debug: print each key's value and type
        for (key, anyCodable) in doshaDict {
            print("[DoshaSource]   key='\(key)' value=\(String(describing: anyCodable.value)) type=\(type(of: anyCodable.value))")
        }
        
        var sources: [String] = []
        
        // Helper to safely extract Int
        func getInt(_ key: String) -> Int? {
            if let val = doshaDict[key]?.value {
                let result = extractHouseNumber(from: val)
                print("[DoshaSource]   getInt('\(key)'): val=\(val) -> \(String(describing: result))")
                return result
            }
            print("[DoshaSource]   getInt('\(key)'): key not found in doshaDict")
            return nil
        }
        
        // Helper to safely extract Bool (handles Bool, NSNumber, Int)
        func getBool(_ key: String) -> Bool {
            guard let val = doshaDict[key]?.value else { 
                print("[DoshaSource]   getBool('\(key)'): key not found")
                return false 
            }
            let result: Bool
            if let boolVal = val as? Bool {
                result = boolVal
                print("[DoshaSource]   getBool('\(key)'): Bool -> \(result)")
            } else if let numVal = val as? NSNumber {
                result = numVal.boolValue
                print("[DoshaSource]   getBool('\(key)'): NSNumber(\(numVal)) -> \(result)")
            } else if let intVal = val as? Int {
                result = intVal != 0
                print("[DoshaSource]   getBool('\(key)'): Int(\(intVal)) -> \(result)")
            } else {
                result = false
                print("[DoshaSource]   getBool('\(key)'): unknown type \(type(of: val)) -> false")
            }
            return result
        }
        
        // Check Lagna Chart
        let lagnaActive = getBool("lagna")
        if lagnaActive, let house = getInt("mars_house_from_lagna") {
            sources.append("House \(house) (from Lagna)")
            print("[DoshaSource] ✅ Added Lagna source: House \(house)")
        }
        
        // Check Moon Chart
        let moonActive = getBool("moon")
        if moonActive, let house = getInt("mars_house_from_moon") {
            sources.append("House \(house) (from Moon)")
            print("[DoshaSource] ✅ Added Moon source: House \(house)")
        }
        
        // Check Venus Chart
        let venusActive = getBool("venus")
        if venusActive, let house = getInt("mars_house_from_venus") {
            sources.append("House \(house) (from Venus)")
            print("[DoshaSource] ✅ Added Venus source: House \(house)")
        }
        
        let result = sources.isEmpty ? nil : sources.joined(separator: " • ")
        print("[DoshaSource] 📊 Final result: \(String(describing: result)) (sources.count=\(sources.count))")
        return result
    }
}

// Helper to extract house number from AnyCodable value outside View scope
private func extractHouseNumber(from value: Any) -> Int? {
    if let intVal = value as? Int {
        return intVal
    } else if let doubleVal = value as? Double {
        return Int(doubleVal)
    } else if let nsNum = value as? NSNumber {
        return nsNum.intValue
    }
    return nil
}

struct MarsPosition: Codable {
    let house: Int
    let sign: String
    let nakshatra: String
    let degree: Double?
    
    /// Get human-readable position string
    var displayString: String {
        return "\(house.ordinal) House • \(DoshaDescriptions.sign(sign))"
    }
}

// MARK: - Kala Sarpa

struct KalaSarpaData: Codable {
    let present: Bool  // API sends "present" OR "yoga_present" depending on source
    let type: String?  // API sends "type" OR "yoga_type" depending on source
    let completeness: String?
    let severity: String?
    let planetsCount: Int?
    let planetsInvolved: [String]?
    let lifeAreas: [String]?
    let peakPeriod: String?
    let remedies: [String]?
    let doshaName: String?  // Added for raw API compatibility
    let analysisNotes: [String]?  // Additional analysis notes
    
    enum CodingKeys: String, CodingKey {
        case present
        case yogaPresent = "yoga_present"  // Alternative key
        case type
        case yogaType = "yoga_type"  // Alternative key
        case completeness
        case severity
        case planetsCount = "planets_count"
        case planetsInvolved = "planets_involved"
        case lifeAreas = "life_areas"
        case peakPeriod = "peak_period"
        case remedies
        case doshaName = "dosha_name"
        case analysisNotes = "analysis_notes"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try "present" first, then "yoga_present"
        if let presentVal = try? container.decode(Bool.self, forKey: .present) {
            present = presentVal
        } else if let yogaPresentVal = try? container.decode(Bool.self, forKey: .yogaPresent) {
            present = yogaPresentVal
        } else {
            present = false
        }
        
        // Try "type" first, then "yoga_type"
        if let typeVal = try? container.decode(String.self, forKey: .type) {
            type = typeVal
        } else if let yogaTypeVal = try? container.decode(String.self, forKey: .yogaType) {
            type = yogaTypeVal
        } else {
            type = nil
        }
        
        completeness = try container.decodeIfPresent(String.self, forKey: .completeness)
        severity = try container.decodeIfPresent(String.self, forKey: .severity)
        planetsCount = try container.decodeIfPresent(Int.self, forKey: .planetsCount)
        planetsInvolved = try container.decodeIfPresent([String].self, forKey: .planetsInvolved)
        lifeAreas = try container.decodeIfPresent([String].self, forKey: .lifeAreas)
        peakPeriod = try container.decodeIfPresent(String.self, forKey: .peakPeriod)
        remedies = try container.decodeIfPresent([String].self, forKey: .remedies)
        doshaName = try container.decodeIfPresent(String.self, forKey: .doshaName)
        analysisNotes = try container.decodeIfPresent([String].self, forKey: .analysisNotes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(present, forKey: .present)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(completeness, forKey: .completeness)
        try container.encodeIfPresent(severity, forKey: .severity)
        try container.encodeIfPresent(planetsCount, forKey: .planetsCount)
        try container.encodeIfPresent(planetsInvolved, forKey: .planetsInvolved)
        try container.encodeIfPresent(lifeAreas, forKey: .lifeAreas)
        try container.encodeIfPresent(peakPeriod, forKey: .peakPeriod)
        try container.encodeIfPresent(remedies, forKey: .remedies)
        try container.encodeIfPresent(doshaName, forKey: .doshaName)
        try container.encodeIfPresent(analysisNotes, forKey: .analysisNotes)
    }
    
    /// Check if present
    var isPresent: Bool {
        return present
    }
    
    /// Yoga type name (for API compatibility)
    var yogaType: String? {
        return type
    }
    
    /// Display name for the yoga (prefer doshaName over raw type)
    var displayName: String {
        return doshaName ?? type?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Unknown"
    }
}

// MARK: - Yoga & Dosha Items

struct YogaDoshaData: Codable {
    let yogas: [YogaItem]?
    let doshas: [YogaItem]?
    
    /// Combined list of all yogas and doshas
    var allItems: [YogaItem] {
        return (yogas ?? []) + (doshas ?? [])
    }
    
    /// Count of active yogas
    var activeYogaCount: Int {
        return yogas?.filter { $0.status == "A" }.count ?? 0
    }
    
    /// Count of active doshas
    var activeDoshaCount: Int {
        return doshas?.filter { $0.status == "A" }.count ?? 0
    }
}

struct YogaItem: Codable, Identifiable {
    var id: String { name }
    let name: String
    let yogaKey: String?  // Machine-readable key for localization (e.g. "gajakesari_yoga")
    let status: String  // A = Active, R = Reduced, C = Cancelled
    let strengthValue: AnyCodable?  // API sends String like "R" or Double
    let category: String?
    let planets: String?
    let houses: String?
    let formation: String?
    let outcome: String?  // Professional description of yoga/dosha effect
    let reason: String?  // Cancellation/reduction reason from API
    let isDosha: Bool?   // Explicit backend flag
    
    enum CodingKeys: String, CodingKey {
        case name
        case yogaKey = "yoga_key"
        case status
        case strengthValue = "strength"
        case category
        case planets
        case houses
        case formation
        case outcome
        case reason
        case isDosha = "is_dosha"
    }
    
    /// Clean display name - strips numbers/parentheses after Yoga/Dosha
    /// e.g., "Grihanasa Yoga (192)" → "Grihanasa Yoga"
    /// e.g., "Bhagya Yoga 241" → "Bhagya Yoga"
    /// e.g., "kala_sarpa" → "Kala Sarpa"
    var displayName: String {
        // Find "Yoga" or "Dosha" and truncate after it
        if let yogaRange = name.range(of: "Yoga", options: .caseInsensitive) {
            return String(name[..<yogaRange.upperBound])
        } else if let doshaRange = name.range(of: "Dosha", options: .caseInsensitive) {
            return String(name[..<doshaRange.upperBound])
        }
        // Handle snake_case names (e.g., "kala_sarpa" → "Kala Sarpa")
        if name.contains("_") {
            return name.split(separator: "_")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
        // Fallback: strip trailing numbers/parentheses
        return name.replacingOccurrences(of: "\\s*[\\(\\d\\)]+$", with: "", options: .regularExpression)
    }
    
    /// Strength as Double (0.0 to 1.0)
    var strength: Double {
        guard let val = strengthValue?.value else { return 0.5 }
        if let doubleVal = val as? Double {
            return doubleVal
        } else if let stringVal = val as? String {
            // Map string values: R = 0.5, A = 1.0, C = 0.2, etc.
            switch stringVal.uppercased() {
            case "A": return 1.0
            case "R": return 0.5
            case "C": return 0.2
            case "H": return 0.8
            case "M": return 0.6
            case "L": return 0.4
            default:
                return Double(stringVal) ?? 0.5
            }
        } else if let intVal = val as? Int {
            return Double(intVal)
        }
        return 0.5
    }
    
    /// Human-readable status
    var statusLabel: String {
        switch status.uppercased() {
        case "A": return "active".localized
        case "R": return "reduced".localized
        case "C": return "cancelled".localized
        default: return status
        }
    }
    
    /// Strength as percentage (0-100)
    var strengthPercentage: Int {
        return Int(strength * 100)
    }
    
    /// Houses with duplicates removed
    var uniqueHouses: String? {
        guard let houses = houses, !houses.isEmpty else { return nil }
        let houseArray = houses.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let uniqueArray = Array(NSOrderedSet(array: houseArray)) as? [String] ?? houseArray
        return uniqueArray.joined(separator: ",")
    }
    
    /// Planets with duplicates removed and converted to short codes
    var uniquePlanets: String? {
        guard let planets = planets, !planets.isEmpty else { return nil }
        
        // Planet short codes mapping
        let shortCodes: [String: String] = [
            "Sun": "Su", "Moon": "Mo", "Mars": "Ma", "Mercury": "Me",
            "Jupiter": "Ju", "Venus": "Ve", "Saturn": "Sa",
            "Rahu": "Ra", "Ketu": "Ke", "Ascendant": "As"
        ]
        
        let planetArray = planets.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let uniqueArray = Array(NSOrderedSet(array: planetArray)) as? [String] ?? planetArray
        
        // Convert to short codes
        let shortPlanets = uniqueArray.map { planet in
            shortCodes[planet] ?? planet // Use short code or original if not found
        }
        
        return shortPlanets.joined(separator: ",")
    }
    
    /// Is this a yoga (positive) or dosha (negative)?
    var isYoga: Bool {
        return true // Set by parent context
    }
    
    // MARK: - Localized Content (uses yogaKey to lookup from Localizable.strings)
    
    /// Localized yoga name - looks up using yoga_key from Localizable.strings
    var localizedName: String {
        guard let key = yogaKey, !key.isEmpty else { return displayName }
        let lookupKey = "yoga_name_\(key)"
        let localized = lookupKey.localized
        // If localization returns the key itself, fallback to displayName
        return localized == lookupKey ? displayName : localized
    }
    
    /// Localized outcome description - from Localizable.strings or API fallback
    var localizedOutcome: String? {
        guard let key = yogaKey, !key.isEmpty else { return outcome }
        let lookupKey = "yoga_outcome_\(key)"
        let localized = lookupKey.localized
        return localized == lookupKey ? outcome : localized
    }
    
    /// Localized formation description - from Localizable.strings or API fallback
    var localizedFormation: String? {
        guard let key = yogaKey, !key.isEmpty else { return formation }
        let lookupKey = "yoga_formation_\(key)"
        let localized = lookupKey.localized
        return localized == lookupKey ? formation : localized
    }
}

// MARK: - Raw Data Container

struct RawDoshaData: Codable {
    let mangalDosha: MangalDoshaData?
    let kalaSarpa: KalaSarpaData?
    let yogas: YogaDoshaData?
    
    enum CodingKeys: String, CodingKey {
        case mangalDosha = "mangal_dosha"
        case kalaSarpa = "kala_sarpa"
        case yogas
    }
}

// MARK: - Int Extension for Ordinals

extension Int {
    var ordinal: String {
        let suffix: String
        let ones = self % 10
        let tens = (self / 10) % 10
        
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(self)\(suffix)"
    }
}
