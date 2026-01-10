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
    
    private var filteredPartners: [PartnerProfile] {
        var result = viewModel.partners
        
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
        NavigationView {
            ZStack {
                AppTheme.Colors.mainBackground
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
            .navigationTitle("Select Partner")
            .navigationBarTitleDisplayMode(.inline)
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
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            TextField("Search partners...", text: $searchText)
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(AppTheme.Colors.cardBackground)
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
            Text("Loading partners...")
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
            
            if viewModel.partners.isEmpty {
                Text("No saved partners yet")
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
                    .foregroundStyle(AppTheme.Colors.premiumGradient)
            }
            .padding(14)
            .background(AppTheme.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.Styles.goldBorder.stroke, lineWidth: 0.5)
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - Add New Button
    
    private var addNewButton: some View {
        Button(action: {
            HapticManager.shared.play(.light)
            showAddForm = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add New Partner")
                    .font(AppTheme.Fonts.body(size: 16))
            }
            .foregroundStyle(AppTheme.Colors.premiumGradient)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.Colors.cardBackground)
            .overlay(
                Rectangle()
                    .fill(AppTheme.Styles.goldBorder.stroke)
                    .frame(height: 0.5),
                alignment: .top
            )
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
