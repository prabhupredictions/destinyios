import SwiftUI

/// Premium Transit Influence Card matching Current Dasha style
/// Professional layout: Badge top right, Arrow bottom right, animated golden border
struct TransitInfluenceCard: View {
    let transit: TransitInfluence
    
    var body: some View {
        ZStack {
            // Main content
            VStack(alignment: .leading, spacing: 12) {
                // Header Row: Icon + Planet Name (Badge is in overlay at top right)
                HStack(spacing: 12) {
                    // Planet Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [planetGlowColor.opacity(0.4), planetGlowColor.opacity(0.1)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: planetSymbol)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, planetGlowColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    // Planet Transit Name
                    Text("\(localizedPlanet) Transit".localized)
                        .font(AppTheme.Fonts.premiumDisplay(size: 17))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                // Sign & House info
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.gold.opacity(0.8))
                    
                    Text("\(localizedSignName(for: transit.sign)) · \("house_label".localized) \(transit.house)")
                        .font(AppTheme.Fonts.body(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.goldLight)
                }
                
                // Description
                Text(transit.description)
                    .font(AppTheme.Fonts.body(size: 13))
                    .foregroundColor(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                
                // Spacer to push arrow to bottom
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            
            // Top Right: Badge Pill (overlay)
            VStack {
                HStack {
                    Spacer()
                    Text(transit.badge)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(badgeColor)
                        )
                }
                Spacer()
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
            
            // Bottom Right: Animated Arrow click indicator
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(1.0)
                }
            }
            .padding(.bottom, 12)
            .padding(.trailing, 12)
        }
        .frame(minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    AppTheme.Colors.gold.opacity(0.5),
                    lineWidth: 2
                )
        )
        .shadow(color: AppTheme.Colors.gold.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Computed Properties
    
    /// Localized planet name
    var localizedPlanet: String {
        switch transit.planet.lowercased() {
        case "sun": return "planet_sun".localized
        case "moon": return "planet_moon".localized
        case "mars": return "planet_mars".localized
        case "mercury": return "planet_mercury".localized
        case "jupiter": return "planet_jupiter".localized
        case "venus": return "planet_venus".localized
        case "saturn": return "planet_saturn".localized
        case "rahu": return "planet_rahu".localized
        case "ketu": return "planet_ketu".localized
        default: return transit.planet
        }
    }
    
    /// Localized sign name from abbreviation
    func localizedSignName(for sign: String) -> String {
        switch sign {
        case "Ar": return "sign_ar".localized
        case "Ta": return "sign_ta".localized
        case "Ge": return "sign_ge".localized
        case "Ca": return "sign_ca".localized
        case "Le": return "sign_le".localized
        case "Vi": return "sign_vi".localized
        case "Li": return "sign_li".localized
        case "Sc": return "sign_sc".localized
        case "Sg": return "sign_sg".localized
        case "Cp": return "sign_cp".localized
        case "Aq": return "sign_aq".localized
        case "Pi": return "sign_pi".localized
        default: return sign
        }
    }
    
    var planetSymbol: String {
        switch transit.planet.lowercased() {
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "mars": return "flame.fill"
        case "mercury": return "sparkle"
        case "jupiter": return "globe"
        case "venus": return "heart.fill"
        case "saturn": return "circle.hexagongrid.fill"
        case "rahu": return "arrow.up.circle.fill"
        case "ketu": return "arrow.down.circle.fill"
        default: return "star.fill"
        }
    }
    
    var planetGlowColor: Color {
        switch transit.planet.lowercased() {
        case "sun": return Color.orange
        case "moon": return Color.white
        case "mars": return Color.red
        case "mercury": return Color.green
        case "jupiter": return Color.yellow
        case "venus": return Color.pink
        case "saturn": return Color.blue
        case "rahu": return Color.purple
        case "ketu": return Color.gray
        default: return AppTheme.Colors.gold
        }
    }
    
    var badgeColor: Color {
        switch transit.badgeType.lowercased() {
        case "positive": return Color.green
        case "caution": return Color.orange
        case "warning": return Color.red
        case "neutral": return Color.gray
        default: return AppTheme.Colors.gold
        }
    }
    
    func fullSignName(for sign: String) -> String {
        let signMap: [String: String] = [
            "Ar": "Aries", "Ta": "Taurus", "Ge": "Gemini",
            "Ca": "Cancer", "Le": "Leo", "Vi": "Virgo",
            "Li": "Libra", "Sc": "Scorpio", "Sg": "Sagittarius",
            "Cp": "Capricorn", "Aq": "Aquarius", "Pi": "Pisces"
        ]
        return signMap[sign] ?? sign
    }
}

/// Compact Transit Orb (Divine Gold Edition)
struct TransitOrbView: View {
    let transit: TransitInfluence
    
