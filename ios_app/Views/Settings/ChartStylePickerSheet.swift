import SwiftUI

/// Sheet for selecting chart display style (North Indian / South Indian)
struct ChartStylePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var chartStyle: String
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // North Indian Style
                    Button {
                        chartStyle = "north"
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("North Indian Style")
                                    .foregroundColor(Color("NavyPrimary"))
                                    .font(.body)
                                Text("Diamond layout, houses fixed, signs rotate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if chartStyle == "north" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("GoldAccent"))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    
                    // South Indian Style
                    Button {
                        chartStyle = "south"
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("South Indian Style")
                                    .foregroundColor(Color("NavyPrimary"))
                                    .font(.body)
                                Text("Grid layout, signs fixed, houses rotate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if chartStyle == "south" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("GoldAccent"))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                } header: {
                    Text("Select Chart Style")
                } footer: {
                    Text("This affects how birth charts are displayed in compatibility analysis.")
                        .font(.caption)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Chart Style")
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

#Preview {
    ChartStylePickerSheet(chartStyle: .constant("north"))
}
