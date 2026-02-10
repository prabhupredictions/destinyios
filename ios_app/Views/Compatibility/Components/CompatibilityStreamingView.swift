import SwiftUI

/// Premium streaming progress view for compatibility analysis
/// Shows fine-grained SSE steps with beautiful animations
struct CompatibilityStreamingView: View {
    @Binding var isVisible: Bool
    @Binding var currentStep: AnalysisStep
    @Binding var streamingText: String
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Main content card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(AppTheme.Fonts.body(size: 16))
                        .foregroundColor(Color("GoldAccent"))
                    
                    Text("analyzing_match".localized)
                        .font(AppTheme.Fonts.title(size: 17))
                        .foregroundColor(Color("NavyPrimary"))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Steps list
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(AnalysisStep.allCases, id: \.self) { step in
                            StepRowView(
                                step: step,
                                currentStep: currentStep,
                                isCompleted: step.rawValue < currentStep.rawValue
                            )
                        }
                        
                        // Streaming text area (only show when LLM is generating)
                        if currentStep == .generatingAnalysis && !streamingText.isEmpty {
                            StreamingTextView(text: streamingText)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: 400)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 30, y: 10)
            )
            .padding(.horizontal, 24)
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

// MARK: - Analysis Steps Enum
enum AnalysisStep: Int, CaseIterable {
    case calculatingCharts = 0
    case ashtakootMatching = 1
    case mangalDosha = 2
    case collectingYogas = 3
    case generatingAnalysis = 4
    case complete = 5
    
    var title: String {
        switch self {
        case .calculatingCharts: return "Mapping Birth Charts"
        case .ashtakootMatching: return "Matching Cosmic Compatibility"
        case .mangalDosha: return "Checking Mangal Harmony"
        case .collectingYogas: return "Evaluating Yogas & Doshas"
        case .generatingAnalysis: return "Crafting Your Reading"
        case .complete: return "Your Reading is Ready ✨"
        }
    }
    
    var icon: String {
        switch self {
        case .calculatingCharts: return "globe.asia.australia"
        case .ashtakootMatching: return "chart.pie"
        case .mangalDosha: return "exclamationmark.triangle"
        case .collectingYogas: return "sparkle"
        case .generatingAnalysis: return "brain.head.profile"
        case .complete: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Step Row View
struct StepRowView: View {
    let step: AnalysisStep
    let currentStep: AnalysisStep
    let isCompleted: Bool
    
    var isActive: Bool {
        step.rawValue == currentStep.rawValue
    }
    
    var isPending: Bool {
        step.rawValue > currentStep.rawValue
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(AppTheme.Fonts.title(size: 14))
                        .foregroundColor(.green)
                } else if isActive {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("GoldAccent")))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: step.icon)
                        .font(AppTheme.Fonts.body(size: 14))
                        .foregroundColor(Color("NavyPrimary").opacity(0.3))
                }
            }
            
            // Step title
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                    .foregroundColor(textColor)
                
                if isActive {
                    Text("processing".localized)
                        .font(AppTheme.Fonts.caption(size: 11))
                        .foregroundColor(Color("GoldAccent"))
                }
            }
            
            Spacer()
            
            // Time indicator for completed steps
            if isCompleted {
                Text("✓")
                    .font(AppTheme.Fonts.title(size: 12))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(isActive ? Color("GoldAccent").opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
    
    private var statusColor: Color {
        if isCompleted { return .green }
        if isActive { return Color("GoldAccent") }
        return Color("NavyPrimary").opacity(0.1)
    }
    
    private var textColor: Color {
        if isCompleted { return Color("NavyPrimary") }
        if isActive { return Color("NavyPrimary") }
        return Color("NavyPrimary").opacity(0.4)
    }
}

// MARK: - Streaming Text View
struct StreamingTextView: View {
    let text: String
    @State private var displayedText: String = ""
    @State private var cursorVisible = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(AppTheme.Fonts.caption(size: 12))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("AI Analysis")
                    .font(AppTheme.Fonts.title(size: 11))
                    .foregroundColor(Color("GoldAccent"))
            }
            
            HStack(alignment: .bottom, spacing: 0) {
                Text(text)
                    .font(AppTheme.Fonts.body(size: 13))
                    .foregroundColor(Color("NavyPrimary"))
                    .lineSpacing(4)
                
                // Blinking cursor
                Rectangle()
                    .fill(Color("GoldAccent"))
                    .frame(width: 2, height: 14)
                    .opacity(cursorVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: cursorVisible)
                    .onAppear { cursorVisible.toggle() }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.98, green: 0.98, blue: 0.99))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("GoldAccent").opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    CompatibilityStreamingView(
        isVisible: .constant(true),
        currentStep: .constant(.mangalDosha),
        streamingText: .constant("Analyzing the compatibility between both charts. The Ashtakoot score indicates...")
    )
}
