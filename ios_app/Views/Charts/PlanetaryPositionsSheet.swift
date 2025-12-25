import SwiftUI

/// Modal sheet showing planetary positions from birth chart
/// Accessible from Chat screen as floating button
struct PlanetaryPositionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Birth data from UserDefaults
    @State private var birthData: BirthData?
    @State private var isLoading = true
    
    // Mock planetary positions (in production, fetch from API)
    private let planets: [(symbol: String, name: String, sign: String, degree: String)] = [
        ("☉", "Sun", "Gemini", "15°23'"),
        ("☽", "Moon", "Aquarius", "8°47'"),
        ("☿", "Mercury", "Gemini", "22°11'"),
        ("♀", "Venus", "Cancer", "3°56'"),
        ("♂", "Mars", "Taurus", "18°32'"),
        ("♃", "Jupiter", "Libra", "11°08'"),
        ("♄", "Saturn", "Pisces", "27°44'"),
        ("☊", "Rahu", "Libra", "5°22'"),
        ("☋", "Ketu", "Aries", "5°22'")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.94, blue: 0.96)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Ascendant header
                        ascendantSection
                        
                        // Planetary grid
                        planetaryGrid
                        
                        // Birth info footer
                        if let data = birthData {
                            birthInfoFooter(data)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Birth Chart")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
                #endif
            }
            .onAppear {
                loadBirthData()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Ascendant Section
    private var ascendantSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("Ascendant")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
            }
            
            Text("♋ Cancer")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("NavyPrimary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
    }
    
    // MARK: - Planetary Grid
    private var planetaryGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("Planetary Positions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(planets, id: \.name) { planet in
                    PlanetCard(
                        symbol: planet.symbol,
                        name: planet.name,
                        sign: planet.sign,
                        degree: planet.degree
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        )
    }
    
    // MARK: - Birth Info Footer
    private func birthInfoFooter(_ data: BirthData) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Birth Details")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.5))
                
                Text("\(data.dob) at \(data.time)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                
                if let city = data.cityOfBirth {
                    Text(city)
                        .font(.system(size: 13))
                        .foregroundColor(Color("TextDark").opacity(0.6))
                }
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Navigate to edit birth data
            }) {
                Text("Edit")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("NavyPrimary").opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("NavyPrimary").opacity(0.05))
        )
    }
    
    // MARK: - Load Birth Data
    private func loadBirthData() {
        if let data = UserDefaults.standard.data(forKey: "birthData"),
           let decoded = try? JSONDecoder().decode(BirthData.self, from: data) {
            birthData = decoded
        }
        isLoading = false
    }
}

// MARK: - Planet Card
struct PlanetCard: View {
    let symbol: String
    let name: String
    let sign: String
    let degree: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(symbol)
                    .font(.system(size: 18))
                
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            VStack(spacing: 2) {
                Text(sign)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
                
                Text(degree)
                    .font(.system(size: 11))
                    .foregroundColor(Color("TextDark").opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.98))
        )
    }
}

// MARK: - Preview
#Preview {
    PlanetaryPositionsSheet()
}
