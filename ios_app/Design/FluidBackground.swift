//
//  FluidBackground.swift
//  ios_app
//
//  Pure SwiftUI fluid background effect (no Metal required)
//  Creates a "Liquid Gold" cosmic effect using Canvas API
//

import SwiftUI

// MARK: - Liquid Gold Fluid Background
/// A premium animated fluid background using Canvas API
struct LiquidGoldBackground: View {
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                // Draw fluid blobs
                drawFluidBlobs(context: context, size: size, time: time)
            }
            .background(AppTheme.Colors.mainBackground)
        }
    }
    
    private func drawFluidBlobs(context: GraphicsContext, size: CGSize, time: Double) {
        let goldColor = Color(red: 0.83, green: 0.69, blue: 0.22)
        
        // Create multiple animated gold blobs
        for i in 0..<5 {
            let baseX = size.width * (0.2 + Double(i) * 0.15)
            let baseY = size.height * (0.3 + Double(i) * 0.1)
            
            // Organic movement using sin/cos
            let offsetX = sin(time * 0.3 + Double(i) * 0.5) * 50
            let offsetY = cos(time * 0.25 + Double(i) * 0.7) * 30
            
            let center = CGPoint(x: baseX + offsetX, y: baseY + offsetY)
            let radius = 80 + sin(time * 0.2 + Double(i)) * 20
            
            // Radial gradient blob
            let gradient = Gradient(colors: [
                goldColor.opacity(0.08),
                goldColor.opacity(0.03),
                Color.clear
            ])
            
            context.fill(
                Circle().path(in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )),
                with: .radialGradient(
                    gradient,
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
        }
    }
}

// MARK: - Shimmer Overlay View
struct ShimmerOverlayView: View {
    @State private var offset: CGFloat = -200
    
    var body: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.3), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 80)
        .offset(x: offset)
        .blendMode(.overlay)
        .onAppear {
            withAnimation(.linear(duration: AppTheme.Splash.shimmerDuration).repeatForever(autoreverses: false)) {
                offset = 200
            }
        }
    }
}

// MARK: - Pulsing Glow View
struct PulsingGlowView: View {
    @State private var isPulsing = false
    let color: Color
    let size: CGFloat
    let blurRadius: CGFloat
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: blurRadius)
            .scaleEffect(isPulsing ? AppTheme.Splash.glowPulseMax : AppTheme.Splash.glowPulseMin)
            .onAppear {
                withAnimation(.easeInOut(duration: AppTheme.Splash.glowPulseDuration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

#Preview {
    LiquidGoldBackground()
}
