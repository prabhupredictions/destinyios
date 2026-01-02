import Foundation

// MARK: - Chart Data Models for UI Display
/// These models decode the chart_data from the compatibility API response

struct ChartData: Codable, Sendable {
    let d1: [String: D1PlanetPosition]
    let d9: [String: D9PlanetPosition]
    
    // Get all planets sorted by house
    var d1Planets: [PlanetEntry] {
        d1.map { PlanetEntry(name: $0.key, position: $0.value) }
            .sorted { ($0.position.house ?? 0) < ($1.position.house ?? 0) }
    }
    
    var d9Planets: [D9PlanetEntry] {
        d9.map { D9PlanetEntry(name: $0.key, position: $0.value) }
            .sorted { ($0.position.house ?? 0) < ($1.position.house ?? 0) }
    }
}

struct D1PlanetPosition: Codable, Sendable {
    let house: Int?
    let sign: String?
    let degree: Double?
    let retrograde: Bool?
    let vargottama: Bool?
    let combust: Bool?
    let nakshatra: String?
    let pada: Int?
    
    // Formatted degree string: "15°23'"
    var formattedDegree: String {
        guard let deg = degree else { return "" }
        let wholeDeg = Int(deg) % 30
        let minutes = Int((deg - Double(Int(deg))) * 60)
        return "\(wholeDeg)°\(minutes)'"
    }
    
    // Sign full name
    var signFullName: String {
        guard let s = sign else { return "" }
        return ChartConstants.signFullNames[s] ?? s
    }
}

struct D9PlanetPosition: Codable, Sendable {
    let house: Int?  // Made optional to prevent decode failure
    let sign: String?
    
    var signFullName: String {
        guard let s = sign else { return "" }
        return ChartConstants.signFullNames[s] ?? s
    }
}

// MARK: - Helper Types

struct PlanetEntry: Identifiable {
    let name: String
    let position: D1PlanetPosition
    
    var id: String { name }
    
    var shortCode: String {
        ChartConstants.planetShortCodes[name] ?? String(name.prefix(2))
    }
}

struct D9PlanetEntry: Identifiable {
    let name: String
    let position: D9PlanetPosition
    
    var id: String { name }
    
    var shortCode: String {
        ChartConstants.planetShortCodes[name] ?? String(name.prefix(2))
    }
}

// MARK: - Constants

enum ChartConstants {
    // Planet short codes
    static let planetShortCodes: [String: String] = [
        "Sun": "Su", "Moon": "Mo", "Mars": "Ma", "Mercury": "Me",
        "Jupiter": "Ju", "Venus": "Ve", "Saturn": "Sa",
        "Rahu": "Ra", "Ketu": "Ke", "Ascendant": "As"
    ]
    
    // Sign short codes to full names
    static let signFullNames: [String: String] = [
        "Ar": "Aries", "Ta": "Taurus", "Ge": "Gemini", "Ca": "Cancer",
        "Le": "Leo", "Vi": "Virgo", "Li": "Libra", "Sc": "Scorpio",
        "Sg": "Sagittarius", "Cp": "Capricorn", "Aq": "Aquarius", "Pi": "Pisces"
    ]
    
    // Sign symbols
    static let signSymbols: [String: String] = [
        "Ar": "♈", "Ta": "♉", "Ge": "♊", "Ca": "♋",
        "Le": "♌", "Vi": "♍", "Li": "♎", "Sc": "♏",
        "Sg": "♐", "Cp": "♑", "Aq": "♒", "Pi": "♓"
    ]
    
    // South Indian chart sign positions (fixed)
    // Row 0: Pi, Ar, Ta, Ge
    // Row 1: Aq, -, -, Ca
    // Row 2: Cp, -, -, Le
    // Row 3: Sg, Sc, Li, Vi
    static let southIndianLayout: [[String?]] = [
        ["Pi", "Ar", "Ta", "Ge"],
        ["Aq", nil, nil, "Ca"],
        ["Cp", nil, nil, "Le"],
        ["Sg", "Sc", "Li", "Vi"]
    ]
    
    // Sign number for South Indian (fixed positions)
    static let signNumbers: [String: Int] = [
        "Ar": 1, "Ta": 2, "Ge": 3, "Ca": 4, "Le": 5, "Vi": 6,
        "Li": 7, "Sc": 8, "Sg": 9, "Cp": 10, "Aq": 11, "Pi": 12
    ]
    
    // Ordered signs for index lookup (0 = Aries/Ar)
    static let orderedSigns = ["Ar", "Ta", "Ge", "Ca", "Le", "Vi", "Li", "Sc", "Sg", "Cp", "Aq", "Pi"]
}
