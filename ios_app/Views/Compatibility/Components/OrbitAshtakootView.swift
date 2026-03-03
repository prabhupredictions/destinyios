import SwiftUI

struct OrbitAshtakootView: View {
    let kutas: [KutaDetail]
    let centerView: () -> AnyView // Closure to render the central gauge
    var boyName: String = "Boy"
    var girlName: String = "Girl"
    var doshaSummary: DoshaSummary? = nil  // V2.1: Cancellation data
    
    @State private var selectedKuta: AshtakootData?
    @State private var hintVisible: Bool = true
    
    // Semantic Map (v5)
    private let semantics: [String: (label: String, icon: String)] = [
        "varna": ("Work", "briefcase.fill"),
        "vashya": ("Dominance", "bolt.heart.fill"),
        "tara": ("Destiny", "star.fill"),
        "yoni": ("Intimacy", "flame.fill"),
        "maitri": ("Friendship", "person.2.fill"),
        "gana": ("Temperament", "theatermasks.fill"),
        "bhakoot": ("Love", "heart.circle.fill"),
        "nadi": ("Health", "waveform.path.ecg")
    ]
    
    // Convert dictionary to ordered array, enriched with cancellation data
    private var orbitItems: [AshtakootData] {
        let order = ["varna", "vashya", "tara", "yoni", "maitri", "gana", "bhakoot", "nadi"]
        
        return order.compactMap { key in
            guard let kuta = kutas.first(where: { $0.name.lowercased().prefix(key.count) == key }) else { return nil }
            let meta = semantics[key] ?? (kuta.name, "circle.fill")
            
            // Enrich with cancellation data from DoshaSummary
            let detail = doshaSummary?.details?[key]
            let doshaPresent = detail?.present ?? false
            let doshaCancelled = detail?.cancelled ?? false
            let reason = detail?.reasonShort
            
            // Adjusted score: if cancelled → max points restored, if active dosha → stays 0
            let adjustedScore: Double? = doshaPresent
                ? (doshaCancelled ? Double(kuta.maxPoints) : 0)
                : nil
            
            return AshtakootData(
                key: key,
                label: meta.label,
                icon: meta.icon,
                score: Double(kuta.points),
                maxScore: Double(kuta.maxPoints),
                description: kuta.description,
                doshaPresent: doshaPresent,
                doshaCancelled: doshaCancelled,
                cancellationReason: reason,
                adjustedScore: adjustedScore
            )
        }
    }
    
    /// Whether any dosha data exists to show indicators
    private var hasDoshaData: Bool {
        orbitItems.contains { $0.doshaPresent }
    }
    
    // Geometry
    private let orbitRadius: CGFloat = 155
    private let bubbleSize: CGFloat = 64
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 1. Orbital Rings (Decoration)
                Circle()
                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                
                Circle()
                    .stroke(AppTheme.Colors.gold.opacity(0.05), lineWidth: 40)
                    .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                
                // 2. Center Sun (The Gauge)
                centerView()
                    .frame(width: 180, height: 180)
                    .opacity(selectedKuta == nil ? 1 : 0.3) // Dim when tooltip active
                    .animation(.easeInOut, value: selectedKuta != nil)
                
                // 3. Planet Bubbles
                ForEach(Array(orbitItems.enumerated()), id: \.element.key) { index, item in
                    let angleDeg = Double(index) * (360.0 / 8.0) - 90.0 // Start from Top (-90)
                    let angleRad = CGFloat(angleDeg) * .pi / 180.0
                    
                    PlanetBubble(item: item, isSelected: selectedKuta?.key == item.key) {
                        // Tap handler
                        HapticManager.shared.play(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedKuta?.key == item.key {
                                selectedKuta = nil
                            } else {
                                selectedKuta = item
                                hintVisible = false // Hide hint once user taps
                            }
                        }
                    }
                    .offset(
                        x: orbitRadius * cos(angleRad),
                        y: orbitRadius * sin(angleRad)
                    )
                }
                
