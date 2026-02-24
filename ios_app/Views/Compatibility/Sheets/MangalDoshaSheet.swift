//
//  MangalDoshaSheet.swift
//  ios_app
//
//  Redesigned Scenario-Based Mangal Dosha Analysis
//

import SwiftUI

enum MarsStatus {
    case safe       // Neither has Dosha
    case cancelled  // Dosha present but cancelled
    case effective  // Dosha present and effective (Bad)
}

/// Helper to replace snake_case exception keys with localized descriptions
private func localizeExceptionKeys(in text: String) -> String {
    var result = text
    
    // Known exception keys pattern (mars_* style keys)
    let exceptionPattern = #"mars_[a-z_]+"#
    
    if let regex = try? NSRegularExpression(pattern: exceptionPattern, options: []) {
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
            if let matchRange = Range(match.range, in: text) {
                let key = String(text[matchRange])
                let localized = DoshaDescriptions.exception(key)
                // Only replace if localization exists (not returning same key)
                if !localized.contains(key) {
                    result = result.replacingCharacters(in: matchRange, with: localized)
                }
            }
        }
    }
    
    return result
}

/// Helper to extract house number from AnyCodable value
private func extractHouseNumber(from value: Any) -> Int? {
    if let intVal = value as? Int {
        return intVal
    } else if let doubleVal = value as? Double {
        return Int(doubleVal)
    }
    return nil
}

struct MangalDoshaSheet: View {
    let boyData: MangalDoshaData?
    let girlData: MangalDoshaData?
    let boyName: String
    let girlName: String
    let mangalCompatibility: [String: AnyCodable]?
    
    @Environment(\.dismiss) private var dismiss
    
    // Determine the high-level scenario
    private var status: MarsStatus {
        let boyHas = boyData?.hasMangalDosha ?? false
        let girlHas = girlData?.hasMangalDosha ?? false
        let isCancelled = mangalCompatibility?["cancellation_occurs"]?.value as? Bool ?? false
        
        if !boyHas && !girlHas {
            return .safe
        } else if isCancelled {
            return .cancelled
        } else {
            return .effective
        }
    }
    
    var body: some View {
        ZStack {
            // Premium Cosmic Background (matching CompatibilityResultView)
            CosmicBackgroundView()
                .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    switch status {
                    case .safe:
                        SafeAnalysisView(boyName: boyName, girlName: girlName)
                    case .cancelled:
                        CancelledAnalysisView(
                            boyName: boyName,
                            girlName: girlName,
                            boyData: boyData,
                            girlData: girlData,
                            reason: mangalCompatibility?["cancellation_reason"]?.value as? String ?? "Dosha cancelled",
                            mangalCompatibility: mangalCompatibility
                        )
                    case .effective:
                        EffectiveAnalysisView(
                            boyName: boyName,
                            girlName: girlName,
                            boyData: boyData,
                            girlData: girlData,
                            remedies: (boyData?.remedies ?? []) + (girlData?.remedies ?? []),
                            mangalCompatibility: mangalCompatibility
                        )
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Mars Compatibility")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}


// MARK: - 1. Safe Scenario (Perfect Match)
struct SafeAnalysisView: View {
    let boyName: String
    let girlName: String
    
    var body: some View {
        VStack(spacing: 30) {
            // 1. Hero Celebration
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.success.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .stroke(AppTheme.Colors.success.opacity(0.5), lineWidth: 1)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.Colors.success)
                        .shadow(color: AppTheme.Colors.success.opacity(0.5), radius: 10)
                }
                
                VStack(spacing: 8) {
                    Text("Perfectly Safe")
                        .font(AppTheme.Fonts.display(size: 24))
                        .foregroundColor(AppTheme.Colors.success)
                    
                    Text("No Mangal Dosha detected in either chart.")
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 20)
            
            // 2. Comparison Card
            HStack(spacing: 16) {
                SafePersonCard(name: boyName, icon: "person.fill")
                SafePersonCard(name: girlName, icon: "person.fill")
            }
            
            // 3. Educational Note
            VStack(spacing: 12) {
                Text("Why is this good?")
                    .font(AppTheme.Fonts.title(size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Since neither partner is 'Manglik', there is no risk of Mars-related conflicts affecting the marriage. This aspect contributes significantly to long-term peace.")
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.45))
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.08), location: 0),
                                    .init(color: Color.white.opacity(0.0), location: 0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
            )
        }
    }
}

struct SafePersonCard: View {
    let name: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(AppTheme.Colors.mainBackground)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.Colors.gold)
                )
                .overlay(Circle().stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1))
            
            Text(name)
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)
            
            Text("Non-Manglik")
                .font(AppTheme.Fonts.caption(size: 12).bold())
                .foregroundColor(AppTheme.Colors.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.Colors.success.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.4))
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.06), location: 0),
                                .init(color: Color.white.opacity(0.0), location: 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - 2. Cancelled Scenario (Good with explanation)
struct CancelledAnalysisView: View {
    let boyName: String
    let girlName: String
    let boyData: MangalDoshaData?
    let girlData: MangalDoshaData?
    let reason: String
    var mangalCompatibility: [String: AnyCodable]? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // 1. Hero Status
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .shadow(color: .blue.opacity(0.5), radius: 8)
                }
                
                VStack(spacing: 4) {
                    Text("Dosha Cancelled")
                        .font(AppTheme.Fonts.display(size: 22))
                        .foregroundColor(.blue)
                    
                    Text({
                        // Use first cancellation_factor from backend if available
                        if let factors = mangalCompatibility?["cancellation_factors"]?.value as? [String],
                           let first = factors.first {
                            return first
                        }
                        return "Any potential negative effects are neutralized."
                    }())
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.top, 10)
            
            // 2. Cancellation Reason Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppTheme.Colors.gold)
                    Text("Why it's cancelled")
                        .font(AppTheme.Fonts.title(size: 16))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                Group {
                    let boyHasExc = (boyData?.activeExceptions.count ?? 0) > 0
                    let girlHasExc = (girlData?.activeExceptions.count ?? 0) > 0
                    
                    if boyHasExc || girlHasExc {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Both partners' Mangal Dosha is at the same level, causing mutual neutralisation.")
                                .font(AppTheme.Fonts.body(size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let boy = boyData, boyHasExc {
                                ExceptionPersonBlock(name: boyName, data: boy)
                            }
                            if let girl = girlData, girlHasExc {
                                if boyHasExc { Divider().padding(.vertical, 2) }
                                ExceptionPersonBlock(name: girlName, data: girl)
                            }
                        }
                    } else {
                        Text(localizeExceptionKeys(in: reason))
                            .font(AppTheme.Fonts.body(size: 15))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.mainBackground.opacity(0.5))
                .cornerRadius(12)
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.45))
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.08), location: 0),
                                    .init(color: Color.white.opacity(0.0), location: 0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
            )

            // 3. Comparison
            HStack(spacing: 12) {
                StatusPersonCard(name: boyName, data: boyData)
                StatusPersonCard(name: girlName, data: girlData)
            }
        }
    }
}

