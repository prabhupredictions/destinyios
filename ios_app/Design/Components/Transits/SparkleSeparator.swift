import SwiftUI

/// BATTERY OPTIMIZATION: Made fully static. The 5 individual .repeatForever animations
/// were removed — at carousel scrolling speed, twinkling of 2-4px dots is imperceptible.
struct SparkleSeparator: View {
    // Golden Sparkle Color
    private let sparkleColor = Color(red: 212/255, green: 175/255, blue: 55/255) // #D4AF37
    
    var body: some View {
        ZStack {
            // Static sparkles within a 40x56 container
            
            // Sparkle 1: Top Left
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 4, height: 4)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: -12, y: -18)
                .opacity(0.7)

            // Sparkle 2: Center Right
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 3, height: 3)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: 10, y: 5)
                .opacity(0.6)
            
            // Sparkle 3: Bottom Left
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 2, height: 2)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: -8, y: 15)
                .opacity(0.5)
            
            // Sparkle 4: Top Right (Tiny)
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 3, height: 3)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: 14, y: -10)
                .opacity(0.7)
                
             // Sparkle 5: Center (Small)
            SparkleShape()
                .fill(sparkleColor)
                .frame(width: 2, height: 2)
                .shadow(color: sparkleColor.opacity(0.8), radius: 2)
                .offset(x: 0, y: -5)
                .opacity(0.5)
        }
        .frame(width: 40, height: 56)
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

