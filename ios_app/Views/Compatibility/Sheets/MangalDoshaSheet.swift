//
//  MangalDoshaSheet.swift
//  ios_app
//
//  Premium Mangal Dosha detail sheet with animated severity gauge
//

import SwiftUI

struct MangalDoshaSheet: View {
    let boyData: MangalDoshaData?
    let girlData: MangalDoshaData?
    let boyName: String
    let girlName: String
    let mangalCompatibility: [String: AnyCodable]?  // Combined analysis data
    
    @State private var selectedPartner: Int = 0  // 0 = boy, 1 = girl, 2 = combined
    @State private var gaugeValue: Double = 0
    @Environment(\.dismiss) private var dismiss
    
    private var currentData: MangalDoshaData? {
        selectedPartner == 0 ? boyData : (selectedPartner == 1 ? girlData : nil)
    }
    
    private var currentName: String {
        selectedPartner == 0 ? boyName : (selectedPartner == 1 ? girlName : "combined".localized)
    }
    
    private var isCombinedView: Bool {
        selectedPartner == 2
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium Deep Space Nebula Background
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Partner Picker
                        partnerPicker
                        
                        if isCombinedView {
                            // Combined View
                            combinedAnalysisView
                        } else if let data = currentData {
                            // Individual Severity Gauge
                            severityGauge(data)
                            
                            // Mars Position (only if data available in dict)
                            if let posDict = data.marsPosition,
                               let house = posDict["house"]?.value as? Int,
                               let sign = posDict["sign"]?.value as? String {
                                let nakshatra = (posDict["nakshatra"]?.value as? String) ?? ""
                                marsPositionCard(house: house, sign: sign, nakshatra: nakshatra)
                            }
                            
                            // Cancellation Status
                            cancellationCard(data)
                            
                            // Dosha Calculation Breakdown (Premium)
                            doshaBreakdownCard(data)
                            
                            // Mitigating Factors (Exceptions)
                            // Show if we have detailed exceptions OR just the count
                            if !data.activeExceptions.isEmpty {
                                factorsCard(
                                    title: "mitigating_factors".localized,
                                    factors: data.exceptionDescriptions,
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )
                            } else if let count = data.exceptionCount, count > 0 {
                                // Fallback: Show count when details unavailable
                                factorsCard(
                                    title: "mitigating_factors".localized,
                                    factors: ["\(count) " + "factors_reduce_severity".localized],
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )
                            }
                            
                            // Intensifying Factors
                            if !data.activeIntensityFactors.isEmpty {
                                factorsCard(
                                    title: "intensifying_factors".localized,
                                    factors: data.intensityDescriptions,
                                    icon: "exclamationmark.triangle.fill",
                                    color: .orange
                                )
                            } else if let count = data.intensityFactorCount, count > 0 {
                                // Fallback: Show count when details unavailable
                                factorsCard(
                                    title: "intensifying_factors".localized,
                                    factors: ["\(count) " + "factors_increase_severity".localized],
                                    icon: "exclamationmark.triangle.fill",
                                    color: .orange
                                )
                            }
                            
                            // Remedies
                            if let remedies = data.remedies, !remedies.isEmpty {
                                remediesCard(remedies)
                            }
                        } else {
                            noDataView
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("mangal_dosha_analysis".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                gaugeValue = currentData?.doshaScore ?? 0
            }
        }
        .onChange(of: selectedPartner) { _ in
            gaugeValue = 0
            withAnimation(.easeOut(duration: 0.8)) {
                gaugeValue = currentData?.doshaScore ?? 0
            }
        }
    }
    


    // MARK: - Position Pill Component
    
