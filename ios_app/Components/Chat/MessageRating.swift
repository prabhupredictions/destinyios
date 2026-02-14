import SwiftUI

// MARK: - Message Rating Component
/// One-click star rating displayed below AI messages
/// Follows ChatGPT/Claude UX pattern but with 5-star granularity

struct MessageRating: View {
    let messageId: String
    let query: String
    let responseText: String
    let predictionId: String?
    
    @State private var selectedRating: Int = 0
    @State private var isSubmitting = false
    @State private var hasSubmitted = false
    @State private var showThankYou = false
    
    var body: some View {
        HStack(spacing: 4) {
            if hasSubmitted {
                // Thank you state
                thankYouView
            } else {
                // Rating prompt
                Text("Rate this response")
                    .font(.system(size: 11))
                    .foregroundColor(Color("NavyPrimary").opacity(0.5))
                
                Spacer()
                
                // Star buttons
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            selectRating(star)
                        } label: {
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundColor(star <= selectedRating ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSubmitting)
                        .accessibilityLabel("\(star) of 5 stars")
                    }
                }
                .opacity(isSubmitting ? 0.5 : 1)
                
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.6)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("NavyPrimary").opacity(0.03))
        )
        .animation(.spring(response: 0.3), value: selectedRating)
        .animation(.spring(response: 0.3), value: hasSubmitted)
    }
    
    // MARK: - Thank You View
    private var thankYouView: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            
            Text("Thanks for your feedback!")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color("NavyPrimary").opacity(0.6))
            
            Spacer()
            
            // Show selected stars
            HStack(spacing: 1) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                        .font(.system(size: 10))
                        .foregroundColor(star <= selectedRating ? Color("GoldAccent") : Color.clear)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Actions
    private func selectRating(_ rating: Int) {
        // Haptic feedback
        HapticManager.shared.play(.light)
        
        selectedRating = rating
        submitRating(rating)
    }
    
    private func submitRating(_ rating: Int) {
        isSubmitting = true
        
        Task {
            do {
                try await FeedbackService.shared.submitRating(
                    predictionId: predictionId,
                    rating: rating,
                    query: query,
                    predictionText: responseText,
                    area: "general"
                )
                
                await MainActor.run {
                    isSubmitting = false
                    hasSubmitted = true
                    
                    // Success haptic
                    HapticManager.shared.notify(.success)
                }
            } catch {
                print("❌ Failed to submit rating: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    // Keep stars visible, user can retry
                }
            }
        }
    }
}

// MARK: - Inline Message Rating (Compact version for metadata row)
/// Compact star rating that fits inline with timestamp/processing time
struct InlineMessageRating: View {
    let message: LocalChatMessage
    let query: String
    let responseText: String
    let predictionId: String?
    
    @State private var selectedRating: Int = 0
    @State private var isSubmitting = false
    @State private var hasSubmitted = false
    
    var body: some View {
        HStack(spacing: 4) {
            if hasSubmitted || (message.rating != nil && message.rating! > 0) {
                // Compact thank you or already rated state
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                
                // Show stars if already rated
                if let rating = message.rating, rating > 0 {
                   HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { star in
                             Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(star <= rating ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary.opacity(0.3))
                        }
                    }
                } else {
                    Text("Rated")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .fixedSize()
                }
            } else {
                // Rate label
                Text("Rate")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize()
                
                // Compact star buttons
                HStack(spacing: 1) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            selectRating(star)
                        } label: {
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(star <= selectedRating ? AppTheme.Colors.gold : AppTheme.Colors.textSecondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSubmitting)
                        .accessibilityLabel("\(star) of 5 stars")
                    }
                }
                .opacity(isSubmitting ? 0.5 : 1)
                
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .animation(.spring(response: 0.3), value: selectedRating)
        .animation(.spring(response: 0.3), value: hasSubmitted)
    }
    
    private func selectRating(_ rating: Int) {
        HapticManager.shared.play(.light)
        
        selectedRating = rating
        submitRating(rating)
    }
    
    private func submitRating(_ rating: Int) {
        isSubmitting = true
        
        Task {
            do {
                try await FeedbackService.shared.submitRating(
                    predictionId: predictionId,
                    rating: rating,
                    query: query,
                    predictionText: responseText,
                    area: "general"
                )
                
                await MainActor.run {
                    isSubmitting = false
                    hasSubmitted = true
                    
                    // Persist locally immediately
                    message.rating = rating
                    
                    HapticManager.shared.notify(.success)
                }
            } catch {
                print("❌ Failed to submit rating: \(error)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Compact Rating (Thumbs only variant for future use)
struct CompactRating: View {
    let onThumbsUp: () -> Void
    let onThumbsDown: () -> Void
    
    @State private var selected: RatingType? = nil
    
    enum RatingType {
        case up, down
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                selected = .up
                onThumbsUp()
            } label: {
                Image(systemName: selected == .up ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 14))
                    .foregroundColor(selected == .up ? .green : Color("NavyPrimary").opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rate helpful")
            
            Button {
                selected = .down
                onThumbsDown()
            } label: {
                Image(systemName: selected == .down ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.system(size: 14))
                    .foregroundColor(selected == .down ? .orange : Color("NavyPrimary").opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rate unhelpful")
        }
    }
}

// MARK: - Preview
#Preview("Star Rating") {
    VStack(spacing: 20) {
        MessageRating(
            messageId: "test-123",
            query: "How will be my next year?",
            responseText: "Based on your chart...",
            predictionId: nil
        )
        
        // Simulated submitted state
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text("Thanks for your feedback!")
                .font(.system(size: 11))
                .foregroundColor(Color("NavyPrimary").opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("NavyPrimary").opacity(0.03))
        )
    }
    .padding()
}