                // 4. Premium Tooltip Overlay (Center)
                if let kuta = selectedKuta {
                    kutaTooltipView(kuta: kuta)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .frame(height: (orbitRadius * 2) + bubbleSize + 20)
            .contentShape(Rectangle())
            .onTapGesture {
                // Tap outside bubbles to dismiss
                if selectedKuta != nil {
                    withAnimation { selectedKuta = nil }
                }
            }
            
        }
    }
    
    // MARK: - Tooltip View
    @ViewBuilder
    private func kutaTooltipView(kuta: AshtakootData) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: kuta.icon)
                    .font(.system(size: 24))
                    .foregroundColor(kuta.statusColor)
                    .shadow(color: kuta.statusColor.opacity(0.6), radius: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(kuta.label)
                        .font(AppTheme.Fonts.title(size: 18))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    // Score line — show original + adjusted if different
                    if kuta.doshaPresent, let adj = kuta.adjustedScore, Int(adj) != Int(kuta.score) {
                        HStack(spacing: 6) {
                            Text("\(format(kuta.score))")
                                .strikethrough(true, color: AppTheme.Colors.textTertiary)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.Colors.gold.opacity(0.6))
                            Text("\(format(adj)) / \(format(kuta.maxScore))")
                                .foregroundColor(kuta.statusColor)
                                .bold()
                        }
                        .font(AppTheme.Fonts.body(size: 14))
                    } else {
                        Text("\(format(kuta.score)) / \(format(kuta.maxScore))")
                            .font(AppTheme.Fonts.body(size: 14).bold())
                            .foregroundColor(kuta.statusColor)
                    }
                }
                
                Spacer()
                
                // Close Button
                Button(action: {
                    withAnimation { selectedKuta = nil }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .font(.system(size: 22))
                }
            }
            
            // Cancellation Badge (if dosha present)
            if kuta.doshaPresent {
                HStack(spacing: 8) {
                    Image(systemName: kuta.doshaCancelled ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(kuta.doshaCancelled ? AppTheme.Colors.success : AppTheme.Colors.error)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kuta.doshaCancelled ? "Dosha Cancelled" : "Active Dosha")
                            .font(AppTheme.Fonts.caption(size: 12).weight(.semibold))
                            .foregroundColor(kuta.doshaCancelled ? AppTheme.Colors.success : AppTheme.Colors.error)
                        
                        if let reason = kuta.cancellationReason, !reason.isEmpty {
                            Text(replaceNames(in: reason))
                                .font(AppTheme.Fonts.caption(size: 11))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            kuta.doshaCancelled
                                ? AppTheme.Colors.success.opacity(0.1)
                                : AppTheme.Colors.error.opacity(0.1)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            kuta.doshaCancelled
                                ? AppTheme.Colors.success.opacity(0.3)
                                : AppTheme.Colors.error.opacity(0.3),
                            lineWidth: 1
                        )
                )
            }
            
            Divider().background(AppTheme.Colors.gold.opacity(0.3))
            
            // Description
            if !kuta.description.isEmpty {
                Text(replaceNames(in: enhanceDescription(kuta.description, for: kuta.key)))
                    .font(AppTheme.Fonts.body(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Description not available")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .italic()
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(16)
        .frame(width: 270)
        .background(
            ZStack {
                AppTheme.Colors.mainBackground
                
                // Subtle cosmic glow
                RadialGradient(
                    colors: [
                        AppTheme.Colors.gold.opacity(0.1),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 150
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.gold.opacity(0.6),
                            AppTheme.Colors.gold.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: AppTheme.Colors.gold.opacity(0.25), radius: 15, x: 0, y: 8)
    }
    
    private func format(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }
    
    /// Enhance description with astrological context and score-based interpretation
    private func enhanceDescription(_ desc: String, for key: String) -> String {
        // Find the matching kuta to get score information
        guard let kuta = orbitItems.first(where: { $0.key == key }) else {
            return desc
        }
        
        let statusColor = kuta.statusColor
        
        // Determine compatibility level based on score
        let compatibilityLevel: String
        if kuta.doshaPresent && kuta.doshaCancelled {
            compatibilityLevel = "dosha was found but has been cancelled by astrological exceptions"
        } else if kuta.doshaPresent && !kuta.doshaCancelled {
            compatibilityLevel = "active dosha that requires attention and remedial measures"
        } else if statusColor == .green {
            compatibilityLevel = "excellent compatibility"
        } else if statusColor == .yellow {
            compatibilityLevel = "moderate compatibility"
        } else {
            compatibilityLevel = "challenging area that requires understanding and effort"
        }
        
        // Clean up API description if present
        let cleanedDesc = desc
            .replacingOccurrences(
                of: "(\\w+) lord: (\\w+)",
                with: "$1's ruling planet $2",
                options: .regularExpression
            )
            .trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        
        // Build comprehensive description based on kuta type
        var result = ""
        
        switch key {
        case "varna":
            result = "Work compatibility is determined using Varna Ashtakoot property which focuses on the Varna categories of both partners (Brahmin, Kshatriya, Vaishya, Shudra);"
            if !cleanedDesc.isEmpty {
                result += " \(cleanedDesc)"
            }
        case "vashya":
            result = "Dominance compatibility is determined using Vashya Ashtakoot property which focuses on the Vashya groups of both partners (Manava, Vanachara, Keeta...);"
            if !cleanedDesc.isEmpty {
                result += " \(cleanedDesc)"
            }
        case "tara":
            result = "Destiny alignment is determined using Tara Ashtakoot property which focuses on the birth stars (Nakshatras) and Tara groups of both partners (Janma, Sampat, Vipat...);"
            if !cleanedDesc.isEmpty {
                result += " \(cleanedDesc)"
            }
        case "yoni":
            result = "Physical and intimate compatibility is determined using Yoni Ashtakoot property which focuses on the animal symbols (Yoni types) of both partners (Aswa, Vanara, Sarpa...);"
            if !cleanedDesc.isEmpty {
                result += " \(cleanedDesc)"
            }
        case "maitri":
            result = "Friendship and mental compatibility is determined using Maitri Ashtakoot property which focuses on the ruling sign lords (Moon sign lords) of both partners;"
            if !cleanedDesc.isEmpty {
                result += " \(cleanedDesc)"
            }
        case "gana":
            result = "Temperament compatibility is determined using Gana Ashtakoot property which focuses on the temperament categories (Deva, Manushya, Rakshasa) of both partners;"
            if !cleanedDesc.isEmpty {
                result += " \(cleanedDesc)"
            }
        case "bhakoot":
            result = "Emotional bonding and love compatibility is determined using Bhakoot Ashtakoot property which focuses on the Moon sign positions (Rashis) of both partners;"
            if !cleanedDesc.isEmpty {
                result += " \(cleanedDesc)"
            }
        case "nadi":
            result = "Health and genetic compatibility is determined using Nadi Ashtakoot property which focuses on the Nadi types (Aadi, Madhya, Antya) of both partners;"
            if !cleanedDesc.isEmpty {
                result += " \(cleanedDesc)"
            }
        default:
            result = desc
        }
        
        // Add score-based interpretation
        if kuta.doshaPresent && kuta.doshaCancelled, let adj = kuta.adjustedScore {
            let reasonText = kuta.cancellationReason ?? "astrological exceptions"
            result += " — Since the dosha was cancelled due to \(reasonText), the score has been adjusted from \(Int(kuta.score))/\(Int(kuta.maxScore)) to \(Int(adj))/\(Int(kuta.maxScore))."
        } else if kuta.doshaPresent && !kuta.doshaCancelled {
            result += " — Score: \(Int(kuta.score))/\(Int(kuta.maxScore)) — This is an active dosha that requires attention and remedial measures."
        } else {
            result += " — Score: \(Int(kuta.score))/\(Int(kuta.maxScore)) — This indicates \(compatibilityLevel)."
        }
        
        return result
    }
    
    /// Replace generic "Boy"/"Girl" with actual partner names
    private func replaceNames(in text: String) -> String {
        text
            .replacingOccurrences(of: "Boy:", with: "\(boyName):")
            .replacingOccurrences(of: "Girl:", with: "\(girlName):")
            .replacingOccurrences(of: "Boy's", with: "\(boyName)'s")
            .replacingOccurrences(of: "Girl's", with: "\(girlName)'s")
            .replacingOccurrences(of: "Boy ", with: "\(boyName) ")
            .replacingOccurrences(of: "Girl ", with: "\(girlName) ")
    }
}

struct PlanetBubble: View {
    let item: AshtakootData
    let isSelected: Bool
    let action: () -> Void
    
    @State private var pulsePhase: Bool = false
    
    var body: some View {
        let orbSize: CGFloat = 64
        
        Button(action: action) {
            ZStack {
                // 0. Outer ring (double circle effect for all orbs)
                Circle()
                    .stroke(
                        item.doshaPresent
                            ? (item.doshaCancelled
                                ? AppTheme.Colors.success.opacity(pulsePhase ? 0.5 : 0.15)
                                : AppTheme.Colors.error.opacity(pulsePhase ? 0.6 : 0.15))
                            : item.statusColor.opacity(pulsePhase ? 0.5 : 0.15),
                        lineWidth: 2
                    )
                    .frame(width: orbSize + 8, height: orbSize + 8)
                    .scaleEffect(pulsePhase ? 1.15 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulsePhase
                    )
                
                // 1. Status Glow Aura
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                item.statusColor.opacity(isSelected ? 0.8 : 0.5),
                                item.statusColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: orbSize * 0.3,
                            endRadius: orbSize * 0.9
                        )
                    )
                    .frame(width: orbSize * 1.5, height: orbSize * 1.5)
                    .blur(radius: 12)
                
                // 2. Glass Sphere Base
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.18, green: 0.2, blue: 0.26),
                                Color(red: 0.12, green: 0.14, blue: 0.18),
                                Color(red: 0.08, green: 0.1, blue: 0.14).opacity(0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: orbSize * 0.52
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                
                // 3. Inner Glass Bubble
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear,
                                Color.black.opacity(0.2)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: orbSize * 0.45
                        )
                    )
                    .frame(width: orbSize * 0.85, height: orbSize * 0.85)
                
                // 4. Highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.25, y: 0.25),
                            startRadius: 0,
                            endRadius: orbSize * 0.3
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                
                // 5. Gold Ring (Brighter if selected)
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.gold.opacity(isSelected ? 1.0 : 0.6),
                                AppTheme.Colors.gold.opacity(isSelected ? 0.6 : 0.3),
                                AppTheme.Colors.gold.opacity(isSelected ? 0.9 : 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1.5
                    )
                    .frame(width: orbSize, height: orbSize)
                
                // 6. Content
                VStack(spacing: 0) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16))
                        .foregroundColor(item.statusColor)
                        .padding(.bottom, 2)
                        .shadow(color: item.statusColor.opacity(0.5), radius: 4)
                    
                    let displayScore = (item.doshaPresent && item.doshaCancelled && item.adjustedScore != nil) ? item.adjustedScore! : item.score
                    Text("\(format(displayScore))/\(format(item.maxScore))")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(item.doshaCancelled ? AppTheme.Colors.success : AppTheme.Colors.goldLight)
                    
                    Text(item.label)
                        .font(AppTheme.Fonts.caption(size: 8))
                        .foregroundColor(.white.opacity(0.9))
                        .textCase(.uppercase)
                        .padding(.top, 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // 7. Dosha indicator badge (top-right corner)
                if item.doshaPresent {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: item.doshaCancelled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(item.doshaCancelled ? AppTheme.Colors.success : AppTheme.Colors.error)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.mainBackground)
                                        .frame(width: 16, height: 16)
                                )
                                .shadow(color: (item.doshaCancelled ? AppTheme.Colors.success : AppTheme.Colors.error).opacity(0.5), radius: 3)
                        }
                        Spacer()
                    }
                    .frame(width: orbSize, height: orbSize)
                }
            }
            .frame(width: 64, height: 64)
            .scaleEffect(isSelected ? 1.1 : 1.0) // Pop effect
        }
        .onAppear {
            pulsePhase = true
        }
    }
    
    private func format(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }
}
