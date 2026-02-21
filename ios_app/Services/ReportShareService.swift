import SwiftUI
import UIKit

// MARK: - Report Share Service
/// Handles PDF generation and social media sharing for compatibility reports
final class ReportShareService {
    
    static let shared = ReportShareService()
    private init() {}
    
    // MARK: - PDF Generation
    
    /// Generates a PDF from a SwiftUI view by rendering it as an image-based PDF
    /// Uses ImageRenderer (iOS 16+) for high-quality rendering
    @MainActor
    func generatePDF<V: View>(
        from view: V,
        pageSize: CGSize = CGSize(width: 612, height: 792), // US Letter
        fileName: String = "Destiny_AI_Compatibility_Report"
    ) -> URL? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).pdf")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: tempURL)
        
        guard renderer.cgImage != nil else { return nil }
        
        var success = false
        renderer.render { size, renderContext in
            var mediaBox = CGRect(origin: .zero, size: size)
            
            guard let consumer = CGDataConsumer(url: tempURL as CFURL),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                return
            }
            
            pdfContext.beginPDFPage(nil)
            renderContext(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
            success = true
        }
        
        return success ? tempURL : nil
    }
    
    /// Generates a multi-page PDF by splitting a tall view into letter-sized pages
    @MainActor
    func generateMultiPagePDF<V: View>(
        from view: V,
        width: CGFloat = 390,
        fileName: String = "Destiny_AI_Compatibility_Report"
    ) -> URL? {
        let renderer = ImageRenderer(content: view.frame(width: width))
        renderer.scale = 2.0 // High quality but not excessive
        
        guard let fullImage = renderer.cgImage else { return nil }
        
        let imageWidth = CGFloat(fullImage.width)
        let imageHeight = CGFloat(fullImage.height)
        let pageWidth: CGFloat = 612 // US Letter
        let scaleFactor = pageWidth / imageWidth
        let scaledHeight = imageHeight * scaleFactor
        let pageHeight: CGFloat = 792 // US Letter height
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).pdf")
        try? FileManager.default.removeItem(at: tempURL)
        
        let pageCount = Int(ceil(scaledHeight / pageHeight))
        
        UIGraphicsBeginPDFContextToFile(tempURL.path, .zero, nil)
        
        for page in 0..<pageCount {
            let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            
            guard let context = UIGraphicsGetCurrentContext() else { continue }
            
            // Flip coordinate system for Core Graphics
            context.translateBy(x: 0, y: pageHeight)
            context.scaleBy(x: 1, y: -1)
            
            // Calculate which portion of the image to draw
            let yOffset = CGFloat(page) * pageHeight
            let drawRect = CGRect(
                x: 0,
                y: -(scaledHeight - pageHeight - yOffset),
                width: pageWidth,
                height: scaledHeight
            )
            
            context.draw(fullImage, in: drawRect)
        }
        
        UIGraphicsEndPDFContext()
        
        return FileManager.default.fileExists(atPath: tempURL.path) ? tempURL : nil
    }
    
    /// Generates a section-aware multi-page PDF where each section is kept whole
    /// (not split across page boundaries) whenever possible
    @MainActor
    func generateSectionAwarePDF(
        sections: [AnyView],
        width: CGFloat = 390,
        fileName: String = "Report",
        pageBackgroundColor: UIColor = UIColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1.0)
    ) -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 24
        let sectionSpacing: CGFloat = 8
        let contentWidth = pageWidth - 2 * margin
        let contentHeight = pageHeight - 2 * margin
        let renderScale: CGFloat = 2.0
        
        // 1. Render each section to get CGImage + display height
        var rendered: [(image: CGImage, displayHeight: CGFloat)] = []
        for section in sections {
            let renderer = ImageRenderer(content: section.frame(width: width))
            renderer.scale = renderScale
            guard let img = renderer.cgImage else { continue }
            let naturalW = CGFloat(img.width) / renderScale
            let naturalH = CGFloat(img.height) / renderScale
            let displayH = naturalH * (contentWidth / naturalW)
            rendered.append((image: img, displayHeight: displayH))
        }
        guard !rendered.isEmpty else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).pdf")
        try? FileManager.default.removeItem(at: tempURL)
        
        // 2. Compose pages
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        UIGraphicsBeginPDFContextToFile(tempURL.path, .zero, nil)
        
        var currentY = pageHeight // Force first page start
        
        func startPage() {
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            if let ctx = UIGraphicsGetCurrentContext() {
                ctx.setFillColor(pageBackgroundColor.cgColor)
                ctx.fill(pageRect)
            }
            currentY = margin
        }
        
        func drawImage(_ img: CGImage, height: CGFloat) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }
            ctx.saveGState()
            ctx.translateBy(x: margin, y: currentY + height)
            ctx.scaleBy(x: 1, y: -1)
            ctx.draw(img, in: CGRect(x: 0, y: 0, width: contentWidth, height: height))
            ctx.restoreGState()
        }
        
        for (i, section) in rendered.enumerated() {
            let spacing: CGFloat = i > 0 ? sectionSpacing : 0
            let needed = spacing + section.displayHeight
            
            // Need new page?
            if currentY + needed > pageHeight - margin {
                startPage()
            }
            
            if i > 0 && currentY > margin { currentY += sectionSpacing }
            
            // Handle oversized sections (taller than content area)
            if section.displayHeight > contentHeight {
                var remaining = section.displayHeight
                var srcY: CGFloat = 0
                while remaining > 0 {
                    let avail = pageHeight - margin - currentY
                    let chunk = min(avail, remaining)
                    let cropY = srcY / section.displayHeight * CGFloat(section.image.height)
                    let cropH = chunk / section.displayHeight * CGFloat(section.image.height)
                    if let cropped = section.image.cropping(to: CGRect(x: 0, y: cropY, width: CGFloat(section.image.width), height: cropH)) {
                        drawImage(cropped, height: chunk)
                    }
                    currentY += chunk
                    srcY += chunk
                    remaining -= chunk
                    if remaining > 0 { startPage() }
                }
            } else {
                drawImage(section.image, height: section.displayHeight)
                currentY += section.displayHeight
            }
        }
        
        UIGraphicsEndPDFContext()
        return FileManager.default.fileExists(atPath: tempURL.path) ? tempURL : nil
    }
    
    // MARK: - Share Card Generation
    
    /// Renders a SwiftUI view as a UIImage for social sharing
    @MainActor
    func generateShareImage<V: View>(from view: V, size: CGSize = CGSize(width: 1080, height: 1080)) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 1.0 // Already at target resolution
        return renderer.uiImage
    }
    
    // MARK: - Share Sheet
    
    /// Presents a UIActivityViewController with the given items
    @MainActor
    func presentShareSheet(items: [Any], excludedTypes: [UIActivity.ActivityType] = []) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.excludedActivityTypes = excludedTypes
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // Find the topmost presented view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        topVC.present(activityVC, animated: true)
    }
    
    // MARK: - Convenience Methods
    
    /// Share a PDF file
    @MainActor
    func sharePDF(url: URL) {
        presentShareSheet(items: [url])
    }
    
    /// Share an image (for social media cards)
    @MainActor
    func shareImage(_ image: UIImage, text: String? = nil) {
        var items: [Any] = [image]
        if let text = text {
            items.insert(text, at: 0)
        }
        presentShareSheet(items: items)
    }
    
    // MARK: - Save to Files (Document Picker)
    
    /// Presents the iOS Files picker directly for saving a file
    @MainActor
    func presentSaveToFiles(fileURL: URL) {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        picker.shouldShowFileExtensions = true
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // Find the topmost presented view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        topVC.present(picker, animated: true)
    }
    
    // MARK: - File Naming
    
    /// Generates a formatted filename for compatibility reports
    /// Format: "Compatibility Report – Name1 and Name2 – YYYY-MM-DD"
    func reportFileName(boyName: String, girlName: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())
        return "Compatibility Report – \(boyName) and \(girlName) – \(dateStr)"
    }
}
