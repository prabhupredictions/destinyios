import SwiftUI
import CoreLocation

/// Location search view with autocomplete
struct LocationSearchView: View {
    @Binding var selectedCity: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var placeId: String?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationSearchService()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                CosmicBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search field
                    searchField
                    
                    // Results
                    if locationService.isSearching {
                        loadingView
                    } else if locationService.suggestions.isEmpty && !searchText.isEmpty {
                        emptyView
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Select City")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .toolbarBackground(AppTheme.Colors.mainBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isSearchFocused = true
        }
    }
    
    // MARK: - Search Field
    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text("Search for a city...")
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                TextField("", text: $searchText)
                    .font(AppTheme.Fonts.body(size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _, newValue in
                        locationService.search(query: newValue)
                    }
            }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(16)
        .background(AppTheme.Colors.inputBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.Styles.inputBorder.stroke, lineWidth: AppTheme.Styles.inputBorder.width)
        )
        .padding(16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppTheme.Colors.gold)
            Text("Searching...")
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No cities found")
                .font(AppTheme.Fonts.body(size: 16).weight(.medium))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Try a different search term")
                .font(AppTheme.Fonts.body(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Results List
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(locationService.suggestions) { result in
                    Button(action: {
                        selectLocation(result)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.Colors.gold)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(AppTheme.Fonts.body(size: 15).weight(.medium))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(AppTheme.Fonts.caption(size: 13))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Source indicator
                            Text(result.source == .apple ? "🍎" : "G")
                                .font(AppTheme.Fonts.caption(size: 10))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.001)) // Ensure fill for tap target, but transparent
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 52)
                        .background(AppTheme.Colors.separator)
                }
            }
        }
        .background(Color.clear)
    }
    
    // MARK: - Select Location
    private func selectLocation(_ result: LocationResult) {
        Task {
            if let coords = await locationService.getCoordinates(for: result) {
                selectedCity = result.title
                latitude = coords.latitude
                longitude = coords.longitude
                placeId = result.id
                dismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LocationSearchView(
        selectedCity: .constant(""),
        latitude: .constant(0),
        longitude: .constant(0),
        placeId: .constant(nil)
    )
}
