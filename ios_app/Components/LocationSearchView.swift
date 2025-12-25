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
            .background(Color(red: 0.96, green: 0.95, blue: 0.98))
            .navigationTitle("Select City")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }
    
    // MARK: - Search Field
    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color("NavyPrimary").opacity(0.5))
            
            TextField("Search for a city...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(Color("NavyPrimary"))
                .focused($isSearchFocused)
                .onChange(of: searchText) { _, newValue in
                    locationService.search(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color("NavyPrimary").opacity(0.3))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
        )
        .padding(16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.system(size: 14))
                .foregroundColor(Color("TextDark").opacity(0.6))
            Spacer()
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 40))
                .foregroundColor(Color("NavyPrimary").opacity(0.3))
            
            Text("No cities found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
            
            Text("Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(Color("TextDark").opacity(0.6))
            Spacer()
        }
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
                                .foregroundColor(Color("GoldAccent"))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color("NavyPrimary"))
                                
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color("TextDark").opacity(0.5))
                                }
                            }
                            
                            Spacer()
                            
                            // Source indicator
                            Text(result.source == .apple ? "🍎" : "G")
                                .font(.system(size: 10))
                                .foregroundColor(Color("TextDark").opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
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
