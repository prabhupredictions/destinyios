import SwiftUI

/// Chart comparison sheet - shows D1 and D9 charts for both persons
/// 2 tabs: D1 | D9, each showing Boy (top) and Girl (bottom)
struct ChartComparisonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chartStyle") private var chartStyle: String = "north"
    
    let boyName: String
    let girlName: String
    let boyChartData: ChartData?
    let girlChartData: ChartData?
    let boyAscendant: String?
    let girlAscendant: String?
    
    @State private var selectedTab = 0  // 0 = D1, 1 = D9
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium Deep Space Nebula Background (Consistent with PlanetaryPositionsSheet)
                GeometryReader { geo in
                    ZStack {
                        // Deep Base
                        Color(red: 0.05, green: 0.07, blue: 0.15).ignoresSafeArea()
                        
                        // Central Blue Glow
                        RadialGradient(
                            colors: [
                                Color(red: 0.12, green: 0.16, blue: 0.28).opacity(0.8),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(geo.size.width, geo.size.height) * 0.8
                        )
                        
                        // Top-Left Gold Nebula Glow
                        RadialGradient(
                            colors: [
                                Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.08),
                                .clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 300
                        )
                        
                        // Bottom-Right Purple/Deep Nebula
                        RadialGradient(
                            colors: [
                                Color(red: 0.3, green: 0.1, blue: 0.4).opacity(0.15),
                                .clear
                            ],
                            center: .bottomTrailing,
                            startRadius: 0,
                            endRadius: 400
                        )
                    }
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector
                        .padding(.top, 10)
                    
                    // Charts
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if selectedTab == 0 {
                                d1Charts
                            } else {
                                d9Charts
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Birth Charts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { chartStyle = "south" }) {
                            Label("South Indian", systemImage: chartStyle == "south" ? "checkmark" : "")
                        }
                        Button(action: { chartStyle = "north" }) {
                            Label("North Indian", systemImage: chartStyle == "north" ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color("GoldAccent"))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "D1 (Rashi)", index: 0)
            tabButton(title: "D9 (Navamsa)", index: 1)
        }
        .background(Color.black.opacity(0.3)) // Dark Glass
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
             RoundedRectangle(cornerRadius: 12)
                 .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: selectedTab == index ? .semibold : .medium))
                .foregroundColor(selectedTab == index ? Color("NavyPrimary") : .white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedTab == index ? Color("GoldAccent") : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - D1 Charts
    
    private var d1Charts: some View {
        VStack(spacing: 32) { // Increased spacing between boy/girl sections
            // Boy D1
            if let boyData = boyChartData {
                chartView(
                    chartData: boyData,
                    chartType: .d1,
                    personName: boyName,
                    ascendant: boyAscendant
                )
            } else {
                Text("Boy chart data not available")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            // Girl D1
            if let girlData = girlChartData {
                chartView(
                    chartData: girlData,
                    chartType: .d1,
                    personName: girlName,
                    ascendant: girlAscendant
                )
            } else {
                Text("Girl chart data not available")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - D9 Charts
    
    private var d9Charts: some View {
        VStack(spacing: 16) {
            // Boy D9
            if let boyData = boyChartData {
                chartView(
                    chartData: boyData,
                    chartType: .d9,
                    personName: boyName,
                    ascendant: boyAscendant
                )
            }
            
            // Girl D9
            if let girlData = girlChartData {
                chartView(
                    chartData: girlData,
                    chartType: .d9,
                    personName: girlName,
                    ascendant: girlAscendant
                )
            }
        }
    }
    
    // MARK: - Chart View (Style-aware) + Planet Cards
    
    @ViewBuilder
    private func chartView(
        chartData: ChartData,
        chartType: SouthIndianChartView.ChartType,
        personName: String,
        ascendant: String?
    ) -> some View {
        VStack(spacing: 12) {
            // Chart (clean - just planet codes)
            if chartStyle == "north" {
                NorthIndianChartView(
                    chartData: chartData,
                    chartType: chartType,
                    personName: personName,
                    ascendantSign: ascendant
                )
            } else {
                SouthIndianChartView(
                    chartData: chartData,
                    chartType: chartType,
                    personName: personName,
                    ascendantSign: ascendant
                )
            }
            
            // Planet Detail Cards (3x3 grid) - only for D1
            if chartType == .d1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Planet Details")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("GoldAccent").opacity(0.9))
                        .padding(.horizontal, 4)
                    
                    PlanetCardsGrid(chartData: chartData, chartType: chartType)
                }
                .padding(.horizontal, 8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChartComparisonSheet(
        boyName: "Prabhu",
        girlName: "Smita",
        boyChartData: ChartData(
            d1: [
                "Sun": D1PlanetPosition(house: 1, sign: "Ge", degree: 76.5, retrograde: false, vargottama: false, combust: false, nakshatra: nil, pada: nil),
                "Moon": D1PlanetPosition(house: 8, sign: "Cp", degree: 290.0, retrograde: false, vargottama: false, combust: false, nakshatra: nil, pada: nil)
            ],
            d9: [
                "Sun": D9PlanetPosition(house: 1, sign: "Ar"),
                "Moon": D9PlanetPosition(house: 5, sign: "Le")
            ]
        ),
        girlChartData: ChartData(
            d1: [
                "Sun": D1PlanetPosition(house: 11, sign: "Li", degree: 207.0, retrograde: false, vargottama: false, combust: false, nakshatra: nil, pada: nil),
                "Moon": D1PlanetPosition(house: 1, sign: "Sg", degree: 268.0, retrograde: false, vargottama: false, combust: false, nakshatra: nil, pada: nil)
            ],
            d9: [
                "Sun": D9PlanetPosition(house: 7, sign: "Li"),
                "Moon": D9PlanetPosition(house: 9, sign: "Sg")
            ]
        ),
        boyAscendant: "Ca",
        girlAscendant: "Sg"
    )
}
