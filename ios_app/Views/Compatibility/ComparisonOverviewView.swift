import SwiftUI

/// Comparison Overview View — Unified Single-Screen Design (V2.1)
/// One scrollable screen that dynamically handles 1-3 partners, mixed recommended/rejected.
/// Matches wireframe: compact cards → koota breakdown → WHY NOT RECOMMENDED → 🏆 recommendation
struct ComparisonOverviewView: View {
    let results: [ComparisonResult]
    let userName: String
    var onSelectPartner: (Int) -> Void  // Navigate to existing detail screen
    var onBack: () -> Void
    var onNewMatch: () -> Void
    
    @State private var showCancellationAlert: Bool = false
    @State private var selectedCancellationReason: String = ""
    @State private var overlayTitle = "Dosha Cancellation"
    @State private var overlaySubtitle = "Astrological exceptions applied"
    @State private var isGeneratingPDF = false
    
    // Viability-sorted: recommended first (by adjustedScore DESC), then not-recommended
    private var sortedResults: [ComparisonResult] {
        let recommended = results.filter { $0.isRecommended }.sorted { $0.adjustedScore > $1.adjustedScore }
        let rejected = results.filter { !$0.isRecommended }.sorted { $0.adjustedScore > $1.adjustedScore }
        return recommended + rejected
    }
    
    private var bestMatch: ComparisonResult? {
        sortedResults.first(where: { $0.isRecommended })
    }
    
    private var allRejected: Bool {
        results.allSatisfy { !$0.isRecommended }
    }
    
