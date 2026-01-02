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
            List {
                // Ayanamsa Section
                Section {
                    ForEach(ayanamsaOptions, id: \.key) { option in
                        Button {
                            ayanamsa = option.key
                        } label: {
                            HStack {
                                Text(option.label)
                                    .foregroundColor(Color("NavyPrimary"))
                                
                                Spacer()
                                
                                if ayanamsa == option.key {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("GoldAccent"))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ayanamsa".localized)
                        Text("ayanamsa_desc".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // House System Section
                Section {
                    ForEach(houseSystemOptions, id: \.key) { option in
                        Button {
                            houseSystem = option.key
                        } label: {
                            HStack {
                                Text(option.label)
                                    .foregroundColor(Color("NavyPrimary"))
                                
                                Spacer()
                                
                                if houseSystem == option.key {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("GoldAccent"))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("house_system".localized)
                        Text("house_system_desc".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Chart Style Section
                Section {
                    ForEach(chartStyleOptions, id: \.key) { option in
                        Button {
                            chartStyle = option.key
                        } label: {
                            HStack {
                                Text(option.label)
                                    .foregroundColor(Color("NavyPrimary"))
                                
                                Spacer()
                                
                                if chartStyle == option.key {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color("GoldAccent"))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chart Style")
                        Text("Choose how birth charts are displayed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Astrology Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("NavyPrimary"))
                }
            }
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