    private func positionPill(label: String, value: String, subValue: String?, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let sub = subValue {
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundColor(color.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05)) // Extremely subtle fill
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 1) // Sharp border
        )
    }
    
    // MARK: - Partner Picker (3 tabs: Boy, Girl, Combined)
    
    private var partnerPicker: some View {
        HStack(spacing: 0) {
            // Boy tab
            pickerButton(title: boyName, index: 0)
            // Girl tab
            pickerButton(title: girlName, index: 1)
            // Combined tab
            pickerButton(title: "combined".localized, index: 2)
        }
        .padding(4)
        .background(Color.black.opacity(0.3)) // Dark Glass
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func pickerButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedPartner = index
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selectedPartner == index ? .white : .white.opacity(0.6))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    selectedPartner == index
                    ? Color("GoldAccent").opacity(0.3)
                    : Color.clear
                )
                .clipShape(Capsule())
                .overlay(
                    selectedPartner == index ?
                    Capsule().stroke(Color("GoldAccent").opacity(0.5), lineWidth: 1) : nil
                )
        }
    }
    
    // MARK: - Combined Analysis View
    
    private var combinedAnalysisView: some View {
        VStack(spacing: 20) {
            // Compatibility Score Card
            compatibilityScoreCard
            
            // Side-by-side comparison
            sideBySideComparison
            
            // Synastry Aspects
            synastryAspectsCard
            
            // Recommendations
            recommendationsCard
        }
    }
    
    // MARK: - Compatibility Score Card
    
    private var compatibilityScoreCard: some View {
        let score = mangalCompatibility?["compatibility_score"]?.value as? Double ?? 0
        let category = mangalCompatibility?["compatibility_category"]?.value as? String ?? "unknown"
        let cancellationOccurs = mangalCompatibility?["cancellation_occurs"]?.value as? Bool ?? false
        let cancellationStrength = mangalCompatibility?["cancellation_strength"]?.value as? Double ?? 0
        let reason = mangalCompatibility?["cancellation_reason"]?.value as? String ?? ""
        
        return VStack(spacing: 16) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(
                        LinearGradient(
                            colors: categoryGradientColors(category),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(score * 100))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(category.capitalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(categoryColor(category))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(categoryColor(category).opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .frame(width: 160, height: 160)
            
            // Cancellation status
            if cancellationOccurs {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("dosha_cancelled".localized)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    Text("(\(Int(cancellationStrength * 100))%)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text(reason)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(glassBackground)
    }
    
    // MARK: - Side by Side Comparison
    
    private var sideBySideComparison: some View {
        HStack(spacing: 12) {
            // Boy mini card
            miniDoshaCard(name: boyName, data: boyData, color: .cyan)
            
            // Girl mini card
            miniDoshaCard(name: girlName, data: girlData, color: .pink)
        }
    }
    
    private func miniDoshaCard(name: String, data: MangalDoshaData?, color: Color) -> some View {
        VStack(spacing: 12) {
            Text(name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            if let data = data {
                // Score
                Text("\(Int(data.doshaScore * 100))%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
                
                // Severity badge
                Text(data.severity.capitalized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(severityColor(data.severity).opacity(0.3))
                    .clipShape(Capsule())
                
                // Status
                HStack(spacing: 4) {
                    Circle()
                        .fill(data.hasMangalDosha ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(data.hasMangalDosha ? "present".localized : "absent".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                Text("no_data".localized)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            glassBackground
                .overlay(color.opacity(0.05).cornerRadius(16))
        )
    }
    
    // MARK: - Synastry Aspects Card
    
    private var synastryAspectsCard: some View {
        let synastryDetails = mangalCompatibility?["synastry_details"]?.value as? [String: Any]
        let beneficialAspects = synastryDetails?["beneficial_aspects"] as? [[String: Any]] ?? []
        let challengingAspects = synastryDetails?["challenging_aspects"] as? [[String: Any]] ?? []
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.purple)
                Text("synastry_aspects".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Beneficial aspects
            if !beneficialAspects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("beneficial".localized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                    
                    ForEach(beneficialAspects.indices, id: \.self) { i in
                        let aspect = beneficialAspects[i]
                        let planet = aspect["planet"] as? String ?? ""
                        let type = aspect["aspect_type"] as? String ?? ""
                        let desc = aspect["description"] as? String ?? ""
                        
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text("\(planet) (\(type))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            // Challenging aspects
            if !challengingAspects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("challenging".localized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    ForEach(challengingAspects.indices, id: \.self) { i in
                        let aspect = challengingAspects[i]
                        let planet = aspect["planet"] as? String ?? ""
                        let type = aspect["aspect_type"] as? String ?? ""
                        
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("\(planet) (\(type))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassBackground)
    }
    
    // MARK: - Recommendations Card
    
    private var recommendationsCard: some View {
        let recommendations = mangalCompatibility?["recommendations"]?.value as? [String] ?? []
        
        guard !recommendations.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("recommendations".localized)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ForEach(recommendations.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.yellow)
                        Text(recommendations[i])
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(glassBackground)
        )
    }
    
    // MARK: - Helper for category colors
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "excellent": return .green
        case "good": return .cyan
        case "moderate": return .yellow
        case "poor": return .orange
        default: return .gray
        }
    }
    
    private func categoryGradientColors(_ category: String) -> [Color] {
        switch category.lowercased() {
        case "excellent": return [.green, .mint]
        case "good": return [.cyan, .blue]
        case "moderate": return [.yellow, .orange]
        case "poor": return [.orange, .red]
        default: return [.gray, .white]
        }
    }
    
    private func severityColor(_ severity: String?) -> Color {
        switch severity?.lowercased() {
        case "mild": return .yellow
        case "moderate": return .orange
        case "severe": return .red
        default: return .gray
        }
    }
    
    // MARK: - Severity Gauge
    
    private func severityGauge(_ data: MangalDoshaData) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.25, to: 0.75)
                    .stroke(Color.white.opacity(0.1), lineWidth: 20)
                    .rotationEffect(.degrees(90))
                
                // Progress arc with gradient
                Circle()
                    .trim(from: 0.25, to: 0.25 + (gaugeValue * 0.5))
                    .stroke(
                        gaugeGradient(for: data.doshaScore),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .animation(.easeOut(duration: 1.0), value: gaugeValue)
                
                // Center content
                VStack(spacing: 4) {
                    Text(data.hasMangalDosha ? "🔴" : "✅")
                        .font(.system(size: 32))
                    
                    Text("\(Int(data.doshaScore * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(data.severityLabel.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(severityColor(data.severity))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(severityColor(data.severity).opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .frame(width: 200, height: 200)
            
            if let explanation = data.explanation {
                Text(explanation)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(glassBackground)
    }
    
    // MARK: - Mars Position Card (Premium)
    
    private func marsPositionCard(house: Int, sign: String, nakshatra: String) -> some View {
        let posDict = currentData?.marsPosition
        let signLord = posDict?["sign_lord"]?.value as? String
        let nakshatraLord = posDict?["nakshatra_lord"]?.value as? String
        let degree = posDict?["degree"]?.value as? Double
        
        return VStack(spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                Text("mars_position".localized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Main Position Grid
            HStack(spacing: 0) {
                // House
                positionPill(
                    label: "house_label".localized,
                    value: house.ordinal,
                    subValue: nil,
                    color: .orange
                )
                
                // Sign
                positionPill(
                    label: DoshaDescriptions.sign(sign),
                    value: signLord != nil ? DoshaDescriptions.planet(signLord!) : "",
                    subValue: degree != nil ? String(format: "%.1f°", degree!) : nil,
                    color: .purple
                )
                
                // Nakshatra
                if !nakshatra.isEmpty {
                    positionPill(
                        label: nakshatra,
                        value: nakshatraLord != nil ? DoshaDescriptions.planet(nakshatraLord!) : "",
                        subValue: "nakshatra_lord".localized,
                        color: .cyan
                    )
                }
            }
        }
        .padding()
        .background(
            glassBackground
                .overlay(    
                    LinearGradient(
                        colors: [Color.red.opacity(0.08), Color.orange.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(16)
                )
        )
    }
    

    
    // MARK: - Cancellation Card
    
    private func cancellationCard(_ data: MangalDoshaData) -> some View {
        let hasExceptions = !data.activeExceptions.isEmpty
        
        return VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: hasExceptions ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .foregroundColor(hasExceptions ? .green : .red.opacity(0.7))
                Text(hasExceptions ? "cancellation_active".localized : "mangal_dosha_status".localized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Strength Meter
            if hasExceptions {
                cancellationStrengthMeter(data)
            }
        }
        .padding()
        .background(
            glassBackground
                .overlay(
                    hasExceptions ? Color.green.opacity(0.05).cornerRadius(16) : Color.white.opacity(0.02).cornerRadius(16)
                )
        )
    }
    
    private func cancellationStrengthMeter(_ data: MangalDoshaData) -> some View {
        HStack {
            Text("strength".localized)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (1.0 - data.doshaScore))
                }
            }
            .frame(height: 8)
            
            Text("\(Int((1.0 - data.doshaScore) * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)
        }
    }
    
    // MARK: - Dosha Breakdown Card (Premium)
    
    private func doshaBreakdownCard(_ data: MangalDoshaData) -> some View {
        // Calculate breakdown values based on exceptions and intensity
        let exceptionCount = data.exceptionCount ?? data.activeExceptions.count
        let intensityCount = data.intensityFactorCount ?? data.activeIntensityFactors.count
        
        // Estimate base score (house-based: 1st/7th=1.0, 2nd/8th=0.75, 4th/12th=0.50)
        let baseScore: Double = 0.75 // Default estimate
        let mitigationScore = Double(exceptionCount) * 0.075
        let intensityScore = Double(intensityCount) * 0.10
        
        return VStack(spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                Text("dosha_calculation".localized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 14) {
                // Base Strength
                breakdownRow(
                    label: "base_strength".localized,
                    value: baseScore,
                    maxValue: 1.0,
                    color: .orange,
                    isAdditive: true
                )
                
                // Mitigation (subtractive - green)
                breakdownRow(
                    label: "mitigation".localized + " (\(exceptionCount))",
                    value: mitigationScore,
                    maxValue: 0.5,
                    color: .green,
                    isAdditive: false
                )
                
                // Intensification (additive - red)
                breakdownRow(
                    label: "intensification".localized + " (\(intensityCount))",
                    value: intensityScore,
                    maxValue: 0.5,
                    color: .red,
                    isAdditive: true
                )
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                
                // Final Score
                HStack {
                    Text("final_score".localized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(String(format: "%.0f%%", data.doshaScore * 100))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(severityColor(data.severity))
                }
            }
        }
        .padding()
        .background(
            glassBackground
                .overlay(Color.blue.opacity(0.05).cornerRadius(16))
        )
    }
    
    // MARK: - Breakdown Row Component
    
    private func breakdownRow(label: String, value: Double, maxValue: Double, color: Color, isAdditive: Bool) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 110, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    
                    Capsule()
                        .fill(color)
                        .frame(width: min(geometry.size.width * (value / maxValue), geometry.size.width))
                }
            }
            .frame(height: 8)
            
            Text(isAdditive ? String(format: "+%.0f%%", value * 100) : String(format: "-%.0f%%", value * 100))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 45, alignment: .trailing)
        }
    }
    
    // MARK: - Factors Card
    
    private func factorsCard(title: String, factors: [String], icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(title) (\(factors.count))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(factors, id: \.self) { factor in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: color == .green ? "checkmark" : "exclamationmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(color)
                            .frame(width: 16, height: 16)
                        
                        Text(factor)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(glassBackground)
    }
    
    // MARK: - Remedies Card
    
    private func remediesCard(_ remedies: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("recommended_remedies".localized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(remedies, id: \.self) { remedy in
                    HStack(alignment: .top, spacing: 10) {
                        Text("🙏")
                            .font(.system(size: 14))
                        
                        Text(remedy)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(glassBackground)
    }
    
    // MARK: - No Data View
    
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Mangal Dosha data available")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(40)
    }
    
    // MARK: - Helpers
    
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .background(Color.black.opacity(0.2).cornerRadius(16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private func gaugeGradient(for score: Double) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
            center: .center,
            startAngle: .degrees(180),
            endAngle: .degrees(0)
        )
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "none": return .green
        case "mild": return .yellow
        case "moderate": return .orange
        case "high", "severe": return .red
        default: return .gray
        }
    }
}



#Preview {
    MangalDoshaSheet(
        boyData: nil,
        girlData: nil,
        boyName: "Partner A",
        girlName: "Partner B",
        mangalCompatibility: nil
    )
}
