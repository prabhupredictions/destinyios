import SwiftUI

/// Premium North Indian style Vedic chart view
/// Houses are fixed in position (diamond layout), signs rotate based on ascendant
/// PREMIUM VERSION: Transparent background, Gold gradients, Sharp lines
struct NorthIndianChartView: View {
    let chartData: ChartData
    let chartType: SouthIndianChartView.ChartType // Keeping type for compatibility, though this is North view
    let personName: String
    let ascendantSign: String?
    
    // Grid dimensions
    private let gridSize: CGFloat = 340 // Slightly larger for "fine grain" open look
    
    var body: some View {
        VStack(spacing: 12) {
            // Chart
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                
                ZStack {
                    // Chart grid - Premium Gold
                    NorthIndianGrid()
                    
                    // House contents - positioned to stay within boundaries
                    ForEach(1...12, id: \.self) { house in
                        houseContent(house: house, size: size)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(width: gridSize, height: gridSize)
            .shadow(color: AppTheme.Colors.gold.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(8)
    }
    
    // MARK: - House Centroid (Geometrically Correct)
    private func houseCentroid(for house: Int, in size: CGFloat) -> CGPoint {
        // North Indian Chart Geometry:
        // - Outer square: (0,0) to (1,1)
        // - Inner diamond vertices: T(0.5,0), R(1,0.5), B(0.5,1), L(0,0.5)
        // - Diagonals: TL(0,0)-BR(1,1) and TR(1,0)-BL(0,1) crossing at C(0.5,0.5)
        // - Intersection points (diagonal meets diamond edge):
        //   I_TL = (0.25, 0.25), I_TR = (0.75, 0.25)
        //   I_BL = (0.25, 0.75), I_BR = (0.75, 0.75)
        
        // Triangle centroids: avg of 3 vertices
        // Adding small inward margin (~0.03) to keep content safely inside
        
        let margin: CGFloat = 0.03
        
        let centroids: [Int: (x: CGFloat, y: CGFloat)] = [
            // Diamond houses (side triangles) - T, I_left, I_right
            1:  (0.50, 0.17 + margin),      // Top: T, I_TL, I_TR -> (0.5, 0.167)
            4:  (0.17 + margin, 0.50),      // Left: L, I_TL, I_BL -> (0.167, 0.5)
            7:  (0.50, 0.83 - margin),      // Bottom: B, I_BL, I_BR -> (0.5, 0.833)
            10: (0.83 - margin, 0.50),      // Right: R, I_TR, I_BR -> (0.833, 0.5)
            
            // Corner triangles - Corner, Side-midpoint, Intersection
            // Top-Left Corner
            2:  (0.25, 0.08 + margin),      // TL, T, I_TL -> (0.25, 0.083)
            3:  (0.08 + margin, 0.25),      // TL, L, I_TL -> (0.083, 0.25)
            
            // Bottom-Left Corner
            5:  (0.08 + margin, 0.75),      // BL, L, I_BL -> (0.083, 0.75)
            6:  (0.25, 0.92 - margin),      // BL, B, I_BL -> (0.25, 0.917)
            
            // Bottom-Right Corner
            8:  (0.75, 0.92 - margin),      // BR, B, I_BR -> (0.75, 0.917)
            9:  (0.92 - margin, 0.75),      // BR, R, I_BR -> (0.917, 0.75)
            
            // Top-Right Corner
            11: (0.92 - margin, 0.25),      // TR, R, I_TR -> (0.917, 0.25)
            12: (0.75, 0.08 + margin)       // TR, T, I_TR -> (0.75, 0.083)
        ]
        
        let pos = centroids[house] ?? (0.5, 0.5)
        return CGPoint(x: size * pos.x, y: size * pos.y)
    }
    
    @ViewBuilder
    private func houseContent(house: Int, size: CGFloat) -> some View {
        let center = houseCentroid(for: house, in: size)
        let planets = planetsInHouse(house)
        let signNum = signNumberForHouse(house)
        
        // Diamond houses are larger; corner triangles are much smaller
        let isDiamond = [1, 4, 7, 10].contains(house)
        
        // Content size proportional to house type
        let contentSize: CGFloat = isDiamond ? size * 0.22 : size * 0.15
        
        // Sign number offset - smaller for corner triangles
        let signOffset: CGFloat = isDiamond ? contentSize * 0.30 : contentSize * 0.25
        
        // Planet font size - slightly smaller for corners to fit
        let planetFont: CGFloat = isDiamond ? 10 : 9
        
        ZStack {
            // 1. Sign Number - Shiny Premium Gold Gradient
            Text("\(signNum)")
                .font(.system(size: isDiamond ? 12 : 10, weight: .bold))
                .foregroundStyle(AppTheme.Colors.premiumGradient)
                .offset(x: 0, y: -signOffset)
            
            // 2. Planets - Placed on fixed safe points
            if !planets.isEmpty {
                let radius = isDiamond ? contentSize * 0.35 : contentSize * 0.40
                let points = getPlanetOffsets(count: planets.count, isDiamond: isDiamond, radius: radius)
                
                ForEach(Array(planets.enumerated()), id: \.element) { index, planet in
                    if index < points.count {
                        let info = getPlanetInfo(planet)
                        let pt = points[index]
                        
                        Text(info?.code ?? String(planet.prefix(2)))
                            .font(.system(size: planetFont, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
                            .position(x: contentSize/2 + pt.x, y: contentSize/2 + pt.y)
                    }
                }
            }
        }
        .frame(width: contentSize, height: contentSize)
        .position(center)
    }
    
    // MARK: - Innovative Positioning System
    // Returns up to 8 safe points relative to center (0,0)
    private func getPlanetOffsets(count: Int, isDiamond: Bool, radius: CGFloat) -> [CGPoint] {
        // We define 8 "safe" slots.
        // Slots: 0: Center, 1-4: Inner Cross, 5-8: Outer Corners
        
        // Define standard layout patterns based on count
        // Using slight random-looking but deterministic offsets to look natural yet structured
        
        var points: [CGPoint] = []
        
        if count == 1 {
            points = [.zero]
        } else if count == 2 {
            // Side by side or Top/Bottom?
            // "Rahu Ke opposite" -> Center-ish is good.
            // Let's use left/right for 2
             points = [CGPoint(x: -radius * 0.5, y: 0), CGPoint(x: radius * 0.5, y: 0)]
        } else if count == 3 {
             // Triangle
             points = [
                CGPoint(x: 0, y: -radius * 0.5),
                CGPoint(x: -radius * 0.6, y: radius * 0.4),
                CGPoint(x: radius * 0.6, y: radius * 0.4)
             ]
        } else {
            // 4 to 8 planets: Use the 8-point grid
            // Inner ring (closer to center)
            let r1 = radius * 0.5
            let innerPoints = [
                CGPoint(x: -r1, y: -r1), CGPoint(x: r1, y: -r1),
                CGPoint(x: -r1, y: r1),  CGPoint(x: r1, y: r1)
            ]
            
            // Outer/Cardinal ring
            let r2 = radius * 0.9
            let outerPoints = [
                CGPoint(x: 0, y: -r2), // Top
                CGPoint(x: 0, y: r2),  // Bottom
                CGPoint(x: -r2, y: 0), // Left
                CGPoint(x: r2, y: 0)   // Right
            ]
            
            // Mix based on diamond vs corner
            if isDiamond {
                // Diamond houses are spacious in center
                points = innerPoints + outerPoints
            } else {
                // Triangle houses might be tighter at corners
                // Use a tighter clustering
                points = innerPoints + [
                    CGPoint(x: 0, y: -r2 * 0.8),
                    CGPoint(x: 0, y: r2 * 0.8),
                    CGPoint(x: -r2 * 0.6, y: 0),
                    CGPoint(x: r2 * 0.6, y: 0)
                ]
            }
            
            // Center slot if needed for odd numbers?
            // For max density, populate the list.
            // If count > 8, they might overlap, but max user requested is 8 points.
        }
        
        return points
    }
    
    // MARK: - Helpers
    private func signNumberForHouse(_ house: Int) -> Int {
        // North Indian: Houses fixed. 1st house is top diamond.
        // Sign Number shown in House 1 = Ascendant Sign Number.
        // Next house (top-left) = House 2. Sign = Asc + 1.
        
        guard let ascSign = ascendantSign,
              let ascNum = ChartConstants.signNumbers[ascSign] else { return house }
        
        // Calculate sign for 'house' based on 'ascNum' at house 1
        // House 1 has sign ascNum.
        // House 2 has sign ascNum + 1...
        // Formula: (ascNum + house - 1 - 1) % 12 + 1
        
        let signIndex = (ascNum + house - 2) % 12
        return signIndex + 1
    }
    
    private func planetsInHouse(_ house: Int) -> [String] {
        // D1 Map: Key=Planet, Value=Position(house,sign)
        // We need to find all planets where position.house == house
        let d1 = chartData.d1
        return d1.filter { $0.value.house == house }.map { $0.key }
    }
    
    private let planetShortCodes: [String: String] = [
        "Sun": "Su", "Moon": "Mo", "Mars": "Ma", "Mercury": "Me",
        "Jupiter": "Ju", "Venus": "Ve", "Saturn": "Sa", "Rahu": "Ra",
        "Ketu": "Ke", "Uranus": "Ur", "Neptune": "Ne", "Pluto": "Pl"
    ]
    
    private func getPlanetInfo(_ name: String) -> PlanetDisplayInfo? {
        // Construct standard info from D1 data
        guard let p = chartData.d1[name] else { return nil }
        return PlanetDisplayInfo(
            id: name,
            code: planetShortCodes[name] ?? String(name.prefix(2)),
            isRetrograde: p.retrograde ?? false,
            isVargottama: p.vargottama ?? false,
            isCombust: p.combust ?? false,
            nakshatra: p.nakshatra,
            pada: p.pada
        )
    }
}

struct NorthIndianGrid: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            
            // Premium Gold Gradient for lines (using AppTheme)
            let goldGradient = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [
                    AppTheme.Colors.gold,
                    AppTheme.Colors.gold.opacity(0.6),
                    AppTheme.Colors.gold
                ]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: w, y: h)
            )
            
            // Line options
            let thinStroke = StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round)
            let mediumStroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            
            // 1. Double Border Outer Square
            let outerRect = CGRect(x: 0, y: 0, width: w, height: h).insetBy(dx: 1, dy: 1)
            context.stroke(Path(outerRect), with: goldGradient, style: mediumStroke)
            
            // Inner border (double line effect)
            let innerRect = outerRect.insetBy(dx: 4, dy: 4)
            context.stroke(Path(innerRect), with: goldGradient, style: thinStroke)
            
            // 2. Diagonals (The "X")
            var diagonals = Path()
            diagonals.move(to: CGPoint(x: 0, y: 0))
            diagonals.addLine(to: CGPoint(x: w, y: h))
            diagonals.move(to: CGPoint(x: w, y: 0))
            diagonals.addLine(to: CGPoint(x: 0, y: h))
            context.stroke(diagonals, with: goldGradient, style: mediumStroke)
            
            // 3. Inner Diamond
            var diamond = Path()
            diamond.move(to: CGPoint(x: w/2, y: 0))
            diamond.addLine(to: CGPoint(x: w, y: h/2))
            diamond.addLine(to: CGPoint(x: w/2, y: h))
            diamond.addLine(to: CGPoint(x: 0, y: h/2))
            diamond.closeSubpath()
            context.stroke(diamond, with: goldGradient, style: mediumStroke)
            
        }
        // Shine/Glow effect on the whole grid
        .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 2, x: 0, y: 0)
    }
}

// MARK: - Planet Display Info (Shared)

struct PlanetDisplayInfo: Identifiable {
    let id: String
    let code: String
    let isRetrograde: Bool
    let isVargottama: Bool
    let isCombust: Bool
    let nakshatra: String?
    let pada: Int?
}

#Preview {
    ZStack {
        Color("NavyPrimary").ignoresSafeArea() // Preview background
        NorthIndianChartView(
            chartData: ChartData(
                d1: [
                    "Sun": D1PlanetPosition(house: 1, sign: "Ge", degree: 76.5, retrograde: false, vargottama: true, combust: false, nakshatra: "Ardra", pada: 3),
                    "Moon": D1PlanetPosition(house: 8, sign: "Cp", degree: 290.0, retrograde: false, vargottama: false, combust: false, nakshatra: "Shravana", pada: 1),
                    "Mars": D1PlanetPosition(house: 4, sign: "Vi", degree: 151.0, retrograde: true, vargottama: false, combust: false, nakshatra: nil, pada: nil)
                ],
                d9: [:]
            ),
            chartType: .d1,
            personName: "Test Chart",
            ascendantSign: "Ge"
        )
    }
}
