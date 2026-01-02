import SwiftUI
import Combine

/// Premium "Midnight Gold" Home Screen
struct HomeView: View {
    // MARK: - Callbacks
    var onQuestionSelected: ((String) -> Void)? = nil
    var onChatHistorySelected: ((String) -> Void)? = nil
    var onMatchHistorySelected: ((CompatibilityHistoryItem) -> Void)? = nil
    
    // MARK: - State
    @State private var viewModel = HomeViewModel()
    @State private var showProfile = false
    @State private var contentOpacity: Double = 0
    
    // Menu Sheet States
    @State private var showHistorySheet = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. Theme Background
            AppTheme.Colors.mainBackground
                .ignoresSafeArea()
            
            // 2. Starfield/Nebula Overlay (Optional, simple gradient for now)
            AppTheme.Colors.backgroundGradient
                .ignoresSafeArea()
                .opacity(0.5)
            
            // 3. Main Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // A. Cosmic Header
                    headerSection
                        .padding(.top, 10)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(AppTheme.Colors.gold)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // B. Hero: Daily Insight
                        insightHeroSection
                        
                        // D. Cosmic Status Strip (Dasha + Transits) - Seamless Integration
                        cosmicStatusStrip
                            .padding(.bottom, -10) // Negative padding to pull next section closer (reduce gap)
                        