    var body: some View {
        VStack(spacing: 4) { // Reduced spacing for tighter layout
            // Planet Orb with centered name badge (floating together)
            ZStack {
                // Planet Image Asset (Premium AI Generated)
                Image(planetImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                
                // Planet Name Badge (centered, floating with planet)
                Text(localizedPlanet)
                    .font(AppTheme.Fonts.caption(size: 9))
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.85))
                            .overlay(
                                Capsule()
                                    .strokeBorder(AppTheme.Colors.gold.opacity(0.4), lineWidth: 0.5)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Status-colored border circle (68x68 centered around 60x60 planet)
                Circle()
                    .stroke(borderColor.opacity(0.5), lineWidth: 2)
                    .frame(width: 68, height: 68)
            }
            .frame(width: 68, height: 68) // Container fits border without clipping
            // Static premium shadow
            .shadow(
                color: borderColor.opacity(0.25),
                radius: 5,
                x: 0,
                y: 3
            )
            
            // Sign (Full Name - Localized)
            Text(localizedSignName)
                .font(AppTheme.Fonts.caption(size: 10))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Arrow Click Indicator (static — pulse removed for battery optimization)
            Image(systemName: "arrow.forward.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.goldLight, AppTheme.Colors.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 80) // Slightly wider for elegance
    }
    
    // MARK: - Computed Properties
    
    var planetImageName: String {
        let name = transit.planet.lowercased().trimmingCharacters(in: .whitespaces)
        return "planet_\(name)"
    }
    
    // Border color based on transit status (green=positive, red=caution, yellow=neutral)
    var borderColor: Color {
        switch transit.badgeType.lowercased() {
        case "positive": return AppTheme.Colors.success // Green
        case "caution": return AppTheme.Colors.error    // Red
        case "warning": return AppTheme.Colors.error    // Red
        case "neutral": return AppTheme.Colors.warning   // Yellow/Orange
        default: return AppTheme.Colors.gold
        }
    }
    
    /// Localized sign name from abbreviation
    var localizedSignName: String {
        switch transit.sign {
        case "Ar": return "sign_ar".localized
        case "Ta": return "sign_ta".localized
        case "Ge": return "sign_ge".localized
        case "Ca": return "sign_ca".localized
        case "Le": return "sign_le".localized
        case "Vi": return "sign_vi".localized
        case "Li": return "sign_li".localized
        case "Sc": return "sign_sc".localized
        case "Sg": return "sign_sg".localized
        case "Cp": return "sign_cp".localized
        case "Aq": return "sign_aq".localized
        case "Pi": return "sign_pi".localized
        default: return transit.sign
        }
    }
    
    /// Localized planet name
    var localizedPlanet: String {
        switch transit.planet.lowercased() {
        case "sun": return "planet_sun".localized
        case "moon": return "planet_moon".localized
        case "mars": return "planet_mars".localized
        case "mercury": return "planet_mercury".localized
        case "jupiter": return "planet_jupiter".localized
        case "venus": return "planet_venus".localized
        case "saturn": return "planet_saturn".localized
        case "rahu": return "planet_rahu".localized
        case "ketu": return "planet_ketu".localized
        default: return transit.planet
        }
    }
    
    /// Convert abbreviated sign to full name (English - kept for backwards compatibility)
    var fullSignName: String {
        let signMap: [String: String] = [
            "Ar": "Aries", "Ta": "Taurus", "Ge": "Gemini",
            "Ca": "Cancer", "Le": "Leo", "Vi": "Virgo",
            "Li": "Libra", "Sc": "Scorpio", "Sg": "Sagittarius",
            "Cp": "Capricorn", "Aq": "Aquarius", "Pi": "Pisces"
        ]
        return signMap[transit.sign] ?? transit.sign
    }
}

/// Section displaying transit influences as horizontal scroll
struct TransitInfluencesSection: View {
    let transits: [TransitInfluence]
    var onTransitTapped: ((TransitInfluence) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header (no extra padding - parent handles it)
            Text("current_transits".localized)
                .font(AppTheme.Fonts.premiumDisplay(size: 18))
                .goldGradient()
            
            // Horizontal Scroll Orbs (needs negative margin to go edge-to-edge)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(transits) { transit in
                        Button(action: {
                            onTransitTapped?(transit)
                        }) {
                            TransitOrbView(transit: transit)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityIdentifier("transit_card_\(transit.planet.lowercased())")
                    }
                }
                .padding(.horizontal, 12) // Match parent edge
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -12) // Negative margin to extend to edges
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            TransitInfluencesSection(transits: [
                TransitInfluence(planet: "Saturn", sign: "Pisces", house: 10, description: "Saturn in 10th - Career responsibilities", badge: "Neutral", badgeType: "neutral"),
                TransitInfluence(planet: "Jupiter", sign: "Gemini", house: 1, description: "Jupiter blessing your Ascendant", badge: "Auspicious", badgeType: "positive"),
                TransitInfluence(planet: "Mars", sign: "Scorpio", house: 12, description: "Mars in 12th - Hidden conflicts may arise", badge: "Challenging", badgeType: "caution")
            ])
        }
    }
}
