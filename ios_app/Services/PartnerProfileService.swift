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
    /// - Parameters:
    ///   - email: User email
    ///   - forCompatibility: Optional filter — true = only compatibility charts, false = only non-compat, nil = all
    func fetchPartners(email: String, forCompatibility: Bool? = nil) async throws -> [PartnerProfile] {
        var urlString = "\(baseURL)/subscription/partners?user_email=\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)"
        if let forCompat = forCompatibility {
            urlString += "&for_compatibility=\(forCompat)"
        }
        guard let url = URL(string: urlString) else {
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
            let guardianConsentGiven: Bool
            
            enum CodingKeys: String, CodingKey {
                case userEmail = "user_email"
                case profile
                case consentGiven = "consent_given"
                case guardianConsentGiven = "guardian_consent_given"
            }
        }
        
        let createRequest = CreateRequest(
            userEmail: email,
            profile: PartnerProfileRequest(from: profile),
            consentGiven: profile.consentGiven,
            guardianConsentGiven: profile.guardianConsentGiven
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
        
        // Handle specific error codes
        if httpResponse.statusCode == 409 {
            throw PartnerProfileError.duplicateProfile
        }
        if httpResponse.statusCode == 403 {
            throw Self.parseProtectionError(from: data, action: "edit")
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PartnerProfileError.invalidResponse
        }
        
        if httpResponse.statusCode == 403 {
            throw Self.parseProtectionError(from: data, action: "delete")
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
    
    /// Update partner locally in SwiftData
    @MainActor
    func updatePartnerLocally(_ updated: PartnerProfile, context: ModelContext) {
        let targetId = updated.id
        let predicate = #Predicate<PartnerProfile> { $0.id == targetId }
        let descriptor = FetchDescriptor<PartnerProfile>(predicate: predicate)
        
        if let existing = try? context.fetch(descriptor), let local = existing.first {
            local.name = updated.name
            local.gender = updated.gender
            local.dateOfBirth = updated.dateOfBirth
            local.timeOfBirth = updated.timeOfBirth
            local.cityOfBirth = updated.cityOfBirth
            local.latitude = updated.latitude
            local.longitude = updated.longitude
            local.timezone = updated.timezone
            local.birthTimeUnknown = updated.birthTimeUnknown
            local.forCompatibility = updated.forCompatibility
            local.guardianConsentGiven = updated.guardianConsentGiven
            local.updatedAt = updated.updatedAt
            local.isSynced = true
            local.serverSyncedAt = Date()
            try? context.save()
            print("[PartnerProfileService] Updated partner locally: \(updated.name)")
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
    
    // MARK: - Error Parsing
    
    /// Parse 403 protection error from server response body
    private static func parseProtectionError(from data: Data, action: String) -> PartnerProfileError {
        struct ErrorDetail: Codable { let detail: String }
        if let parsed = try? JSONDecoder().decode(ErrorDetail.self, from: data) {
            return .protectedProfile(detail: parsed.detail, action: action)
        }
        return .serverError(statusCode: 403)
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
    case protectedProfile(detail: String, action: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let code): return "Server error: \(code)"
        case .decodingError: return "Failed to decode response"
        case .notFound: return "Partner not found"
        case .duplicateProfile: return "A birth chart with the same birth data already exists."
        case .protectedProfile(let detail, let action):
            return PartnerProfileViewModel.localizedMessageForAPIError(detail, action: action)
        }
    }
}
