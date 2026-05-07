import SwiftUI

/// Astrology settings sheet for selecting Ayanamsa, House System, and Chart Style
struct AstrologySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Settings stored in UserDefaults
    @AppStorage("ayanamsa") private var ayanamsa = "lahiri"
    @AppStorage("houseSystem") private var houseSystem = "whole_sign"
    @AppStorage("chartStyle") private var chartStyle = "north"  // North Indian default
    
    // Ayanamsa options matching API
    private let ayanamsaOptions: [(key: String, label: String)] = [
        ("lahiri", "ayanamsa_lahiri"),
        ("raman", "ayanamsa_raman"),
        ("krishnamurti", "ayanamsa_krishnamurti"),
        ("fagan_bradley", "ayanamsa_fagan_bradley")
    ]

    // House system options matching API
    private let houseSystemOptions: [(key: String, label: String)] = [
        ("equal", "house_system_equal"),
        ("whole_sign", "house_system_whole_sign"),
        ("placidus", "house_system_placidus"),
        ("koch", "house_system_koch"),
        ("regiomontanus", "house_system_regiomontanus"),
        ("campanus", "house_system_campanus"),
        ("morinus", "house_system_morinus"),
        ("alcabitus", "house_system_alcabitus"),
        ("porphyrius", "house_system_porphyrius")
    ]

    // Chart style options
    private let chartStyleOptions: [(key: String, label: String)] = [
        ("north", "north_indian_style"),
        ("south", "south_indian_style")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                List {
                    // Ayanamsa Section
                    Section {
                        ForEach(ayanamsaOptions, id: \.key) { option in
                            Button {
                                ayanamsa = option.key
                                HapticManager.shared.play(.light)
                            } label: {
                                HStack {
                                    Text(option.label.localized)
                                        .font(AppTheme.Fonts.body(size: 16))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if ayanamsa == option.key {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppTheme.Colors.gold)
                                            .font(AppTheme.Fonts.title(size: 14))
                                    }
                                }
                            }
                            .listRowBackground(AppTheme.Colors.cardBackground)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ayanamsa".localized)
                                .font(AppTheme.Fonts.title(size: 14))
                                .foregroundColor(AppTheme.Colors.gold)
                            Text("ayanamsa_desc".localized)
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    
                    // House System Section
                    Section {
                        ForEach(houseSystemOptions, id: \.key) { option in
                            Button {
                                houseSystem = option.key
                                HapticManager.shared.play(.light)
                            } label: {
                                HStack {
                                    Text(option.label.localized)
                                        .font(AppTheme.Fonts.body(size: 16))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if houseSystem == option.key {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppTheme.Colors.gold)
                                            .font(AppTheme.Fonts.title(size: 14))
                                    }
                                }
                            }
                            .listRowBackground(AppTheme.Colors.cardBackground)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("house_system".localized)
                                .font(AppTheme.Fonts.title(size: 14))
                                .foregroundColor(AppTheme.Colors.gold)
                            Text("house_system_desc".localized)
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    
                    // Chart Style Section
                    Section {
                        ForEach(chartStyleOptions, id: \.key) { option in
                            Button {
                                chartStyle = option.key
                                HapticManager.shared.play(.light)
                            } label: {
                                HStack {
                                    Text(option.label.localized)
                                        .font(AppTheme.Fonts.body(size: 16))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if chartStyle == option.key {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppTheme.Colors.gold)
                                            .font(AppTheme.Fonts.title(size: 14))
                                    }
                                }
                            }
                            .listRowBackground(AppTheme.Colors.cardBackground)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("chart_style".localized)
                                .font(AppTheme.Fonts.body(size: 16).weight(.medium))
                                .foregroundColor(AppTheme.Colors.gold)
                            Text("choose_chart_display".localized)
                                .font(AppTheme.Fonts.caption(size: 13))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("astrology_settings_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done_action".localized) { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Helper to get display names
extension String {
    var ayanamsaDisplayName: String {
        switch self {
        case "lahiri": return "Lahiri"
        case "raman": return "Raman"
        case "krishnamurti": return "Krishnamurti"
        case "fagan_bradley": return "Fagan-Bradley"
        default: return self.capitalized
        }
    }
    
    var houseSystemDisplayName: String {
        switch self {
        case "equal": return "Equal"
        case "whole_sign": return "Whole Sign"
        case "placidus": return "Placidus"  
        case "koch": return "Koch"
        case "regiomontanus": return "Regiomontanus"
        case "campanus": return "Campanus"
        case "morinus": return "Morinus"
        case "alcabitus": return "Alcabitus"
        case "porphyrius": return "Porphyrius"
        default: return self.capitalized
        }
    }
}

#Preview {
    AstrologySettingsSheet()
}
