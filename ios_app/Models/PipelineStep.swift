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
        case .houses:        return "Reading the cosmic map"
        case .promise:       return "Decoding planetary promises"
        case .strength:      return "Weighing celestial forces"
        case .afflictions:   return "Sensing cosmic tensions"
        case .manifestation: return "Tracing destiny's timing"
        case .reading:       return "Crafting your reading"
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