    var body: some View {
        ZStack {
            CosmicBackgroundView().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Single unified scroll
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // ═══════════════════════════════════════
                        // SECTION 1: Compact Partner Cards (equal width, fit to screen)
                        // ═══════════════════════════════════════
                        HStack(spacing: sortedResults.count > 2 ? 4 : 10) {
                            ForEach(Array(sortedResults.enumerated()), id: \.element.id) { index, result in
                                let isBest = (bestMatch?.id == result.id)
                                compactPartnerCard(result: result, isBest: isBest, index: index)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, sortedResults.count > 2 ? 2 : 16)
                        
                        if sortedResults.contains(where: { $0.adjustedScore != $0.overallScore }) {
                            Text("*After dosha cancellation")
                                .font(AppTheme.Fonts.caption(size: 11).italic())
                                .foregroundColor(AppTheme.Colors.gold)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, sortedResults.count > 2 ? 10 : 20)
                                .padding(.top, -6)
                        }
                        
                        // ═══════════════════════════════════════
                        // SECTION 1.5: Final Recommendation
                        // ═══════════════════════════════════════
                        recommendationFooter
                            .padding(.horizontal, sortedResults.count > 2 ? 6 : 16)
                            .padding(.top, 4)
                        
                        // ═══════════════════════════════════════
                        // SECTION 2: Detailed Koota Breakdown Table
                        // ═══════════════════════════════════════
                        if sortedResults.count >= 2 {
                            detailedBreakdownTable
                                .padding(.horizontal, sortedResults.count > 2 ? 6 : 12)
                        }
                        
                        // ═══════════════════════════════════════
                        // SECTION 3: Analysis (Per Partner)
                        // ═══════════════════════════════════════
                        ForEach(sortedResults, id: \.id) { result in
                            analysisSection(for: result)
                        }
                        .padding(.horizontal, sortedResults.count > 2 ? 6 : 16)
                        
                        // ═══════════════════════════════════════
                        // SECTION 4: New Match Button
                        // ═══════════════════════════════════════
                        
                        // Save to Files Button
                        Button {
                            saveToFiles()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Text("Save to Files")
                                    .font(AppTheme.Fonts.body(size: 16))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.Colors.gold.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(isGeneratingPDF)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        
                        // New Match Button
                        Button(action: onNewMatch) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("new_match".localized)
                                    .font(AppTheme.Fonts.body(size: 16).weight(.medium))
                            }
                            .foregroundColor(AppTheme.Colors.gold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.gold.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .overlay(
            Group {
                if showCancellationAlert {
                    cancellationOverlay
                }
            }
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                // Back button
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                Spacer()
                
                // Title
                HStack(spacing: 8) {
                    Image("match_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    Text("comparison_results".localized)
                        .font(AppTheme.Fonts.display(size: 22))
                        .foregroundColor(AppTheme.Colors.gold)
                }
                
                Spacer()
                
                // Share button
                Button {
                    shareComparisonReport()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            .padding(.horizontal, 16)
            
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Text(userName)
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }
    
    // MARK: - Compact Partner Card
    /// Horizontal scrollable card per partner: name, badge, adj score, [View Detail →]
    private func compactPartnerCard(result: ComparisonResult, isBest: Bool, index: Int) -> some View {
        let statusColor: Color = result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error
        let badgeText = isBest ? "⭐ " + "best_match".localized : (result.isRecommended ? "✅ " + "recommended".localized : "❌ " + "not_rec".localized)
        
        return DivineGlassCard(cornerRadius: 14) {
            VStack(spacing: 6) {
                // Name
                Text(result.partner.name.uppercased())
                    .font(AppTheme.Fonts.title(size: 15).weight(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                // Score Display
                if result.adjustedScore != result.overallScore {
                    VStack(spacing: 0) {
                        Text("\(result.adjustedScore)/36*")
                            .font(AppTheme.Fonts.caption(size: 11).weight(.semibold))
                            .foregroundColor(AppTheme.Colors.gold)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)
                        Text("\(result.overallScore)/36 actual")
                            .font(AppTheme.Fonts.caption(size: 9))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .minimumScaleFactor(0.7)
                    }
                } else {
                    VStack(spacing: 0) {
                        Text("\(result.overallScore)/36 actual")
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.gold)
                        Text("No Adjustment")
                            .font(AppTheme.Fonts.caption(size: 9))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                // Badge
                Text(badgeText)
                    .font(AppTheme.Fonts.caption(size: 10).weight(.semibold))
                    .foregroundColor(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
                Spacer(minLength: 2)
                
                // Re-added View Details indicator
                HStack(spacing: 4) {
                    Text("View Details")
                        .font(AppTheme.Fonts.caption(size: 10).weight(.semibold))
                        .foregroundColor(AppTheme.Colors.gold)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.Colors.gold)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 0)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            HapticManager.shared.play(.light)
            if let originalIndex = results.firstIndex(where: { $0.id == result.id }) {
                onSelectPartner(originalIndex)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isBest ? AppTheme.Colors.gold.opacity(0.6) :
                    (!result.isRecommended ? AppTheme.Colors.error.opacity(0.3) : Color.clear),
                    lineWidth: isBest ? 2 : 1
                )
        )
    }
    
    // MARK: - Detailed Breakdown Table (Koota × Partner Grid)
    private var detailedBreakdownTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section Divider
            sectionDivider(title: "DETAILED BREAKDOWN")
            
            DivineGlassCard(cornerRadius: 14) {
                VStack(spacing: 0) {
                    // Header Row
                    HStack(spacing: 0) {
                        Text("Area")
                            .font(AppTheme.Fonts.caption(size: 12).weight(.medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .frame(width: sortedResults.count > 2 ? 70 : 95, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        ForEach(sortedResults, id: \.id) { result in
                            Text(String(result.partner.name.prefix(8)))
                                .font(AppTheme.Fonts.caption(size: 12).weight(.bold))
                                .foregroundColor(AppTheme.Colors.gold)
                                .frame(maxWidth: .infinity)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    
                    dividerLine
                    
                    // Guna rows — user-friendly names matching orbit view
                    let kutaRows: [(key: String, label: String)] = [
                        ("Nadi", "Health"),
                        ("Bhakoot", "Love"),
                        ("Gana", "Temperament"),
                        ("Maitri", "Friendship"),
                        ("Yoni", "Intimacy"),
                        ("Vashya", "Dominance"),
                        ("Tara", "Destiny"),
                        ("Varna", "Work")
                    ]
                    ForEach(kutaRows, id: \.key) { kuta in
                        kutaRow(key: kuta.key, label: kuta.label)
                    }
                    
                    // Mangal row
                    mangalRow
                    
                    dividerLine
                    
                    // Actual totals
                    HStack(spacing: 0) {
                        Text("Actual")
                            .font(AppTheme.Fonts.caption(size: 13).weight(.semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(width: sortedResults.count > 2 ? 70 : 95, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        ForEach(sortedResults, id: \.id) { result in
                            Text("\(result.overallScore)/36")
                                .font(AppTheme.Fonts.caption(size: 13))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 6)
                    
                    // Adjusted totals (bold gold)
                    HStack(spacing: 0) {
                        Text("Adjusted")
                            .font(AppTheme.Fonts.caption(size: 13).weight(.bold))
                            .foregroundColor(AppTheme.Colors.gold)
                            .frame(width: sortedResults.count > 2 ? 70 : 95, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        ForEach(sortedResults, id: \.id) { result in
                            Text("\(result.adjustedScore)/36")
                                .font(AppTheme.Fonts.body(size: 15).weight(.bold))
                                .foregroundColor(AppTheme.Colors.gold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 6)
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - Kuta Row
    private func kutaRow(key: String, label: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(AppTheme.Fonts.caption(size: 12).weight(.medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: sortedResults.count > 2 ? 70 : 95, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            ForEach(sortedResults, id: \.id) { result in
                let kuta = result.result.kutas.first(where: { $0.name.lowercased() == key.lowercased() })
                kutaCellView(kuta: kuta, kutaName: key, result: result)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
    }
    
    // MARK: - Kuta Cell (score + status icon)
    private func kutaCellView(kuta: KutaDetail?, kutaName: String, result: ComparisonResult) -> some View {
        guard let k = kuta else {
            return AnyView(
                Text("—")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            )
        }
        
        let cancelReason = result.doshaCancellationReason(for: kutaName)
        let isCancelled = cancelReason != nil
        let hasRejection = result.rejectionReasons.contains { $0.contains(kutaName) }
        let isZero = k.points == 0
        
        if isCancelled {
            // Cancelled dosha: 0→max ✅ + (i)
            return AnyView(
                HStack(spacing: 2) {
                    Text("\(k.points)→\(k.maxPoints)")
                        .font(AppTheme.Fonts.caption(size: 11).weight(.medium))
                        .foregroundColor(AppTheme.Colors.success)
                    
                    Button {
                        overlayTitle = "Dosha Cancellation"
                        overlaySubtitle = "Astrological exceptions applied"
                        selectedCancellationReason = formatRejectionReason(cancelReason ?? "", partnerName: result.partner.name)
                        showCancellationAlert = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                }
            )
        } else if isZero && hasRejection {
            // Active dosha: 0 🚫
            return AnyView(
                HStack(spacing: 1) {
                    Text("\(k.points)")
                        .font(AppTheme.Fonts.caption(size: 12).weight(.medium))
                        .foregroundColor(AppTheme.Colors.error)
                    Text("🚫")
                        .font(.system(size: 8))
                }
            )
        } else if k.points == k.maxPoints {
            // Full score ✅
            return AnyView(
                HStack(spacing: 1) {
                    Text("\(k.points)")
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(AppTheme.Colors.success)
                    Text("✅")
                        .font(.system(size: 8))
                }
            )
        } else if isZero {
            // Zero score (non-critical) ⚠️
            return AnyView(
                HStack(spacing: 1) {
                    Text("\(k.points)")
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(Color.orange)
                    
                    Button {
                        overlayTitle = "Low Score Warning"
                        overlaySubtitle = "Attention may be required"
                        let desc = k.description.isEmpty ? "\(kutaName) compatibility score is 0. This area requires mutual understanding and effort." : k.description
                        selectedCancellationReason = formatRejectionReason(desc, partnerName: result.partner.name)
                        showCancellationAlert = true
                    } label: {
                        Text("⚠️")
                            .font(.system(size: 8))
                    }
                }
            )
        } else {
            // Partial score without white dashes
            return AnyView(
                Text("\(k.points)")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            )
        }
    }
    
    // MARK: - Manglik Row
    private var mangalRow: some View {
        HStack(spacing: 0) {
            Text("Manglik")
                .font(AppTheme.Fonts.caption(size: 12).weight(.medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: sortedResults.count > 2 ? 70 : 95, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            ForEach(sortedResults, id: \.id) { result in
                let hasMangalRejection = result.rejectionReasons.contains { $0.contains("Mangal") }
                let mangalCompat = result.result.analysisData?.joint?.mangalCompatibility
                
                // Use structured data: check cancellation.occurs or compatibility_category
                let cancellationOccurs = (mangalCompat?["cancellation"]?.value as? [String: Any])?["occurs"] as? Bool
                let compatCategory = mangalCompat?["compatibility_category"]?.value as? String
                let hasMangalData = mangalCompat != nil
                
                HStack(spacing: 1) {
                    if hasMangalRejection {
                        Text("Active")
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.error)
                        Text("🚫")
                            .font(.system(size: 8))
                    } else if cancellationOccurs == true {
                        // Structured data: cancellation confirmed
                        Text("Cancelled")
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.success)
                        Text("✅")
                            .font(.system(size: 8))
                    } else if let cat = compatCategory {
                        // Structured data: use compatibility category
                        Text(cat.prefix(1).uppercased() + cat.dropFirst().lowercased())
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(
                                cat.lowercased() == "excellent" ? AppTheme.Colors.success :
                                cat.lowercased() == "good" ? AppTheme.Colors.success :
                                cat.lowercased() == "moderate" ? .orange : .yellow
                            )
                        Text(cat.lowercased() == "excellent" || cat.lowercased() == "good" ? "✅" : "⚠️")
                            .font(.system(size: 8))
                    } else if !hasMangalData {
                        // No mangal data at all — neither present
                        Text("None")
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.success)
                        Text("✅")
                            .font(.system(size: 8))
                    } else {
                        Text("View")
                            .font(AppTheme.Fonts.caption(size: 11))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
    }
    
    // MARK: - Analysis Section (Per Partner)
    private func analysisSection(for result: ComparisonResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionDivider(
                title: "ANALYSIS (\(result.partner.name.uppercased()))",
                color: AppTheme.Colors.gold
            )
            
            VStack(alignment: .leading, spacing: 10) {
                // Final Recommendation Summary
                MarkdownTextView(
                    content: extractFinalRecommendation(from: result.result.summary),
                    fontSize: 14
                )
                
                // Recommendation Label
                HStack(spacing: 6) {
                    Circle()
                        .fill(result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error)
                        .frame(width: 8, height: 8)
                    Text(result.statusLabel)
                        .font(AppTheme.Fonts.caption(size: 13).weight(.medium))
                        .foregroundColor(result.isRecommended ? AppTheme.Colors.success : AppTheme.Colors.error)
                }
                

            }
            .padding(14)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Recommendation Footer
    private var recommendationFooter: some View {
        DivineGlassCard(cornerRadius: 14) {
            VStack(spacing: 6) {
                if allRejected {
                    // All rejected — warning state
                    HStack(alignment: .top, spacing: 8) {
                        Text("⚠️")
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("None of the profiles meet the recommended compatibility threshold.")
                                .font(AppTheme.Fonts.body(size: 13))
                                .foregroundColor(AppTheme.Colors.warning)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Review individual analyses below for detailed insights.")
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else if let best = bestMatch {
                    // Best match recommendation
                    HStack(alignment: .top, spacing: 8) {
                        Text("🏆")
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Final Recommendation: \(best.partner.name) (\(best.adjustedScore)/36)")
                                .font(AppTheme.Fonts.title(size: 15))
                                .foregroundColor(AppTheme.Colors.gold)
                            Text(best.oneLiner ?? "All doshas safe. Highest compatibility.")
                                .font(AppTheme.Fonts.caption(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(2)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    allRejected ? AppTheme.Colors.warning.opacity(0.4) : AppTheme.Colors.gold.opacity(0.5),
                    lineWidth: 1.5
                )
        )
    }
    
    // MARK: - Helpers
    private func formatRejectionReason(_ reason: String, partnerName: String) -> String {
        // Extract first names
        let userFirstName = userName.components(separatedBy: " ").first ?? userName
        let partnerFirstName = partnerName.components(separatedBy: " ").first ?? partnerName
        
        var formatted = reason
        // Replace labels
        formatted = formatted.replacingOccurrences(of: "Boy:", with: "\(userFirstName):")
        formatted = formatted.replacingOccurrences(of: "Girl:", with: "\(partnerFirstName):")
        formatted = formatted.replacingOccurrences(of: "Boy is", with: "\(userFirstName) is")
        formatted = formatted.replacingOccurrences(of: "Girl is", with: "\(partnerFirstName) is")
        formatted = formatted.replacingOccurrences(of: "Boy's", with: "\(userFirstName)'s")
        formatted = formatted.replacingOccurrences(of: "Girl's", with: "\(partnerFirstName)'s")
        formatted = formatted.replacingOccurrences(of: " Boy ", with: " \(userFirstName) ")
        formatted = formatted.replacingOccurrences(of: " Girl ", with: " \(partnerFirstName) ")
        return formatted
    }
    
    // MARK: - Share & Save Actions
    
    private func shareComparisonReport() {
        Task { @MainActor in
            // Build a text summary for sharing
            var shareText = "✨ Compatibility Analysis – \(userName)\n\n"
            for r in sortedResults {
                let status = r.isRecommended ? "✅ " + "recommended".localized : "❌ " + "not_recommended".localized
                shareText += "• \(r.partner.name): \(r.adjustedScore)/\(r.maxScore) – \(status)\n"
            }
            shareText += "\nAnalyzed with Destiny AI Astrology\n🔗 destinyaiastrology.com"
            
            // Generate professional PDF
            let renderer = ComparisonPDFRenderer(results: results, userName: userName)
            let pdfData = renderer.render()
            
            let partnerNames = sortedResults.map { $0.partner.name }.joined(separator: "_")
            let firstName = userName.components(separatedBy: " ").first ?? userName
            let fileName = "\(firstName)_vs_\(partnerNames)_comparison.pdf"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try? pdfData.write(to: tempURL)
            
            var shareItems: [Any] = [shareText]
            shareItems.append(tempURL)
            
            ReportShareService.shared.presentShareSheet(items: shareItems)
        }
    }
    
    private func saveToFiles() {
        isGeneratingPDF = true
        
        Task { @MainActor in
            let renderer = ComparisonPDFRenderer(results: results, userName: userName)
            let pdfData = renderer.render()
            
            let partnerNames = sortedResults.map { $0.partner.name }.joined(separator: "_")
            let firstName = userName.components(separatedBy: " ").first ?? userName
            let fileName = "\(firstName)_vs_\(partnerNames)_comparison.pdf"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try? pdfData.write(to: tempURL)
            
            ReportShareService.shared.presentSaveToFiles(fileURL: tempURL)
            
            isGeneratingPDF = false
        }
    }
    
    /// Build a simple PDF view of the comparison results
    @MainActor
    private func comparisonPDFView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("DESTINY AI ASTROLOGY")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    .tracking(4)
                
                Text("COMPATIBILITY COMPARISON")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.6))
                    .tracking(3)
                
                Text(userName)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            
            // Each partner result
            ForEach(sortedResults, id: \.id) { r in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(r.partner.name)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(r.adjustedScore)/\(r.maxScore)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.83, green: 0.69, blue: 0.22))
                    }
                    
                    Text(r.isRecommended ? "✅ " + "recommended".localized : "❌ " + "not_recommended".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(r.isRecommended ? .green : .red)
                    
                    if !r.result.summary.isEmpty {
                        // Trim to first 600 chars for PDF compactness
                        let trimmedSummary = r.result.summary.count > 600
                            ? String(r.result.summary.prefix(600)) + "..."
                            : r.result.summary
                        Text(trimmedSummary)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.83, green: 0.69, blue: 0.22).opacity(0.15), lineWidth: 0.5)
                        )
                )
            }
            
            // Footer
            VStack(spacing: 6) {
                let dateFormatter: DateFormatter = {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    return f
                }()
                Text("Generated: \(dateFormatter.string(from: Date()))")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.3))
                Text("© 2026 Destiny AI Astrology · destinyaiastrology.com")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.25))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .padding(20)
        .background(Color(red: 0.04, green: 0.06, blue: 0.10))
    }
    
    private func sectionDivider(title: String, color: Color = AppTheme.Colors.textSecondary) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color.opacity(0.4))
                .frame(width: 16, height: 1)
            Text(title)
                .font(AppTheme.Fonts.caption(size: 10))
                .tracking(1.2)
                .foregroundColor(color.opacity(0.8))
            Rectangle()
                .fill(color.opacity(0.4))
                .frame(height: 1)
        }
    }
    
    private var dividerLine: some View {
        Rectangle()
            .fill(AppTheme.Colors.gold.opacity(0.15))
            .frame(height: 0.5)
            .padding(.horizontal, 6)
    }
    
    // MARK: - Helpers
    private func extractFinalRecommendation(from text: String) -> String {
        let pattern = "FINAL RECOMMENDATION"
        guard let range = text.range(of: pattern) else { return text }
        
        let afterRecommendation = String(text[range.upperBound...])
        return afterRecommendation.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Cancellation Overlay
    private var cancellationOverlay: some View {
        ZStack {
            // Dark dimming background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showCancellationAlert = false
                    }
                }
            
            // Pop-up Card
            VStack(spacing: 16) {
                // Header
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.success)
                        .shadow(color: AppTheme.Colors.success.opacity(0.4), radius: 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(overlayTitle)
                            .font(AppTheme.Fonts.title(size: 18))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text(overlaySubtitle)
                            .font(AppTheme.Fonts.caption(size: 12))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showCancellationAlert = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .font(.system(size: 22))
                    }
                }
                
                Divider().background(AppTheme.Colors.gold.opacity(0.3))
                
                // Content
                Text(selectedCancellationReason)
                    .font(AppTheme.Fonts.body(size: 15))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .frame(width: 320)
            .background(
                ZStack {
                    AppTheme.Colors.mainBackground
                    
                    // Subtle cosmic glow
                    RadialGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0.05),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.gold.opacity(0.5),
                                AppTheme.Colors.gold.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: AppTheme.Colors.gold.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .zIndex(100)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ComparisonOverviewView(
            results: [],
            userName: "Prabhu",
            onSelectPartner: { _ in },
            onBack: {},
            onNewMatch: {}
        )
    }
}
