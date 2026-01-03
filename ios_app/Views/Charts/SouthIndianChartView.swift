import SwiftUI

/// Premium South Indian style Vedic chart view
/// Signs are fixed in position, planets are placed in their sign boxes
/// PREMIUM VERSION: Gold gradients, Transparent background
struct SouthIndianChartView: View {
    let chartData: ChartData
    let chartType: ChartType
    let personName: String
    let ascendantSign: String?
    
    enum ChartType {
        case d1, d9
    }
    
    // Grid dimensions
    private let gridSize: CGFloat = 340
    private var cellSize: CGFloat { gridSize / 4 }
    
    var body: some View {
        VStack(spacing: 8) {
            // Chart grid
            ZStack {
                // Premium Gold Grid (correct South Indian format)
                SouthIndianGrid()
                
                // Chart content (signs + planets)
                chartContent
            }
            .frame(width: gridSize, height: gridSize)
            .shadow(color: AppTheme.Colors.gold.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(8)
    }
    
    // MARK: - Chart Content
    
    private var chartContent: some View {
        GeometryReader { geometry in
            let cell = geometry.size.width / 4
            
            ForEach(0..<4, id: \.self) { row in
                ForEach(0..<4, id: \.self) { col in
                    if let sign = signAt(row: row, col: col) {
                        cellView(sign: sign, cell: cell)
                            .position(
                                x: cell * CGFloat(col) + cell / 2,
                                y: cell * CGFloat(row) + cell / 2
                            )
                    }
                }
            }
        }
    }
    
    private func signAt(row: Int, col: Int) -> String? {
        // Center 2x2 is empty
        if (row == 1 || row == 2) && (col == 1 || col == 2) { return nil }
        return ChartConstants.southIndianLayout[row][col]
    }
    
    private func cellView(sign: String, cell: CGFloat) -> some View {
        let planets = planetsInSign(sign)
        let isAscendant = sign == ascendantSign
        
        return VStack(spacing: 4) {
            // Sign abbreviation - Premium Gold Gradient for Ascendant
            Text(sign)
                .font(.system(size: 11, weight: isAscendant ? .bold : .semibold))
                .foregroundStyle(
                    isAscendant ?
                    AnyShapeStyle(AppTheme.Colors.premiumGradient) :
                    AnyShapeStyle(LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                )
            
            // Planets - White text, consistent font
            if !planets.isEmpty {
                planetRow(planets: planets, cell: cell)
            }
        }
        .frame(width: cell - 6, height: cell - 6)
    }
    
    @ViewBuilder
    private func planetRow(planets: [String], cell: CGFloat) -> some View {
        let fontSize: CGFloat = 10
        
        if planets.count <= 3 {
            HStack(spacing: 4) {
                ForEach(planets, id: \.self) { code in
                    Text(code)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }
        } else {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    ForEach(planets.prefix(3), id: \.self) { code in
                        Text(code)
                            .font(.system(size: fontSize - 1, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                HStack(spacing: 4) {
                    ForEach(planets.dropFirst(3), id: \.self) { code in
                        Text(code)
                            .font(.system(size: fontSize - 1, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private func planetsInSign(_ sign: String) -> [String] {
        switch chartType {
        case .d1:
            return chartData.d1.compactMap { (name, pos) in
                pos.sign == sign ? ChartConstants.planetShortCodes[name] ?? String(name.prefix(2)) : nil
            }
        case .d9:
            return chartData.d9.compactMap { (name, pos) in
                pos.sign == sign ? ChartConstants.planetShortCodes[name] ?? String(name.prefix(2)) : nil
            }
        }
    }
}

// MARK: - Premium South Indian Grid (Correct Format)

struct SouthIndianGrid: View {
    var body: some View {
        Canvas { context, size in
            let cell = size.width / 4
            let w = size.width
            let h = size.height
            
            // Premium Gold Gradient (using AppTheme)
            let goldGradient = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [
                    AppTheme.Colors.gold,
                    AppTheme.Colors.gold.opacity(0.6),
                    AppTheme.Colors.gold
                ]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: w, y: h)
            )
            
            let thinStroke = StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round)
            let mediumStroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            
            // 1. Outer Border - Double line effect
            let outerRect = CGRect(x: 1, y: 1, width: w - 2, height: h - 2)
            context.stroke(Path(outerRect), with: goldGradient, style: mediumStroke)
            
            let innerRect = outerRect.insetBy(dx: 4, dy: 4)
            context.stroke(Path(innerRect), with: goldGradient, style: thinStroke)
            
            // 2. Horizontal Lines - ONLY outside center 2x2
            // Top horizontal line (y = cell)
            var topLine = Path()
            topLine.move(to: CGPoint(x: 0, y: cell))
            topLine.addLine(to: CGPoint(x: w, y: cell))
            context.stroke(topLine, with: goldGradient, style: thinStroke)
            
            // Bottom horizontal line (y = cell * 3)
            var bottomLine = Path()
            bottomLine.move(to: CGPoint(x: 0, y: cell * 3))
            bottomLine.addLine(to: CGPoint(x: w, y: cell * 3))
            context.stroke(bottomLine, with: goldGradient, style: thinStroke)
            
            // Middle horizontal lines (y = cell * 2) - only left and right parts
            var midHorizLeft = Path()
            midHorizLeft.move(to: CGPoint(x: 0, y: cell * 2))
            midHorizLeft.addLine(to: CGPoint(x: cell, y: cell * 2))
            context.stroke(midHorizLeft, with: goldGradient, style: thinStroke)
            
            var midHorizRight = Path()
            midHorizRight.move(to: CGPoint(x: cell * 3, y: cell * 2))
            midHorizRight.addLine(to: CGPoint(x: w, y: cell * 2))
            context.stroke(midHorizRight, with: goldGradient, style: thinStroke)
            
            // 3. Vertical Lines - ONLY outside center 2x2
            // Left vertical line (x = cell)
            var leftLine = Path()
            leftLine.move(to: CGPoint(x: cell, y: 0))
            leftLine.addLine(to: CGPoint(x: cell, y: h))
            context.stroke(leftLine, with: goldGradient, style: thinStroke)
            
            // Right vertical line (x = cell * 3)
            var rightLine = Path()
            rightLine.move(to: CGPoint(x: cell * 3, y: 0))
            rightLine.addLine(to: CGPoint(x: cell * 3, y: h))
            context.stroke(rightLine, with: goldGradient, style: thinStroke)
            
            // Middle vertical lines (x = cell * 2) - only top and bottom parts
            var midVertTop = Path()
            midVertTop.move(to: CGPoint(x: cell * 2, y: 0))
            midVertTop.addLine(to: CGPoint(x: cell * 2, y: cell))
            context.stroke(midVertTop, with: goldGradient, style: thinStroke)
            
            var midVertBottom = Path()
            midVertBottom.move(to: CGPoint(x: cell * 2, y: cell * 3))
            midVertBottom.addLine(to: CGPoint(x: cell * 2, y: h))
            context.stroke(midVertBottom, with: goldGradient, style: thinStroke)
            
            // 4. Center square border (outer edge of the empty center 2x2)
            let centerRect = CGRect(x: cell, y: cell, width: cell * 2, height: cell * 2)
            context.stroke(Path(centerRect), with: goldGradient, style: mediumStroke)
        }
        // Subtle glow
        .shadow(color: AppTheme.Colors.gold.opacity(0.2), radius: 2, x: 0, y: 0)
    }
}

#Preview {
    ZStack {
        Color(red: 0.08, green: 0.10, blue: 0.20).ignoresSafeArea()
        SouthIndianChartView(
            chartData: ChartData(
                d1: [
                    "Sun": D1PlanetPosition(house: 1, sign: "Ge", degree: 76.5, retrograde: false, vargottama: true, combust: false, nakshatra: "Ardra", pada: 3),
                    "Moon": D1PlanetPosition(house: 8, sign: "Cp", degree: 290.0, retrograde: false, vargottama: false, combust: false, nakshatra: nil, pada: nil)
                ],
                d9: [:]
            ),
            chartType: .d1,
            personName: "Test",
            ascendantSign: "Ge"
        )
    }
}
