import UIKit

// MARK: - Professional PDF Report Renderer
/// Generates a print-optimized, vector-based PDF for compatibility reports.
/// Uses UIGraphicsPDFRenderer for crisp, selectable text instead of rasterised SwiftUI views.
final class CompatibilityPDFRenderer {
    
    // MARK: - Design Tokens
    
    private struct Layout {
        static let pageWidth: CGFloat = 612         // US Letter
        static let pageHeight: CGFloat = 792
        static let margin: CGFloat = 54             // 0.75 inch
        static let contentWidth: CGFloat = pageWidth - 2 * margin
        static let contentTop: CGFloat = 72         // below running header
        static let contentBottom: CGFloat = pageHeight - 46 // above running footer
        static let availableHeight: CGFloat = contentBottom - contentTop
    }
    
    private struct Colors {
        // All pages use dark navy theme matching the cover
        static let background = UIColor(red: 0.06, green: 0.07, blue: 0.12, alpha: 1)   // Dark navy
        static let text = UIColor.white.withAlphaComponent(0.9)
        static let textSecondary = UIColor.white.withAlphaComponent(0.5)
        static let gold = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1)         // #D4B038
        static let goldLight = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.12)
        static let divider = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.3)
        static let coverBg = UIColor(red: 0.06, green: 0.07, blue: 0.12, alpha: 1)      // Dark navy
        static let coverText = UIColor.white
        static let tableBorder = UIColor.white.withAlphaComponent(0.15)
        static let tableHeaderBg = UIColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1)
        static let tableAltRow = UIColor.white.withAlphaComponent(0.04)
        static let red = UIColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1)
        static let green = UIColor(red: 0.30, green: 0.80, blue: 0.50, alpha: 1)
        // Card backgrounds for section cards
        static let cardBg = UIColor.white.withAlphaComponent(0.05)
        static let cardBorder = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.15)
    }
    
    private struct Fonts {
        static let brand = UIFont(name: "Georgia-Bold", size: 12)
            ?? UIFont.systemFont(ofSize: 12, weight: .bold)
        static let titleLarge = UIFont(name: "Georgia-Bold", size: 26)
            ?? UIFont.systemFont(ofSize: 26, weight: .bold)
        static let titleMedium = UIFont(name: "Georgia-Bold", size: 18)
            ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        static let sectionTitle = UIFont(name: "Georgia-Bold", size: 14)
            ?? UIFont.systemFont(ofSize: 14, weight: .bold)
        static let body = UIFont.systemFont(ofSize: 11)
        static let bodyBold = UIFont.boldSystemFont(ofSize: 11)
        static let small = UIFont.systemFont(ofSize: 9)
        static let smallBold = UIFont.boldSystemFont(ofSize: 9)
        static let tiny = UIFont.systemFont(ofSize: 8)
        static let tableHeader = UIFont.boldSystemFont(ofSize: 10)
        static let tableCell = UIFont.systemFont(ofSize: 10)
        static let tableCellBold = UIFont.boldSystemFont(ofSize: 10)
        static let header = UIFont.systemFont(ofSize: 8)
        static let score = UIFont(name: "Georgia-Bold", size: 42)
            ?? UIFont.systemFont(ofSize: 42, weight: .bold)
        static let scoreLabel = UIFont(name: "Georgia", size: 14)
            ?? UIFont.systemFont(ofSize: 14)
    }
    
    // MARK: - State
    
    private var currentY: CGFloat = 0
    private var pageNumber: Int = 0
    private var totalPages: Int = 0
    private var pdfContext: UIGraphicsPDFRendererContext?
    
    // Data
    private let result: CompatibilityResult
    private let boyName: String
    private let girlName: String
    private let boyDob: String?
    private let girlDob: String?
    private let sections: [(emoji: String, title: String, content: String)]
    
    private var ratingText: String {
        if !result.isRecommended { return "Not Recommended" }
        let pct = result.percentage * 100
        if pct >= 90 { return "Excellent" }
        else if pct >= 75 { return "Very Good" }
        else if pct >= 60 { return "Good" }
        else if pct >= 50 { return "Average" }
        else { return "Not Recommended" }
    }
    
    private var starCount: Int {
        if !result.isRecommended { return 1 }
        let pct = result.percentage * 100
        if pct >= 90 { return 5 }
        else if pct >= 75 { return 4 }
        else if pct >= 60 { return 3 }
        else if pct >= 50 { return 2 }
        else { return 1 }
    }
    
    // MARK: - Init
    
    init(
        result: CompatibilityResult,
        boyName: String,
        girlName: String,
        boyDob: String? = nil,
        girlDob: String? = nil,
        sections: [(emoji: String, title: String, content: String)]
    ) {
        self.result = result
        self.boyName = boyName
        self.girlName = girlName
        self.boyDob = boyDob
        self.girlDob = girlDob
        self.sections = sections
    }
    
    // MARK: - Public API
    
    /// Generate the professional PDF report and return its file URL
    func generateReport() -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(reportFileName() + ".pdf")
        try? FileManager.default.removeItem(at: tempURL)
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Compatibility Report – \(boyName) & \(girlName)",
            kCGPDFContextAuthor as String: "Destiny AI Astrology",
            kCGPDFContextCreator as String: "Destiny AI Astrology App"
        ]
        
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                self.pdfContext = context
                self.pageNumber = 0
                
                // 1. Cover page
                drawCoverPage(context: context)
                
                // 2. Content pages
                startNewPage(context: context)
                
                // Summary / Verdict
                drawVerdictSection()
                
                // Rejection reasons (if not recommended)
                if !result.isRecommended && !result.rejectionReasons.isEmpty {
                    drawRejectionReasons()
                }
                
                // Ashtakoot table
                drawAshtakootTable()
                
                // LLM analysis sections
                for section in sections {
                    drawContentSection(title: section.title, content: section.content)
                }
                
                // Disclaimer footer (on last page)
                addSpacing(20)
                drawDisclaimer()
            }
            
            return FileManager.default.fileExists(atPath: tempURL.path) ? tempURL : nil
        } catch {
            print("[CompatibilityPDFRenderer] Error generating PDF: \(error)")
            return nil
        }
    }
    
    private func reportFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        return "Compatibility Report – \(boyName) and \(girlName) – \(dateStr)"
    }
    
    // MARK: - Cover Page
    
    private func drawCoverPage(context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        pageNumber += 1
        
        let ctx = context.cgContext
        
        // Dark background
        ctx.setFillColor(Colors.coverBg.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight))
        
        // Gold border frame
        let borderInset: CGFloat = 30
        let borderRect = CGRect(
            x: borderInset, y: borderInset,
            width: Layout.pageWidth - 2 * borderInset,
            height: Layout.pageHeight - 2 * borderInset
        )
        ctx.setStrokeColor(Colors.gold.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(borderRect)
        
        // Inner decorative corners
        let cornerLen: CGFloat = 20
        let innerInset: CGFloat = 40
        let innerRect = CGRect(
            x: innerInset, y: innerInset,
            width: Layout.pageWidth - 2 * innerInset,
            height: Layout.pageHeight - 2 * innerInset
        )
        ctx.setStrokeColor(Colors.gold.withAlphaComponent(0.2).cgColor)
        ctx.setLineWidth(1)
        // Top-left
        ctx.move(to: CGPoint(x: innerRect.minX, y: innerRect.minY + cornerLen))
        ctx.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.minY))
        ctx.addLine(to: CGPoint(x: innerRect.minX + cornerLen, y: innerRect.minY))
        // Top-right
        ctx.move(to: CGPoint(x: innerRect.maxX - cornerLen, y: innerRect.minY))
        ctx.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.minY))
        ctx.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.minY + cornerLen))
        // Bottom-left
        ctx.move(to: CGPoint(x: innerRect.minX, y: innerRect.maxY - cornerLen))
        ctx.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.maxY))
        ctx.addLine(to: CGPoint(x: innerRect.minX + cornerLen, y: innerRect.maxY))
        // Bottom-right
        ctx.move(to: CGPoint(x: innerRect.maxX - cornerLen, y: innerRect.maxY))
        ctx.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY))
        ctx.addLine(to: CGPoint(x: innerRect.maxX, y: innerRect.maxY - cornerLen))
        ctx.strokePath()
        
        var y: CGFloat = 160
        
        // Logo image
        if let logoImage = UIImage(named: "logo_gold") {
            let logoSize: CGFloat = 50
            let logoRect = CGRect(
                x: (Layout.pageWidth - logoSize) / 2,
                y: y,
                width: logoSize,
                height: logoSize
            )
            logoImage.draw(in: logoRect)
            y += logoSize + 16
        }
        
        // Brand name
        let brandText = "DESTINY AI ASTROLOGY"
        let brandAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.brand,
            .foregroundColor: Colors.gold,
            .kern: 4
        ]
        drawCenteredText(brandText, at: y, attributes: brandAttrs)
        y += 30
        
        // Subtitle
        let subtitleText = "COMPATIBILITY REPORT"
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: Colors.gold.withAlphaComponent(0.6),
            .kern: 3
        ]
        drawCenteredText(subtitleText, at: y, attributes: subtitleAttrs)
        y += 40
        
        // Gold divider line
        drawHorizontalLine(at: y, from: Layout.pageWidth * 0.3, to: Layout.pageWidth * 0.7, color: Colors.gold.withAlphaComponent(0.4))
        y += 30
        
        // Boy name
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.titleLarge,
            .foregroundColor: Colors.coverText
        ]
        drawCenteredText(boyName.uppercased(), at: y, attributes: nameAttrs)
        y += 36
        
        // Ampersand
        let ampAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Georgia-Italic", size: 16) ?? UIFont.italicSystemFont(ofSize: 16),
            .foregroundColor: Colors.gold
        ]
        drawCenteredText("&", at: y, attributes: ampAttrs)
        y += 28
        
        // Girl name
        drawCenteredText(girlName.uppercased(), at: y, attributes: nameAttrs)
        y += 50
        
        // Score circle — use adjusted percentage when available for accuracy
        let displayPercentage: Double
        if let adjScore = result.adjustedScore {
            displayPercentage = Double(adjScore) / Double(result.maxScore)
        } else {
            displayPercentage = result.percentage
        }
        let circleSize: CGFloat = 120
        let circleCenterX = Layout.pageWidth / 2
        let circleCenterY = y + circleSize / 2
        drawScoreCircle(
            center: CGPoint(x: circleCenterX, y: circleCenterY),
            radius: circleSize / 2,
            percentage: displayPercentage,
            score: result.adjustedScore ?? result.totalScore,
            maxScore: result.maxScore
        )
        y += circleSize + 20
        
        // Star rating
        drawStarRating(at: y, stars: starCount)
        y += 24
        
        // Rating text
        let ratingAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: !result.isRecommended ? Colors.red : Colors.gold,
            .kern: 3
        ]
        drawCenteredText(ratingText.uppercased(), at: y, attributes: ratingAttrs)
        y += 22
        
        // Transparency text — explain original vs adjusted scores
        let transparencyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5),
            .foregroundColor: Colors.coverText.withAlphaComponent(0.45)
        ]
        if let adjScore = result.adjustedScore, adjScore != result.totalScore {
            drawCenteredText("Ashtakoot: \(result.totalScore)/\(result.maxScore) · Adjusted: \(adjScore)/\(result.maxScore)", at: y, attributes: transparencyAttrs)
            y += 12
            if !result.isRecommended {
                let overrideAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: Colors.red.withAlphaComponent(0.6)
                ]
                drawCenteredText("Overridden due to dosha incompatibility", at: y, attributes: overrideAttrs)
                y += 12
            }
        } else {
            drawCenteredText("Ashtakoot Score: \(result.totalScore)/\(result.maxScore)", at: y, attributes: transparencyAttrs)
            y += 12
        }
        y += 16
        
        // Birth dates
        if let bDob = boyDob, let gDob = girlDob {
            let dobAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: Colors.coverText.withAlphaComponent(0.5)
            ]
            drawCenteredText("Born: \(bDob) · \(gDob)", at: y, attributes: dobAttrs)
            y += 20
        }
        
        // Divider
        drawHorizontalLine(at: y, from: Layout.pageWidth * 0.3, to: Layout.pageWidth * 0.7, color: Colors.gold.withAlphaComponent(0.3))
        y += 30
        
        // Footer: website
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: Colors.gold.withAlphaComponent(0.5),
            .kern: 2
        ]
        drawCenteredText("destinyaiastrology.com", at: Layout.pageHeight - 60, attributes: footerAttrs)
        
        // Generation date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tiny,
            .foregroundColor: Colors.coverText.withAlphaComponent(0.3)
        ]
        drawCenteredText("Generated: \(dateFormatter.string(from: Date()))", at: Layout.pageHeight - 46, attributes: dateAttrs)
    }
    
    // MARK: - Verdict Section
    
    private func drawVerdictSection() {
        let boxPadding: CGFloat = 16
        
        let title = "COMPATIBILITY VERDICT"
        let titleHeight: CGFloat = 22
        
        // Build transparent verdict lines
        var verdictLines: [(label: String, value: String, color: UIColor)] = [
            ("Raw Ashtakoot Score:", "\(result.totalScore)/\(result.maxScore)", Colors.text)
        ]
        
        if let adjScore = result.adjustedScore, adjScore != result.totalScore {
            let adjPct = Int(Double(adjScore) / Double(result.maxScore) * 100)
            verdictLines.append(("Adjusted Score:", "\(adjScore)/\(result.maxScore) (\(adjPct)%)", Colors.gold))
        }
        
        if !result.isRecommended {
            verdictLines.append(("Final Verdict:", "Not Recommended", Colors.red))
            if result.adjustedScore != nil && result.adjustedScore! != result.totalScore {
                verdictLines.append(("Reason:", "Dosha incompatibility overrides adjusted score", Colors.red.withAlphaComponent(0.8)))
            }
        } else {
            let pct = Int(result.percentage * 100)
            verdictLines.append(("Compatibility:", "\(pct)%", Colors.text))
            verdictLines.append(("Final Verdict:", ratingText, Colors.green))
        }
        
        verdictLines.append(("Overall Rating:", String(repeating: "★", count: starCount) + String(repeating: "☆", count: 5 - starCount), Colors.gold))
        
        let lineHeight: CGFloat = 18
        let totalHeight = boxPadding + titleHeight + CGFloat(verdictLines.count) * lineHeight + boxPadding + 8
        
        ensureSpace(totalHeight + 20)
        
        let boxRect = CGRect(
            x: Layout.margin,
            y: currentY,
            width: Layout.contentWidth,
            height: totalHeight
        )
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(Colors.cardBg.cgColor)
        ctx.fill(boxRect)
        ctx.setStrokeColor(Colors.gold.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(boxRect)
        
        let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.sectionTitle,
            .foregroundColor: Colors.gold
        ]
        let titleRect = CGRect(x: Layout.margin + boxPadding, y: currentY + boxPadding, width: Layout.contentWidth - 2 * boxPadding, height: titleHeight)
        (title as NSString).draw(in: titleRect, withAttributes: sectionTitleAttrs)
        
        var lineY = currentY + boxPadding + titleHeight + 4
        
        for line in verdictLines {
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.bodyBold,
                .foregroundColor: Colors.text
            ]
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.bodyBold,
                .foregroundColor: line.color
            ]
            let labelRect = CGRect(x: Layout.margin + boxPadding, y: lineY, width: 140, height: lineHeight)
            (line.label as NSString).draw(in: labelRect, withAttributes: labelAttrs)
            let valueRect = CGRect(x: Layout.margin + boxPadding + 140, y: lineY, width: Layout.contentWidth - 2 * boxPadding - 140, height: lineHeight)
            (line.value as NSString).draw(in: valueRect, withAttributes: valueAttrs)
            lineY += lineHeight
        }
        
        currentY += totalHeight + 16
    }
    
    // MARK: - Rejection Reasons
    
    private func drawRejectionReasons() {
        let header = "REASONS FOR NOT RECOMMENDED"
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.sectionTitle,
            .foregroundColor: Colors.red
        ]
        
        let lineHeight: CGFloat = 16
        let totalEstimate = 28 + CGFloat(result.rejectionReasons.count) * (lineHeight + 4) + 16
        ensureSpace(totalEstimate)
        
        let headerRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 22)
        (header as NSString).draw(in: headerRect, withAttributes: headerAttrs)
        currentY += 26
        
        for reason in result.rejectionReasons {
            let bulletAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.body,
                .foregroundColor: Colors.red.withAlphaComponent(0.9)
            ]
            let bulletText = "✕  \(reason)"
            let textRect = CGRect(x: Layout.margin + 8, y: currentY, width: Layout.contentWidth - 16, height: 1000)
            let boundingRect = (bulletText as NSString).boundingRect(with: textRect.size, options: [.usesLineFragmentOrigin], attributes: bulletAttrs, context: nil)
            ensureSpace(boundingRect.height + 6)
            (bulletText as NSString).draw(in: CGRect(x: Layout.margin + 8, y: currentY, width: Layout.contentWidth - 16, height: boundingRect.height), withAttributes: bulletAttrs)
            currentY += boundingRect.height + 6
        }
        
        currentY += 10
    }
    
    // MARK: - Ashtakoot Table
    
    private func drawAshtakootTable() {
        let sectionTitle = "ASHTAKOOT (8 GUNA) ANALYSIS"
        let sectionAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.sectionTitle,
            .foregroundColor: Colors.gold
        ]
        
        // Section title with ornamental divider
        drawOrnamentalDivider()
        currentY += 8
        let titleRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 22)
        (sectionTitle as NSString).draw(in: titleRect, withAttributes: sectionAttrs)
        currentY += 28
        drawHorizontalLine(at: currentY - 4, from: Layout.margin, to: Layout.margin + Layout.contentWidth, color: Colors.gold.withAlphaComponent(0.15))
        
        // Column widths — 5 columns with Adjusted column
        let col1: CGFloat = 80   // Koota name
        let col2: CGFloat = 42   // Score
        let col3: CGFloat = 42   // Max
        let col4: CGFloat = 50   // Adjusted
        let col5: CGFloat = Layout.contentWidth - col1 - col2 - col3 - col4 // Analysis (≈290pt)
        let columns = [col1, col2, col3, col4, col5]
        let headers = ["Koota", "Score", "Max", "Adj.", "Analysis"]
        
        let tableX = Layout.margin
        let ctx = UIGraphicsGetCurrentContext()!
        let headerRowHeight: CGFloat = 28
        let minRowHeight: CGFloat = 26
        let cellPadding: CGFloat = 6
        
        // Pre-measure all row heights for dynamic sizing
        var rowHeights: [CGFloat] = []
        for kuta in result.kutas {
            let descText = kuta.description.isEmpty ? "—" : kuta.description
            let descAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tableCell]
            let boundingRect = (descText as NSString).boundingRect(
                with: CGSize(width: col5 - 12, height: 200),
                options: [.usesLineFragmentOrigin],
                attributes: descAttrs,
                context: nil
            )
            let rowH = max(minRowHeight, boundingRect.height + cellPadding * 2 + 2)
            rowHeights.append(rowH)
        }
        
        // Estimate total height to determine if page break needed
        let totalTableHeight = headerRowHeight + rowHeights.reduce(0, +) + minRowHeight + 20
        ensureSpace(min(totalTableHeight, 300))
        
        let tableStartY = currentY
        
        // Header row
        ctx.setFillColor(Colors.tableHeaderBg.cgColor)
        ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: headerRowHeight))
        
        let headerTextAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tableHeader,
            .foregroundColor: Colors.gold
        ]
        var colX = tableX
        for (i, header) in headers.enumerated() {
            let cellRect = CGRect(x: colX + 6, y: currentY + 7, width: columns[i] - 12, height: headerRowHeight - 14)
            (header as NSString).draw(in: cellRect, withAttributes: headerTextAttrs)
            colX += columns[i]
        }
        currentY += headerRowHeight
        
        // Data rows with dynamic heights
        for (index, kuta) in result.kutas.enumerated() {
            let rowH = rowHeights[index]
            let isAlt = index % 2 == 1
            
            ensureSpace(rowH + 4)
            
            if isAlt {
                ctx.setFillColor(Colors.tableAltRow.cgColor)
                ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: rowH))
            }
            
            let isDosha = kuta.points == 0 && kuta.maxPoints >= 6
            
            // Use doshaSummary.details to detect cancelled doshas
            let kutaKey = kuta.name.lowercased()
            let doshaDetail = result.doshaSummary?.details?[kutaKey]
                ?? result.doshaSummary?.details?["\(kutaKey)_dosha"]
            let isCancelled = doshaDetail?.cancelled ?? false
            
            // Color: green for cancelled dosha, red for active dosha, default otherwise
            let kutaColor: UIColor
            if isDosha && isCancelled {
                kutaColor = Colors.green
            } else if isDosha {
                kutaColor = Colors.red
            } else {
                kutaColor = Colors.text
            }
            
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.tableCellBold,
                .foregroundColor: kutaColor
            ]
            let cellAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.tableCell,
                .foregroundColor: kutaColor
            ]
            let descAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.tableCell,
                .foregroundColor: isCancelled ? Colors.green.withAlphaComponent(0.8) : Colors.textSecondary
            ]
            
            colX = tableX
            (kuta.name as NSString).draw(in: CGRect(x: colX + 6, y: currentY + cellPadding, width: columns[0] - 12, height: rowH - cellPadding * 2), withAttributes: nameAttrs)
            colX += columns[0]
            
            ("\(kuta.points)" as NSString).draw(in: CGRect(x: colX + 6, y: currentY + cellPadding, width: columns[1] - 12, height: rowH - cellPadding * 2), withAttributes: cellAttrs)
            colX += columns[1]
            
            ("\(kuta.maxPoints)" as NSString).draw(in: CGRect(x: colX + 6, y: currentY + cellPadding, width: columns[2] - 12, height: rowH - cellPadding * 2), withAttributes: cellAttrs)
            colX += columns[2]
            
            // Adjusted column: show adjusted score per kuta
            let adjText: String
            let adjColor: UIColor
            if isDosha && isCancelled {
                adjText = "\(kuta.maxPoints)"  // Restored to max
                adjColor = Colors.green
            } else if isDosha {
                adjText = "0"  // Active dosha, not adjusted
                adjColor = Colors.red
            } else {
                adjText = "—"  // No adjustment needed
                adjColor = Colors.textSecondary.withAlphaComponent(0.5)
            }
            let adjAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.tableCell,
                .foregroundColor: adjColor
            ]
            (adjText as NSString).draw(in: CGRect(x: colX + 6, y: currentY + cellPadding, width: columns[3] - 12, height: rowH - cellPadding * 2), withAttributes: adjAttrs)
            colX += columns[3]
            
            var descText = kuta.description.isEmpty ? "—" : kuta.description
            if isDosha && isCancelled {
                let reason = doshaDetail?.reasonShort ?? "Cancelled"
                descText += " — Cancelled: \(reason)"
            } else if isDosha {
                descText += " — Active dosha"
            }
            (descText as NSString).draw(in: CGRect(x: colX + 6, y: currentY + cellPadding, width: columns[4] - 12, height: rowH - cellPadding * 2), withAttributes: descAttrs)
            
            // Row border
            ctx.setStrokeColor(Colors.tableBorder.cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: tableX, y: currentY + rowH))
            ctx.addLine(to: CGPoint(x: tableX + Layout.contentWidth, y: currentY + rowH))
            ctx.strokePath()
            
            currentY += rowH
        }
        
        // Total row
        let totalRowH = minRowHeight
        ctx.setFillColor(Colors.tableHeaderBg.cgColor)
        ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: totalRowH))
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tableCellBold,
            .foregroundColor: UIColor.white
        ]
        colX = tableX
        ("TOTAL" as NSString).draw(in: CGRect(x: colX + 6, y: currentY + cellPadding, width: columns[0] - 12, height: totalRowH - 12), withAttributes: totalAttrs)
        colX += columns[0]
        ("\(result.totalScore)" as NSString).draw(in: CGRect(x: colX + 6, y: currentY + cellPadding, width: columns[1] - 12, height: totalRowH - 12), withAttributes: totalAttrs)
        colX += columns[1]
        ("\(result.maxScore)" as NSString).draw(in: CGRect(x: colX + 6, y: currentY + cellPadding, width: columns[2] - 12, height: totalRowH - 12), withAttributes: totalAttrs)
        // Adj. column for TOTAL row — leave empty
        currentY += totalRowH
        
        // Adjusted score row — transparent, factual language
        if let adjScore = result.adjustedScore, adjScore != result.totalScore {
            let adjRowH: CGFloat = 30
            ctx.setFillColor(Colors.goldLight.cgColor)
            ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: adjRowH))
            
            let adjLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: Fonts.tableCellBold,
                .foregroundColor: Colors.gold
            ]
            let adjValueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia-Bold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: Colors.gold
            ]
            ("ADJUSTED" as NSString).draw(in: CGRect(x: tableX + 6, y: currentY + 8, width: columns[0] - 12, height: adjRowH - 12), withAttributes: adjLabelAttrs)
            colX = tableX + columns[0]
            // Score column: same as total raw score
            ("\(result.totalScore)" as NSString).draw(in: CGRect(x: colX + 6, y: currentY + 8, width: columns[1] - 12, height: adjRowH - 12), withAttributes: adjValueAttrs)
            colX += columns[1]
            ("\(result.maxScore)" as NSString).draw(in: CGRect(x: colX + 6, y: currentY + 8, width: columns[2] - 12, height: adjRowH - 12), withAttributes: adjValueAttrs)
            colX += columns[2]
            // Adj. column: shows total adjusted score
            ("\(adjScore)" as NSString).draw(in: CGRect(x: colX + 6, y: currentY + 8, width: columns[3] - 12, height: adjRowH - 12), withAttributes: adjValueAttrs)
            colX += columns[3]
            // Analysis column: factual note
            let adjPct = Int(Double(adjScore) / Double(result.maxScore) * 100)
            let adjNoteText: String
            if !result.isRecommended {
                adjNoteText = "\(adjPct)% — overridden by dosha"
            } else {
                let adjCatText = result.adjustedCategory ?? "\(adjPct)%"
                adjNoteText = "\(adjCatText) (\(adjPct)%)"
            }
            (adjNoteText as NSString).draw(in: CGRect(x: colX + 6, y: currentY + 8, width: columns[4] - 12, height: adjRowH - 12), withAttributes: adjLabelAttrs)
            
            currentY += adjRowH
        }
        
        // Outer table border
        let tableRect = CGRect(
            x: tableX,
            y: tableStartY,
            width: Layout.contentWidth,
            height: currentY - tableStartY
        )
        ctx.setStrokeColor(Colors.tableBorder.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(tableRect)
        
        // Vertical column lines
        colX = tableX
        for i in 0..<(columns.count - 1) {
            colX += columns[i]
            ctx.move(to: CGPoint(x: colX, y: tableRect.minY))
            ctx.addLine(to: CGPoint(x: colX, y: tableRect.maxY))
        }
        ctx.strokePath()
        
        currentY += 20
    }
    
    // MARK: - Content Section (LLM Analysis Blocks)
    
    private func drawContentSection(title: String, content: String) {
        let headerHeight: CGFloat = 28
        ensureSpace(headerHeight + 40)
        
        // Ornamental divider between sections
        drawOrnamentalDivider()
        currentY += 10
        
        // Section title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.sectionTitle,
            .foregroundColor: Colors.gold
        ]
        let titleRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: headerHeight)
        (title as NSString).draw(in: titleRect, withAttributes: titleAttrs)
        currentY += headerHeight
        
        // Thin gold line under title
        drawHorizontalLine(at: currentY - 4, from: Layout.margin, to: Layout.margin + Layout.contentWidth, color: Colors.gold.withAlphaComponent(0.15))
        currentY += 2
        
        drawMarkdownContent(content)
        
        currentY += 14
    }
    
    // MARK: - Markdown Content Renderer
    
    private func drawMarkdownContent(_ content: String) {
        let lines = content.components(separatedBy: "\n")
        var i = 0
        
        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                addSpacing(6)
                i += 1
                continue
            }
            
            // Check for markdown table: collect consecutive pipe-delimited rows
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                var tableRows: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if t.hasPrefix("|") && t.hasSuffix("|") {
                        // Skip separator rows like |---|---|---|
                        let inner = t.dropFirst().dropLast().trimmingCharacters(in: .whitespaces)
                        let isSeparator = inner.allSatisfy { $0 == "-" || $0 == "|" || $0 == " " || $0 == ":" }
                        if !isSeparator {
                            tableRows.append(t)
                        }
                        i += 1
                    } else {
                        break
                    }
                }
                if !tableRows.isEmpty {
                    drawMarkdownTable(tableRows)
                }
                continue
            }
            
            if trimmed.hasPrefix("---") {
                i += 1
                continue
            }
            
            // Determine formatting
            var text = trimmed
            var font = Fonts.body
            let color = Colors.text
            var indent: CGFloat = 0
            
            if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                text = String(trimmed.dropFirst(2).dropLast(2))
                font = Fonts.bodyBold
            } else if trimmed.hasPrefix("**") && trimmed.contains(":**") {
                drawBoldLabelLine(trimmed)
                i += 1
                continue
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") || trimmed.hasPrefix("* ") {
                text = "•   " + String(trimmed.dropFirst(2))
                indent = 12
            } else if trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                indent = 12
                text = trimmed
            }
            
            // Handle inline bold (**text**)
            if text.contains("**") {
                drawRichTextLine(text, baseFont: font, baseColor: color, indent: indent)
                i += 1
                continue
            }
            
            // Draw simple text
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let availWidth = Layout.contentWidth - indent
            let textRect = CGRect(x: Layout.margin + indent, y: currentY, width: availWidth, height: 1000)
            let boundingRect = (text as NSString).boundingRect(with: textRect.size, options: [.usesLineFragmentOrigin], attributes: textAttrs, context: nil)
            
            ensureSpace(boundingRect.height + 3)
            
            (text as NSString).draw(
                in: CGRect(x: Layout.margin + indent, y: currentY, width: availWidth, height: boundingRect.height),
                withAttributes: textAttrs
            )
            currentY += boundingRect.height + 3
            i += 1
        }
    }
    
    /// Draw a line with **Bold Label:** value format
    private func drawBoldLabelLine(_ line: String) {
        guard let boldEnd = line.range(of: ":**") else {
            drawRichTextLine(line, baseFont: Fonts.body, baseColor: Colors.text, indent: 0)
            return
        }
        
        let labelPart = String(line[line.index(line.startIndex, offsetBy: 2)..<boldEnd.lowerBound]) + ":"
        let valuePart = String(line[boldEnd.upperBound...]).trimmingCharacters(in: .whitespaces)
        
        let attrString = NSMutableAttributedString()
        attrString.append(NSAttributedString(string: labelPart + " ", attributes: [
            .font: Fonts.bodyBold,
            .foregroundColor: Colors.text
        ]))
        attrString.append(NSAttributedString(string: valuePart, attributes: [
            .font: Fonts.body,
            .foregroundColor: Colors.text
        ]))
        
        let availWidth = Layout.contentWidth
        let boundingRect = attrString.boundingRect(with: CGSize(width: availWidth, height: 1000), options: [.usesLineFragmentOrigin], context: nil)
        
        ensureSpace(boundingRect.height + 3)
        attrString.draw(in: CGRect(x: Layout.margin, y: currentY, width: availWidth, height: boundingRect.height))
        currentY += boundingRect.height + 3
    }
    
    /// Draw a line with mixed bold/regular text
    private func drawRichTextLine(_ line: String, baseFont: UIFont, baseColor: UIColor, indent: CGFloat) {
        let attrString = NSMutableAttributedString()
        let parts = line.components(separatedBy: "**")
        
        for (index, part) in parts.enumerated() {
            if part.isEmpty { continue }
            let isBold = index % 2 == 1
            attrString.append(NSAttributedString(string: part, attributes: [
                .font: isBold ? Fonts.bodyBold : baseFont,
                .foregroundColor: baseColor
            ]))
        }
        
        let availWidth = Layout.contentWidth - indent
        let boundingRect = attrString.boundingRect(with: CGSize(width: availWidth, height: 1000), options: [.usesLineFragmentOrigin], context: nil)
        
        ensureSpace(boundingRect.height + 3)
        attrString.draw(in: CGRect(x: Layout.margin + indent, y: currentY, width: availWidth, height: boundingRect.height))
        currentY += boundingRect.height + 3
    }
    
    /// Draw a proper multi-row markdown table with dynamic row heights and proportional columns
    private func drawMarkdownTable(_ rows: [String]) {
        guard !rows.isEmpty else { return }
        
        // Parse all rows into cell arrays
        let parsedRows = rows.map { row -> [String] in
            row.components(separatedBy: "|").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        let colCount = parsedRows.map { $0.count }.max() ?? 1
        guard colCount > 0 else { return }
        
        let tableX = Layout.margin + 4
        let tableWidth = Layout.contentWidth - 8
        let cellPadding: CGFloat = 5
        let minRowHeight: CGFloat = 22
        
        // Smart column widths: measure widest text across ALL rows for non-last columns
        var colWidths: [CGFloat] = Array(repeating: tableWidth / CGFloat(colCount), count: colCount)
        if colCount > 1 {
            let minColWidth: CGFloat = 70  // Minimum to fit words like "Bhakoot"
            var maxWidthPerCol: [CGFloat] = Array(repeating: minColWidth, count: colCount)
            
            // Measure widest content in each column (across all rows)
            for (rowIdx, cells) in parsedRows.enumerated() {
                let font = rowIdx == 0 ? Fonts.tableHeader : Fonts.tableCell
                for (colIdx, cell) in cells.enumerated() {
                    if colIdx >= colCount - 1 { break } // Skip last column — it gets remaining
                    let size = (cell as NSString).size(withAttributes: [.font: font])
                    maxWidthPerCol[colIdx] = max(maxWidthPerCol[colIdx], size.width + 20)
                }
            }
            
            // Cap each non-last column at 35% of table width
            for i in 0..<(colCount - 1) {
                maxWidthPerCol[i] = min(maxWidthPerCol[i], tableWidth * 0.35)
            }
            
            // Give remaining width to the last column
            let fixedColsWidth = maxWidthPerCol.dropLast().reduce(0, +)
            if fixedColsWidth < tableWidth * 0.7 {
                colWidths = Array(maxWidthPerCol.dropLast()) + [tableWidth - fixedColsWidth]
            }
        }
        
        // Pre-measure row heights
        var rowHeights: [CGFloat] = []
        for (rowIdx, cells) in parsedRows.enumerated() {
            var maxH: CGFloat = minRowHeight
            let font = rowIdx == 0 ? Fonts.tableHeader : Fonts.tableCell
            for (colIdx, cell) in cells.enumerated() {
                if colIdx >= colCount { break }
                let w = colWidths[colIdx] - 12
                let boundingRect = (cell as NSString).boundingRect(
                    with: CGSize(width: w, height: 200),
                    options: [.usesLineFragmentOrigin],
                    attributes: [.font: font],
                    context: nil
                )
                maxH = max(maxH, boundingRect.height + cellPadding * 2 + 2)
            }
            rowHeights.append(maxH)
        }
        
        ensureSpace(min(rowHeights.reduce(0, +) + 10, 200))
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let tableStartY = currentY
        
        for (rowIndex, cells) in parsedRows.enumerated() {
            let isHeader = rowIndex == 0
            let isAlt = rowIndex % 2 == 0 && !isHeader
            let rowH = rowHeights[rowIndex]
            
            ensureSpace(rowH + 4)
            
            if isHeader {
                ctx.setFillColor(Colors.tableHeaderBg.cgColor)
                ctx.fill(CGRect(x: tableX, y: currentY, width: tableWidth, height: rowH))
            } else if isAlt {
                ctx.setFillColor(Colors.tableAltRow.cgColor)
                ctx.fill(CGRect(x: tableX, y: currentY, width: tableWidth, height: rowH))
            }
            
            let cellAttrs: [NSAttributedString.Key: Any] = [
                .font: isHeader ? Fonts.tableHeader : Fonts.tableCell,
                .foregroundColor: isHeader ? Colors.gold : Colors.text
            ]
            
            var cellX = tableX
            for (colIndex, cell) in cells.enumerated() {
                if colIndex >= colCount { break }
                let cellRect = CGRect(
                    x: cellX + 6,
                    y: currentY + cellPadding,
                    width: colWidths[colIndex] - 12,
                    height: rowH - cellPadding * 2
                )
                (cell as NSString).draw(in: cellRect, withAttributes: cellAttrs)
                cellX += colWidths[colIndex]
            }
            
            ctx.setStrokeColor(Colors.tableBorder.cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: tableX, y: currentY + rowH))
            ctx.addLine(to: CGPoint(x: tableX + tableWidth, y: currentY + rowH))
            ctx.strokePath()
            
            currentY += rowH
        }
        
        // Outer border
        let tableRect = CGRect(x: tableX, y: tableStartY, width: tableWidth, height: currentY - tableStartY)
        ctx.setStrokeColor(Colors.tableBorder.cgColor)
        ctx.setLineWidth(0.5)
        ctx.stroke(tableRect)
        
        // Vertical column lines
        var lineX = tableX
        for i in 0..<(colCount - 1) {
            lineX += colWidths[i]
            ctx.move(to: CGPoint(x: lineX, y: tableRect.minY))
            ctx.addLine(to: CGPoint(x: lineX, y: tableRect.maxY))
        }
        ctx.strokePath()
        
        currentY += 8
    }
    
    // MARK: - Disclaimer
    
    private func drawDisclaimer() {
        let disclaimerHeight: CGFloat = 60
        ensureSpace(disclaimerHeight)
        
        drawHorizontalLine(at: currentY, from: Layout.margin + 80, to: Layout.margin + Layout.contentWidth - 80, color: Colors.divider)
        currentY += 12
        
        let centerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.small,
            .foregroundColor: Colors.gold.withAlphaComponent(0.5)
        ]
        drawCenteredText("ⓘ AI-Generated Analysis", at: currentY, attributes: centerAttrs)
        currentY += 14
        
        let discText = "This report is generated using AI based on vedic astrology principles. Results are for informational and entertainment purposes only."
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .center
        let discAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tiny,
            .foregroundColor: Colors.textSecondary,
            .paragraphStyle: paraStyle
        ]
        let discRect = CGRect(x: Layout.margin + 40, y: currentY, width: Layout.contentWidth - 80, height: 30)
        (discText as NSString).draw(in: discRect, withAttributes: discAttrs)
        currentY += 26
        
        let copyrightAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tiny,
            .foregroundColor: Colors.textSecondary.withAlphaComponent(0.6),
            .paragraphStyle: paraStyle
        ]
        drawCenteredText("© 2026 Destiny AI Astrology · destinyaiastrology.com", at: currentY, attributes: copyrightAttrs)
    }
    
    // MARK: - Page Management
    
    private func startNewPage(context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        pageNumber += 1
        currentY = Layout.contentTop
        
        // Page background
        let ctx = context.cgContext
        ctx.setFillColor(Colors.background.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight))
        
        // Premium: decorative corner brackets
        drawCornerBrackets(ctx: ctx)
        
        // Premium: subtle constellation dots
        drawConstellationDots(ctx: ctx)
        
        drawPageHeader()
        drawPageFooter()
    }
    
    private func ensureSpace(_ needed: CGFloat) {
        if currentY + needed > Layout.contentBottom {
            guard let context = pdfContext else { return }
            startNewPage(context: context)
        }
    }
    
    private func addSpacing(_ amount: CGFloat) {
        currentY += amount
    }
    
    private func drawPageHeader() {
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.header,
            .foregroundColor: Colors.gold.withAlphaComponent(0.5),
            .kern: 2
        ]
        let headerRect = CGRect(x: Layout.margin, y: 30, width: Layout.contentWidth, height: 14)
        ("DESTINY AI ASTROLOGY" as NSString).draw(in: headerRect, withAttributes: headerAttrs)
        
        let pageAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.header,
            .foregroundColor: Colors.gold.withAlphaComponent(0.4)
        ]
        let pageText = "Page \(pageNumber)"
        let pageSize = (pageText as NSString).size(withAttributes: pageAttrs)
        let pageRect = CGRect(x: Layout.pageWidth - Layout.margin - pageSize.width, y: 30, width: pageSize.width, height: 14)
        (pageText as NSString).draw(in: pageRect, withAttributes: pageAttrs)
        
        drawHorizontalLine(at: 48, from: Layout.margin, to: Layout.pageWidth - Layout.margin, color: Colors.gold.withAlphaComponent(0.2))
    }
    
    private func drawPageFooter() {
        let footerY = Layout.pageHeight - 30
        drawHorizontalLine(at: footerY - 8, from: Layout.margin, to: Layout.pageWidth - Layout.margin, color: Colors.gold.withAlphaComponent(0.1))
        
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tiny,
            .foregroundColor: Colors.gold.withAlphaComponent(0.3)
        ]
        let footerRect = CGRect(x: Layout.margin, y: footerY, width: Layout.contentWidth, height: 12)
        ("\(boyName) & \(girlName) — Compatibility Report" as NSString).draw(in: footerRect, withAttributes: footerAttrs)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM yyyy"
        let dateText = dateFormatter.string(from: Date())
        let dateSize = (dateText as NSString).size(withAttributes: footerAttrs)
        let dateRect = CGRect(x: Layout.pageWidth - Layout.margin - dateSize.width, y: footerY, width: dateSize.width, height: 12)
        (dateText as NSString).draw(in: dateRect, withAttributes: footerAttrs)
    }
    
    // MARK: - Drawing Helpers
    
    private func drawCenteredText(_ text: String, at y: CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: (Layout.pageWidth - size.width) / 2, y: y, width: size.width, height: size.height)
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }
    
    private func drawHorizontalLine(at y: CGFloat, from x1: CGFloat, to x2: CGFloat, color: UIColor, width: CGFloat = 1) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.move(to: CGPoint(x: x1, y: y))
        ctx.addLine(to: CGPoint(x: x2, y: y))
        ctx.strokePath()
    }
    
    /// Premium ornamental divider between sections: ——◆——
    private func drawOrnamentalDivider() {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ensureSpace(20)
        
        let centerX = Layout.pageWidth / 2
        let y = currentY + 8
        let diamondSize: CGFloat = 5
        let lineLength: CGFloat = 80
        
        // Left line
        ctx.setStrokeColor(Colors.gold.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(0.8)
        ctx.move(to: CGPoint(x: centerX - diamondSize - lineLength, y: y))
        ctx.addLine(to: CGPoint(x: centerX - diamondSize - 4, y: y))
        ctx.strokePath()
        
        // Diamond shape
        ctx.setFillColor(Colors.gold.withAlphaComponent(0.4).cgColor)
        ctx.move(to: CGPoint(x: centerX, y: y - diamondSize))
        ctx.addLine(to: CGPoint(x: centerX + diamondSize, y: y))
        ctx.addLine(to: CGPoint(x: centerX, y: y + diamondSize))
        ctx.addLine(to: CGPoint(x: centerX - diamondSize, y: y))
        ctx.closePath()
        ctx.fillPath()
        
        // Small dots flanking the diamond
        ctx.setFillColor(Colors.gold.withAlphaComponent(0.25).cgColor)
        let dotRadius: CGFloat = 1.5
        ctx.fillEllipse(in: CGRect(x: centerX - diamondSize - 10 - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        ctx.fillEllipse(in: CGRect(x: centerX + diamondSize + 10 - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        
        // Right line
        ctx.setStrokeColor(Colors.gold.withAlphaComponent(0.3).cgColor)
        ctx.move(to: CGPoint(x: centerX + diamondSize + 4, y: y))
        ctx.addLine(to: CGPoint(x: centerX + diamondSize + lineLength, y: y))
        ctx.strokePath()
        
        currentY += 16
    }
    
    /// Subtle decorative L-shaped corner brackets on content pages
    private func drawCornerBrackets(ctx: CGContext) {
        let inset: CGFloat = 22
        let len: CGFloat = 18
        let color = Colors.gold.withAlphaComponent(0.12)
        
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1)
        
        // Top-left
        ctx.move(to: CGPoint(x: inset, y: inset + len))
        ctx.addLine(to: CGPoint(x: inset, y: inset))
        ctx.addLine(to: CGPoint(x: inset + len, y: inset))
        
        // Top-right
        ctx.move(to: CGPoint(x: Layout.pageWidth - inset - len, y: inset))
        ctx.addLine(to: CGPoint(x: Layout.pageWidth - inset, y: inset))
        ctx.addLine(to: CGPoint(x: Layout.pageWidth - inset, y: inset + len))
        
        // Bottom-left
        ctx.move(to: CGPoint(x: inset, y: Layout.pageHeight - inset - len))
        ctx.addLine(to: CGPoint(x: inset, y: Layout.pageHeight - inset))
        ctx.addLine(to: CGPoint(x: inset + len, y: Layout.pageHeight - inset))
        
        // Bottom-right
        ctx.move(to: CGPoint(x: Layout.pageWidth - inset - len, y: Layout.pageHeight - inset))
        ctx.addLine(to: CGPoint(x: Layout.pageWidth - inset, y: Layout.pageHeight - inset))
        ctx.addLine(to: CGPoint(x: Layout.pageWidth - inset, y: Layout.pageHeight - inset - len))
        
        ctx.strokePath()
    }
    
    /// Faint decorative constellation dots (repeatable, seeded by page number)
    private func drawConstellationDots(ctx: CGContext) {
        ctx.setFillColor(Colors.gold.withAlphaComponent(0.06).cgColor)
        
        // Deterministic positions seeded by page number
        let seed = pageNumber * 7
        let positions: [(CGFloat, CGFloat)] = [
            (0.85, 0.12), (0.12, 0.25), (0.92, 0.38), (0.08, 0.52),
            (0.88, 0.65), (0.15, 0.78), (0.90, 0.88), (0.10, 0.15),
            (0.75, 0.08), (0.20, 0.92)
        ]
        
        for (i, pos) in positions.enumerated() {
            let r: CGFloat = CGFloat(((seed + i * 13) % 3) + 1)
            let x = pos.0 * Layout.pageWidth
            let y = pos.1 * Layout.pageHeight
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
    }
    
    private func drawScoreCircle(center: CGPoint, radius: CGFloat, percentage: Double, score: Int, maxScore: Int) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        // Background circle
        ctx.setStrokeColor(Colors.gold.withAlphaComponent(0.2).cgColor)
        ctx.setLineWidth(4)
        ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()
        
        // Progress arc
        ctx.setStrokeColor(Colors.gold.cgColor)
        ctx.setLineWidth(4)
        ctx.setLineCap(.round)
        let startAngle: CGFloat = -.pi / 2
        let endAngle = startAngle + CGFloat(percentage) * .pi * 2
        ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        ctx.strokePath()
        
        // Percentage text
        let pctText = "\(Int(percentage * 100))%"
        let pctAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.score,
            .foregroundColor: Colors.coverText
        ]
        let pctSize = (pctText as NSString).size(withAttributes: pctAttrs)
        (pctText as NSString).draw(at: CGPoint(x: center.x - pctSize.width / 2, y: center.y - pctSize.height / 2 - 6), withAttributes: pctAttrs)
        
        // Score label
        let scoreText = "\(score)/\(maxScore)"
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.scoreLabel,
            .foregroundColor: Colors.gold
        ]
        let scoreSize = (scoreText as NSString).size(withAttributes: scoreAttrs)
        (scoreText as NSString).draw(at: CGPoint(x: center.x - scoreSize.width / 2, y: center.y + pctSize.height / 2 - 14), withAttributes: scoreAttrs)
    }
    
    private func drawStarRating(at y: CGFloat, stars: Int) {
        // Use Unicode star characters — SF Symbols don't render in PDF context
        var starText = ""
        for i in 0..<5 {
            starText += i < stars ? "★" : "☆"
            if i < 4 { starText += "  " }
        }
        let starAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: Colors.gold
        ]
        drawCenteredText(starText, at: y, attributes: starAttrs)
    }
}
