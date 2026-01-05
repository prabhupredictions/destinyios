import SwiftUI

/// Sheet for selecting chart display style (North Indian / South Indian)
struct ChartStylePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var chartStyle: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.mainBackground.ignoresSafeArea()
                
                List {
                    Section {
                        // North Indian Style
                        Button {
                            chartStyle = "north"
                            HapticManager.shared.play(.light)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("North Indian Style")
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .font(AppTheme.Fonts.body(size: 16))
                                    Text("Diamond layout, houses fixed, signs rotate")
                                        .font(AppTheme.Fonts.caption(size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if chartStyle == "north" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.Colors.gold)
                                        .font(AppTheme.Fonts.title(size: 14))
                                }
                            }
                        }
                        .listRowBackground(AppTheme.Colors.cardBackground)
                        
                        // South Indian Style
                        Button {
                            chartStyle = "south"
                            HapticManager.shared.play(.light)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("South Indian Style")
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .font(AppTheme.Fonts.body(size: 16))
                                    Text("Grid layout, signs fixed, houses rotate")
                                        .font(AppTheme.Fonts.caption(size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if chartStyle == "south" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.Colors.gold)
                                        .font(AppTheme.Fonts.title(size: 14))
                                }
                            }
                        }
                        .listRowBackground(AppTheme.Colors.cardBackground)
                    } header: {
                        Text("Select Chart Style")
                            .font(AppTheme.Fonts.title(size: 14))
                            .foregroundColor(AppTheme.Colors.gold)
                    } footer: {
                        Text("This affects how birth charts are displayed in compatibility analysis.")
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Chart Style")
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

#Preview {
    ChartStylePickerSheet(chartStyle: .constant("north"))
}
