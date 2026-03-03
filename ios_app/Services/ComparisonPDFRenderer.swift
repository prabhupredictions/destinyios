import UIKit

// MARK: - Multi-Partner Comparison PDF Renderer
/// Generates a professional, consolidated PDF report comparing multiple partner compatibility results.
/// Uses UIGraphicsPDFRenderer for crisp, vector-based output matching the individual report style.
final class ComparisonPDFRenderer {
    
    // MARK: - Design Tokens (matching CompatibilityPDFRenderer)
    
    private struct Layout {
        static let pageWidth: CGFloat = 612         // US Letter
        static let pageHeight: CGFloat = 792
        static let margin: CGFloat = 54             // 0.75 inch
        static let contentWidth: CGFloat = pageWidth - 2 * margin
        static let contentTop: CGFloat = 56
        static let contentBottom: CGFloat = pageHeight - 40
        static let availableHeight: CGFloat = contentBottom - contentTop
    }
    
    private struct Colors {
        static let background = UIColor(red: 0.06, green: 0.07, blue: 0.12, alpha: 1)
        static let text = UIColor.white.withAlphaComponent(0.9)
        static let textSecondary = UIColor.white.withAlphaComponent(0.5)
        static let gold = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1)
        static let goldLight = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.12)
        static let divider = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.3)
        static let tableBorder = UIColor.white.withAlphaComponent(0.15)
        static let tableHeaderBg = UIColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1)
        static let tableAltRow = UIColor.white.withAlphaComponent(0.04)
        static let red = UIColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1)
        static let green = UIColor(red: 0.30, green: 0.80, blue: 0.50, alpha: 1)
        static let orange = UIColor(red: 0.95, green: 0.65, blue: 0.20, alpha: 1)
        static let cardBg = UIColor.white.withAlphaComponent(0.05)
        static let cardBorder = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.15)
    }
    
    private struct Fonts {
        static let brand = UIFont(name: "Georgia-Bold", size: 12) ?? .boldSystemFont(ofSize: 12)
        static let titleLarge = UIFont(name: "Georgia-Bold", size: 28) ?? .boldSystemFont(ofSize: 28)
        static let titleMedium = UIFont(name: "Georgia-Bold", size: 18) ?? .boldSystemFont(ofSize: 18)
        static let sectionTitle = UIFont(name: "Georgia-Bold", size: 14) ?? .boldSystemFont(ofSize: 14)
        static let body = UIFont.systemFont(ofSize: 11)
        static let bodyBold = UIFont.boldSystemFont(ofSize: 11)
        static let small = UIFont.systemFont(ofSize: 9)
        static let smallBold = UIFont.boldSystemFont(ofSize: 9)
        static let tiny = UIFont.systemFont(ofSize: 8)
        static let tableHeader = UIFont.boldSystemFont(ofSize: 10)
        static let tableCell = UIFont.systemFont(ofSize: 10)
        static let tableCellBold = UIFont.boldSystemFont(ofSize: 10)
        static let header = UIFont.systemFont(ofSize: 8)
    }
    
    // MARK: - State
    
    private var currentY: CGFloat = 0
    private var pageNumber: Int = 0
    private var pdfContext: UIGraphicsPDFRendererContext?
    
    // Data
    private let results: [ComparisonResult]
    private let userName: String
    private let sortedResults: [ComparisonResult]
    
    private var bestMatch: ComparisonResult? {
        sortedResults.first(where: { $0.isRecommended })
    }
    
    private var allRejected: Bool {
        results.allSatisfy { !$0.isRecommended }
    }
    
    // MARK: - Init
    
    init(results: [ComparisonResult], userName: String) {
        self.results = results
        self.userName = userName
        self.sortedResults = results.sorted { a, b in
            if a.isRecommended != b.isRecommended { return a.isRecommended }
            return a.adjustedScore > b.adjustedScore
        }
    }
    
    // MARK: - Public API
    
    func render() -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Compatibility Comparison — \(userName)",
            kCGPDFContextAuthor as String: "Destiny AI Astrology"
        ]
        
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { ctx in
            self.pdfContext = ctx
            self.pageNumber = 0
            
            // Page 1: Cover
            drawCoverPage()
            
            // Page 2+: Executive Summary + Koota Table (flow naturally)
            startContentPage()
            drawExecutiveSummary()
            drawKootaBreakdownTable()
            
            // Each partner gets a fresh page — professional section breaks
            for result in sortedResults {
                startContentPage()
                drawPartnerAnalysis(result)
            }
            
            drawDisclaimer()
        }
    }
    
    // MARK: - Page Management
    
    private func startContentPage() {
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        pdfContext?.beginPage()
        pageNumber += 1
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(Colors.background.cgColor)
        ctx.fill(pageRect)
        
        drawRunningHeader()
        drawRunningFooter()
        currentY = Layout.contentTop
    }
    
    private func ensureSpace(_ height: CGFloat) {
        if currentY + height > Layout.contentBottom {
            startContentPage()
        }
    }
    
    private func addSpacing(_ spacing: CGFloat) {
        currentY += spacing
    }
    
    // MARK: - Running Header & Footer
    
    private func drawRunningHeader() {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.header,
            .foregroundColor: Colors.gold.withAlphaComponent(0.5)
        ]
        let left = "Destiny AI Astrology"
        let right = "Compatibility Comparison — \(userName)"
        (left as NSString).draw(at: CGPoint(x: Layout.margin, y: 22), withAttributes: attrs)
        let rightSize = (right as NSString).size(withAttributes: attrs)
        (right as NSString).draw(at: CGPoint(x: Layout.pageWidth - Layout.margin - rightSize.width, y: 22), withAttributes: attrs)
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setStrokeColor(Colors.gold.withAlphaComponent(0.15).cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: Layout.margin, y: 36))
        ctx.addLine(to: CGPoint(x: Layout.pageWidth - Layout.margin, y: 36))
        ctx.strokePath()
    }
    
    private func drawRunningFooter() {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Fonts.tiny,
            .foregroundColor: Colors.textSecondary.withAlphaComponent(0.4)
        ]
        let footerY = Layout.pageHeight - 28
        ("Page \(pageNumber)" as NSString).draw(at: CGPoint(x: Layout.margin, y: footerY), withAttributes: attrs)
        let rightText = "© 2026 Destiny AI Astrology"
        let rightSize = (rightText as NSString).size(withAttributes: attrs)
        (rightText as NSString).draw(at: CGPoint(x: Layout.pageWidth - Layout.margin - rightSize.width, y: footerY), withAttributes: attrs)
    }
    
    // MARK: - Cover Page
    
    private func drawCoverPage() {
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        pdfContext?.beginPage()
        pageNumber += 1
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(Colors.background.cgColor)
        ctx.fill(pageRect)
        
        let centerX = Layout.pageWidth / 2
        var y: CGFloat = 220
        
        // App logo
        if let logoImage = UIImage(named: "logo_gold") {
            let logoSize: CGFloat = 60
            let logoRect = CGRect(
                x: (Layout.pageWidth - logoSize) / 2,
                y: y,
                width: logoSize,
                height: logoSize
            )
            logoImage.draw(in: logoRect)
            y += logoSize + 16
        }
        
        // Brand
        drawCenteredText("DESTINY AI ASTROLOGY", at: y, font: Fonts.brand,
                         color: Colors.gold, kern: 6)
        y += 22
        drawCenteredText("VEDIC COMPATIBILITY ANALYSIS", at: y,
                         font: UIFont.systemFont(ofSize: 9, weight: .medium),
                         color: Colors.gold.withAlphaComponent(0.6), kern: 3)
        y += 24
        
        drawHorizontalLine(at: y, from: centerX - 60, to: centerX + 60, color: Colors.gold.withAlphaComponent(0.3))
        y += 20
        
        // Main title
        drawCenteredText("COMPARISON REPORT", at: y,
                         font: UIFont(name: "Georgia-Bold", size: 30) ?? .boldSystemFont(ofSize: 30),
                         color: .white)
        y += 50
        
        // User name
        drawCenteredText(userName, at: y,
                         font: UIFont(name: "Georgia", size: 18) ?? .systemFont(ofSize: 18),
                         color: Colors.gold)
        y += 30
        drawCenteredText("compared with", at: y,
                         font: UIFont.systemFont(ofSize: 10), color: Colors.textSecondary)
        y += 22
        
        // Partner names
        for r in sortedResults {
            drawCenteredText(r.partner.name, at: y,
                             font: UIFont(name: "Georgia", size: 14) ?? .systemFont(ofSize: 14),
                             color: UIColor.white.withAlphaComponent(0.85))
            y += 24
        }
        
        y += 12
        drawHorizontalLine(at: y, from: centerX - 60, to: centerX + 60, color: Colors.gold.withAlphaComponent(0.3))
        drawDiamond(at: CGPoint(x: centerX, y: y + 10), size: 5, color: Colors.gold.withAlphaComponent(0.6))
        y += 30
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        drawCenteredText(dateFormatter.string(from: Date()), at: y,
                         font: UIFont.systemFont(ofSize: 10),
                         color: Colors.textSecondary.withAlphaComponent(0.6))
        
        // Footer
        drawCenteredText("destinyaiastrology.com", at: Layout.pageHeight - 50,
                         font: Fonts.tiny,
                         color: Colors.textSecondary.withAlphaComponent(0.3))
    }
    
    // MARK: - Executive Summary
    
    private func drawExecutiveSummary() {
        drawSectionTitle("EXECUTIVE SUMMARY")
        
        // Recommendation card
        drawRecommendationCard()
        addSpacing(10)
        
        // Partner score cards
        drawPartnerScoreCards()
        addSpacing(10)
        
        // Score bar chart
        drawScoreBarChart()
        addSpacing(6)
    }
    
    private func drawRecommendationCard() {
        let ctx = UIGraphicsGetCurrentContext()!
        let cardHeight: CGFloat = 48
        ensureSpace(cardHeight + 4)
        
        let cardRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: cardHeight)
        let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
        ctx.setFillColor(Colors.cardBg.cgColor)
        ctx.addPath(path.cgPath); ctx.fillPath()
        ctx.setStrokeColor(Colors.gold.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(path.cgPath); ctx.strokePath()
        
        let iconAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18)]
        ("🏆" as NSString).draw(at: CGPoint(x: Layout.margin + 12, y: currentY + 12), withAttributes: iconAttrs)
        
        if allRejected {
            let attrs: [NSAttributedString.Key: Any] = [.font: Fonts.bodyBold, .foregroundColor: Colors.orange]
            ("None of the profiles meet the recommended threshold" as NSString).draw(
                at: CGPoint(x: Layout.margin + 40, y: currentY + 10), withAttributes: attrs)
            let sub: [NSAttributedString.Key: Any] = [.font: Fonts.small, .foregroundColor: Colors.textSecondary]
            ("Review individual analyses for detailed insights." as NSString).draw(
                at: CGPoint(x: Layout.margin + 40, y: currentY + 28), withAttributes: sub)
        } else if let best = bestMatch {
            let attrs: [NSAttributedString.Key: Any] = [.font: Fonts.sectionTitle, .foregroundColor: Colors.gold]
            ("Final Recommendation: \(best.partner.name) (\(best.adjustedScore)/36)" as NSString).draw(
                at: CGPoint(x: Layout.margin + 40, y: currentY + 8), withAttributes: attrs)
            let sub: [NSAttributedString.Key: Any] = [.font: Fonts.body, .foregroundColor: Colors.textSecondary]
            let oneLiner = best.oneLiner ?? "Highest compatibility. All doshas safe."
            (oneLiner as NSString).draw(
                in: CGRect(x: Layout.margin + 40, y: currentY + 28, width: Layout.contentWidth - 60, height: 16), withAttributes: sub)
        }
        currentY += cardHeight + 2
    }
    
    private func drawPartnerScoreCards() {
        let ctx = UIGraphicsGetCurrentContext()!
        let count = sortedResults.count
        let spacing: CGFloat = 8
        let cardWidth = (Layout.contentWidth - spacing * CGFloat(count - 1)) / CGFloat(count)
        let cardHeight: CGFloat = 90
        
        ensureSpace(cardHeight + 8)
        
        for (i, result) in sortedResults.enumerated() {
            let x = Layout.margin + (cardWidth + spacing) * CGFloat(i)
            let cardRect = CGRect(x: x, y: currentY, width: cardWidth, height: cardHeight)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
            ctx.setFillColor(Colors.cardBg.cgColor)
            ctx.addPath(path.cgPath); ctx.fillPath()
            
            let borderColor = result.isRecommended ? Colors.gold.withAlphaComponent(0.4) : Colors.red.withAlphaComponent(0.3)
            ctx.setStrokeColor(borderColor.cgColor); ctx.setLineWidth(1)
            ctx.addPath(path.cgPath); ctx.strokePath()
            
            // Name
            let nameAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.smallBold, .foregroundColor: UIColor.white]
            let name = result.partner.name.uppercased()
            let nameSize = (name as NSString).size(withAttributes: nameAttrs)
            (name as NSString).draw(at: CGPoint(x: x + (cardWidth - nameSize.width) / 2, y: currentY + 8), withAttributes: nameAttrs)
            
            // Status dot
            ctx.setFillColor((result.isRecommended ? Colors.green : Colors.red).cgColor)
            ctx.fillEllipse(in: CGRect(x: x + cardWidth / 2 - 3, y: currentY + 22, width: 6, height: 6))
            
            // Score
            let scoreAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia-Bold", size: 20) ?? .boldSystemFont(ofSize: 20),
                .foregroundColor: Colors.gold
            ]
            let scoreText = "\(result.adjustedScore)/\(result.maxScore)*"
            let scoreSize = (scoreText as NSString).size(withAttributes: scoreAttrs)
            (scoreText as NSString).draw(at: CGPoint(x: x + (cardWidth - scoreSize.width) / 2, y: currentY + 32), withAttributes: scoreAttrs)
            
            // Actual
            let actualAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tiny, .foregroundColor: Colors.textSecondary]
            let actualText = "\(result.overallScore)/\(result.maxScore) actual"
            let actualSize = (actualText as NSString).size(withAttributes: actualAttrs)
            (actualText as NSString).draw(at: CGPoint(x: x + (cardWidth - actualSize.width) / 2, y: currentY + 56), withAttributes: actualAttrs)
            
            // Status
            let statusAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.smallBold, .foregroundColor: result.isRecommended ? Colors.green : Colors.red]
            let statusText = result.isRecommended ? (i == 0 ? "★ Best" : "Recommended") : "✗ Not Rec"
            let statusSize = (statusText as NSString).size(withAttributes: statusAttrs)
            (statusText as NSString).draw(at: CGPoint(x: x + (cardWidth - statusSize.width) / 2, y: currentY + 72), withAttributes: statusAttrs)
        }
        
        currentY += cardHeight + 2
        
        // Footnote
        let noteAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 7), .foregroundColor: Colors.textSecondary.withAlphaComponent(0.5)]
        let noteText = "*After dosha cancellation adjustment"
        let noteSize = (noteText as NSString).size(withAttributes: noteAttrs)
        (noteText as NSString).draw(at: CGPoint(x: Layout.margin + (Layout.contentWidth - noteSize.width) / 2, y: currentY), withAttributes: noteAttrs)
        currentY += 12
    }
    
    private func drawScoreBarChart() {
        let ctx = UIGraphicsGetCurrentContext()!
        let barHeight: CGFloat = 14
        let barSpacing: CGFloat = 6
        let labelWidth: CGFloat = 70
        let barAreaWidth = Layout.contentWidth - labelWidth - 50
        let maxScore = sortedResults.first?.maxScore ?? 36
        
        ensureSpace(CGFloat(sortedResults.count) * (barHeight + barSpacing) + 30)
        
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.smallBold, .foregroundColor: Colors.textSecondary]
        ("SCORE COMPARISON" as NSString).draw(at: CGPoint(x: Layout.margin, y: currentY), withAttributes: labelAttrs)
        currentY += 14
        
        for result in sortedResults {
            let nameAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.small, .foregroundColor: Colors.text]
            (result.partner.name as NSString).draw(at: CGPoint(x: Layout.margin, y: currentY + 1), withAttributes: nameAttrs)
            
            let barX = Layout.margin + labelWidth
            
            // Bar bg
            let bgPath = UIBezierPath(roundedRect: CGRect(x: barX, y: currentY, width: barAreaWidth, height: barHeight), cornerRadius: 3)
            ctx.setFillColor(Colors.tableAltRow.cgColor)
            ctx.addPath(bgPath.cgPath); ctx.fillPath()
            
            // Adjusted bar
            let adjWidth = barAreaWidth * CGFloat(result.adjustedScore) / CGFloat(maxScore)
            let adjColor = result.isRecommended ? Colors.gold : Colors.red.withAlphaComponent(0.7)
            let adjPath = UIBezierPath(roundedRect: CGRect(x: barX, y: currentY, width: adjWidth, height: barHeight), cornerRadius: 3)
            ctx.setFillColor(adjColor.withAlphaComponent(0.6).cgColor)
            ctx.addPath(adjPath.cgPath); ctx.fillPath()
            
            // Score label
            let scoreAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.smallBold, .foregroundColor: UIColor.white]
            ("\(result.adjustedScore)/\(maxScore)" as NSString).draw(at: CGPoint(x: barX + adjWidth + 4, y: currentY + 1), withAttributes: scoreAttrs)
            
            currentY += barHeight + barSpacing
        }
        currentY += 4
    }
    
    // MARK: - Koota Breakdown Table
    
    private func drawKootaBreakdownTable() {
        drawSectionTitle("DETAILED KOOTA BREAKDOWN")
        
        let ctx = UIGraphicsGetCurrentContext()!
        let count = sortedResults.count
        let areaColWidth: CGFloat = 72
        let partnerColWidth = (Layout.contentWidth - areaColWidth) / CGFloat(count)
        let tableX = Layout.margin
        let headerRowHeight: CGFloat = 22
        let rowHeight: CGFloat = 20
        let cellPadding: CGFloat = 3
        
        let kutaOrder = ["Varna", "Vashya", "Tara", "Yoni", "Maitri", "Gana", "Bhakoot", "Nadi"]
        let totalHeight = headerRowHeight + CGFloat(kutaOrder.count + 3) * rowHeight
        ensureSpace(min(totalHeight + 20, 300))
        
        let tableStartY = currentY
        
        // Header
        ctx.setFillColor(Colors.tableHeaderBg.cgColor)
        ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: headerRowHeight))
        
        let headerAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tableHeader, .foregroundColor: Colors.gold]
        ("Area" as NSString).draw(in: CGRect(x: tableX + 6, y: currentY + cellPadding, width: areaColWidth - 12, height: headerRowHeight - cellPadding * 2), withAttributes: headerAttrs)
        
        for (i, result) in sortedResults.enumerated() {
            let x = tableX + areaColWidth + partnerColWidth * CGFloat(i)
            let firstName = result.partner.name.components(separatedBy: " ").first ?? result.partner.name
            (firstName as NSString).draw(in: CGRect(x: x + 6, y: currentY + cellPadding, width: partnerColWidth - 12, height: headerRowHeight - cellPadding * 2), withAttributes: headerAttrs)
        }
        currentY += headerRowHeight
        
        // Kuta rows
        for (rowIndex, kutaName) in kutaOrder.enumerated() {
            if rowIndex % 2 == 1 {
                ctx.setFillColor(Colors.tableAltRow.cgColor)
                ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: rowHeight))
            }
            
            let areaAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tableCellBold, .foregroundColor: Colors.textSecondary]
            (kutaName as NSString).draw(in: CGRect(x: tableX + 6, y: currentY + cellPadding, width: areaColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: areaAttrs)
            
            for (i, result) in sortedResults.enumerated() {
                let x = tableX + areaColWidth + partnerColWidth * CGFloat(i)
                let kuta = result.result.kutas.first(where: { $0.name.lowercased() == kutaName.lowercased() })
                
                if let k = kuta {
                    let cancelReason = result.doshaCancellationReason(for: kutaName)
                    let isCancelled = cancelReason != nil
                    let isDosha = k.points == 0 && k.maxPoints >= 6
                    let hasRejection = result.rejectionReasons.contains { $0.contains(kutaName) }
                    
                    let cellText: String
                    let cellColor: UIColor
                    if isCancelled {
                        cellText = "\(k.points)→\(k.maxPoints) ✓"
                        cellColor = Colors.green
                    } else if isDosha && hasRejection {
                        cellText = "\(k.points) ✗"
                        cellColor = Colors.red
                    } else if k.points == k.maxPoints {
                        cellText = "\(k.points) ✓"
                        cellColor = Colors.green
                    } else if k.points == 0 {
                        cellText = "\(k.points) ▲"
                        cellColor = Colors.orange
                    } else {
                        cellText = "\(k.points)"
                        cellColor = Colors.text
                    }
                    
                    let cellAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tableCell, .foregroundColor: cellColor]
                    (cellText as NSString).draw(in: CGRect(x: x + 6, y: currentY + cellPadding, width: partnerColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: cellAttrs)
                } else {
                    let dashAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tableCell, .foregroundColor: Colors.textSecondary.withAlphaComponent(0.3)]
                    ("—" as NSString).draw(in: CGRect(x: x + 6, y: currentY + cellPadding, width: partnerColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: dashAttrs)
                }
            }
            
            ctx.setStrokeColor(Colors.tableBorder.cgColor); ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: tableX, y: currentY + rowHeight))
            ctx.addLine(to: CGPoint(x: tableX + Layout.contentWidth, y: currentY + rowHeight))
            ctx.strokePath()
            currentY += rowHeight
        }
        
        // Mangal row
        if kutaOrder.count % 2 == 1 {
            ctx.setFillColor(Colors.tableAltRow.cgColor)
            ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: rowHeight))
        }
        let mangalAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tableCellBold, .foregroundColor: Colors.textSecondary]
        ("Manglik" as NSString).draw(in: CGRect(x: tableX + 6, y: currentY + cellPadding, width: areaColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: mangalAttrs)
        
        for (i, result) in sortedResults.enumerated() {
            let x = tableX + areaColWidth + partnerColWidth * CGFloat(i)
            let hasMangalRejection = result.rejectionReasons.contains { $0.contains("Mangal") }
            let mangalCompat = result.result.analysisData?.joint?.mangalCompatibility
            let cancellationOccurs = (mangalCompat?["cancellation"]?.value as? [String: Any])?["occurs"] as? Bool
            let compatCategory = mangalCompat?["compatibility_category"]?.value as? String
            
            let mangalText: String; let mangalColor: UIColor
            if hasMangalRejection {
                mangalText = "Active ✗"; mangalColor = Colors.red
            } else if cancellationOccurs == true {
                mangalText = "Cancelled ✓"; mangalColor = Colors.green
            } else if let cat = compatCategory {
                mangalText = cat.prefix(1).uppercased() + cat.dropFirst().lowercased() + " ✓"
                mangalColor = (cat.lowercased() == "excellent" || cat.lowercased() == "good") ? Colors.green : Colors.orange
            } else {
                mangalText = "None ✓"; mangalColor = Colors.green
            }
            
            let cellAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tableCell, .foregroundColor: mangalColor]
            (mangalText as NSString).draw(in: CGRect(x: x + 6, y: currentY + cellPadding, width: partnerColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: cellAttrs)
        }
        ctx.setStrokeColor(Colors.tableBorder.cgColor); ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: tableX, y: currentY + rowHeight))
        ctx.addLine(to: CGPoint(x: tableX + Layout.contentWidth, y: currentY + rowHeight))
        ctx.strokePath()
        currentY += rowHeight
        
        // Actual total
        ctx.setFillColor(Colors.tableHeaderBg.cgColor)
        ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: rowHeight))
        let totalAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tableCellBold, .foregroundColor: UIColor.white]
        ("Actual" as NSString).draw(in: CGRect(x: tableX + 6, y: currentY + cellPadding, width: areaColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: totalAttrs)
        for (i, result) in sortedResults.enumerated() {
            let x = tableX + areaColWidth + partnerColWidth * CGFloat(i)
            ("\(result.overallScore)/\(result.maxScore)" as NSString).draw(in: CGRect(x: x + 6, y: currentY + cellPadding, width: partnerColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: totalAttrs)
        }
        currentY += rowHeight
        
        // Adjusted total
        ctx.setFillColor(Colors.goldLight.cgColor)
        ctx.fill(CGRect(x: tableX, y: currentY, width: Layout.contentWidth, height: rowHeight))
        let adjLabelAttrs: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Georgia-Bold", size: 10) ?? .boldSystemFont(ofSize: 10), .foregroundColor: Colors.gold]
        ("Adjusted" as NSString).draw(in: CGRect(x: tableX + 6, y: currentY + cellPadding, width: areaColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: adjLabelAttrs)
        for (i, result) in sortedResults.enumerated() {
            let x = tableX + areaColWidth + partnerColWidth * CGFloat(i)
            let adjColor = result.isRecommended ? Colors.gold : Colors.red
            let adjAttrs: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Georgia-Bold", size: 10) ?? .boldSystemFont(ofSize: 10), .foregroundColor: adjColor]
            ("\(result.adjustedScore)/\(result.maxScore)" as NSString).draw(in: CGRect(x: x + 6, y: currentY + cellPadding, width: partnerColWidth - 12, height: rowHeight - cellPadding * 2), withAttributes: adjAttrs)
        }
        currentY += rowHeight
        
        // Outer border + vertical lines
        let tableRect = CGRect(x: tableX, y: tableStartY, width: Layout.contentWidth, height: currentY - tableStartY)
        ctx.setStrokeColor(Colors.tableBorder.cgColor); ctx.setLineWidth(1)
        ctx.stroke(tableRect)
        ctx.setLineWidth(0.5)
        var colX = tableX + areaColWidth
        for _ in 0..<count {
            ctx.move(to: CGPoint(x: colX, y: tableRect.minY))
            ctx.addLine(to: CGPoint(x: colX, y: tableRect.maxY))
            colX += partnerColWidth
        }
        ctx.strokePath()
        
        // Legend
        currentY += 6
        let legendAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.tiny, .foregroundColor: Colors.textSecondary.withAlphaComponent(0.5)]
        ("✓ Full/Cancelled   ✗ Active dosha   ▲ Caution   0→7 Adjusted from cancellation" as NSString).draw(
            in: CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 14), withAttributes: legendAttrs)
        currentY += 14
    }
    
    // MARK: - Per-Partner Analysis (with Markdown Rendering)
    
    private func drawPartnerAnalysis(_ result: ComparisonResult) {
        drawSectionTitle("ANALYSIS — \(result.partner.name.uppercased())")
        
        let ctx = UIGraphicsGetCurrentContext()!
        
        // Status card
        let statusHeight: CGFloat = 40
        ensureSpace(statusHeight + 4)
        let statusRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: statusHeight)
        let statusPath = UIBezierPath(roundedRect: statusRect, cornerRadius: 8)
        ctx.setFillColor(Colors.cardBg.cgColor)
        ctx.addPath(statusPath.cgPath); ctx.fillPath()
        let borderColor = result.isRecommended ? Colors.gold.withAlphaComponent(0.3) : Colors.red.withAlphaComponent(0.3)
        ctx.setStrokeColor(borderColor.cgColor); ctx.setLineWidth(1)
        ctx.addPath(statusPath.cgPath); ctx.strokePath()
        
        // Score
        let scoreAttrs: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Georgia-Bold", size: 18) ?? .boldSystemFont(ofSize: 18), .foregroundColor: Colors.gold]
        ("\(result.adjustedScore)/\(result.maxScore)" as NSString).draw(at: CGPoint(x: Layout.margin + 12, y: currentY + 10), withAttributes: scoreAttrs)
        
        // Status label
        let statusLabelAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.bodyBold, .foregroundColor: result.isRecommended ? Colors.green : Colors.red]
        (result.statusLabel as NSString).draw(at: CGPoint(x: Layout.margin + 90, y: currentY + 10), withAttributes: statusLabelAttrs)
        
        if result.adjustedScore != result.overallScore {
            let noteAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.small, .foregroundColor: Colors.textSecondary]
            ("Ashtakoot: \(result.overallScore)/\(result.maxScore) · Adjusted: \(result.adjustedScore)/\(result.maxScore)" as NSString).draw(
                at: CGPoint(x: Layout.margin + 90, y: currentY + 26), withAttributes: noteAttrs)
        }
        currentY += statusHeight + 8
        
        // Rejection reasons
        if !result.isRecommended && !result.rejectionReasons.isEmpty {
            ensureSpace(20 + CGFloat(result.rejectionReasons.count) * 14)
            let reasonTitleAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.smallBold, .foregroundColor: Colors.red.withAlphaComponent(0.8)]
            ("WHY NOT RECOMMENDED:" as NSString).draw(at: CGPoint(x: Layout.margin, y: currentY), withAttributes: reasonTitleAttrs)
            currentY += 14
            
            for reason in result.rejectionReasons {
                ensureSpace(16)
                let formattedReason = formatReason(reason, partnerName: result.partner.name)
                let bulletAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.small, .foregroundColor: Colors.red]
                ("✗" as NSString).draw(at: CGPoint(x: Layout.margin + 4, y: currentY), withAttributes: bulletAttrs)
                
                let textAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.small, .foregroundColor: Colors.textSecondary]
                let boundingRect = (formattedReason as NSString).boundingRect(with: CGSize(width: Layout.contentWidth - 24, height: 80), options: [.usesLineFragmentOrigin], attributes: textAttrs, context: nil)
                (formattedReason as NSString).draw(in: CGRect(x: Layout.margin + 16, y: currentY, width: Layout.contentWidth - 24, height: boundingRect.height + 2), withAttributes: textAttrs)
                currentY += max(14, boundingRect.height + 4)
            }
            currentY += 4
        }
        
        // LLM summary — rendered with markdown parser for proper tables
        let summary = result.result.summary
        if !summary.isEmpty {
            drawMarkdownContent(summary)
        }
        
        currentY += 6
    }
    
    // MARK: - Markdown Content Renderer (from CompatibilityPDFRenderer)
    
    private func drawMarkdownContent(_ content: String) {
        let lines = content.components(separatedBy: "\n")
        var i = 0
        
        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                addSpacing(4)
                i += 1
                continue
            }
            
            // Markdown table: consecutive pipe-delimited rows
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                var tableRows: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if t.hasPrefix("|") && t.hasSuffix("|") {
                        let inner = t.dropFirst().dropLast().trimmingCharacters(in: .whitespaces)
                        let isSeparator = inner.allSatisfy { $0 == "-" || $0 == "|" || $0 == " " || $0 == ":" }
                        if !isSeparator { tableRows.append(t) }
                        i += 1
                    } else { break }
                }
                if !tableRows.isEmpty { drawMarkdownTable(tableRows) }
                continue
            }
            
            // Skip dividers
            if trimmed.hasPrefix("---") { i += 1; continue }
            
            // ### headers — draw as bold gold section headers
            // Keep header + at least 100px of following content together
            if trimmed.hasPrefix("###") {
                let headerText = trimmed.replacingOccurrences(of: "###", with: "").trimmingCharacters(in: .whitespaces)
                ensureSpace(110)  // Prevent orphaned headers — keep with following content
                addSpacing(8)
                drawHorizontalLine(at: currentY, from: Layout.margin, to: Layout.margin + Layout.contentWidth, color: Colors.gold.withAlphaComponent(0.1))
                addSpacing(4)
                let headerAttrs: [NSAttributedString.Key: Any] = [.font: Fonts.bodyBold, .foregroundColor: Colors.gold]
                let boundingRect = (headerText as NSString).boundingRect(with: CGSize(width: Layout.contentWidth, height: 100), options: [.usesLineFragmentOrigin], attributes: headerAttrs, context: nil)
                (headerText as NSString).draw(in: CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: boundingRect.height), withAttributes: headerAttrs)
                currentY += boundingRect.height + 4
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
                text = "•  " + String(trimmed.dropFirst(2))
                indent = 10
            } else if trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                indent = 10
            }
            
            // Mixed bold
            if text.contains("**") {
                drawRichTextLine(text, baseFont: font, baseColor: color, indent: indent)
                i += 1
                continue
            }
            
            let textAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            let availWidth = Layout.contentWidth - indent
            let boundingRect = (text as NSString).boundingRect(with: CGSize(width: availWidth, height: 1000), options: [.usesLineFragmentOrigin], attributes: textAttrs, context: nil)
            ensureSpace(boundingRect.height + 2)
            (text as NSString).draw(in: CGRect(x: Layout.margin + indent, y: currentY, width: availWidth, height: boundingRect.height), withAttributes: textAttrs)
            currentY += boundingRect.height + 2
            i += 1
        }
    }
    
    private func drawBoldLabelLine(_ line: String) {
        guard let boldEnd = line.range(of: ":**") else {
            drawRichTextLine(line, baseFont: Fonts.body, baseColor: Colors.text, indent: 0)
            return
        }
        let labelPart = String(line[line.index(line.startIndex, offsetBy: 2)..<boldEnd.lowerBound]) + ":"
        let valuePart = String(line[boldEnd.upperBound...]).trimmingCharacters(in: .whitespaces)
        
        let attrString = NSMutableAttributedString()
        attrString.append(NSAttributedString(string: labelPart + " ", attributes: [.font: Fonts.bodyBold, .foregroundColor: Colors.text]))
        attrString.append(NSAttributedString(string: valuePart, attributes: [.font: Fonts.body, .foregroundColor: Colors.text]))
        
        let boundingRect = attrString.boundingRect(with: CGSize(width: Layout.contentWidth, height: 1000), options: [.usesLineFragmentOrigin], context: nil)
        ensureSpace(boundingRect.height + 2)
        attrString.draw(in: CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: boundingRect.height))
        currentY += boundingRect.height + 2
    }
    
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
        ensureSpace(boundingRect.height + 2)
        attrString.draw(in: CGRect(x: Layout.margin + indent, y: currentY, width: availWidth, height: boundingRect.height))
        currentY += boundingRect.height + 2
    }
    
    private func drawMarkdownTable(_ rows: [String]) {
        guard !rows.isEmpty else { return }
        
        let parsedRows = rows.map { row -> [String] in
            row.components(separatedBy: "|").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        let colCount = parsedRows.map { $0.count }.max() ?? 1
        guard colCount > 0 else { return }
        
        let tableX = Layout.margin + 4
        let tableWidth = Layout.contentWidth - 8
        let cellPadding: CGFloat = 4
        let minRowHeight: CGFloat = 18
        
        // Smart column widths
        var colWidths: [CGFloat] = Array(repeating: tableWidth / CGFloat(colCount), count: colCount)
        if colCount > 1 {
            let minColWidth: CGFloat = 60
            var maxWidthPerCol: [CGFloat] = Array(repeating: minColWidth, count: colCount)
            for (rowIdx, cells) in parsedRows.enumerated() {
                let font = rowIdx == 0 ? Fonts.tableHeader : Fonts.tableCell
                for (colIdx, cell) in cells.enumerated() {
                    if colIdx >= colCount - 1 { break }
                    let size = (cell as NSString).size(withAttributes: [.font: font])
                    maxWidthPerCol[colIdx] = max(maxWidthPerCol[colIdx], size.width + 16)
                }
            }
            for i in 0..<(colCount - 1) {
                maxWidthPerCol[i] = min(maxWidthPerCol[i], tableWidth * 0.35)
            }
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
                let w = colWidths[colIdx] - 10
                let rect = (cell as NSString).boundingRect(with: CGSize(width: w, height: 200), options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
                maxH = max(maxH, rect.height + cellPadding * 2 + 2)
            }
            rowHeights.append(maxH)
        }
        
        ensureSpace(min(rowHeights.reduce(0, +) + 6, 180))
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let tableStartY = currentY
        
        for (rowIndex, cells) in parsedRows.enumerated() {
            let isHeader = rowIndex == 0
            let isAlt = rowIndex % 2 == 0 && !isHeader
            let rowH = rowHeights[rowIndex]
            
            ensureSpace(rowH + 2)
            
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
                (cell as NSString).draw(in: CGRect(x: cellX + 5, y: currentY + cellPadding, width: colWidths[colIndex] - 10, height: rowH - cellPadding * 2), withAttributes: cellAttrs)
                cellX += colWidths[colIndex]
            }
            
            ctx.setStrokeColor(Colors.tableBorder.cgColor); ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: tableX, y: currentY + rowH))
            ctx.addLine(to: CGPoint(x: tableX + tableWidth, y: currentY + rowH))
            ctx.strokePath()
            currentY += rowH
        }
        
        // Outer border + column lines
        let tableRect = CGRect(x: tableX, y: tableStartY, width: tableWidth, height: currentY - tableStartY)
        ctx.setStrokeColor(Colors.tableBorder.cgColor); ctx.setLineWidth(0.5)
        ctx.stroke(tableRect)
        var colX = tableX
        for i in 0..<(colCount - 1) {
            colX += colWidths[i]
            ctx.move(to: CGPoint(x: colX, y: tableRect.minY))
            ctx.addLine(to: CGPoint(x: colX, y: tableRect.maxY))
        }
        ctx.strokePath()
        currentY += 4
    }
    
    // MARK: - Disclaimer
    
    private func drawDisclaimer() {
        let disclaimerHeight: CGFloat = 60
        ensureSpace(disclaimerHeight)
        
        drawHorizontalLine(at: currentY, from: Layout.margin + 80, to: Layout.margin + Layout.contentWidth - 80, color: Colors.divider)
        currentY += 12
        
        drawCenteredText("ⓘ AI-Generated Analysis", at: currentY, font: Fonts.small, color: Colors.gold.withAlphaComponent(0.5))
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
        
        drawCenteredText("© 2026 Destiny AI Astrology · destinyaiastrology.com", at: currentY, font: Fonts.tiny, color: Colors.textSecondary.withAlphaComponent(0.6))
    }
    
    // MARK: - Drawing Helpers
    
    private func drawSectionTitle(_ title: String) {
        ensureSpace(36)
        drawOrnamentalDivider()
        let attrs: [NSAttributedString.Key: Any] = [.font: Fonts.sectionTitle, .foregroundColor: Colors.gold]
        (title as NSString).draw(in: CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 20), withAttributes: attrs)
        currentY += 22
        drawHorizontalLine(at: currentY - 2, from: Layout.margin, to: Layout.margin + Layout.contentWidth, color: Colors.gold.withAlphaComponent(0.15))
        currentY += 4
    }
    
    private func drawOrnamentalDivider() {
        let ctx = UIGraphicsGetCurrentContext()!
        let centerX = Layout.pageWidth / 2
        let lineY = currentY + 4
        ctx.setStrokeColor(Colors.divider.cgColor); ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: centerX - 50, y: lineY))
        ctx.addLine(to: CGPoint(x: centerX - 6, y: lineY)); ctx.strokePath()
        drawDiamond(at: CGPoint(x: centerX, y: lineY), size: 4, color: Colors.gold.withAlphaComponent(0.6))
        ctx.move(to: CGPoint(x: centerX + 6, y: lineY))
        ctx.addLine(to: CGPoint(x: centerX + 50, y: lineY)); ctx.strokePath()
        currentY += 10
    }
    
    private func drawDiamond(at center: CGPoint, size: CGFloat, color: UIColor) {
        let ctx = UIGraphicsGetCurrentContext()!
        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: center.y - size))
        path.addLine(to: CGPoint(x: center.x + size, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + size))
        path.addLine(to: CGPoint(x: center.x - size, y: center.y))
        path.close()
        ctx.setFillColor(color.cgColor)
        ctx.addPath(path.cgPath); ctx.fillPath()
    }
    
    private func drawHorizontalLine(at y: CGFloat, from x1: CGFloat, to x2: CGFloat, color: UIColor) {
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setStrokeColor(color.cgColor); ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: x1, y: y))
        ctx.addLine(to: CGPoint(x: x2, y: y)); ctx.strokePath()
    }
    
    private func drawCenteredText(_ text: String, at y: CGFloat, font: UIFont, color: UIColor, kern: CGFloat = 0) {
        var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        if kern > 0 { attrs[.kern] = kern as NSNumber }
        let size = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: (Layout.pageWidth - size.width) / 2, y: y), withAttributes: attrs)
    }
    
    private func formatReason(_ reason: String, partnerName: String) -> String {
        let userFirst = userName.components(separatedBy: " ").first ?? userName
        let partnerFirst = partnerName.components(separatedBy: " ").first ?? partnerName
        return reason
            .replacingOccurrences(of: "Boy:", with: "\(userFirst):")
            .replacingOccurrences(of: "Girl:", with: "\(partnerFirst):")
            .replacingOccurrences(of: "Boy ", with: "\(userFirst) ")
            .replacingOccurrences(of: "Girl ", with: "\(partnerFirst) ")
    }
}
