import SwiftUI

/// Astrology settings sheet for selecting Ayanamsa, House System, and Chart Style
struct AstrologySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Settings stored in UserDefaults
    @AppStorage("ayanamsa") private var ayanamsa = "lahiri"
    @AppStorage("houseSystem") private var houseSystem = "equal"
    @AppStorage("chartStyle") private var chartStyle = "north"  // North Indian default
    
    // Ayanamsa options matching API
    private let ayanamsaOptions: [(key: String, label: String)] = [
        ("lahiri", "Lahiri (Most common)"),
        ("raman", "Raman"),
        ("krishnamurti", "Krishnamurti (KP)"),
        ("fagan_bradley", "Fagan-Bradley")
    ]
    
    // House system options matching API
    private let houseSystemOptions: [(key: String, label: String)] = [
        ("equal", "Equal Houses"),
        ("whole_sign", "Whole Sign"),
        ("placidus", "Placidus"),
        ("koch", "Koch"),
        ("regiomontanus", "Regiomontanus"),
        ("campanus", "Campanus"),
        ("morinus", "Morinus"),
        ("alcabitus", "Alcabitus"),
        ("porphyrius", "Porphyrius")
    ]
    
    // Chart style options
    private let chartStyleOptions: [(key: String, label: String)] = [
        ("north", "North Indian Style"),
        ("south", "South Indian Style")
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
                                    Text(option.label)
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
                                    Text(option.label)
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
                                    Text(option.label)
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
                            Text("Chart Style")
                                .font(AppTheme.Fonts.title(size: 14))
                                .foregroundColor(AppTheme.Colors.gold)
                            Text("Choose how birth charts are displayed")
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Astrology Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PremiumCloseButton {
                        dismiss()
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
