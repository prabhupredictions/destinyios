import Foundation
import SwiftData

/// Service for managing partner profiles (API + local storage)
class PartnerProfileService {
    static let shared = PartnerProfileService()
    
    private init() {}
    
    // MARK: - API Endpoints
    
    private var baseURL: String { APIConfig.baseURL }
    
    // MARK: - Fetch Partners from Server
    
    /// Fetch all partners for a user from server
    func fetchPartners(email: String) async throws -> [PartnerProfile] {
        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/subscription/partners?user_email=\(encodedEmail)") else {
            throw PartnerProfileError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PartnerProfileError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PartnerProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let responses = try decoder.decode([PartnerProfileResponse].self, from: data)
        
        return responses.map { $0.toPartnerProfile() }
    }
    
    // MARK: - Create Partner on Server
    
    /// Create a new partner on server
    func createPartner(_ profile: PartnerProfile, email: String) async throws -> PartnerProfile {
        guard let url = URL(string: "\(baseURL)/subscription/partners") else {
            throw PartnerProfileError.invalidURL
        }
        
        struct CreateRequest: Codable {
            let userEmail: String
            let profile: PartnerProfileRequest
            let consentGiven: Bool
            
            enum CodingKeys: String, CodingKey {
                case userEmail = "user_email"
                case profile
                case consentGiven = "consent_given"
            }
        }
        
        let createRequest = CreateRequest(
            userEmail: email,
            profile: PartnerProfileRequest(from: profile),
            consentGiven: profile.consentGiven
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(createRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PartnerProfileError.invalidResponse
        }
        
        if httpResponse.statusCode == 409 {
            throw PartnerProfileError.duplicateProfile
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PartnerProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let createdPartner = try decoder.decode(PartnerProfileResponse.self, from: data)
        
        print("[PartnerProfileService] Created partner: \(createdPartner.name)")
        return createdPartner.toPartnerProfile()
    }
    
    // MARK: - Update Partner on Server
    
    /// Update an existing partner on server
    func updatePartner(_ profile: PartnerProfile, email: String) async throws -> PartnerProfile {
        guard let url = URL(string: "\(baseURL)/subscription/partners/\(profile.id)") else {
            throw PartnerProfileError.invalidURL
        }
        
        struct UpdateRequest: Codable {
            let userEmail: String
            let profile: PartnerProfileRequest
            
            enum CodingKeys: String, CodingKey {
                case userEmail = "user_email"
                case profile
            }
        }
        
        let updateRequest = UpdateRequest(
            userEmail: email,
            profile: PartnerProfileRequest(from: profile)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(updateRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PartnerProfileError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PartnerProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let updatedPartner = try decoder.decode(PartnerProfileResponse.self, from: data)
        
        print("[PartnerProfileService] Updated partner: \(updatedPartner.name)")
        return updatedPartner.toPartnerProfile()
    }
    
    // MARK: - Delete Partner from Server
    
    /// Delete a partner from server
    func deletePartner(id: String, email: String) async throws {
        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/subscription/partners/\(id)?user_email=\(encodedEmail)") else {
            throw PartnerProfileError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PartnerProfileError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PartnerProfileError.serverError(statusCode: httpResponse.statusCode)
        }
        
        print("[PartnerProfileService] Deleted partner: \(id)")
    }
    
    // MARK: - Local Storage (SwiftData)
    
    /// Save partners to local SwiftData storage
    @MainActor
    func savePartnersLocally(_ partners: [PartnerProfile], context: ModelContext) {
        // Delete existing partners
        let descriptor = FetchDescriptor<PartnerProfile>()
        if let existing = try? context.fetch(descriptor) {
            for partner in existing {
                context.delete(partner)
            }
        }
        
        // Insert new partners
        for partner in partners {
            context.insert(partner)
        }
        
        try? context.save()
        print("[PartnerProfileService] Saved \(partners.count) partners locally")
    }
    
    /// Fetch partners from local SwiftData storage
    @MainActor
    func fetchPartnersLocally(context: ModelContext) -> [PartnerProfile] {
        let descriptor = FetchDescriptor<PartnerProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Save single partner locally
    @MainActor
    func savePartnerLocally(_ partner: PartnerProfile, context: ModelContext) {
        context.insert(partner)
        try? context.save()
    }
    
    /// Save partner only if not exists (Smart Save)
    @MainActor
    func savePartnerSmartly(_ partner: PartnerProfile, context: ModelContext) {
        let descriptor = FetchDescriptor<PartnerProfile>()
        let existingPartners = (try? context.fetch(descriptor)) ?? []
        
        // Match based on astrological identity (DOB + Time + Place)
        // Name is ignored as users might save "John" then "John Doe" for same person
        let exists = existingPartners.contains { existing in
            existing.dateOfBirth == partner.dateOfBirth &&
            existing.timeOfBirth == partner.timeOfBirth &&
            existing.cityOfBirth?.lowercased() == partner.cityOfBirth?.lowercased()
        }
        
        if !exists {
            context.insert(partner)
            try? context.save()
            print("[PartnerProfileService] Saved new partner: \(partner.name)")
        } else {
            print("[PartnerProfileService] Partner already exists (Astrological Match): \(partner.name) (Skipping save)")
        }
    }
    
    /// Delete partner locally
    @MainActor
    func deletePartnerLocally(id: String, context: ModelContext) {
        let predicate = #Predicate<PartnerProfile> { $0.id == id }
        let descriptor = FetchDescriptor<PartnerProfile>(predicate: predicate)
        
        if let partners = try? context.fetch(descriptor), let partner = partners.first {
            context.delete(partner)
            try? context.save()
        }
    }
}

// MARK: - Errors

enum PartnerProfileError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    case notFound
    case duplicateProfile
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code): return "Server error: \(code)"
        case .decodingError: return "Failed to decode response"
        case .notFound: return "Partner not found"
        case .duplicateProfile: return "A profile with this birth data already exists."
        }
    }
}
