import SwiftUI

/// Modal sheet showing planetary positions from birth chart
/// Accessible from Chat screen as floating button
struct PlanetaryPositionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chartStyle") private var chartStyle: String = "north" // north | south
    
    // User Birth Data
    @State private var birthData: UserBirthData?
    @State private var chartData: UserAstroDataResponse?
    @State private var cityOfBirth: String = ""
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium Deep Space Nebula Background
                GeometryReader { geo in
                    ZStack {
                        // Deep Base
                        AppTheme.Colors.mainBackground.ignoresSafeArea()
                        
                        // Central Blue Glow
                        RadialGradient(
                            colors: [
                                AppTheme.Colors.secondaryBackground.opacity(0.8),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(geo.size.width, geo.size.height) * 0.8
                        )
                        
                        // Top-Left Gold Nebula/Star Glow
                        RadialGradient(
                            colors: [
                                AppTheme.Colors.gold.opacity(0.1),
                                .clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 300
                        )
                        
                        // Bottom-Right Purple/Deep Nebula
                        RadialGradient(
                            colors: [
                                AppTheme.Colors.purpleAccent.opacity(0.15),
                                .clear
                            ],
                            center: .bottomTrailing,
                            startRadius: 0,
                            endRadius: 400
                        )
                    }
                }
                .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Color("GoldAccent"))
                            .scaleEffect(1.5)
                        Text("Calculating Chart...")
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else if let error = errorMessage {
                     VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(AppTheme.Fonts.display(size: 40))
                            .foregroundColor(.red.opacity(0.8))
                        Text("Failed to load chart")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
                        Button("Retry") { loadData() }
                            .buttonStyle(.borderedProminent)
                            .tint(Color("GoldAccent"))
                    }
                    .padding()
                } else if let chart = chartData {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Calculate Ascendant for display
                            let signNum = chart.houses["1"]?.signNum ?? 1
                            let ascIndex = max(0, min(11, signNum - 1))
                            let ascSignCode = ChartConstants.orderedSigns[ascIndex]
                            let ascName = ChartConstants.signFullNames[ascSignCode] ?? ascSignCode
                            
                            // Minimal Birth Info Line + Ascendant
                            minimalBirthInfo(chart.birthDetails, city: cityOfBirth, ascendant: ascName)
                            
                            // Chart Visualization (North/South)
                            chartVisualSection(chart: chart)
                            
                            // Premium Planetary Grid
                            planetaryGrid(chart: chart)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Birth Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            // .toolbarBackground(.visible, for: .navigationBar) // was solid NavyPrimary
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Chart Style Toggles
                    Menu {
                        Button(action: { chartStyle = "north" }) {
                            Label("North Indian", systemImage: chartStyle == "north" ? "checkmark" : "")
                        }
                        Button(action: { chartStyle = "south" }) {
                            Label("South Indian", systemImage: chartStyle == "south" ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color("GoldAccent"))
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .onAppear {
                loadData()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Chart Visualization Section
    private func chartVisualSection(chart: UserAstroDataResponse) -> some View {
        VStack(spacing: 12) {
            // Header Removed as requested - Clean Look
            
            // The Chart
            let mappedData = mapToChartData(chart)
            // Get Ascendant Sign (House 1)
            let signNum = chart.houses["1"]?.signNum ?? 1
            let ascIndex = max(0, min(11, signNum - 1))
            let ascendantSign = ChartConstants.orderedSigns[ascIndex]
            
            Group {
                if chartStyle == "north" {
                    NorthIndianChartView(
                        chartData: mappedData,
                        chartType: .d1,
                        personName: "", // Hidden in view
                        ascendantSign: nil // Hidden in view
                    )
                } else {
                    SouthIndianChartView(
                        chartData: mappedData,
                        chartType: .d1,
                        personName: "Rashi (D1)",
                        ascendantSign: ascendantSign
                    )
                }
            }
            .frame(maxWidth: .infinity)
            // Removed fixed height and background to let chart "gel" with app background
        }
    }
    
    // MARK: - Planetary Grid
    private func planetaryGrid(chart: UserAstroDataResponse) -> some View {
        // Define planet order
        let planetOrder = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu"]
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Planetary Positions")
                    .font(AppTheme.Fonts.title(size: 18))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(planetOrder, id: \.self) { planetName in
                    if let pData = chart.planets[planetName] {
                        PremiumPlanetRow(
                            name: planetName,
                            data: pData,
                            nakshatra: chart.nakshatra[planetName]
                        )
                    }
                }
            }
        }
    }

    // MARK: - Minimal Birth Info (Clean, no box)
    private func minimalBirthInfo(_ details: AstroBirthDetails, city: String, ascendant: String) -> some View {
        return HStack(spacing: 8) {
            // Date
            Text(formatBirthDate(details.dob))
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("•")
                .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
            
            // Time
            Text(formatBirthTime(details.time))
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            // City (if available)
            if !city.isEmpty {
                Text("•")
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
                
                Text(city)
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            // Ascendant
            Text("•")
                .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
            
            Text("Asc: \(ascendant)")
                .font(AppTheme.Fonts.title(size: 14)) // Slightly bolder
                .foregroundColor(AppTheme.Colors.gold) // Gold color to stand out
        }
        .padding(.vertical, 4)
    }
    
    private func formatBirthDate(_ dob: String) -> String {
        // Convert 2013-04-22 to Apr 22, 2013
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM dd, yyyy"
        
        if let date = inputFormatter.date(from: dob) {
            return outputFormatter.string(from: date)
        }
        return dob
    }
    
    private func formatBirthTime(_ time: String) -> String {
        // Convert 20:20 to 8:20 PM
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        if let date = inputFormatter.date(from: time) {
            return outputFormatter.string(from: date)
        }
        return time
    }
    
    // MARK: - Data Mapper
    private func mapToChartData(_ response: UserAstroDataResponse) -> ChartData {
        // Map D1
        var d1Map: [String: D1PlanetPosition] = [:]
        for (key, data) in response.planets {
            d1Map[key] = D1PlanetPosition(
                house: data.house,
                sign: data.sign,
                degree: data.degree,
                retrograde: data.isRetrograde ?? false,
                vargottama: data.vargottama ?? false,
                combust: data.isCombust ?? false,
                nakshatra: response.nakshatra[key]?.nakshatra,
                pada: response.nakshatra[key]?.pada
            )
        }
        
        // Map D9 (API returns flat structure, which is D9 data directly)
        var d9Map: [String: D9PlanetPosition] = [:]
        for (key, divData) in response.divisionalCharts {
            // divData.house is String in model, converting to Int
            let houseInt = Int(divData.house)
            d9Map[key] = D9PlanetPosition(
                house: houseInt,
                sign: divData.sign
            )
        }
        
        return ChartData(d1: d1Map, d9: d9Map)
    }
    
    // MARK: - Helper Functions
    
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        // Read from correct key: "userBirthData" (not "userBirthProfile")
        guard let storedData = UserDefaults.standard.data(forKey: "userBirthData"),
              let savedBirthData = try? JSONDecoder().decode(BirthData.self, from: storedData) else {
            isLoading = false
            errorMessage = "No birth profile found."
            return
        }
        
        // Convert BirthData (local storage) -> UserBirthData (API request)
        // Normalize time to 24-hour format for legacy data
        let normalizedTime = normalizeTimeFormat(savedBirthData.time)
        
        let apiBirthData = UserBirthData(
            dob: savedBirthData.dob,
            time: normalizedTime,
            latitude: savedBirthData.latitude,
            longitude: savedBirthData.longitude,
            ayanamsa: savedBirthData.ayanamsa,
            houseSystem: savedBirthData.houseSystem,
            cityOfBirth: savedBirthData.cityOfBirth
        )
        
        Task {
            do {
                let chart = try await UserChartService.shared.fetchFullChartData(birthData: apiBirthData)
                
                await MainActor.run {
                    self.chartData = chart
                    self.cityOfBirth = savedBirthData.cityOfBirth ?? ""
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// Normalize time to 24-hour format (handles legacy "8:30 PM" -> "20:30")
    private func normalizeTimeFormat(_ time: String) -> String {
        // Check if already in HH:mm format (24-hour)
        let hhmmRegex = "^\\d{2}:\\d{2}$"
        if time.range(of: hhmmRegex, options: .regularExpression) != nil {
            return time // Already normalized
        }
        
        // Try to parse 12-hour format
        let formatter12 = DateFormatter()
        formatter12.locale = Locale(identifier: "en_US_POSIX")
        formatter12.dateFormat = "h:mm a"
        
        if let date = formatter12.date(from: time) {
            let formatter24 = DateFormatter()
            formatter24.dateFormat = "HH:mm"
            let normalizedTime = formatter24.string(from: date)
            print("[PlanetaryPositionsSheet] Normalized time from '\(time)' to '\(normalizedTime)'")
            return normalizedTime
        }
        
        return time // Return as-is if can't parse
    }
}

// MARK: - Premium Planet Row (Updated for Dark Mode Contrast)
// MARK: - Premium Planet Row (Updated for Dark Mode Contrast)
struct PremiumPlanetRow: View {
    let name: String
    let data: PlanetData
    let nakshatra: NakshatraData?
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Column - Dark Glass Circle
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 48, height: 48)
                
                Text(planetSymbol(for: name))
                    .font(AppTheme.Fonts.title(size: 22))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
                // Main Info Column
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name.localized)
                        .font(AppTheme.Fonts.title(size: 16))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    // Badges
                    if data.isRetrograde == true {
                        Badge(text: "R", color: AppTheme.Colors.error)
                    }
                    if data.isCombust == true {
                        Badge(text: "C", color: .orange)
                    }
                    if data.vargottama == true {
                        Badge(text: "V", color: .purple)
                    }
                }
                
                HStack(spacing: 6) {
                    Text(data.sign)
                        .font(AppTheme.Fonts.title(size: 14))
                        .foregroundColor(AppTheme.Colors.gold)
                    
                    Text("•")
                        .font(AppTheme.Fonts.caption(size: 10))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Text(formatDegree(data.degree))
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Detailed Right Column (House & Nakshatra)
            VStack(alignment: .trailing, spacing: 4) {
                Text("House \(data.house)")
                    .font(AppTheme.Fonts.title(size: 12))
                    .foregroundColor(AppTheme.Colors.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.gold.opacity(0.15))
                            .strokeBorder(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                    )
                
                if let nak = nakshatra {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(nak.nakshatra)
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text("Pada \(nak.pada)")
                            .font(AppTheme.Fonts.caption(size: 10))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [AppTheme.Colors.gold.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Add subtle shadow for depth
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // Helpers within struct
    private func planetSymbol(for name: String) -> String {
        switch name {
        case "Sun": return "☉"
        case "Moon": return "☽"
        case "Mars": return "♂"
        case "Mercury": return "☿"
        case "Jupiter": return "♃"
        case "Venus": return "♀"
        case "Saturn": return "♄"
        case "Rahu": return "☊"
        case "Ketu": return "☋"
        default: return "⋆"
        }
    }
    
    private func formatDegree(_ degree: Double) -> String {
        let d = Int(degree)
        let m = Int((degree - Double(d)) * 60)
        return String(format: "%d°%02d'", d, m)
    }
}

struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(AppTheme.Fonts.title(size: 10))
            .foregroundColor(color.opacity(0.9))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
                    .strokeBorder(color.opacity(0.4), lineWidth: 0.5)
            )
    }
}