                        // E. Life Areas
                        lifeAreasGridSection
                            .padding(.horizontal, 0) // No extra padding here (using outer padding)
                            .padding(.bottom, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 10) // Reduced main padding to maximize width
            }
            .opacity(contentOpacity)
            .refreshable {
                await viewModel.loadHomeData()
            }
        }
        .task {
            await viewModel.loadHomeData()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                contentOpacity = 1.0
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showHistorySheet) {
            HistoryView(
                onChatSelected: onChatHistorySelected,
                onMatchSelected: onMatchHistorySelected
            )
        }
    }
    
    // MARK: - Components
    
    // A. Header
    private var headerSection: some View {
        HStack {
            // History Button (Left Side)
            Button(action: { showHistorySheet = true }) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.Colors.gold.opacity(0.5), lineWidth: 1)
                        .background(Circle().fill(AppTheme.Colors.secondaryBackground))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
            
            Spacer()
            
            // Logo / Brand (Centered)
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.gold)
                
                Text("Destiny")
                    .font(AppTheme.Fonts.display(size: 28))
                    .foregroundColor(AppTheme.Colors.gold)
            }
            
            Spacer()
            
            // Profile Button
            Button(action: { showProfile = true }) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.Colors.gold.opacity(0.5), lineWidth: 1)
                        .background(Circle().fill(AppTheme.Colors.secondaryBackground))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.gold)
                }
            }
        }
    }
    
    // B. Hero Section (Frosted Dark Glass)
    // B. Hero Section (3:1 Aspect Ratio)
    private var insightHeroSection: some View {
        PremiumCard(style: .hero) {
            VStack(alignment: .leading, spacing: 8) {
                // Header Row
                HStack(alignment: .top) {
                    Text("Today's Cosmic Vibe")
                        .font(.system(size: 18, weight: .medium, design: .serif)) // Compact
                        .foregroundColor(Color(hex: "E8D4A0"))
                        .tracking(0.3)
                    
                    Spacer(minLength: 50)
                }
                
                // Insight Text - more compact
                Text(viewModel.dailyInsight)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "D1D5DB"))
                    .lineSpacing(3)
                    .lineLimit(3) // Limit lines for compact layout
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4) // Reduce internal padding
        }
        .aspectRatio(2.5, contentMode: .fit) // 2.5:1 width:height ratio (Taller)
        .overlay(alignment: .topTrailing) {
            // Moon Sign Badge - Proportional to 2.5:1 Card
            if !viewModel.moonSign.isEmpty {
                VStack(spacing: 1) {
                    // Zodiac Symbol: 18px (Slightly larger)
                    Text(zodiacSymbol(for: viewModel.moonSign))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "1A1E3C"))
                    
                    // "Moon in": 9px
                    Text("Moon in")
                        .font(.system(size: 9, weight: .light))
                        .foregroundColor(Color(hex: "1A1E3C"))
                    
                    // Sign name: 10px
                    Text(fullZodiacName(for: viewModel.moonSign))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1E3C"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: 68, height: 68) // Increased to 68px for taller card
                .background(
                    // 3D Metallic Radial Gradient
                    ZStack {
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(hex: "FFFDE7"), location: 0.0),
                                .init(color: Color(hex: "F5D580"), location: 0.3),
                                .init(color: Color(hex: "D4AF37"), location: 0.6),
                                .init(color: Color(hex: "B8962C"), location: 0.85),
                                .init(color: Color(hex: "8B7226"), location: 1.0)
                            ]),
                            center: .center,
                            startRadius: 3,
                            endRadius: 35
                        )
                        
                        // Specular Highlight
                        RadialGradient(
                            colors: [Color.white.opacity(0.5), Color.clear],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: 25
                        )
                    }
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: Color(hex: "D4AF37").opacity(0.5), radius: 10, x: 0, y: 3)
                .offset(x: 8, y: -8) // Adjusted for smaller badge
                .zIndex(100)
            }
        }
    }
    
    // Helper to get zodiac symbol and full name
    private func zodiacSymbol(for sign: String) -> String {
        // Handle short codes and full names
        let map: [String: String] = [
            "Ar": "♈\u{FE0E}", "Aries": "♈\u{FE0E}",
            "Ta": "♉\u{FE0E}", "Taurus": "♉\u{FE0E}",
            "Ge": "♊\u{FE0E}", "Gemini": "♊\u{FE0E}",
            "Cn": "♋\u{FE0E}", "Cancer": "♋\u{FE0E}", "Ca": "♋\u{FE0E}",
            "Le": "♌\u{FE0E}", "Leo": "♌\u{FE0E}",
            "Vi": "♍\u{FE0E}", "Virgo": "♍\u{FE0E}",
            "Li": "♎\u{FE0E}", "Libra": "♎\u{FE0E}",
            "Sc": "♏\u{FE0E}", "Scorpio": "♏\u{FE0E}",
            "Sg": "♐\u{FE0E}", "Sagittarius": "♐\u{FE0E}", "Sag": "♐\u{FE0E}",
            "Cp": "♑\u{FE0E}", "Capricorn": "♑\u{FE0E}", "Cap": "♑\u{FE0E}",
            "Aq": "♒\u{FE0E}", "Aquarius": "♒\u{FE0E}",
            "Pi": "♓\u{FE0E}", "Pisces": "♓\u{FE0E}"
        ]
        return map[sign] ?? map[sign.prefix(2).capitalized] ?? "☽"
    }
    
    // Helper for full name display
    private func fullZodiacName(for sign: String) -> String {
        let map: [String: String] = [
            "Ar": "Aries",      "Aries": "Aries",
            "Ta": "Taurus",     "Taurus": "Taurus",
            "Ge": "Gemini",     "Gemini": "Gemini",
            "Cn": "Cancer",     "Cancer": "Cancer",
            "Le": "Leo",        "Leo": "Leo",
            "Vi": "Virgo",      "Virgo": "Virgo",
            "Li": "Libra",      "Libra": "Libra",
            "Sc": "Scorpio",    "Scorpio": "Scorpio",
            "Sag": "Sagittarius", "Sagittarius": "Sagittarius", "Sg": "Sagittarius",
            "Cp": "Capricorn",  "Capricorn": "Capricorn", "Cap": "Capricorn",
            "Aq": "Aquarius",   "Aquarius": "Aquarius",
            "Pi": "Pisces",     "Pisces": "Pisces"
        ]
        return map[sign] ?? map[sign.prefix(2).capitalized] ?? sign
    }
    
    // C. Cosmic Status Strip (Dasha + Transits combined)
    private var cosmicStatusStrip: some View {
        let transits = viewModel.currentTransits.map { transit in
            (planet: transit.planet, sign: transit.sign)
        }
        return CosmicStatusStrip(
            currentDasha: viewModel.currentDasha,
            transits: transits.isEmpty ? [
                ("Sun", "Leo"), ("Moon", "Capricorn"), ("Mars", "Scorpio")
            ] : transits
        )
    }
    
    // Old Dasha Status (kept for reference, no longer used)
    private var dashaStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Current Dasha")
                    .font(AppTheme.Fonts.title(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Spacer()
            }
            
            HStack {
                Image(systemName: "hourglass")
                    .foregroundColor(AppTheme.Colors.gold)
                    .font(.system(size: 14))
                
                Text(viewModel.currentDasha)
                    .font(AppTheme.Fonts.title(size: 16))
                    .foregroundColor(AppTheme.Colors.goldLight)
                    .monospacedDigit()
                
                Spacer()
                
                // Active Pulse Dot
                Circle()
                    .fill(AppTheme.Colors.success)
                    .frame(width: 8, height: 8)
                    .shadow(color: AppTheme.Colors.success.opacity(0.5), radius: 4)
            }
            .padding(16)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.Colors.gold.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    // D. Ask Destiny
    private var askDestinySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask Destiny")
                .font(AppTheme.Fonts.display(size: 20))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                    Button(action: { onQuestionSelected?(question) }) {
                        HStack {
                            Text(question)
                                .font(AppTheme.Fonts.body(size: 15))
                                .foregroundColor(AppTheme.Colors.textPrimary.opacity(0.9))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.gold.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 1)
                                .background(AppTheme.Colors.secondaryBackground.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // E. Life Areas Grid
    private var lifeAreasGridSection: some View {
        VStack(spacing: 16) {
            // Header (Centered, No Sparkle)
            Text("What the stars suggest")
                .font(AppTheme.Fonts.display(size: 22))
                .foregroundColor(AppTheme.Colors.gold)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
            
            // 3-Column Grid
            let columns = [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ]
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(viewModel.lifeAreas.keys.sorted()), id: \.self) { key in
                    if let status = viewModel.lifeAreas[key] {
                        LifeAreaGridItem(area: key, status: status) { question in
                            onQuestionSelected?(question)
                        }
                    }
                }
            }
        }
    }
    
    // F. Transit Scroller (Premium)
    private var transitScroller: some View {
        VStack(alignment: .leading, spacing: 10) {
            TransitsCarousel()
        }
    }
}