// MARK: - 3. Effective Scenario (Attention Needed)
struct EffectiveAnalysisView: View {
    let boyName: String
    let girlName: String
    let boyData: MangalDoshaData?
    let girlData: MangalDoshaData?
    let remedies: [String]
    var mangalCompatibility: [String: AnyCodable]? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // 1. Hero Alert
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .shadow(color: .orange.opacity(0.5), radius: 8)
                }
                
                VStack(spacing: 4) {
                    Text("Attention Required")
                        .font(AppTheme.Fonts.display(size: 22))
                        .foregroundColor(.orange)
                    
                    Text({
                        // Use cancellation_reason from backend or first residual_effect
                        if let reason = mangalCompatibility?["cancellation_reason"]?.value as? String, !reason.isEmpty {
                            return reason
                                .replacingOccurrences(of: "Girl", with: girlName)
                                .replacingOccurrences(of: "Boy", with: boyName)
                        }
                        return "Mangal Dosha is effective and may cause friction."
                    }())
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.top, 10)
            
            // 2. Who has it?
            HStack(spacing: 12) {
                StatusPersonCard(name: boyName, data: boyData)
                StatusPersonCard(name: girlName, data: girlData)
            }
            
            // 2b. Mitigating Exceptions — show for ALL persons who have exceptions
            let boyHasExc = (boyData?.activeExceptions.count ?? 0) > 0
            let girlHasExc = (girlData?.activeExceptions.count ?? 0) > 0
            
            if boyHasExc || girlHasExc {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(AppTheme.Colors.gold)
                        Text("Mitigating Exceptions")
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                    }
                    
                    Text("Vedic astrology recognises planetary conditions that reduce or neutralise Mangal Dosha. Below are the exceptions found in each chart.")
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Boy exceptions
                    if let boy = boyData, boyHasExc {
                        ExceptionPersonBlock(
                            name: boyName,
                            data: boy
                        )
                    }
                    
                    // Girl exceptions
                    if let girl = girlData, girlHasExc {
                        if boyHasExc { Divider().padding(.vertical, 2) }
                        ExceptionPersonBlock(
                            name: girlName,
                            data: girl
                        )
                    }
                }
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.45))
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.08), location: 0),
                                        .init(color: Color.white.opacity(0.0), location: 0.45)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppTheme.Colors.gold.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
                )
            }
            
            // 3. Remedies (Top Priority Here)
            if !remedies.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.green)
                        Text("Suggested Remedies")
                            .font(AppTheme.Fonts.title(size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                    }
                    
                    ForEach(remedies.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(i + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.Colors.mainBackground)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(AppTheme.Colors.gold))
                            
                            Text(remedies[i])
                                .font(AppTheme.Fonts.body(size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.45))
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.08), location: 0),
                                        .init(color: Color.white.opacity(0.0), location: 0.45)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
                )
            }
        }
    }
}

