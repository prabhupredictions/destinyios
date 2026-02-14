import SwiftUI

struct OrbitAshtakootView: View {
    let kutas: [KutaDetail]
    let centerView: () -> AnyView // Closure to render the central gauge
    var boyName: String = "Boy"
    var girlName: String = "Girl"
    
    @State private var selectedKuta: AshtakootData?
    
    // Semantic Map (v5)
    private let semantics: [String: (label: String, icon: String)] = [
        "varna": ("Work", "briefcase.fill"),
        "vashya": ("Dominance", "bolt.heart.fill"),
        "tara": ("Destiny", "star.fill"),
        "yoni": ("Sex", "flame.fill"),
        "maitri": ("Friendship", "person.2.fill"),
        "gana": ("Temper", "theatermasks.fill"),
        "bhakoot": ("Love", "heart.circle.fill"),
        "nadi": ("Health", "waveform.path.ecg")
    ]
    
    // Convert dictionary to ordered array ensuring consistent position
    private var orbitItems: [AshtakootData] {
        let order = ["varna", "vashya", "tara", "yoni", "maitri", "gana", "bhakoot", "nadi"]
        
        return order.compactMap { key in
            guard let kuta = kutas.first(where: { $0.name.lowercased().prefix(key.count) == key }) else { return nil }
            let meta = semantics[key] ?? (kuta.name, "circle.fill")
            return AshtakootData(
                key: key,
                label: meta.label,
                icon: meta.icon,
                score: Double(kuta.points),
                maxScore: Double(kuta.maxPoints),
                description: kuta.description
            )
        }
    }
    
    // Geometry
    private let orbitRadius: CGFloat = 155
    private let bubbleSize: CGFloat = 64
    
    var body: some View {
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
                            
                            Text("\(format(kuta.score)) / \(format(kuta.maxScore))")
                                .font(AppTheme.Fonts.body(size: 14).bold())
                                .foregroundColor(kuta.statusColor)
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
                    
                    Divider().background(AppTheme.Colors.gold.opacity(0.3))
                    
                    // Description
                    if !kuta.description.isEmpty {
                        Text(replaceNames(in: kuta.description))
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
                .frame(width: 260)
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
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
        }
        .frame(height: (orbitRadius * 2) + bubbleSize + 20)
        .contentShape(Rectangle()) // Allow taps in empty space if needed, but bubble taps handle selection
        .onTapGesture {
            // Tap outside bubbles to dismiss
            if selectedKuta != nil {
                withAnimation { selectedKuta = nil }
            }
        }
    }
    
    private func format(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
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
    
    var body: some View {
        let orbSize: CGFloat = 64
        
        Button(action: action) {
            ZStack {
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
                            endRadius: orbSize * 0.9 // Larger glow when selected
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
                    
                    Text("\(format(item.score))/\(format(item.maxScore))")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.goldLight)
                    
                    Text(item.label)
                        .font(AppTheme.Fonts.caption(size: 8))
                        .foregroundColor(.white.opacity(0.9))
                        .textCase(.uppercase)
                        .padding(.top, 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(width: 64, height: 64)
            .scaleEffect(isSelected ? 1.1 : 1.0) // Pop effect
        }
    }
    
    private func format(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }
}