// MARK: - Subviews

struct LifeAreaGridItem: View {
    let area: String
    let status: LifeAreaStatus
    let onQuestionSelected: (String) -> Void
    
    var body: some View {
        Button(action: {
            // Generate contextual question based on area and insight
            let question = "As per today's analysis of \(area.lowercased()) related matters, \"\(status.brief)\". Could you elaborate more on this?"
            onQuestionSelected(question)
        }) {
            VStack(alignment: .leading, spacing: 4) { // Tighter vertical spacing
                // Header: Icon + Title + Status
                HStack(spacing: 4) {
                    // Icon Circle (Soft Golden Background)
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.gold.opacity(0.15)) // Soft gold bg
                            .frame(width: 20, height: 20) // Reduced from default
                        
                        Image(systemName: iconName)
                            .font(.system(size: 10)) // Reduced icon size
                            .foregroundColor(AppTheme.Colors.gold)
                    }
                    
                    // Title
                    Text(area.localized)
                        .font(AppTheme.Fonts.title(size: 11))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                
                Spacer()
            }
            
            // Content: Insight
            Text(status.brief)
                .font(AppTheme.Fonts.body(size: 9)) // Reduced to 9
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 0)
            
            // Footer: Status (Left) + Arrow (Right)
            HStack {
                // Status Badge at Bottom Left
                HStack(spacing: 2) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 4, height: 4)
                    Text(status.status)
                        .font(.system(size: 8, weight: .medium)) // Reduced to 8
                        .foregroundColor(statusColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Arrow at Bottom Right
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14)) // Reduced to 14
                    .foregroundColor(AppTheme.Colors.gold.opacity(0.8))
            }
        }
        .padding(8) // Reduced internal padding
        .frame(height: 116) // Squared height (approx width on standard phone)

            .background(
                ZStack {
                    // Card Background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.Colors.cardBackground)
                    
                    // Shiny Radial Gradient Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.Colors.gold.opacity(0.6),
                                    AppTheme.Colors.gold.opacity(0.1)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 200
                            ),
                            lineWidth: 1.5
                        )
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    var iconName: String {
        switch area.lowercased() {
        case "career": return "briefcase.fill"
        case "relationship": return "heart.fill"
        case "finance": return "banknote.fill"
        case "health": return "heart.text.square.fill"
        case "family": return "house.fill"
        case "education": return "book.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        default: return "star.fill"
        }
    }
    
    var statusColor: Color {
        switch status.status.lowercased() {
        case "good", "excellent": return AppTheme.Colors.success
        case "steady", "neutral": return AppTheme.Colors.warning
        case "caution", "difficult", "challenging": return AppTheme.Colors.error
        default: return AppTheme.Colors.textSecondary
        }
    }
}



#Preview {
    HomeView()
}
