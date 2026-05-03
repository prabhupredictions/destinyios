import Foundation

enum PipelineStep: Int, CaseIterable {
    case houses = 0
    case promise = 1
    case strength = 2
    case afflictions = 3
    case manifestation = 4
    case reading = 5

    var label: String {
        switch self {
        case .houses:        return "Mapping your houses and planets"
        case .promise:       return "Checking their promise"
        case .strength:      return "Checking their strength"
        case .afflictions:   return "Checking their afflictions"
        case .manifestation: return "Checking how they manifest now"
        case .reading:       return "Preparing your reading"
        }
    }

    static func from(tool: String) -> PipelineStep? {
        switch tool {
        case "houses", "planets_data", "nakshatra_data":
            return .houses
        case "functional", "dignity", "yoga_dosha":
            return .promise
        case "shadbala", "ashtakavarga", "vimsopaka_bala":
            return .strength
        case "avasthas", "mangal_dosha", "kala_sarpa", "modifiers":
            return .afflictions
        case "dasha", "transits", "divisional":
            return .manifestation
        case "final_answer":
            return .reading
        default:
            return nil
        }
    }
}
