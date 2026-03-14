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
                                    Text("north_indian_style".localized)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .font(AppTheme.Fonts.body(size: 16).weight(.semibold))
                                    Text("north_indian_desc".localized)
                                        .font(AppTheme.Fonts.caption(size: 13))
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
                                    Text("south_indian_style".localized)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .font(AppTheme.Fonts.body(size: 16).weight(.semibold))
                                    Text("south_indian_desc".localized)
                                        .font(AppTheme.Fonts.caption(size: 13))
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
                        Text("select_chart_style".localized)
                            .font(AppTheme.Fonts.title(size: 20))
                            .foregroundColor(AppTheme.Colors.gold)
                    } footer: {
                        Text("chart_style_note".localized)
                            .font(AppTheme.Fonts.body(size: 14))
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
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ChartStylePickerSheet(chartStyle: .constant("north"))
}