// MARK: - Shared Components

struct ExceptionPersonBlock: View {
    let name: String
    let data: MangalDoshaData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Impact header with color-coded icon
            HStack(spacing: 6) {
                Image(systemName: data.isCancelled ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(data.isCancelled ? AppTheme.Colors.success : .yellow)
                
                if let impact = data.exceptionImpactSummary {
                    Text("\(name): \(impact)")
                        .font(AppTheme.Fonts.caption(size: 13).bold())
                        .foregroundColor(data.isCancelled ? AppTheme.Colors.success : .yellow)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("\(name)")
                        .font(AppTheme.Fonts.caption(size: 13).bold())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            // Exception list
            ForEach(data.exceptionDescriptions, id: \.self) { desc in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(AppTheme.Colors.gold.opacity(0.7))
                    Text(desc)
                        .font(AppTheme.Fonts.body(size: 13))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 4)
            }
            
            // Intensity factors (if any)
            if !data.activeIntensityFactors.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange.opacity(0.8))
                    Text("\(data.activeIntensityFactors.count) intensifying factor\(data.activeIntensityFactors.count == 1 ? "" : "s")")
                        .font(AppTheme.Fonts.caption(size: 12))
                        .foregroundColor(.orange.opacity(0.8))
                }
                .padding(.top, 4)
                
                ForEach(data.intensityDescriptions, id: \.self) { desc in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.orange.opacity(0.6))
                        Text(desc)
                            .font(AppTheme.Fonts.body(size: 13))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 4)
                }
            }
        }
    }
}

struct StatusPersonCard: View {
    let name: String
    let data: MangalDoshaData?
    
    var hasDosha: Bool { data?.hasMangalDosha ?? false }
    
    private var borderColor: Color {
        guard let data = data, hasDosha else { return .white }
        if data.isCancelled { return AppTheme.Colors.success }
        if data.isReduced { return .yellow }
        return .orange
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(name)
                .font(AppTheme.Fonts.title(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)
            
            if let data = data {
                if hasDosha {
                    VStack(spacing: 6) {
                        // Severity Badge
                        if data.isCancelled {
                            Text("Cancelled")
                                .font(AppTheme.Fonts.caption(size: 12).bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.Colors.success)
                                .clipShape(Capsule())
                        } else {
                            Text({
                                let sev = data.severity.lowercased()
                                if sev == "mild" { return "Mild Manglik" }
                                else if sev == "moderate" { return "Moderate Manglik" }
                                else if sev == "high" { return "High Manglik" }
                                else if sev == "severe" { return "Severe Manglik" }
                                return "Manglik"
                            }())
                                .font(AppTheme.Fonts.caption(size: 12).bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background({
                                    let sev = data.severity.lowercased()
                                    if sev == "severe" || sev == "high" { return Color.red }
                                    else if sev == "moderate" { return Color.orange }
                                    return Color.orange.opacity(0.8)
                                }())
                                .clipShape(Capsule())
                        }
                        
                        // Dosha Source
                        if let doshaSource = data.activeDoshaSourcesDisplay {
                            Text(doshaSource)
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if let pos = data.marsPosition,
                           let houseValue = pos["house"]?.value,
                           let houseNum = extractHouseNumber(from: houseValue),
                           houseNum > 0 {
                            Text("Mars in House \(houseNum)")
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        
                        // Exception impact summary (for both reduced AND cancelled)
                        if let impact = data.exceptionImpactSummary {
                            Text(impact)
                                .font(AppTheme.Fonts.caption(size: 10))
                                .foregroundColor(data.isCancelled ? AppTheme.Colors.success.opacity(0.9) : .yellow.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    Text("Safe")
                        .font(AppTheme.Fonts.caption(size: 12).bold())
                        .foregroundColor(AppTheme.Colors.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.success.opacity(0.15))
                        .clipShape(Capsule())
                }
            } else {
                Text("--")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.4))
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.06), location: 0),
                                .init(color: Color.white.opacity(0.0), location: 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [borderColor.opacity(0.6), borderColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: hasDosha ? 1.5 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
        )
    }
}
