import XCTest
@testable import ios_app

/// Golden decode test for a full natal chart response.
///
/// This test pins the `ChartData` Codable contract by decoding a
/// checked-in JSON fixture representing Prabhu Kushwaha's natal chart
/// (Gemini lagna 29°30', Sun H1, Moon+Ketu H8, Mercury+Rahu H2,
/// Venus H12 own sign, Jupiter+Saturn H3).
///
/// Why this test exists:
///   - The `/vedic/api/predict` response embeds `chart_data` that the
///     iOS chart views (SouthIndianChartView, PlanetDetailCard, etc.)
///     decode into `ChartData`. If the backend renames a field or
///     changes a type, decoding silently fails to Optional-none and the
///     chart renders as empty tiles with no error surfaced to the user.
///   - By pinning the exact shape here, any drift in the wire format
///     fails CI loudly during iOS unit tests.
///
/// The JSON is embedded inline (not loaded via `Bundle`) because the
/// iOS test target has an empty PBXResourcesBuildPhase and adding
/// bundled resources would touch project.pbxproj. The human-readable
/// reference version lives at
///   ios_appTests/Fixtures/PrabhuNatalChart.json
/// and must stay in sync with `Self.prabhuChartJSON` below.
final class PrabhuNatalChartGoldenTests: XCTestCase {

    // MARK: - Decode

    func test_decodePrabhuChartJSON_succeeds() throws {
        let data = Self.prabhuChartJSON.data(using: .utf8)!
        _ = try JSONDecoder().decode(ChartData.self, from: data)
    }

    // MARK: - D1 placements

    /// Gemini rising with Sun in the 1st house — the lagna signature.
    func test_d1_ascendantAndSunAreInGemini() throws {
        let chart = try Self.decodeFixture()

        let asc = try XCTUnwrap(chart.d1["Ascendant"])
        XCTAssertEqual(asc.house, 1)
        XCTAssertEqual(asc.sign, "Ge")

        let sun = try XCTUnwrap(chart.d1["Sun"])
        XCTAssertEqual(sun.house, 1)
        XCTAssertEqual(sun.sign, "Ge")
        XCTAssertEqual(sun.retrograde, false)
    }

    /// Moon+Ketu in H8 Capricorn — the spiritual/8th-house signature.
    func test_d1_moonAndKetuAreInEighthHouseCapricorn() throws {
        let chart = try Self.decodeFixture()

        let moon = try XCTUnwrap(chart.d1["Moon"])
        XCTAssertEqual(moon.house, 8)
        XCTAssertEqual(moon.sign, "Cp")

        let ketu = try XCTUnwrap(chart.d1["Ketu"])
        XCTAssertEqual(ketu.house, 8)
        XCTAssertEqual(ketu.sign, "Cp")
        XCTAssertEqual(ketu.retrograde, true, "Ketu is always retrograde")
    }

    /// Mercury+Rahu in H2 Cancer — the wealth-house dispositor signature.
    func test_d1_mercuryAndRahuAreInSecondHouseCancer() throws {
        let chart = try Self.decodeFixture()

        let mercury = try XCTUnwrap(chart.d1["Mercury"])
        XCTAssertEqual(mercury.house, 2)
        XCTAssertEqual(mercury.sign, "Ca")

        let rahu = try XCTUnwrap(chart.d1["Rahu"])
        XCTAssertEqual(rahu.house, 2)
        XCTAssertEqual(rahu.sign, "Ca")
        XCTAssertEqual(rahu.retrograde, true, "Rahu is always retrograde")
    }

    /// Venus in H12 Taurus (own sign).
    func test_d1_venusInTwelfthHouseTaurusOwnSign() throws {
        let chart = try Self.decodeFixture()

        let venus = try XCTUnwrap(chart.d1["Venus"])
        XCTAssertEqual(venus.house, 12)
        XCTAssertEqual(venus.sign, "Ta")
    }

    /// Jupiter+Saturn in H3 Leo — the effort/career-through-communication axis.
    func test_d1_jupiterAndSaturnAreInThirdHouseLeo() throws {
        let chart = try Self.decodeFixture()

        let jupiter = try XCTUnwrap(chart.d1["Jupiter"])
        XCTAssertEqual(jupiter.house, 3)
        XCTAssertEqual(jupiter.sign, "Le")

        let saturn = try XCTUnwrap(chart.d1["Saturn"])
        XCTAssertEqual(saturn.house, 3)
        XCTAssertEqual(saturn.sign, "Le")
    }

    // MARK: - Derived UI helpers

    /// `d1Planets` sorted by house is what the chart list-view consumes;
    /// this pins the ordering contract.
    func test_d1PlanetsSortedByHouse() throws {
        let chart = try Self.decodeFixture()
        let houses = chart.d1Planets.compactMap { $0.position.house }
        XCTAssertEqual(houses, houses.sorted(),
                       "d1Planets must return entries sorted by house")
    }

