import Foundation
import MapKit
import CoreLocation
import Combine

/// Location search result
struct LocationResult: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D?
    let source: LocationSource
    
    enum LocationSource {
        case apple
        case google
    }
    
    static func == (lhs: LocationResult, rhs: LocationResult) -> Bool {
        lhs.id == rhs.id
    }
}

/// Hybrid location search service: Apple MapKit primary, Google Places fallback
@MainActor
class LocationSearchService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var suggestions: [LocationResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let completer = MKLocalSearchCompleter()
    private var currentQuery = ""
    private var pendingCompletion: ((CLLocationCoordinate2D?) -> Void)?
    
    // Google Places API key
    private let googleAPIKey = "AIzaSyBQbUsVpdBM1Fv_QOYBLWVr_6amhEllh3o"
    
    // MARK: - Init
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    
    // MARK: - Search
    
    /// Search for locations with hybrid approach
    func search(query: String) {
        currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !currentQuery.isEmpty else {
            suggestions = []
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // Try Apple MapKit first
        completer.queryFragment = currentQuery
    }
    
    /// Get coordinates for a selected location
    func getCoordinates(for result: LocationResult) async -> CLLocationCoordinate2D? {
        if let coord = result.coordinate {
            return coord
        }
        
        switch result.source {
        case .apple:
            return await getAppleCoordinates(title: result.title, subtitle: result.subtitle)
        case .google:
            return await getGoogleCoordinates(placeId: result.id)
        }
    }
    
    // MARK: - Apple MapKit
    
    private func getAppleCoordinates(title: String, subtitle: String) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(title), \(subtitle)"
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            return response.mapItems.first?.placemark.coordinate
        } catch {
            print("Apple MapKit search failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Google Places Fallback
    
    private func searchGooglePlaces() async {
        guard !currentQuery.isEmpty else { return }
        
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "input", value: currentQuery),
            URLQueryItem(name: "types", value: "(cities)"),
            URLQueryItem(name: "key", value: googleAPIKey)
        ]
        
        guard let url = components.url else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
            
            suggestions = response.predictions.map { prediction in
                LocationResult(
                    id: prediction.placeId,
                    title: prediction.structuredFormatting.mainText,
                    subtitle: prediction.structuredFormatting.secondaryText ?? "",
                    coordinate: nil,
                    source: .google
                )
            }
        } catch {
            print("Google Places search failed: \(error)")
            errorMessage = "Location search failed"
        }
        
        isSearching = false
    }
    
    private func getGoogleCoordinates(placeId: String) async -> CLLocationCoordinate2D? {
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "geometry"),
            URLQueryItem(name: "key", value: googleAPIKey)
        ]
        
        guard let url = components.url else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GooglePlaceDetailsResponse.self, from: data)
            
            if let location = response.result?.geometry?.location {
                return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
            }
        } catch {
            print("Google place details failed: \(error)")
        }
        
        return nil
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension LocationSearchService: MKLocalSearchCompleterDelegate {
    
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            let results = completer.results
            
            if results.isEmpty {
                // Apple found nothing, try Google fallback
                await searchGooglePlaces()
            } else {
                suggestions = results.map { result in
                    LocationResult(
                        id: UUID().uuidString,
                        title: result.title,
                        subtitle: result.subtitle,
                        coordinate: nil,
                        source: .apple
                    )
                }
                isSearching = false
            }
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("Apple MapKit failed: \(error), trying Google fallback")
            await searchGooglePlaces()
        }
    }
}

// MARK: - Google Places Response Models

private struct GooglePlacesResponse: Codable {
    let predictions: [GooglePrediction]
    let status: String
}

private struct GooglePrediction: Codable {
    let placeId: String
    let structuredFormatting: StructuredFormatting
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case structuredFormatting = "structured_formatting"
    }
}

private struct StructuredFormatting: Codable {
    let mainText: String
    let secondaryText: String?
    
    enum CodingKeys: String, CodingKey {
        case mainText = "main_text"
        case secondaryText = "secondary_text"
    }
}

private struct GooglePlaceDetailsResponse: Codable {
    let result: PlaceResult?
    let status: String
}

private struct PlaceResult: Codable {
    let geometry: Geometry?
}

private struct Geometry: Codable {
    let location: LatLng?
}

private struct LatLng: Codable {
    let lat: Double
    let lng: Double
}
