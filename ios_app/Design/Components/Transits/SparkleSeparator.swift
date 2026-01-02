import SwiftUI

struct SparkleSeparator: View {
    @State private var isTwinkling = false
    
    // Golden Sparkle Color
    private let sparkleColor = Color(red: 212/255, green: 175/255, blue: 55/255) // #D4AF37
    
    var body: some View {
        ZStack {
            // Randomly positioned sparkles within a 40x56 container
            
            // Sparkle 1: Top Left
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 4, height: 4)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: -12, y: -18)
                .opacity(isTwinkling ? 1.0 : 0.4)
                .scaleEffect(isTwinkling ? 1.2 : 0.8)
                .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.1), value: isTwinkling)

            // Sparkle 2: Center Right
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 3, height: 3)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: 10, y: 5)
                .opacity(isTwinkling ? 0.9 : 0.3)
                .scaleEffect(isTwinkling ? 1.3 : 0.7)
                .animation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.4), value: isTwinkling)
            
            // Sparkle 3: Bottom Left
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 2, height: 2)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: -8, y: 15)
                .opacity(isTwinkling ? 0.8 : 0.2)
                .scaleEffect(isTwinkling ? 1.1 : 0.9)
                .animation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.7), value: isTwinkling)
            
            // Sparkle 4: Top Right (Tiny)
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 3, height: 3)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: 14, y: -10)
                .opacity(isTwinkling ? 1.0 : 0.5)
                .scaleEffect(isTwinkling ? 1.2 : 0.8)
                .animation(Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.2), value: isTwinkling)
                
             // Sparkle 5: Center (Small)
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 2, height: 2)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: 0, y: -5)
                .opacity(isTwinkling ? 0.7 : 0.3)
                .scaleEffect(isTwinkling ? 1.1 : 0.9)
                .animation(Animation.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.5), value: isTwinkling)
        }
        .frame(width: 40, height: 56)
        .onAppear {
            isTwinkling = true
        }
    }
}

// Diamond Shape for Sparkles
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Diamond points: Top, Right, Bottom, Left
        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: center.y))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        Color.black
        SparkleSeparator()
    }
}