    /// `formattedDegree` renders degree-within-sign, not raw longitude.
    /// If this drifts we get "89°30'" instead of "29°30'" — visually broken.
    func test_ascendantFormattedDegreeRendersDegreeWithinSign() throws {
        let chart = try Self.decodeFixture()
        let asc = try XCTUnwrap(chart.d1["Ascendant"])
        // 89.5° absolute longitude → 29°30' within Gemini
        XCTAssertEqual(asc.formattedDegree, "29°30'",
                       "formattedDegree must compute (longitude % 30)")
    }

    /// Retrograde flag survives decoding for the shadow planets and Saturn.
    func test_retrogradeFlagsDecodeCorrectly() throws {
        let chart = try Self.decodeFixture()
        XCTAssertEqual(chart.d1["Sun"]?.retrograde, false)
        XCTAssertEqual(chart.d1["Saturn"]?.retrograde, true)
        XCTAssertEqual(chart.d1["Rahu"]?.retrograde, true)
        XCTAssertEqual(chart.d1["Ketu"]?.retrograde, true)
    }

    /// All ten canonical bodies (9 grahas + ascendant) must be present so
    /// the chart wheel has no missing tiles.
    func test_allTenBodiesArePresentInD1() throws {
        let chart = try Self.decodeFixture()
        let required = ["Ascendant", "Sun", "Moon", "Mercury", "Venus",
                        "Mars", "Jupiter", "Saturn", "Rahu", "Ketu"]
        for name in required {
            XCTAssertNotNil(chart.d1[name], "Missing body in D1: \(name)")
        }
    }

    // MARK: - D9

    /// D9 (navamsa) is what marriage timing reads from — decode must
    /// produce all bodies with house + sign.
    func test_d9BodiesDecodeWithHouseAndSign() throws {
        let chart = try Self.decodeFixture()
        XCTAssertGreaterThanOrEqual(chart.d9.count, 10,
                                    "D9 must include at least the 9 grahas + Ascendant")
        for (name, pos) in chart.d9 {
            XCTAssertNotNil(pos.house, "D9 \(name) missing house")
            XCTAssertNotNil(pos.sign,  "D9 \(name) missing sign")
        }
    }

    // MARK: - Helpers

    private static func decodeFixture() throws -> ChartData {
        let data = prabhuChartJSON.data(using: .utf8)!
        return try JSONDecoder().decode(ChartData.self, from: data)
    }

    /// Inline JSON kept in sync with
    /// `ios_appTests/Fixtures/PrabhuNatalChart.json`.
    /// If you edit one, edit both.
    private static let prabhuChartJSON = """
    {
      "d1": {
        "Ascendant": {"house": 1, "sign": "Ge", "degree": 89.5, "retrograde": false, "vargottama": false, "combust": false, "nakshatra": "Punarvasu", "pada": 4},
        "Sun":       {"house": 1, "sign": "Ge", "degree": 75.42, "retrograde": false, "vargottama": false, "combust": false, "nakshatra": "Ardra", "pada": 2},
        "Moon":      {"house": 8, "sign": "Cp", "degree": 292.15, "retrograde": false, "vargottama": false, "combust": false, "nakshatra": "Shravana", "pada": 3},
        "Mercury":   {"house": 2, "sign": "Ca", "degree": 98.30, "retrograde": false, "vargottama": false, "combust": false, "nakshatra": "Pushya", "pada": 1},
        "Venus":     {"house": 12, "sign": "Ta", "degree": 48.05, "retrograde": false, "vargottama": false, "combust": false, "nakshatra": "Rohini", "pada": 2},
        "Mars":      {"house": 11, "sign": "Ar", "degree": 15.60, "retrograde": false, "vargottama": false, "combust": false, "nakshatra": "Bharani", "pada": 1},
        "Jupiter":   {"house": 3, "sign": "Le", "degree": 132.20, "retrograde": false, "vargottama": false, "combust": false, "nakshatra": "Purva Phalguni", "pada": 2},
        "Saturn":    {"house": 3, "sign": "Le", "degree": 134.55, "retrograde": true, "vargottama": false, "combust": false, "nakshatra": "Purva Phalguni", "pada": 2},
        "Rahu":      {"house": 2, "sign": "Ca", "degree": 112.10, "retrograde": true, "vargottama": false, "combust": false, "nakshatra": "Ashlesha", "pada": 2},
        "Ketu":      {"house": 8, "sign": "Cp", "degree": 292.10, "retrograde": true, "vargottama": false, "combust": false, "nakshatra": "Shravana", "pada": 3}
      },
      "d9": {
        "Ascendant": {"house": 1, "sign": "Sc"},
        "Sun":       {"house": 3, "sign": "Cp"},
        "Moon":      {"house": 7, "sign": "Ta"},
        "Mercury":   {"house": 5, "sign": "Pi"},
        "Venus":     {"house": 10, "sign": "Le"},
        "Mars":      {"house": 12, "sign": "Li"},
        "Jupiter":   {"house": 2, "sign": "Sg"},
        "Saturn":    {"house": 6, "sign": "Ar"},
        "Rahu":      {"house": 5, "sign": "Pi"},
        "Ketu":      {"house": 11, "sign": "Vi"}
      }
    }
    """
}
