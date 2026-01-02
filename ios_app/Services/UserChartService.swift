import Foundation
import Combine

class UserChartService: ObservableObject {
    static let shared = UserChartService()
    
    private let cache = AstroDataCache.shared
    
    private init() {}
    
    // MARK: - API Endpoints
    
    // MARK: - Fetch Methods
    
    func fetchFullChartData(birthData: UserBirthData) async throws -> UserAstroDataResponse {
        // Check cache first
        if let cached = cache.getFullChart(birthData: birthData) {
            return cached
        }
        
        let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.astroDataFull)")!
        let request = UserAstroDataRequest(birthData: birthData)
        let response: UserAstroDataResponse = try await performRequest(url: url, body: request)
        
        // Cache the response (forever)
        let hash = cache.birthHash(birthData)
        cache.setFullChart(response, birthHash: hash)
        
        return response
    }
    
    func fetchDashaPeriods(birthData: UserBirthData, year: Int? = nil) async throws -> DashaResponse {
        let targetYear = year ?? Calendar.current.component(.year, from: Date())
        
        // Check cache first
        if let cached = cache.getDasha(birthData: birthData, year: targetYear) {
            return cached
        }
        
        let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.astroDataDasha)")!
        let body: [String: Any] = [
            "birth_data": [
                "dob": birthData.dob,
                "time": birthData.time,
                "latitude": birthData.latitude,
                "longitude": birthData.longitude,
                "ayanamsa": birthData.ayanamsa,
                "house_system": birthData.houseSystem,
                "city_of_birth": birthData.cityOfBirth as Any
            ],
            "year": targetYear
        ]
        
        let response: DashaResponse = try await performRequest(url: url, jsonBody: body)
        
        // Cache the response (per year)
        let hash = cache.birthHash(birthData)
        cache.setDasha(response, birthHash: hash, year: targetYear)
        
        return response
    }
    
    func fetchTransits(birthData: UserBirthData, year: Int? = nil) async throws -> TransitResponse {
        let targetYear = year ?? Calendar.current.component(.year, from: Date())
        
        // Check cache first
        if let cached = cache.getTransits(birthData: birthData, year: targetYear) {
            return cached
        }
        
        let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.astroDataTransits)")!
        let body: [String: Any] = [
            "birth_data": [
                "dob": birthData.dob,
                "time": birthData.time,
                "latitude": birthData.latitude,
                "longitude": birthData.longitude,
                "ayanamsa": birthData.ayanamsa,
                "house_system": birthData.houseSystem,
                "city_of_birth": birthData.cityOfBirth as Any
            ],
            "year": targetYear
        ]
        
        let response: TransitResponse = try await performRequest(url: url, jsonBody: body)
        
        // Cache the response (per year)
        let hash = cache.birthHash(birthData)
        cache.setTransits(response, birthHash: hash, year: targetYear)
        
        return response
    }
    
    // MARK: - Helper Methods
    
    private func performRequest<T: Decodable>(url: URL, body: Encodable) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        return try validateAndDecode(data: data, response: response)
    }
    
    private func performRequest<T: Decodable>(url: URL, jsonBody: [String: Any]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        return try validateAndDecode(data: data, response: response)
    }
    
    private func validateAndDecode<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("API Error: \(httpResponse.statusCode)")
            if let errorText = String(data: data, encoding: .utf8) {
                print("Error Body: \(errorText)")
            }
            throw URLError(.badServerResponse)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding Error: \(error)")
            throw error
        }
    }
}
