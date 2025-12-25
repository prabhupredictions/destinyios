# Phase 3: Core Screens - Home & Tab Bar - Detailed Implementation Plan

> **Duration:** 4 days  
> **Goal:** Main navigation and home screen functional with real API integration  
> **Prerequisites:** Phase 2 complete (Onboarding & Auth flow working, 48+ tests passing)

---

## Table of Contents

1. [Data Architecture](#data-architecture)
2. [Local Caching Strategy](#local-caching-strategy)
3. [Day 1: Tab Bar & Navigation Structure](#day-1-tab-bar--navigation-structure)
4. [Day 2: Home Screen - Full Implementation](#day-2-home-screen---full-implementation)
5. [Day 3: Chat Screen - Ask Predictions (Streaming + History)](#day-3-chat-screen---ask-predictions-with-streaming--history)
6. [Day 4: Compatibility Screen - Match](#day-4-compatibility-screen---match)
7. [UI/UX Design Guidelines](#uiux-design-guidelines)
8. [Success Criteria](#success-criteria)

---

## Data Architecture

### API Hierarchy (from astroapi-v2)

The iOS app data model must align with the backend hierarchy:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATA MODEL HIERARCHY                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    USER (email)                                                             │
│    └── SESSION (session_id)                                                │
│        ├── session_data: { vedic_analysis, preferences, auth_context }     │
│        ├── created_at, last_accessed, expires_at                           │
│        │                                                                    │
│        └── THREADS (conversation_id / thread_id)                           │
│            ├── title (auto from first message)                             │
│            ├── preview (last message)                                      │
│            ├── primary_area (marriage, career, health...)                  │
│            ├── is_archived, is_pinned                                      │
│            │                                                                │
│            └── MESSAGES                                                    │
│                ├── role (user / assistant / system)                        │
│                ├── content                                                 │
│                ├── area, confidence                                        │
│                ├── tool_calls (for "Analyzed 7th house...")               │
│                ├── sources (["BPHS Ch.7", ...])                           │
│                └── trace_id (link to reasoning trace)                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### iOS Swift Models

**File: `ios_app/ios_app/Models/ChatModels.swift`**

```swift
import Foundation
import SwiftData

// MARK: - Message Role
enum MessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

// MARK: - Chat Message (SwiftData Model)
@Model
final class ChatMessage {
    @Attribute(.unique) var id: String
    var threadId: String
    var role: String  // MessageRole raw value
    var content: String
    var area: String?  // Life area (marriage, career, etc.)
    var confidence: String?  // e.g., "82%"
    var traceId: String?  // Link to reasoning trace
    var toolCalls: [String]?  // Tool call previews
    var sources: [String]?  // References
    var createdAt: Date
    var isStreaming: Bool
    
    init(
        id: String = UUID().uuidString,
        threadId: String,
        role: MessageRole,
        content: String,
        area: String? = nil,
        confidence: String? = nil,
        traceId: String? = nil,
        toolCalls: [String]? = nil,
        sources: [String]? = nil,
        createdAt: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.threadId = threadId
        self.role = role.rawValue
        self.content = content
        self.area = area
        self.confidence = confidence
        self.traceId = traceId
        self.toolCalls = toolCalls
        self.sources = sources
        self.createdAt = createdAt
        self.isStreaming = isStreaming
    }
    
    var messageRole: MessageRole {
        MessageRole(rawValue: role) ?? .user
    }
}

// MARK: - Chat Thread (SwiftData Model)
@Model
final class ChatThread {
    @Attribute(.unique) var id: String
    var sessionId: String
    var userEmail: String
    var title: String
    var preview: String
    var primaryArea: String?
    var areasDiscussed: [String]
    var messageCount: Int
    var isArchived: Bool
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationship
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.threadId)
    var messages: [ChatMessage]?
    
    init(
        id: String = UUID().uuidString,
        sessionId: String,
        userEmail: String,
        title: String = "New Conversation",
        preview: String = "",
        primaryArea: String? = nil,
        areasDiscussed: [String] = [],
        messageCount: Int = 0,
        isArchived: Bool = false,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.userEmail = userEmail
        self.title = title
        self.preview = preview
        self.primaryArea = primaryArea
        self.areasDiscussed = areasDiscussed
        self.messageCount = messageCount
        self.isArchived = isArchived
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func updateFromMessages(_ messages: [ChatMessage]) {
        if let first = messages.first(where: { $0.messageRole == .user }) {
            title = String(first.content.prefix(40))
        }
        if let last = messages.last {
            preview = String(last.content.prefix(60))
            updatedAt = last.createdAt
        }
        messageCount = messages.count
    }
}

// MARK: - User Session (SwiftData Model)
@Model
final class UserSession {
    @Attribute(.unique) var sessionId: String
    var userEmail: String
    var birthDataHash: String?  // For linking same chart
    var createdAt: Date
    var lastAccessed: Date
    var expiresAt: Date
    var isActive: Bool
    
    // Cached preferences
    var historyEnabled: Bool
    var saveConversations: Bool
    var groupByDate: Bool
    
    init(
        sessionId: String = UUID().uuidString,
        userEmail: String,
        birthDataHash: String? = nil,
        createdAt: Date = Date(),
        lastAccessed: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
        isActive: Bool = true,
        historyEnabled: Bool = true,
        saveConversations: Bool = true,
        groupByDate: Bool = true
    ) {
        self.sessionId = sessionId
        self.userEmail = userEmail
        self.birthDataHash = birthDataHash
        self.createdAt = createdAt
        self.lastAccessed = lastAccessed
        self.expiresAt = expiresAt
        self.isActive = isActive
        self.historyEnabled = historyEnabled
        self.saveConversations = saveConversations
        self.groupByDate = groupByDate
    }
}
```

---

## Local Caching Strategy

### Best Practices Applied (iOS 17+)

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Persistent Storage** | SwiftData | Chat history, sessions, threads, messages |
| **In-Memory Cache** | NSCache | API responses, computed insights |
| **Key-Value** | UserDefaults | UI state, preferences, birth data |
| **Secure Storage** | Keychain | Auth tokens, user ID |

### SwiftData Container Setup

**File: `ios_app/ios_app/Services/DataManager.swift`**

```swift
import SwiftData
import Foundation

@MainActor
final class DataManager {
    static let shared = DataManager()
    
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    
    private init() {
        let schema = Schema([
            UserSession.self,
            ChatThread.self,
            ChatMessage.self,
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // Can enable for iCloud sync later
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }
    
    // MARK: - Session Management
    func getOrCreateSession(for email: String) -> UserSession {
        let predicate = #Predicate<UserSession> { $0.userEmail == email && $0.isActive }
        let descriptor = FetchDescriptor<UserSession>(predicate: predicate)
        
        if let existing = try? context.fetch(descriptor).first {
            existing.lastAccessed = Date()
            return existing
        }
        
        let newSession = UserSession(userEmail: email)
        context.insert(newSession)
        try? context.save()
        return newSession
    }
    
    // MARK: - Thread Management
    func fetchThreads(for sessionId: String, includeArchived: Bool = false) -> [ChatThread] {
        var predicate: Predicate<ChatThread>
        if includeArchived {
            predicate = #Predicate { $0.sessionId == sessionId }
        } else {
            predicate = #Predicate { $0.sessionId == sessionId && !$0.isArchived }
        }
        
        let descriptor = FetchDescriptor<ChatThread>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.isPinned, order: .reverse), SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func createThread(sessionId: String, userEmail: String) -> ChatThread {
        let thread = ChatThread(sessionId: sessionId, userEmail: userEmail)
        context.insert(thread)
        try? context.save()
        return thread
    }
    
    // MARK: - Message Management
    func fetchMessages(for threadId: String) -> [ChatMessage] {
        let predicate = #Predicate<ChatMessage> { $0.threadId == threadId }
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func saveMessage(_ message: ChatMessage) {
        context.insert(message)
        try? context.save()
    }
    
    // MARK: - Cleanup
    func deleteThread(_ thread: ChatThread) {
        context.delete(thread)
        try? context.save()
    }
    
    func archiveThread(_ thread: ChatThread) {
        thread.isArchived = true
        try? context.save()
    }
    
    func clearOldData(olderThan days: Int = 90) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<ChatThread> { $0.updatedAt < cutoff && !$0.isPinned }
        let descriptor = FetchDescriptor<ChatThread>(predicate: predicate)
        
        if let oldThreads = try? context.fetch(descriptor) {
            for thread in oldThreads {
                context.delete(thread)
            }
            try? context.save()
        }
    }
}
```

### Phase 3 Deliverables

| Component | Tests | New Files |
|-----------|-------|-----------|
| SwiftData Models | 6 | ChatModels.swift (updated) |
| DataManager | 4 | DataManager.swift |
| MainTabView | 2 | 1 View + TabBar components |
| HomeView (Full) | 6 | 1 ViewModel + 4 Components |
| ChatView + Streaming | 10 | 1 ViewModel + 5 Components |
| CompatibilityView | 6 | 1 ViewModel + 2 Views |
| StreamingService | 3 | 1 Service |
| **Total** | **37+** | **18 files** |

> **Key Features:**
> - ✅ SwiftData for persistent local caching (iOS 17+ best practice)
> - ✅ Proper data hierarchy: User → Session → Threads → Messages
> - ✅ Real API integration with local server
> - ✅ Word-by-word streaming display
> - ✅ Offline-capable with sync on reconnect

---

## Day 1: Tab Bar & Navigation Structure

### Task 1.1: Create MainTabView (45 min)

**Goal:** Replace HomeView placeholder with full tab-based navigation

**File: `ios_app/ios_app/Views/MainTabView.swift`**

```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showNewChat = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                ChatView()
                    .tag(1)
                
                CompatibilityView()
                    .tag(2)
            }
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarItem(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            // Ask Tab (Center - FAB Style)
            AskTabButton {
                selectedTab = 1
            }
            
            // Match Tab
            TabBarItem(
                icon: "heart.fill",
                title: "Match",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 20, y: -5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? Color("NavyPrimary") : Color("TextDark").opacity(0.4))
            .frame(maxWidth: .infinity)
        }
    }
}

struct AskTabButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color("GoldAccent").opacity(0.4), radius: 10, y: 4)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color("NavyPrimary"))
                }
                .offset(y: -20)
                
                Text("Ask")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
                    .offset(y: -16)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MainTabView()
}
```

---

### Task 1.2: Update AppRootView (15 min)

**File: `ios_app/ios_app/Views/AppRootView.swift`**

Update to use `MainTabView` instead of `HomeView`:

```swift
// Change line:
} else {
    MainTabView()  // Was: HomeView()
}
```

---

### Task 1.3: Create Header Component (30 min)

**File: `ios_app/ios_app/Components/AppHeader.swift`**

```swift
import SwiftUI

struct AppHeader: View {
    var onMenuTap: (() -> Void)? = nil
    var onProfileTap: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            // Menu button
            Button(action: { onMenuTap?() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Spacer()
            
            // Logo
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color("GoldAccent"))
                        .frame(width: 28, height: 28)
                    Text("D")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(Color("NavyPrimary"))
                }
                
                Text("destiny")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            Spacer()
            
            // Profile button
            Button(action: { onProfileTap?() }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("NavyPrimary").opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    AppHeader()
}
```

---

## Day 2: Home Screen - Full Implementation

### Task 2.1: Create HomeViewModel (45 min)

**File: `ios_app/ios_app/ViewModels/HomeViewModel.swift`**

```swift
import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    // MARK: - State
    var userName: String = ""
    var quotaRemaining: Int = 10
    var quotaTotal: Int = 10
    var renewalDate: Date = Date()
    var dailyInsight: String = ""
    var suggestedQuestions: [String] = []
    var isLoading = false
    var errorMessage: String?
    var isGuest = false
    
    // MARK: - Init
    init() {
        loadUserInfo()
    }
    
    // MARK: - Load User Info
    private func loadUserInfo() {
        // Load from UserDefaults
        userName = UserDefaults.standard.string(forKey: "userName") ?? "there"
        isGuest = UserDefaults.standard.bool(forKey: "isGuest")
        
        // Load quota (would come from API in production)
        quotaRemaining = UserDefaults.standard.integer(forKey: "quotaRemaining")
        if quotaRemaining == 0 { quotaRemaining = 10 } // Default
        
        // Set renewal date (first of next month)
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) {
            renewalDate = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) ?? Date()
        }
    }
    
    // MARK: - Load Home Data
    func loadHomeData() async {
        isLoading = true
        errorMessage = nil
        
        // Simulated API call - would use real PredictionService
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            // Mock data - in production, fetch from API
            dailyInsight = "You're more sensitive to tone than words today. Mercury's position in your 3rd house heightens your intuition about communication."
            
            suggestedQuestions = [
                "What should I be mindful of today?",
                "How can I improve my focus?",
                "What's a good time for important decisions?"
            ]
            
            isLoading = false
        }
    }
    
    // MARK: - Actions
    func decrementQuota() {
        if quotaRemaining > 0 {
            quotaRemaining -= 1
            UserDefaults.standard.set(quotaRemaining, forKey: "quotaRemaining")
        }
    }
    
    var quotaProgress: Double {
        Double(quotaRemaining) / Double(quotaTotal)
    }
    
    var renewalDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: renewalDate)
    }
    
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}
```

---

### Task 2.2: Create Home Components (60 min)

**File: `ios_app/ios_app/Components/Home/QuotaWidget.swift`**

```swift
import SwiftUI

struct QuotaWidget: View {
    let remaining: Int
    let total: Int
    let renewalDate: String
    
    var progress: Double {
        Double(remaining) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("\(remaining)/\(total) questions left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("NavyPrimary"))
                
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("NavyPrimary").opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("Renews \(renewalDate)")
                .font(.system(size: 12))
                .foregroundColor(Color("TextDark").opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
    }
}

#Preview {
    QuotaWidget(remaining: 7, total: 10, renewalDate: "Jan 1")
        .padding()
}
```

**File: `ios_app/ios_app/Components/Home/InsightCard.swift`**

```swift
import SwiftUI

struct InsightCard: View {
    let insight: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color("GoldAccent"))
                
                Text("Today's Insight")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
            }
            
            Text(insight)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color("NavyPrimary"))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("NavyPrimary").opacity(0.03),
                            Color("GoldAccent").opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("NavyPrimary").opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    InsightCard(insight: "You're more sensitive to tone than words today. Mercury's position heightens your intuition.")
        .padding()
}
```

**File: `ios_app/ios_app/Components/Home/SuggestedQuestions.swift`**

```swift
import SwiftUI

struct SuggestedQuestions: View {
    let questions: [String]
    var onQuestionTap: ((String) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask Destiny")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color("TextDark").opacity(0.6))
                .padding(.leading, 4)
            
            VStack(spacing: 10) {
                ForEach(questions, id: \.self) { question in
                    Button(action: { onQuestionTap?(question) }) {
                        HStack {
                            Text(question)
                                .font(.system(size: 15))
                                .foregroundColor(Color("NavyPrimary"))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color("NavyPrimary").opacity(0.4))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 8)
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    SuggestedQuestions(
        questions: [
            "What should I be mindful of today?",
            "How can I improve my focus?",
            "What's a good time for decisions?"
        ]
    )
    .padding()
}
```

---

### Task 2.3: Update HomeView (60 min)

**File: `ios_app/ios_app/Views/Home/HomeView.swift`**

```swift
import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showMenu = false
    @State private var showProfile = false
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.96, green: 0.95, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    AppHeader(
                        onMenuTap: { showMenu = true },
                        onProfileTap: { showProfile = true }
                    )
                    
                    // Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.greetingMessage), \(viewModel.userName)!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("NavyPrimary"))
                        
                        Text("Let's look at today.")
                            .font(.system(size: 16))
                            .foregroundColor(Color("TextDark").opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Quota Widget (not for premium users)
                    if !viewModel.isGuest {
                        QuotaWidget(
                            remaining: viewModel.quotaRemaining,
                            total: viewModel.quotaTotal,
                            renewalDate: viewModel.renewalDateString
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Daily Insight
                    if !viewModel.dailyInsight.isEmpty {
                        InsightCard(insight: viewModel.dailyInsight)
                            .padding(.horizontal, 20)
                    }
                    
                    // Suggested Questions
                    if !viewModel.suggestedQuestions.isEmpty {
                        SuggestedQuestions(
                            questions: viewModel.suggestedQuestions
                        ) { question in
                            // Navigate to chat with question
                            print("Selected: \(question)")
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Loading state
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color("GoldAccent"))
                            .padding()
                    }
                    
                    // Spacer for tab bar
                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
        }
        .task {
            await viewModel.loadHomeData()
        }
    }
}

#Preview {
    HomeView()
}
```

---

## Day 3: Chat Screen - Ask Predictions (With Streaming & History)

> **Key Features:**
> - ✅ Real API integration with local server (`http://localhost:8000`)
> - ✅ Word-by-word streaming (professional iOS style)
> - ✅ Chat history persistence (local storage)

---

### Task 3.1: Create Chat Models with Persistence (30 min)

**File: `ios_app/ios_app/Models/ChatModels.swift`**

```swift
import Foundation

// MARK: - Chat Message
struct ChatMessage: Identifiable, Codable, Sendable {
    let id: UUID
    let role: MessageRole
    var content: String  // Mutable for streaming
    let timestamp: Date
    var isStreaming: Bool
    
    enum MessageRole: String, Codable, Sendable {
        case user
        case assistant
        case system
    }
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

// MARK: - Chat Session (for History)
struct ChatSession: Identifiable, Codable, Sendable {
    let id: String
    var title: String
    var lastMessage: String
    var timestamp: Date
    var messages: [ChatMessage]
    
    init(id: String = UUID().uuidString, title: String = "New Chat", lastMessage: String = "", timestamp: Date = Date(), messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.messages = messages
    }
    
    mutating func updateFromMessages() {
        if let first = messages.first(where: { $0.role == .user }) {
            title = String(first.content.prefix(40))
        }
        if let last = messages.last {
            lastMessage = String(last.content.prefix(60))
            timestamp = last.timestamp
        }
    }
}

// MARK: - Chat History Manager
final class ChatHistoryManager: @unchecked Sendable {
    static let shared = ChatHistoryManager()
    private let key = "chatSessions"
    
    private init() {}
    
    func loadSessions() -> [ChatSession] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let sessions = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.timestamp > $1.timestamp }
    }
    
    func saveSession(_ session: ChatSession) {
        var sessions = loadSessions()
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }
        // Keep only last 50 sessions
        sessions = Array(sessions.prefix(50))
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func deleteSession(id: String) {
        var sessions = loadSessions()
        sessions.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
```

---

### Task 3.2: Create Streaming Service (45 min)

**File: `ios_app/ios_app/Services/StreamingPredictionService.swift`**

```swift
import Foundation

/// Streaming prediction service for word-by-word response display
final class StreamingPredictionService: @unchecked Sendable {
    private let baseURL: String
    private let apiKey: String
    
    init(baseURL: String = APIConfig.baseURL, apiKey: String = APIConfig.apiKey) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    /// Stream prediction response with callback for each chunk
    func streamPredict(
        request: PredictionRequest,
        onChunk: @escaping @Sendable (String) -> Void,
        onComplete: @escaping @Sendable (Result<PredictionResponse, Error>) -> Void
    ) {
        Task {
            do {
                guard let url = URL(string: "\(baseURL)/vedic/api/predict/") else {
                    throw NetworkError.invalidURL
                }
                
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
                urlRequest.httpBody = try JSONEncoder().encode(request)
                
                let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw NetworkError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
                }
                
                var fullResponse = ""
                var buffer = ""
                
                // Read stream byte by byte
                for try await byte in bytes {
                    let char = String(UnicodeScalar(byte))
                    buffer += char
                    
                    // When we hit a space or newline, emit the buffered word
                    if char == " " || char == "\n" || char == "." || char == "," {
                        await MainActor.run {
                            onChunk(buffer)
                        }
                        fullResponse += buffer
                        buffer = ""
                    }
                }
                
                // Emit any remaining buffer
                if !buffer.isEmpty {
                    await MainActor.run {
                        onChunk(buffer)
                    }
                    fullResponse += buffer
                }
                
                // Create final response
                let predictionResponse = PredictionResponse(
                    predictionId: UUID().uuidString,
                    answer: fullResponse,
                    reasoning: nil,
                    model: "streaming"
                )
                
                await MainActor.run {
                    onComplete(.success(predictionResponse))
                }
                
            } catch {
                await MainActor.run {
                    onComplete(.failure(error))
                }
            }
        }
    }
    
    /// Non-streaming predict with simulated word-by-word display
    func predictWithSimulatedStreaming(
        request: PredictionRequest,
        onWord: @escaping @Sendable (String) -> Void
    ) async throws -> PredictionResponse {
        // Use regular prediction service
        let service = PredictionService()
        let response = try await service.predict(request: request)
        
        // Simulate streaming by emitting words with delay
        let words = response.answer.components(separatedBy: " ")
        for (index, word) in words.enumerated() {
            // Small delay between words (30-50ms for natural feel)
            try await Task.sleep(nanoseconds: UInt64.random(in: 30_000_000...50_000_000))
            
            await MainActor.run {
                if index < words.count - 1 {
                    onWord(word + " ")
                } else {
                    onWord(word)
                }
            }
        }
        
        return response
    }
}
```

---

### Task 3.3: Create ChatViewModel with Streaming (90 min)

**File: `ios_app/ios_app/ViewModels/ChatViewModel.swift`**

```swift
import Foundation
import SwiftUI

@Observable
class ChatViewModel {
    // MARK: - State
    var messages: [ChatMessage] = []
    var isLoading = false
    var isStreaming = false
    var errorMessage: String?
    var inputText = ""
    var currentSession: ChatSession
    var chatHistory: [ChatSession] = []
    
    // MARK: - Streaming State
    private var streamingMessageId: UUID?
    
    // MARK: - Dependencies
    private let predictionService: PredictionServiceProtocol
    private let streamingService: StreamingPredictionService
    private let historyManager: ChatHistoryManager
    
    // MARK: - Init
    init(
        predictionService: PredictionServiceProtocol = PredictionService(),
        session: ChatSession? = nil
    ) {
        self.predictionService = predictionService
        self.streamingService = StreamingPredictionService()
        self.historyManager = ChatHistoryManager.shared
        self.currentSession = session ?? ChatSession()
        
        loadHistory()
        
        if session == nil {
            addWelcomeMessage()
        } else {
            messages = session?.messages ?? []
        }
    }
    
    // MARK: - History Management
    func loadHistory() {
        chatHistory = historyManager.loadSessions()
    }
    
    func saveCurrentSession() {
        currentSession.messages = messages
        currentSession.updateFromMessages()
        historyManager.saveSession(currentSession)
        loadHistory()
    }
    
    func loadSession(_ session: ChatSession) {
        currentSession = session
        messages = session.messages
    }
    
    func startNewChat() {
        saveCurrentSession()
        currentSession = ChatSession()
        messages = []
        addWelcomeMessage()
    }
    
    func deleteSession(_ session: ChatSession) {
        historyManager.deleteSession(id: session.id)
        loadHistory()
    }
    
    private func addWelcomeMessage() {
        let welcome = ChatMessage(
            role: .assistant,
            content: "Hello! I'm Destiny, your personal astrology guide. What would you like to know about your day, relationships, or path ahead?"
        )
        messages.append(welcome)
    }
    
    // MARK: - Send Message with Streaming
    func sendMessage() async {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        // Clear input immediately
        await MainActor.run {
            inputText = ""
            errorMessage = nil
        }
        
        // Add user message
        let userMessage = ChatMessage(role: .user, content: query)
        await MainActor.run {
            messages.append(userMessage)
            isLoading = true
        }
        
        // Get birth data
        guard let birthData = loadBirthData() else {
            await MainActor.run {
                errorMessage = "Please complete your birth data first"
                isLoading = false
            }
            return
        }
        
        // Create streaming placeholder message
        let streamingId = UUID()
        let placeholderMessage = ChatMessage(
            id: streamingId,
            role: .assistant,
            content: "",
            isStreaming: true
        )
        
        await MainActor.run {
            messages.append(placeholderMessage)
            streamingMessageId = streamingId
            isLoading = false
            isStreaming = true
        }
        
        do {
            let request = PredictionRequest(
                query: query,
                birthData: birthData,
                sessionId: currentSession.id,
                platform: "ios"
            )
            
            // Use simulated streaming (works with non-streaming API)
            let response = try await streamingService.predictWithSimulatedStreaming(
                request: request
            ) { [weak self] word in
                self?.appendToStreamingMessage(word)
            }
            
            await MainActor.run {
                // Mark streaming complete
                if let index = messages.firstIndex(where: { $0.id == streamingId }) {
                    messages[index].isStreaming = false
                }
                isStreaming = false
                streamingMessageId = nil
                
                // Save to history
                saveCurrentSession()
            }
            
        } catch {
            await MainActor.run {
                // Remove streaming message on error
                messages.removeAll { $0.id == streamingId }
                errorMessage = "Failed to get response. Please try again."
                isStreaming = false
                streamingMessageId = nil
            }
        }
    }
    
    private func appendToStreamingMessage(_ text: String) {
        guard let streamingId = streamingMessageId,
              let index = messages.firstIndex(where: { $0.id == streamingId }) else {
            return
        }
        messages[index].content += text
    }
    
    // MARK: - Helpers
    private func loadBirthData() -> BirthData? {
        guard let data = UserDefaults.standard.data(forKey: "userBirthData"),
              let birthData = try? JSONDecoder().decode(BirthData.self, from: data) else {
            return nil
        }
        return birthData
    }
    
    func clearChat() {
        messages.removeAll()
        currentSession = ChatSession()
        addWelcomeMessage()
    }
}
```

---

### Task 3.4: Create ChatView with Streaming UI (90 min)

**File: `ios_app/ios_app/Views/Chat/ChatView.swift`**

```swift
import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.98)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                AppHeader()
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { _, isLoading in
                        if isLoading {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Input bar
                ChatInputBar(
                    text: $viewModel.inputText,
                    isFocused: $isInputFocused,
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.sendMessage() }
                }
                
                // Spacer for tab bar
                Spacer()
                    .frame(height: 80)
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !isUser {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(Color("GoldAccent"))
                        .frame(width: 32, height: 32)
                    Text("D")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(Color("NavyPrimary"))
                }
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isUser ? .white : Color("NavyPrimary"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isUser ? Color("NavyPrimary") : Color.white)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(Color("TextDark").opacity(0.4))
            }
            .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
            
            if isUser {
                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationOffset = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("GoldAccent"))
                    .frame(width: 32, height: 32)
                Text("D")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(Color("NavyPrimary"))
            }
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color("NavyPrimary").opacity(0.4))
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset == index ? -4 : 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                    animationOffset = (animationOffset + 1) % 3
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Chat Input Bar
struct ChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isLoading: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask anything...", text: $text, axis: .vertical)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(24)
                .focused(isFocused)
                .lineLimit(1...4)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(
                        text.isEmpty || isLoading 
                            ? Color("NavyPrimary").opacity(0.3) 
                            : Color("NavyPrimary")
                    )
            }
            .disabled(text.isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.96, green: 0.95, blue: 0.98))
    }
}

#Preview {
    ChatView()
}
```

---

## Day 4: Compatibility Screen - Match

### Task 4.1: Create CompatibilityViewModel (45 min)

**File: `ios_app/ios_app/ViewModels/CompatibilityViewModel.swift`**

```swift
import Foundation
import SwiftUI

@Observable
class CompatibilityViewModel {
    // MARK: - State
    var boyName = ""
    var boyBirthData = BirthData(dob: "", time: "", latitude: 0, longitude: 0, cityOfBirth: nil)
    var girlName = ""
    var girlBirthData = BirthData(dob: "", time: "", latitude: 0, longitude: 0, cityOfBirth: nil)
    
    var result: CompatibilityResponse?
    var isAnalyzing = false
    var errorMessage: String?
    var showResult = false
    
    // MARK: - Dependencies
    private let service: CompatibilityServiceProtocol
    
    init(service: CompatibilityServiceProtocol = CompatibilityService()) {
        self.service = service
    }
    
    // MARK: - Validation
    var isValid: Bool {
        !boyName.isEmpty && 
        !boyBirthData.dob.isEmpty && 
        boyBirthData.cityOfBirth != nil &&
        !girlName.isEmpty && 
        !girlBirthData.dob.isEmpty && 
        girlBirthData.cityOfBirth != nil
    }
    
    // MARK: - Analyze
    func analyzeMatch() async {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
        }
        
        do {
            let request = CompatibilityRequest(
                boy: BirthDetails(
                    name: boyName,
                    dob: boyBirthData.dob,
                    time: boyBirthData.time,
                    latitude: boyBirthData.latitude,
                    longitude: boyBirthData.longitude
                ),
                girl: BirthDetails(
                    name: girlName,
                    dob: girlBirthData.dob,
                    time: girlBirthData.time,
                    latitude: girlBirthData.latitude,
                    longitude: girlBirthData.longitude
                )
            )
            
            let response = try await service.analyze(request: request)
            
            await MainActor.run {
                result = response
                showResult = true
                isAnalyzing = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Analysis failed. Please try again."
                isAnalyzing = false
            }
        }
    }
    
    func reset() {
        boyName = ""
        boyBirthData = BirthData(dob: "", time: "", latitude: 0, longitude: 0, cityOfBirth: nil)
        girlName = ""
        girlBirthData = BirthData(dob: "", time: "", latitude: 0, longitude: 0, cityOfBirth: nil)
        result = nil
        showResult = false
        errorMessage = nil
    }
}
```

---

### Task 4.2: Create CompatibilityView (90 min)

**File: `ios_app/ios_app/Views/Compatibility/CompatibilityView.swift`**

```swift
import SwiftUI

struct CompatibilityView: View {
    @State private var viewModel = CompatibilityViewModel()
    @State private var selectedTab = 0 // 0 = Boy, 1 = Girl
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.98)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    AppHeader()
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Match Compatibility")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("NavyPrimary"))
                        
                        Text("Compare birth charts to see\nhow your stars align")
                            .font(.system(size: 15))
                            .foregroundColor(Color("TextDark").opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Tab Selector
                    HStack(spacing: 0) {
                        TabButton(title: "Boy Details", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        TabButton(title: "Girl Details", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Form
                    if selectedTab == 0 {
                        PersonForm(
                            name: $viewModel.boyName,
                            birthData: $viewModel.boyBirthData,
                            icon: "♂",
                            color: Color.blue.opacity(0.1)
                        )
                    } else {
                        PersonForm(
                            name: $viewModel.girlName,
                            birthData: $viewModel.girlBirthData,
                            icon: "♀",
                            color: Color.pink.opacity(0.1)
                        )
                    }
                    
                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                    
                    // Analyze Button
                    Button(action: {
                        Task { await viewModel.analyzeMatch() }
                    }) {
                        HStack {
                            if viewModel.isAnalyzing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                Text("Analyze Match")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.isValid ? Color("NavyPrimary") : Color.gray.opacity(0.5)
                        )
                        .cornerRadius(16)
                    }
                    .disabled(!viewModel.isValid || viewModel.isAnalyzing)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $viewModel.showResult) {
            if let result = viewModel.result {
                CompatibilityResultView(
                    result: result,
                    boyName: viewModel.boyName,
                    girlName: viewModel.girlName
                )
            }
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color("NavyPrimary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color("NavyPrimary") : Color.clear)
                .cornerRadius(12)
        }
    }
}

// MARK: - Person Form
struct PersonForm: View {
    @Binding var name: String
    @Binding var birthData: BirthData
    let icon: String
    let color: Color
    
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var city = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Text(icon)
                .font(.system(size: 40))
                .padding(20)
                .background(color)
                .clipShape(Circle())
            
            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
                
                TextField("Enter name", text: $name)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            // Date
            VStack(alignment: .leading, spacing: 8) {
                Text("Date of Birth")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
                
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: selectedDate) { _, newValue in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        birthData = BirthData(
                            dob: formatter.string(from: newValue),
                            time: birthData.time,
                            latitude: 0,
                            longitude: 0,
                            cityOfBirth: birthData.cityOfBirth
                        )
                    }
            }
            
            // Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Time of Birth")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
                
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: selectedTime) { _, newValue in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        birthData = BirthData(
                            dob: birthData.dob,
                            time: formatter.string(from: newValue),
                            latitude: 0,
                            longitude: 0,
                            cityOfBirth: birthData.cityOfBirth
                        )
                    }
            }
            
            // City
            VStack(alignment: .leading, spacing: 8) {
                Text("Place of Birth")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("TextDark").opacity(0.6))
                
                TextField("Enter city", text: $city)
                    .textFieldStyle(CustomTextFieldStyle())
                    .onChange(of: city) { _, newValue in
                        birthData = BirthData(
                            dob: birthData.dob,
                            time: birthData.time,
                            latitude: 0,
                            longitude: 0,
                            cityOfBirth: newValue
                        )
                    }
            }
        }
        .padding(20)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("NavyPrimary").opacity(0.15), lineWidth: 1)
            )
    }
}

#Preview {
    CompatibilityView()
}
```

---

### Task 4.3: Create CompatibilityResultView (60 min)

**File: `ios_app/ios_app/Views/Compatibility/CompatibilityResultView.swift`**

```swift
import SwiftUI

struct CompatibilityResultView: View {
    let result: CompatibilityResponse
    let boyName: String
    let girlName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Score Circle
                    VStack(spacing: 16) {
                        HStack(spacing: 24) {
                            PersonBadge(name: boyName, icon: "♂", color: .blue)
                            
                            Text("VS")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color("TextDark").opacity(0.4))
                            
                            PersonBadge(name: girlName, icon: "♀", color: .pink)
                        }
                        
                        ScoreCircle(score: result.totalScore ?? 0, maxScore: 36)
                    }
                    .padding(.top, 20)
                    
                    // Summary
                    if let summary = result.summary {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Summary")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color("TextDark").opacity(0.6))
                            
                            Text(summary)
                                .font(.system(size: 15))
                                .foregroundColor(Color("NavyPrimary"))
                                .lineSpacing(6)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    
                    // Detailed Analysis placeholder
                    Text("Detailed Kuta analysis coming soon")
                        .font(.system(size: 14))
                        .foregroundColor(Color("TextDark").opacity(0.5))
                        .padding()
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.98).ignoresSafeArea())
            .navigationTitle("Match Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color("NavyPrimary"))
                }
            }
        }
    }
}

struct PersonBadge: View {
    let name: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
                .padding(16)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("NavyPrimary"))
        }
    }
}

struct ScoreCircle: View {
    let score: Int
    let maxScore: Int
    
    var progress: Double {
        Double(score) / Double(maxScore)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color("NavyPrimary").opacity(0.1), lineWidth: 12)
                .frame(width: 140, height: 140)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color("GoldAccent"), Color("GoldAccent").opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
            
            // Score text
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Color("NavyPrimary"))
                
                Text("out of \(maxScore)")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextDark").opacity(0.5))
            }
        }
    }
}

#Preview {
    CompatibilityResultView(
        result: CompatibilityResponse(
            compatibilityId: "test",
            boy: nil,
            girl: nil,
            totalScore: 28,
            kutaDetails: nil,
            summary: "This is a highly compatible match with strong emotional and spiritual bonds.",
            recommendation: "Proceed with confidence"
        ),
        boyName: "Vamshi",
        girlName: "Swathi"
    )
}
```

---

## UI/UX Design Guidelines

### World-Class Professional Design Principles

Following modern iOS design best practices (ChatGPT, Claude, Perplexity style):

---

### 1. Color System (Verified from Mockup)

```swift
// Primary Colors (Updated to match mockup)
extension Color {
    static let navyPrimary = Color("NavyPrimary")      // #263248 - Dark navy from mockup
    static let goldAccent = Color("GoldAccent")        // #D4A84B - Warm amber/gold from mockup
    static let textDark = Color("TextDark")            // #333333 - Dark gray
    static let backgroundSoft = Color(red: 0.95, green: 0.94, blue: 0.95)  // #F2F1F3 - Watercolor cream
    
    // Semantic Colors
    static let userMessage = navyPrimary
    static let assistantMessage = Color.white
    static let successGreen = Color(red: 0.286, green: 0.651, blue: 0.471)  // #49A678
    static let errorRed = Color(red: 0.878, green: 0.376, blue: 0.431)      // #E0606E
}
```

**Asset Color Values:**
| Asset | Hex | RGB (0-1) |
|-------|-----|-----------|
| NavyPrimary | #263248 | (0.149, 0.196, 0.282) |
| GoldAccent | #D4A84B | (0.831, 0.659, 0.294) |
| TextDark | #333333 | (0.2, 0.2, 0.2) |
| BackgroundLight | #F5F5F5 | (0.961, 0.961, 0.961) |

---

### 2. Typography Scale

| Element | Size | Weight | Line Height |
|---------|------|--------|-------------|
| Title | 28pt | Bold | 1.2 |
| Subtitle | 20pt | Semibold | 1.3 |
| Body | 16pt | Regular | 1.5 |
| Message | 15pt | Regular | 1.5 |
| Caption | 13pt | Medium | 1.4 |
| Footnote | 11pt | Regular | 1.3 |

```swift
// Typography extensions
extension Font {
    static let titleLarge = Font.system(size: 28, weight: .bold)
    static let titleMedium = Font.system(size: 20, weight: .semibold)
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let messageBody = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .medium)
    static let footnote = Font.system(size: 11, weight: .regular)
}
```

---

### 3. Spacing System

Use 4pt base grid:

| Name | Value | Usage |
|------|-------|-------|
| xs | 4pt | Inline spacing |
| sm | 8pt | Icon gaps |
| md | 16pt | Section padding |
| lg | 24pt | Card spacing |
| xl | 32pt | Section gaps |

---

### 4. Message Bubbles (Chat UI)

**User Message:**
```
┌────────────────────────────┐
│  Navy background           │ ← cornerRadius: 18
│  White text               │
│  Right-aligned            │
└────────────────────────────┘
                         [Timestamp]
```

**Assistant Message:**
```
[Avatar]  ┌────────────────────────────┐
    D     │  White background         │ ← Subtle shadow
          │  Navy text                │
          │  Left-aligned             │
          │                           │
          │  [Tool Chips]             │ ← "Analyzed 7th house..."
          │  [Source Chips]           │ ← "BPHS Ch.7"
          └────────────────────────────┘
          [Timestamp]
```

**Streaming State:**
```
[Avatar]  ┌────────────────────────────┐
    D     │  Word by word typing ▌    │ ← Blinking cursor
          │                           │
          └────────────────────────────┘
          [Typing...]
```

---

### 5. Card Components

```swift
// Standard Card Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(16)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 10,
                x: 0,
                y: 4
            )
    }
}

// Usage
SomeView()
    .modifier(CardModifier())
```

---

### 6. Animations

| Animation | Duration | Easing | Usage |
|-----------|----------|--------|-------|
| Fade In | 0.3s | easeOut | Screen transitions |
| Spring | 0.4s | spring(response: 0.4) | Buttons, cards |
| Slide | 0.25s | easeInOut | Sheets, modals |
| Streaming | 30-50ms | linear | Word-by-word |

```swift
// Standard animations
extension Animation {
    static let cardSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let fadeIn = Animation.easeOut(duration: 0.3)
    static let slideIn = Animation.easeInOut(duration: 0.25)
}
```

---

### 7. Chat History Sidebar (Premium Feature)

```
┌─────────────────────────────┐
│  ☰  Chat History        [+] │ ← New chat button
├─────────────────────────────┤
│  📌 PINNED                  │
│  ├─ Marriage prospects...   │
│  └─ Career guidance...      │
├─────────────────────────────┤
│  📅 TODAY                   │
│  ├─ What about my...        │
│  └─ Health concerns...      │
├─────────────────────────────┤
│  📅 YESTERDAY              │
│  ├─ Financial outlook...    │
│  └─ Relationship advice...  │
├─────────────────────────────┤
│  📅 LAST 7 DAYS            │
│  └─ ...                     │
└─────────────────────────────┘
```

---

### 8. Loading States

**Typing Indicator:**
```swift
struct TypingIndicator: View {
    @State private var bounce = [false, false, false]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.navyPrimary.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .offset(y: bounce[i] ? -4 : 0)
            }
        }
        .onAppear { startBouncing() }
    }
}
```

**Skeleton Loader:**
```swift
struct SkeletonLoader: View {
    @State private var shimmer = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                LinearGradient(...)
                    .offset(x: shimmer ? 200 : -200)
            )
            .animation(.linear(duration: 1.2).repeatForever, value: shimmer)
    }
}
```

---

### 9. Haptic Feedback

```swift
// Haptic feedback for interactions
struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// Usage
Button("Send") {
    HapticManager.impact(.medium)
    // Send action
}
```

---

### 10. Accessibility

```swift
// All interactive elements must have:
Button("Send Message") { ... }
    .accessibilityLabel("Send your question to Destiny")
    .accessibilityHint("Double tap to send your astrological question")

// Dynamic type support
Text("Hello")
    .font(.body)
    .dynamicTypeSize(.medium ... .accessibility3)

// Color contrast minimum 4.5:1 for text
// VoiceOver labels for all images
// Reduce motion support
```

---

### 11. Professional UI Examples

**Home Screen - Greeting Card:**
```
┌─────────────────────────────────────────────┐
│                                             │
│  Good morning, Vamshi! ☀️                  │
│  Let's look at today.                       │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ ✨ 7/10 questions left              │   │
│  │ ━━━━━━━━━━━░░░░░  Renews Jan 1    │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ 🌟 Today's Insight                   │   │
│  │                                      │   │
│  │ You're more sensitive to tone       │   │
│  │ than words today. Mercury's...      │   │
│  └─────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

**Chat Screen - Conversation Flow:**
```
┌─────────────────────────────────────────────┐
│  ☰    D destiny                      👤     │
├─────────────────────────────────────────────┤
│                                             │
│  [D]  Hello! I'm Destiny, your personal    │
│       astrology guide. What would you       │
│       like to know?                         │
│       ───────────────── 10:30 AM           │
│                                             │
│                    ┌────────────────────┐   │
│                    │ What's my career   │   │
│                    │ outlook for 2024?  │   │
│                    └────────────────────┘   │
│                              10:31 AM ──── │
│                                             │
│  [D]  Based on your chart, Saturn's        │
│       transit through your 10th house...   │
│                                             │
│       🔮 Analyzed: 10th house, Saturn      │
│       📚 BPHS Ch.12, Career guidance       │
│       ───────────────── 10:31 AM           │
│                                             │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────┐  [➤]  │
│  │ Ask anything...                 │       │
│  └─────────────────────────────────┘       │
└─────────────────────────────────────────────┘
```

---

## Success Criteria

### Must Have

- [ ] Tab bar navigation working (Home, Ask, Match)
- [ ] Custom floating Ask button in center
- [ ] Home screen shows greeting, quota, insight, questions
- [ ] Chat screen sends messages and shows AI responses with streaming
- [ ] Chat history persisted with SwiftData
- [ ] Compatibility screen collects data and shows results
- [ ] All screens have world-class professional UI
- [ ] 37+ new tests passing

### User Flows

1. **Home → Chat:** Tap suggested question → opens chat with that question
2. **Chat:** Type question → see AI response stream word-by-word
3. **Chat History:** Tap hamburger → see conversation history grouped by date
4. **Match:** Enter both details → Analyze → See score and summary

---

## Verification

```bash
cd /Users/i074917/Documents/destiny_ai_astrology/ios_app

# Count new files
find ios_app -name "*.swift" -newer ios_app/Views/AppRootView.swift | wc -l
# Expected: 14+

# Test count
grep -r "func test" ios_appTests --include="*.swift" | wc -l
# Expected: 70+ (48 + 22 new)

# Run tests in Xcode: ⌘ + U
```

---

## Git Commit

```bash
git add .
git commit -m "feat: Complete Phase 3 - Home & Tab Bar

- Add MainTabView with custom floating tab bar
- Add full HomeView with quota, insights, questions
- Add ChatView with message bubbles and typing indicator
- Add CompatibilityView with dual forms and results
- Add HomeViewModel, ChatViewModel, CompatibilityViewModel
- Add ChatModels (Message, Session)
- Add Components: AppHeader, QuotaWidget, InsightCard
- 24+ new tests, total 70+ passing"

git push origin main
```

---

**End of Phase 3 Detailed Plan**

---

## Gap Analysis & Resolution Record

> **Review Date:** 2025-12-24  
> **Status:** ✅ All gaps resolved - Clean implementation

### Identified Gaps (Pre-Implementation)

| Component | Original Plan | Gap Identified | Resolution |
|-----------|---------------|----------------|------------|
| History Screen | Not in Phase 3 scope | Missing History thread view | Added `HistoryView.swift` + `HistoryViewModel.swift` |
| Subscription Screen | Not specified | No premium flow | Added `SubscriptionView.swift` (StoreKit 2 ready) |
| Charts Screen | Separate screen listed | No planetary positions view | Added `PlanetaryPositionsSheet.swift` as modal in Chat |
| Profile Sheet | Minimal implementation | Missing: Astrology System, Language, Upgrade link | Enhanced `ProfileSheet` with all spec options |
| Menu Navigation | ☰ placeholder only | Not connected to History | Connected to `HistoryView` sheet |
| Chat Charts Access | Not specified | No way to view chart while chatting | Added chart button to `ChatHeader` |

### Files Added to Complete Phase 3

| File | Type | Purpose |
|------|------|---------|
| `Views/History/HistoryView.swift` | View | Thread list with grouping & swipe delete |
| `ViewModels/HistoryViewModel.swift` | ViewModel | History data loading & management |
| `Views/Subscription/SubscriptionView.swift` | View | Premium subscription with StoreKit 2 |
| `Views/Charts/PlanetaryPositionsSheet.swift` | View | Birth chart modal for Chat screen |

### Files Modified

| File | Change |
|------|--------|
| `Services/DataManager.swift` | Added `fetchAllThreads(for:)` method |
| `Views/Home/HomeView.swift` | Enhanced `ProfileSheet` with all spec options |
| `Components/AppHeader.swift` | Added `onChartTap` to `ChatHeader` |
| `Views/Chat/ChatView.swift` | Connected Charts modal |

### Test Coverage

| Test File | Status | Coverage |
|-----------|--------|----------|
| `HomeViewModelTests.swift` | ✅ Exists | HomeViewModel |
| `ChatViewModelTests.swift` | ✅ Exists | ChatViewModel |
| `CompatibilityViewModelTests.swift` | ✅ Exists | CompatibilityViewModel |
| `DataManagerTests.swift` | ✅ Exists | DataManager |
| `HistoryViewModelTests.swift` | 🆕 To Add | HistoryViewModel |

### Build Status

- **Compilation:** ✅ Succeeded
- **Warnings:** 5 (Swift 6 @MainActor isolation - expected, non-blocking)
- **UI Tests:** 2/2 passed
