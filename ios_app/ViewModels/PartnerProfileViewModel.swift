import Foundation
import SwiftUI
import SwiftData
import Observation

/// ViewModel for Partner Profile Manager
@Observable
class PartnerProfileViewModel {
    // MARK: - State
    
    var partners: [PartnerProfile] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false
    
    // Filter
    var searchText = ""
    var filterGender: String? // nil = all, "male", "female"
    
    // MARK: - Dependencies
    
    private let service = PartnerProfileService.shared
    private var modelContext: ModelContext?
    
    // MARK: - Computed Properties
    
    var filteredPartners: [PartnerProfile] {
        var result = partners
        
        // Filter by gender
        if let gender = filterGender {
            result = result.filter { $0.gender == gender }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.cityOfBirth?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return result
    }
    
    var malePartners: [PartnerProfile] {
        partners.filter { $0.gender == "male" }
    }
    
    var femalePartners: [PartnerProfile] {
        partners.filter { $0.gender == "female" }
    }
    
    // MARK: - Setup
    
    func setup(context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Load Partners
    
    @MainActor
    func loadPartners() async {
        guard let email = getCurrentUserEmail() else {
            print("[PartnerProfileVM] No user email found")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch from server
            let serverPartners = try await service.fetchPartners(email: email)
            
            // Save locally
            if let context = modelContext {
                service.savePartnersLocally(serverPartners, context: context)
            }
            
            partners = serverPartners
            print("[PartnerProfileVM] Loaded \(partners.count) partners")
            
        } catch {
            print("[PartnerProfileVM] Failed to load from server: \(error)")
            
            // Fallback to local storage
            if let context = modelContext {
                partners = service.fetchPartnersLocally(context: context)
                print("[PartnerProfileVM] Loaded \(partners.count) partners from local storage")
            }
            
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Add Partner
    
    @MainActor
    func addPartner(_ profile: PartnerProfile) async -> Bool {
        guard let email = getCurrentUserEmail() else {
            errorMessage = "User not signed in"
            showError = true
            return false
        }
        
        isLoading = true
        
        do {
            // Create on server
            let createdPartner = try await service.createPartner(profile, email: email)
            
            // Save locally
            if let context = modelContext {
                service.savePartnerLocally(createdPartner, context: context)
            }
            
            // Add to list
            partners.insert(createdPartner, at: 0)
            
            print("[PartnerProfileVM] Added partner: \(createdPartner.name)")
            isLoading = false
            return true
            
        } catch {
            print("[PartnerProfileVM] Failed to add partner: \(error)")
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
            return false
        }
    }
    
    // MARK: - Update Partner
    
    @MainActor
    func updatePartner(_ profile: PartnerProfile) async -> Bool {
        guard let email = getCurrentUserEmail() else {
            errorMessage = "User not signed in"
            showError = true
            return false
        }
        
        isLoading = true
        
        do {
            // Update on server
            let updatedPartner = try await service.updatePartner(profile, email: email)
            
            // Update in list
            if let index = partners.firstIndex(where: { $0.id == profile.id }) {
                partners[index] = updatedPartner
            }
            
            print("[PartnerProfileVM] Updated partner: \(updatedPartner.name)")
            isLoading = false
            return true
            
        } catch {
            print("[PartnerProfileVM] Failed to update partner: \(error)")
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
            return false
        }
    }
    
    // MARK: - Delete Partner
    
    @MainActor
    func deletePartner(_ profile: PartnerProfile) async -> Bool {
        guard let email = getCurrentUserEmail() else {
            errorMessage = "User not signed in"
            showError = true
            return false
        }
        
        do {
            // Delete from server
            try await service.deletePartner(id: profile.id, email: email)
            
            // Delete locally
            if let context = modelContext {
                service.deletePartnerLocally(id: profile.id, context: context)
            }
            
            // Remove from list
            partners.removeAll { $0.id == profile.id }
            
            print("[PartnerProfileVM] Deleted partner: \(profile.name)")
            return true
            
        } catch {
            print("[PartnerProfileVM] Failed to delete partner: \(error)")
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
    
    // MARK: - Refresh
    
    @MainActor
    func refresh() async {
        await loadPartners()
    }
    
    // MARK: - Helpers
    
    private func getCurrentUserEmail() -> String? {
        UserDefaults.standard.string(forKey: "userEmail")
    }
    
    // MARK: - Protection Checks
    
    /// Reasons why a profile cannot be modified
    enum ProfileProtectionReason {
        case mainUser       // is_self = true
        case activeChart    // is_active = true
        case usedProfile    // first_switched_at != nil (server-side check)
        
        var editMessage: String {
            switch self {
            case .mainUser:
                return "profile_edit_blocked_main_user".localized
            case .activeChart:
                return "profile_edit_blocked_active".localized
            case .usedProfile:
                return "profile_edit_blocked_used".localized
            }
        }
        
        var deleteMessage: String {
            switch self {
            case .mainUser:
                return "profile_delete_blocked_main_user".localized
            case .activeChart:
                return "profile_delete_blocked_active".localized
            case .usedProfile:
                return "profile_delete_blocked_used".localized
            }
        }
    }
    
    /// Check if a profile can be edited (client-side validation)
    func canEditProfile(_ profile: PartnerProfile) -> (allowed: Bool, reason: ProfileProtectionReason?) {
        if profile.isSelf {
            return (false, .mainUser)
        }
        if profile.isActive {
            return (false, .activeChart)
        }
        // Note: usedProfile check is server-side (first_switched_at)
        return (true, nil)
    }
    
    /// Check if a profile can be deleted (client-side validation)
    func canDeleteProfile(_ profile: PartnerProfile) -> (allowed: Bool, reason: ProfileProtectionReason?) {
        // Same logic as edit
        return canEditProfile(profile)
    }
    
    /// Map API error codes to localized messages
    static func localizedMessageForAPIError(_ detail: String, action: String) -> String {
        switch detail {
        case "PROTECTED_MAIN_USER":
            return action == "edit" 
                ? "profile_edit_blocked_main_user".localized 
                : "profile_delete_blocked_main_user".localized
        case "PROTECTED_ACTIVE_CHART":
            return action == "edit"
                ? "profile_edit_blocked_active".localized
                : "profile_delete_blocked_active".localized
        case "PROTECTED_USED_PROFILE":
            return action == "edit"
                ? "profile_edit_blocked_used".localized
                : "profile_delete_blocked_used".localized
        case "DUPLICATE_BIRTH_PROFILE":
            return "profile_add_blocked_duplicate".localized
        default:
            return detail
        }
    }
}
