import SwiftUI
import SwiftData

/// Profile Switcher Sheet
/// Allows users to switch between their saved profiles
struct ProfileSwitcherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PartnerProfile.updatedAt, order: .reverse)
    private var allProfiles: [PartnerProfile]
    
    @State private var isLoading = true
    @State private var serverProfiles: [PartnerProfile] = []
    @State private var selectedProfileId: String?
    @State private var showUpgradePrompt = false
    @State private var showAddForm = false
    @State private var limitMessage: String?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isManagingProfiles = false
    
    let profileContext = ProfileContextManager.shared
    
    /// Profiles to display (non-active, non-self)
    /// Uses ProfileContextManager.activeProfile for consistency with HomeView
    private var otherProfiles: [PartnerProfile] {
        let activeId = profileContext.activeProfile?.id
        return serverProfiles.filter { $0.id != activeId && !$0.isSelf }
    }
    
    /// Self profile if exists
    private var selfProfile: PartnerProfile? {
        serverProfiles.first { $0.isSelf }
    }
    
    /// Active profile - uses ProfileContextManager for consistency with HomeView
    private var activeProfile: PartnerProfile? {
        profileContext.activeProfile
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.mainBackground
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(AppTheme.Colors.gold)
                        Text("Loading profiles...")
                            .font(AppTheme.Fonts.caption(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                } else {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("Switch Birth Chart")
                                .font(AppTheme.Fonts.title(size: 20))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            if profileContext.isSwitching {
                                ProgressView()
                                    .tint(AppTheme.Colors.gold)
                            } else {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .frame(width: 32, height: 32)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Close")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Active Profile Card
                        if let active = activeProfile {
                            ActiveProfileCard(profile: active)
                        } else if let selfP = selfProfile {
                            // If no active, show self as active (default)
                            ActiveProfileCard(profile: selfP)
                        }
                        
                        // Profile List
                        ScrollView {
                            VStack(spacing: 12) {
                                // Self Profile (if not displayed as active - either explicitly or as fallback)
                                // When activeProfile is nil, self is shown as fallback active card, so don't show in list
                                let selfIsDisplayedAsActive = (activeProfile == nil) || (selfProfile?.id == activeProfile?.id)
                                if let selfP = selfProfile, !selfIsDisplayedAsActive {
                                    ProfileRow(profile: selfP, isSelected: false) {
                                        Task {
                                            let success = await profileContext.switchTo(selfP)
                                            if success {
                                                dismiss()
                                            } else {
                                                errorMessage = profileContext.switchError ?? "Failed to switch profile"
                                                if errorMessage?.contains("Upgrade") == true {
                                                    showUpgradePrompt = true
                                                } else {
                                                    showError = true
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Other Profiles
                                ForEach(otherProfiles) { profile in
                                    ProfileRow(profile: profile, isSelected: false) {
                                        Task {
                                            let success = await profileContext.switchTo(profile)
                                            if success {
                                                dismiss()
                                            } else {
                                                errorMessage = profileContext.switchError ?? "Failed to switch profile"
                                                if errorMessage?.contains("Upgrade") == true {
                                                    showUpgradePrompt = true
                                                } else {
                                                    showError = true
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Empty State
                                if otherProfiles.isEmpty && selfProfile == nil {
                                    VStack(spacing: 12) {
                                        Image(systemName: "person.2.slash")
                                            .font(.system(size: 40))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                        Text("No profiles found")
                                            .font(AppTheme.Fonts.body(size: 16))
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                        Text("Add a partner profile to get started")
                                            .font(AppTheme.Fonts.caption(size: 14))
                                            .foregroundColor(AppTheme.Colors.textTertiary)
                                    }
                                    .padding(.top, 40)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        // Link to Manage Birth Charts
                        NavigationLink(isActive: $isManagingProfiles) {
                            PartnerManagerView()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Manage Birth Charts")
                                    .font(AppTheme.Fonts.body(size: 15))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.Colors.gold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadProfiles()
            }
        }
        .onChange(of: isManagingProfiles) { wasManaging, isManaging in
            // Reload profiles when returning from PartnerManagerView
            if wasManaging && !isManaging {
                Task {
                    await loadProfiles()
                }
            }
        }
        .alert("Profile Switch Failed", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showUpgradePrompt) {
            SubscriptionView()
        }
        .sheet(isPresented: $showAddForm) {
            PartnerFormView(mode: .add) { newPartner in
                // Actually create the partner via API
                Task {
                    guard let email = UserDefaults.standard.string(forKey: "userEmail") else {
                        return
                    }
                    
                    do {
                        let created = try await PartnerProfileService.shared.createPartner(newPartner, email: email)
                        print("[ProfileSwitcher] Created partner: \(created.name)")
                        await loadProfiles()
                    } catch {
                        print("[ProfileSwitcher] Failed to create partner: \(error)")
                        await MainActor.run {
                            errorMessage = "Failed to save profile: \(error.localizedDescription)"
                            showError = true
                        }
                    }
                }
            }
        }
        .alert("Profile Limit Reached", isPresented: .constant(limitMessage != nil)) {
            Button("Upgrade") {
                limitMessage = nil
                showUpgradePrompt = true
            }
            Button("OK", role: .cancel) {
                limitMessage = nil
            }
        } message: {
            Text(limitMessage ?? "")
        }
    }
    
    // MARK: - Load Profiles
    
    private func loadProfiles() async {
        isLoading = true
        
        guard let email = UserDefaults.standard.string(forKey: "userEmail") else {
            print("[ProfileSwitcher] No user email found")
            isLoading = false
            return
        }
        
        do {
            // Fetch from server
            let profiles = try await PartnerProfileService.shared.fetchPartners(email: email)
            
            // Save to local SwiftData
            await MainActor.run {
                PartnerProfileService.shared.savePartnersLocally(profiles, context: modelContext)
                serverProfiles = profiles
                
                // Refresh active profile after loading from server
                // This ensures activeProfile is set on fresh installs where no cache exists
                profileContext.loadActiveProfile(context: modelContext)
                
                print("[ProfileSwitcher] Loaded \(profiles.count) profiles from server")
            }
            
        } catch {
            print("[ProfileSwitcher] Failed to fetch profiles: \(error)")
            // Fallback to local
            await MainActor.run {
                serverProfiles = PartnerProfileService.shared.fetchPartnersLocally(context: modelContext)
                print("[ProfileSwitcher] Loaded \(serverProfiles.count) profiles from local")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Quota Check
    
    private func checkAndShowAddForm() {
        Task {
            let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
            let result = await QuotaManager.shared.canAddProfile(email: email, currentCount: serverProfiles.count)
            
            await MainActor.run {
                if result.canAdd {
                    showAddForm = true
                } else if result.limit == 0 {
                    // Free user - show upgrade directly
                    showUpgradePrompt = true
                } else {
                    // Core user at limit
                    limitMessage = "You can save up to \(result.limit) profiles. Upgrade to Plus for unlimited profiles."
                }
            }
        }
    }
}

// MARK: - Active Profile Card

private struct ActiveProfileCard: View {
    let profile: PartnerProfile
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(AppTheme.Colors.premiumGradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(profile.name.prefix(1)))
                        .font(AppTheme.Fonts.premiumDisplay(size: 24))
                        .foregroundColor(AppTheme.Colors.textOnGold)
                )
                .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 10)
            
            HStack(spacing: 8) {
                Text(profile.name)
                    .font(AppTheme.Fonts.title(size: 18))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if profile.isSelf {
                    Text("YOU")
                        .font(AppTheme.Fonts.caption(size: 10))
                        .foregroundColor(AppTheme.Colors.gold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.gold.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Text("Active Profile")
                .font(AppTheme.Fonts.caption(size: 12))
                .foregroundColor(AppTheme.Colors.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.Colors.gold.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Active profile: \(profile.name)\(profile.isSelf ? ", you" : "")")
    }
}

struct ProfileRow: View {
    let profile: PartnerProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 15) {
                // Avatar
                Circle()
                    .fill(AppTheme.Colors.surfaceBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(profile.name.prefix(1)))
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(profile.name)
                            .font(AppTheme.Fonts.body(size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if profile.isSelf {
                            Text("YOU")
                                .font(AppTheme.Fonts.caption(size: 10))
                                .foregroundColor(AppTheme.Colors.gold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.gold.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(profile.dateOfBirth)
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .padding()
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.Colors.gold.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch to \(profile.name)\(profile.isSelf ? ", your profile" : "")")
        .accessibilityHint("Double tap to switch")
    }
}

// MARK: - Preview

#Preview {
    ProfileSwitcherSheet()
        .modelContainer(for: PartnerProfile.self)
}
