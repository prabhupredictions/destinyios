import SwiftUI
import SwiftData

/// Partner Profile Manager - Main view for managing saved partners
/// Follows Soul of the App theme with cosmic aesthetics
struct PartnerManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = PartnerProfileViewModel()
    @State private var showAddForm = false
    @State private var editingPartner: PartnerProfile?
    @State private var partnerToDelete: PartnerProfile?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            // ATMOSPHERE - Cosmic depth
            CosmicBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if viewModel.isLoading && viewModel.partners.isEmpty {
                    loadingView
                } else if viewModel.partners.isEmpty {
                    emptyStateView
                } else {
                    partnerListView
                }
            }
        }
        .navigationBarHidden(true)
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
        .sheet(item: $editingPartner) { partner in
            PartnerFormView(mode: .edit(partner)) { updatedPartner in
                Task {
                    let success = await viewModel.updatePartner(updatedPartner)
                    if success {
                        SoundManager.shared.playSuccess()
                        HapticManager.shared.playSuccess()
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete Partner?",
            isPresented: $showDeleteConfirmation,
            presenting: partnerToDelete
        ) { partner in
            Button("Delete \(partner.name)", role: .destructive) {
                Task {
                    let success = await viewModel.deletePartner(partner)
                    if success {
                        SoundManager.shared.playButtonTap()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { partner in
            Text("This will permanently remove \(partner.name) from your saved partners.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onAppear {
            viewModel.setup(context: modelContext)
            Task {
                await viewModel.loadPartners()
            }
            SoundManager.shared.playButtonTap()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {
                HapticManager.shared.play(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.premiumGradient)
            }
            
            Spacer()
            
            Text("Saved Partners")
                .font(AppTheme.Fonts.title(size: 20))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.play(.medium)
                showAddForm = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add")
                }
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.mainBackground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.Colors.premiumGradient)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.gold))
                .scaleEffect(1.5)
            
            Text("Loading partners...")
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            HapticManager.shared.playHeartbeat()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.Colors.premiumGradient)
                .modifier(Tilt3DModifier())
            
            Text("No Saved Partners")
                .font(AppTheme.Fonts.title(size: 24))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Save partner profiles for quick matching")
                .font(AppTheme.Fonts.body(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                HapticManager.shared.play(.medium)
                showAddForm = true
            }) {
                Text("Add Partner")
                    .font(AppTheme.Fonts.title(size: 16))
                    .foregroundColor(AppTheme.Colors.mainBackground)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppTheme.Colors.premiumGradient)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(40)
    }
    
    // MARK: - Partner List
    
    private var partnerListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredPartners) { partner in
                    PartnerCardView(
                        partner: partner,
                        onTap: {
                            HapticManager.shared.play(.light)
                            editingPartner = partner
                        },
                        onDelete: {
                            HapticManager.shared.notify(.warning)
                            partnerToDelete = partner
                            showDeleteConfirmation = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .animation(.interpolatingSpring(stiffness: 100, damping: 10), value: viewModel.partners.count)
        }
        .refreshable {
            await viewModel.refresh()
            HapticManager.shared.playSuccess()
        }
    }
}

// MARK: - Partner Card View

struct PartnerCardView: View {
    let partner: PartnerProfile
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showMenu = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with gold ring
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.premiumGradient)
                    .frame(width: 50, height: 50)
                
                Text(partner.avatarInitial)
                    .font(AppTheme.Fonts.title(size: 20))
                    .foregroundColor(AppTheme.Colors.mainBackground)
            }
            .modifier(Tilt3DModifier())
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(partner.name)
                    .font(AppTheme.Fonts.title(size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                HStack(spacing: 6) {
                    Text(partner.genderSymbol)
                        .foregroundStyle(AppTheme.Colors.premiumGradient)
                    
                    Text(partner.gender.capitalized)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text(partner.formattedDateOfBirth)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    if let city = partner.cityOfBirth, !city.isEmpty {
                        Text("•")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text(city.components(separatedBy: ",").first ?? city)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .font(AppTheme.Fonts.body(size: 13))
            }
            
            Spacer()
            
            // Menu button
            Menu {
                Button(action: onTap) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.Colors.premiumGradient)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(16)
        .background(AppTheme.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.Styles.goldBorder.stroke, lineWidth: 1)
        )
        .cornerRadius(16)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PartnerManagerView()
    }
}
