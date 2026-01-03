import SwiftUI

/// Beautiful loading screen shown after user saves birth data for the first time
/// Fetches all astro data (prediction + chart) before navigating to Home
struct ProfileSetupLoadingView: View {
    // Callback when setup is complete
    var onComplete: () -> Void
    
    // Birth data to use for fetching
    let birthData: BirthData
    let userEmail: String
    
    @State private var currentPhase: SetupPhase = .calculatingChart
    @State private var progress: CGFloat = 0
    @State private var showCheckmark = false
    
    enum SetupPhase: String, CaseIterable {
        case calculatingChart = "Calculating your birth chart..."
        case analyzingPlanets = "Analyzing planetary positions..."
        case generatingInsights = "Generating today's insights..."
        case complete = "Your cosmic profile is ready!"
        
        var icon: String {
            switch self {
            case .calculatingChart: return "circle.hexagongrid"
            case .analyzingPlanets: return "sparkles"
            case .generatingInsights: return "brain.head.profile"
            case .complete: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.mainBackground
                .ignoresSafeArea()
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    AppTheme.Colors.gold.opacity(0.1),
                    Color.clear,
                    AppTheme.Colors.gold.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated cosmic icon
                ZStack {
                    // Outer ring animation
                    Circle()
                        .stroke(AppTheme.Colors.gold.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(progress * 360))
                    
                    // Inner ring animation
                    Circle()
                        .stroke(AppTheme.Colors.gold.opacity(0.5), lineWidth: 2)
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-progress * 180))
                    
                    // Center icon
                    if showCheckmark {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.Colors.gold)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: currentPhase.icon)
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.Colors.gold)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                }
                .animation(.spring(response: 0.5), value: showCheckmark)
                
                // Status text
                VStack(spacing: 12) {
                    Text("setting_up_profile".localized)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(currentPhase.rawValue)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .animation(.easeInOut, value: currentPhase)
                }
                
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(GoldProgressStyle())
                    .frame(width: 200)
                
                Spacer()
                
                // Subtle cosmic message
                Text("cosmic_alignment".localized)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.bottom, 40)
            }
        }
        .task {
            await performSetup()
        }
    }
    
    private func performSetup() async {
        // Convert BirthData to UserBirthData for API calls
        let userBirthData = UserBirthData(
            dob: birthData.dob,
            time: birthData.time,
            latitude: birthData.latitude,
            longitude: birthData.longitude,
            ayanamsa: birthData.ayanamsa,
            houseSystem: birthData.houseSystem,
            cityOfBirth: birthData.cityOfBirth
        )
        
        // Phase 1: Calculate chart (fetch full chart data)
        currentPhase = .calculatingChart
        withAnimation(.linear(duration: 1.5)) { progress = 0.3 }
        
        do {
            _ = try await UserChartService.shared.fetchFullChartData(birthData: userBirthData)
        } catch {
            print("[ProfileSetup] Chart fetch failed: \(error)")
        }
        
        // Phase 2: Analyze planets (visual pause)
        currentPhase = .analyzingPlanets
        withAnimation(.linear(duration: 1.0)) { progress = 0.6 }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s visual pause
        
        // Phase 3: Generate insights (fetch today's prediction)
        currentPhase = .generatingInsights
        withAnimation(.linear(duration: 1.5)) { progress = 0.9 }
        
        do {
            let request = UserAstroDataRequest(birthData: userBirthData, userEmail: userEmail)
            _ = try await PredictionService().getTodaysPrediction(request: request)
        } catch {
            print("[ProfileSetup] Prediction fetch failed: \(error)")
        }
        
        // Phase 4: Complete
        currentPhase = .complete
        withAnimation(.easeOut(duration: 0.3)) { 
            progress = 1.0
            showCheckmark = true
        }
        
        // Brief pause to show completion
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
        
        // Navigate to Home
        await MainActor.run {
            onComplete()
        }
    }
}

// MARK: - Custom Progress Style

struct GoldProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                
                // Filled track
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.gold, AppTheme.Colors.gold.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0), height: 8)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    ProfileSetupLoadingView(
        onComplete: {},
        birthData: BirthData(
            dob: "1990-01-15",
            time: "10:30",
            latitude: 28.6139,
            longitude: 77.2090,
            cityOfBirth: "New Delhi"
        ),
        userEmail: "test@example.com"
    )
}
