import SwiftUI
import SwiftData

/// Partner Picker Sheet for Match screen integration
/// Allows user to select a saved partner to auto-fill match form
struct PartnerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var isPresented: Bool
    let gender: String? // nil = all, "male", "female"
    let onSelect: (PartnerProfile) -> Void
    
    @State private var viewModel = PartnerProfileViewModel()
    @State private var searchText = ""
    @State private var showAddForm = false
    @State private var showUpgradePrompt = false
    @State private var limitMessage: String?
    
    private var filteredPartners: [PartnerProfile] {
        var result = viewModel.partners
        
        // Exclude the active profile (can't match with yourself)
        let activeProfileId = ProfileContextManager.shared.activeProfileId
        result = result.filter { $0.id != activeProfileId }
        
        // Filter by gender if specified
        if let gender = gender {
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    if viewModel.isLoading && viewModel.partners.isEmpty {
                        loadingView
                    } else if filteredPartners.isEmpty {
                        emptyView
                    } else {
                        partnerList
                    }
                    
                    // Add new partner button
                    addNewButton
                }
            }
            .navigationTitle("Select Birth Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.play(.light)
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .sheet(isPresented: $showAddForm) {
                PartnerFormView(mode: .add) { newPartner in
                    Task {
                        let success = await viewModel.addPartner(newPartner)
                        if success {
                            SoundManager.shared.playSuccess()
                            HapticManager.shared.playShimmer()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.setup(context: modelContext)
                Task {
                    await viewModel.loadPartners()
                }
            }
            .sheet(isPresented: $showUpgradePrompt) {
                SubscriptionView()
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
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.gold)
            
            TextField("Search birth charts...", text: $searchText)
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(AppTheme.Colors.inputBackground.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
            Text("Loading profiles...")
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.Colors.premiumGradient)
                .opacity(0.8)
            
            if viewModel.partners.isEmpty {
                Text("No saved profiles yet")
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            } else {
                Text("No matches found")
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            Spacer()
        }
    }
    
    // MARK: - Partner List
    
    private var partnerList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredPartners) { partner in
                    partnerRow(partner)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Partner Row
    
    private func partnerRow(_ partner: PartnerProfile) -> some View {
        Button(action: {
            HapticManager.shared.play(.medium)
            SoundManager.shared.playButtonTap()
            onSelect(partner)
            isPresented = false
        }) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.premiumGradient)
                        .frame(width: 44, height: 44)
                        .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 5)
                    
                    Text(partner.avatarInitial)
                        .font(AppTheme.Fonts.title(size: 18))
                        .foregroundColor(AppTheme.Colors.mainBackground)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(partner.name)
                        .font(AppTheme.Fonts.title(size: 15))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack(spacing: 6) {
                        Text(partner.genderSymbol)
                            .foregroundStyle(AppTheme.Colors.premiumGradient)
                        
                        Text(partner.formattedDateOfBirth)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        if let city = partner.cityOfBirth {
                            Text("•")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(city.components(separatedBy: ",").first ?? city)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .font(AppTheme.Fonts.body(size: 12))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.gold.opacity(0.5))
            }
            .padding(14)
            .background(AppTheme.Colors.cardBackground.opacity(0.2)) // Transparent background
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - Add New Button
    
    private var addNewButton: some View {
        Button(action: {
            HapticManager.shared.play(.light)
            checkAndShowAddForm()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add New Birth Chart")
                    .font(AppTheme.Fonts.body(size: 16))
            }
            .foregroundStyle(AppTheme.Colors.premiumGradient)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.Colors.surfaceBackground)
            .overlay(
                Rectangle()
                    .fill(AppTheme.Colors.gold.opacity(0.2))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .background(AppTheme.Colors.mainBackground)
    }
    
    // MARK: - Quota Check
    
    private func checkAndShowAddForm() {
        Task {
            let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
            let result = await QuotaManager.shared.canAddProfile(email: email, currentCount: viewModel.partners.count)
            
            await MainActor.run {
                if result.canAdd {
                    showAddForm = true
                } else if result.limit == 0 {
                    showUpgradePrompt = true
                } else {
                    limitMessage = "You can save up to \(result.limit) profiles. Upgrade to Plus for unlimited profiles."
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PartnerPickerSheet(
        isPresented: .constant(true),
        gender: nil
    ) { partner in
        print("Selected: \(partner.name)")
    }
}
