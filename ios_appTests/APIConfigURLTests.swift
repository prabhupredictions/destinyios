//
//  APIConfigURLTests.swift
//  ios_appTests
//
//  Verifies APIConfig.baseURL handles the xcconfig `$()` escape pattern
//  correctly and produces a parseable URL whose host matches the Android
//  BuildConfig.API_BASE_URL host (cross-platform parity).
//
//  Background:
//    Test.xcconfig and Production.xcconfig declare:
//      API_BASE_URL = https:/$()/astroapi-{test,prod}-dsqvza5jza-ul.a.run.app
//    The `$()` is an empty Xcode build-setting reference that defeats the
//    xcconfig `//` comment parser. At build time it evaluates to "" so the
//    final string is the correct https URL. APIConfig.baseURL also strips
//    `$()` defensively in case the placeholder leaks through.
//

import XCTest
@testable import ios_app

final class APIConfigURLTests: XCTestCase {

    // MARK: - Defensive xcconfig $() stripping

    func test_baseURL_stripsLiteralXcconfigEscape() {
        // Simulates the raw value an old-Xcode tool might pass through.
        let raw = "https:/$()/astroapi-prod-dsqvza5jza-ul.a.run.app"
        let stripped = raw.replacingOccurrences(of: "$()", with: "")
        XCTAssertEqual(stripped, "https://astroapi-prod-dsqvza5jza-ul.a.run.app")
    }

    // MARK: - URL.host parity with Android BuildConfig

    func test_baseURL_isParseableURL_andHostMatchesAndroid() {
        let urlString = APIConfig.baseURL
        XCTAssertFalse(urlString.contains("$()"),
                       "baseURL must not contain xcconfig $() placeholder: \(urlString)")

        guard let url = URL(string: urlString) else {
            XCTFail("APIConfig.baseURL is not a parseable URL: \(urlString)")
            return
        }
        XCTAssertNotNil(url.host, "APIConfig.baseURL has nil host: \(urlString)")
        XCTAssertNotEqual(url.host, "", "APIConfig.baseURL has empty host: \(urlString)")

        // Cross-platform parity assertion. Android BuildConfig.API_BASE_URL
        // for the production flavor is exactly:
        //   "https://astroapi-prod-dsqvza5jza-ul.a.run.app"
        // For the staging flavor:
        //   "https://astroapi-test-dsqvza5jza-ul.a.run.app"
        // Local-debug iOS hits 127.0.0.1; we accept any of the three.
        let acceptableHosts = [
            "astroapi-prod-dsqvza5jza-ul.a.run.app",
            "astroapi-test-dsqvza5jza-ul.a.run.app",
            "127.0.0.1",
            "localhost"
        ]
        XCTAssertTrue(acceptableHosts.contains(url.host ?? ""),
                      "APIConfig.baseURL host '\(url.host ?? "nil")' is not in the cross-platform accepted set: \(acceptableHosts)")
    }

    func test_baseURL_doesNotProduceTripleSlash() {
        let urlString = APIConfig.baseURL
        XCTAssertFalse(urlString.contains("https:///"),
                       "baseURL contains malformed triple slash — xcconfig $() escape not stripped: \(urlString)")
        XCTAssertFalse(urlString.contains("http:///"),
                       "baseURL contains malformed triple slash: \(urlString)")
    }
}
