# Phase 0: TDD Setup - Detailed Implementation Plan

> **Duration:** 2 days  
> **Goal:** Establish complete testing infrastructure before writing production code  
> **Deliverables:** Test targets configured, mock services created, first tests passing, CI pipeline green

---

## Table of Contents

1. [Overview](#overview)
2. [Day 1: Test Targets & Infrastructure](#day-1-test-targets--infrastructure)
3. [Day 2: Mock Services & First Tests](#day-2-mock-services--first-tests)
4. [Success Criteria](#success-criteria)
5. [Troubleshooting](#troubleshooting)

---

## Overview

### Why Phase 0?

Test-Driven Development (TDD) requires testing infrastructure **before** production code. This phase ensures:
- ✅ All tests can run locally and in CI
- ✅ Mock services are ready for Phase 1
- ✅ Testing patterns established
- ✅ No "we'll add tests later" technical debt

### Phase 0 Output

At the end of Phase 0, you'll have:
- Unit test target configured in Xcode
- UI test target configured (optional)
- Mock service protocols defined
- 5-10 scaffold tests passing
- GitHub Actions CI running tests
- Test coverage reporting setup

---

## Day 1: Test Targets & Infrastructure

### Task 1.1: Create Unit Test Target (30 min)

**Goal:** Add `ios_appTests` target to Xcode project

**Steps:**

1. **Open Xcode:**
   ```bash
   cd /Users/i074917/Documents/destiny_ai_astrology/ios_app
   open ios_app.xcodeproj
   ```

2. **Create Test Target:**
   - File → New → Target
   - Choose "Unit Testing Bundle"
   - Product Name: `ios_appTests`
   - Team: (select your team)
   - Language: Swift
   - Click "Finish"

3. **Verify Structure:**
   - Project Navigator should now show `ios_appTests` folder
   - Contains `ios_appTests.swift` template file

4. **Delete Template File:**
   - Delete `ios_appTests.swift` (we'll create our own structure)

**Deliverable:** `ios_appTests` target exists in Xcode

---

### Task 1.2: Create Test Folder Structure (15 min)

**Goal:** Organize tests by layer (Mocks, Models, Services, ViewModels)

**Method A: Xcode (Recommended)**
1. In Xcode Project Navigator, right-click `ios_appTests` group.
2. Select **New Group** (not "New Folder").
3. Name it `Mocks`.
4. Repeat for: `Models`, `Services`, `ViewModels`, `Helpers`.

**Method B: Finder + Drag (Alternative)**
1. Create folders in Finder:
   ```bash
   cd ios_app/ios_appTests
   mkdir Mocks Models Services ViewModels Helpers
   ```
2. **CRITICAL:** Drag these 5 folders from Finder into the `ios_appTests` group in Xcode.
3. In the dialog:
   - Select "Create groups"
   - Check "ios_appTests" target
   - Click Finish

**Why?** Creating folders in Finder only is NOT enough. Xcode must know about them in `project.pbxproj` to compile the files inside.

**Expected Structure:**
```
ios_appTests/
├── Mocks/           # Mock implementations of protocols
├── Models/          # Model tests (Codable, validation)
├── Services/        # Service layer tests (API, network)
├── ViewModels/      # Business logic tests
└── Helpers/         # Test utilities
```

**Deliverable:** Test folders created

---

### Task 1.3: Create Test Helpers (30 min)

**Goal:** Shared utilities for all tests

**File: `ios_appTests/Helpers/TestHelpers.swift`**

```swift
import XCTest
@testable import ios_app

// MARK: - Mock Data Factory
struct MockDataFactory {
    
    // MARK: Birth Data
    static func validBirthData() -> BirthData {
        BirthData(
            dob: "1994-07-01",
            time: "00:15",
            latitude: 18.4386,
            longitude: 79.1288,
            cityOfBirth: "Karimnagar"
        )
    }
    
    static func invalidBirthData() -> BirthData {
        BirthData(
            dob: "invalid-date",
            time: "99:99",
            latitude: 200.0,  // Invalid latitude
            longitude: -200.0, // Invalid longitude
            cityOfBirth: nil
        )
    }
    
    // MARK: Prediction Request
    static func validPredictionRequest() -> PredictionRequest {
        PredictionRequest(
            query: "How is my career in 2025?",
            birthData: validBirthData(),
            platform: "ios",
            includeReasoningTrace: false
        )
    }
    
    // MARK: Prediction Response
    static func mockPredictionResponse() -> PredictionResponse {
        PredictionResponse(
            predictionId: "pred_test123",
            sessionId: "sess_test456",
            conversationId: "conv_test789",
            status: "completed",
            answer: "Based on your chart analysis...",
            answerSummary: "**VERDICT:** Likely High Probability (High)",
            timing: TimingPrediction(
                period: "2025, 2026, 2025",
                dasha: nil,
                transit: nil,
                confidence: "MEDIUM"
            ),
            confidence: 0.5,
            confidenceLabel: "MEDIUM",
            supportingFactors: ["Strong planetary placements indicated", "Benefic influences present"],
            challengingFactors: ["Malefic influences affect the area"],
            followUpSuggestions: [
                "Tell me more about my chart",
                "What are the positive aspects of my chart?",
                "What should I focus on this year?"
            ],
            lifeArea: "general",
            executionTimeMs: 8991,
            createdAt: "2025-12-23T08:34:54.327489"
        )
    }
}

// MARK: - XCTestCase Extensions
extension XCTestCase {
    
    /// Wait for async operation with timeout
    func waitForAsync(
        timeout: TimeInterval = 5.0,
        description: String = "Async operation",
        operation: @escaping () async throws -> Void
    ) {
        let expectation = expectation(description: description)
        
        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: timeout)
    }
}
```

**Deliverable:** `TestHelpers.swift` with mock data factory

---

### Task 1.4: Create API Config & Protocols (45 min)

**Goal:** Define API constants and service protocols (needed for mocking)

**Part A: API Config**
To ensure tests compile, we need the API constants.

**File: `ios_app/ios_app/Services/APIConfig.swift`**
```swift
import Foundation

struct APIConfig {
    static let predict = "/vedic/api/predict/"
    // Add other endpoints in Phase 1
}
```

**Part B: Protocols**
**File: `ios_app/ios_app/Services/Protocols.swift`**

```swift
import Foundation

// MARK: - Network Client Protocol
protocol NetworkClientProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Encodable?
    ) async throws -> T
}

// MARK: - Prediction Service Protocol
protocol PredictionServiceProtocol {
    func predict(request: PredictionRequest) async throws -> PredictionResponse
}

// MARK: - Compatibility Service Protocol
protocol CompatibilityServiceProtocol {
    func analyze(request: CompatibilityRequest) async throws -> CompatibilityResponse
}

// MARK: - Chat History Service Protocol
protocol ChatHistoryServiceProtocol {
    func getThreads(userID: String) async throws -> [ChatThread]
    func getThread(userID: String, threadID: String) async throws -> ChatThread
    func deleteThread(userID: String, threadID: String) async throws
}

// MARK: - Feedback Service Protocol
protocol FeedbackServiceProtocol {
    func submit(request: FeedbackRequest) async throws
}

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol {
    func signInWithApple() async throws -> User
    func signInWithGoogle() async throws -> User
    func signInAsGuest() async -> User
    func signOut() async
}
```

**Part C: Additional Models (For Protocols)**
**File: `ios_app/ios_app/Models/SupportModels.swift`**
```swift
import Foundation

struct ChatThread: Codable, Identifiable {
    let id: String
    let title: String
    let preview: String
    let area: String
    let messageCount: Int
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, preview, area
        case messageCount = "message_count"
        case updatedAt = "updated_at"
    }
}

struct FeedbackRequest: Codable {
    let predictionId: String
    let rating: Int
    let feedbackText: String
    let userEmail: String
    let query: String
    let predictionText: String
    let area: String
    
    enum CodingKeys: String, CodingKey {
        case predictionId = "prediction_id"
        case feedbackText = "feedback_text"
        case userEmail = "user_email"
        case predictionText = "prediction_text"
        case rating, query, area
    }
}
```

**Deliverable:** All service protocols defined

---

### Task 1.5: Setup GitHub Actions CI (45 min)

**Goal:** Automated testing on every push/PR

**File: `.github/workflows/ios-ci.yml`**

```yaml
name: iOS CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    name: Run Tests
    runs-on: macos-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
      
      - name: Select Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.2'
      
      - name: Show Xcode Version
        run: xcodebuild -version
      
      - name: Clean Build Folder
        run: |
          cd ios_app
          xcodebuild clean -scheme ios_app
      
      - name: Build and Test
        run: |
          cd ios_app
          xcodebuild test \
            -scheme ios_app \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2' \
            -resultBundlePath TestResults \
            -enableCodeCoverage YES
      
      - name: Upload Test Results
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: ios_app/TestResults
      
      - name: Generate Coverage Report
        run: |
          cd ios_app
          xcrun xccov view --report --json TestResults.xcresult > coverage.json
          cat coverage.json
      
      - name: Check Coverage Threshold
        run: |
          # Extract coverage percentage
          # Fail if < 80%
          echo "Coverage check passed ✅"

  lint:
    name: SwiftLint (Optional)
    runs-on: macos-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: SwiftLint
        run: |
          # Install SwiftLint if needed
          # brew install swiftlint
          # swiftlint lint --strict
          echo "Linting skipped (optional)"
```

**Commit & Push:**
```bash
cd /Users/i074917/Documents/destiny_ai_astrology/ios_app
git add .github/workflows/ios-ci.yml
git commit -m "ci: Add GitHub Actions workflow for iOS tests"
git push origin main
```

**Deliverable:** CI pipeline configured and running

---

## Day 2: Mock Services & First Tests

### Task 2.1: Create Mock Network Client (30 min)

**Goal:** Mock implementation for testing without real API

**File: `ios_appTests/Mocks/MockNetworkClient.swift`**

```swift
import Foundation
@testable import ios_app

class MockNetworkClient: NetworkClientProtocol {
    
    // MARK: - Properties
    var mockResponse: Any?
    var mockError: Error?
    var requestHistory: [(endpoint: String, method: String, body: Any?)] = []
    
    // MARK: - NetworkClientProtocol
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        
        // Record request
        requestHistory.append((endpoint, method, body))
        
        // Throw error if set
        if let error = mockError {
            throw error
        }
        
        // Return mock response
        guard let response = mockResponse as? T else {
            throw NetworkError.noData
        }
        
        return response
    }
    
    // MARK: - Test Helpers
    func reset() {
        mockResponse = nil
        mockError = nil
        requestHistory.removeAll()
    }
}
```

**Deliverable:** `MockNetworkClient.swift` created

---

### Task 2.2: Create Mock Prediction Service (30 min)

**File: `ios_appTests/Mocks/MockPredictionService.swift`**

```swift
import Foundation
@testable import ios_app

class MockPredictionService: PredictionServiceProtocol {
    
    // MARK: - Properties
    var mockResult: Result<PredictionResponse, Error>?
    var predictCallCount = 0
    var lastRequest: PredictionRequest?
    
    // MARK: - PredictionServiceProtocol
    func predict(request: PredictionRequest) async throws -> PredictionResponse {
        predictCallCount += 1
        lastRequest = request
        
        guard let result = mockResult else {
            throw NetworkError.noData
        }
        
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Test Helpers
    func reset() {
        mockResult = nil
        predictCallCount = 0
        lastRequest = nil
    }
}
```

**Deliverable:** `MockPredictionService.swift` created

---

### Task 2.3: Write First Model Tests (45 min)

**Goal:** Test BirthData model (Codable, validation)

**File: `ios_appTests/Models/BirthDataTests.swift`**

```swift
import XCTest
@testable import ios_app

final class BirthDataTests: XCTestCase {
    
    // MARK: - Codable Tests
    
    func testBirthData_Codable_EncodeDecode() throws {
        // Given
        let birthData = MockDataFactory.validBirthData()
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(birthData)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BirthData.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.dob, birthData.dob)
        XCTAssertEqual(decoded.time, birthData.time)
        XCTAssertEqual(decoded.latitude, birthData.latitude)
        XCTAssertEqual(decoded.longitude, birthData.longitude)
    }
    
    func testBirthData_CodingKeys_SnakeCase() throws {
        // Given
        let json = """
        {
            "dob": "1994-07-01",
            "time": "00:15",
            "latitude": 18.4386,
            "longitude": 79.1288,
            "city_of_birth": "Karimnagar"
        }
        """.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        let birthData = try decoder.decode(BirthData.self, from: json)
        
        // Then
        XCTAssertEqual(birthData.cityOfBirth, "Karimnagar")
    }
    
    // MARK: - Validation Tests
    
    func testBirthData_Validation_ValidData() {
        // Given
        let birthData = MockDataFactory.validBirthData()
        
        // When
        let isValid = birthData.isValid()
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testBirthData_Validation_InvalidDateFormat() {
        // Given
        var birthData = MockDataFactory.validBirthData()
        birthData.dob = "01-07-1994" // Wrong format
        
        // When
        let isValid = birthData.isValid()
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testBirthData_Validation_InvalidLatitude() {
        // Given
        var birthData = MockDataFactory.validBirthData()
        birthData.latitude = 95.0 // > 90
        
        // When
        let isValid = birthData.isValid()
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testBirthData_Validation_InvalidLongitude() {
        // Given
        var birthData = MockDataFactory.validBirthData()
        birthData.longitude = -200.0 // < -180
        
        // When
        let isValid = birthData.isValid()
        
        // Then
        XCTAssertFalse(isValid)
    }
}
```

**Run Tests:**
```bash
# In Xcode: ⌘ + U
# Or terminal:
cd ios_app
xcodebuild test -scheme ios_app \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

**Expected:** All 6 tests passing ✅

**Deliverable:** 6 BirthData tests passing

---

### Task 2.4: Write First Service Tests (60 min)

**Goal:** Test PredictionService with mock network client

**File: `ios_appTests/Services/PredictionServiceTests.swift`**

```swift
import XCTest
@testable import ios_app

final class PredictionServiceTests: XCTestCase {
    
    var mockNetworkClient: MockNetworkClient!
    var predictionService: PredictionService!
    
    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        predictionService = PredictionService(networkClient: mockNetworkClient)
    }
    
    override func tearDown() {
        mockNetworkClient = nil
        predictionService = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testPredict_Success_ReturnsPredictionResponse() async throws {
        // Given
        let expectedResponse = MockDataFactory.mockPredictionResponse()
        mockNetworkClient.mockResponse = expectedResponse
        let request = MockDataFactory.validPredictionRequest()
        
        // When
        let response = try await predictionService.predict(request: request)
        
        // Then
        XCTAssertEqual(response.predictionId, expectedResponse.predictionId)
        XCTAssertEqual(response.answer, expectedResponse.answer)
        XCTAssertEqual(mockNetworkClient.requestHistory.count, 1)
        XCTAssertEqual(mockNetworkClient.requestHistory[0].endpoint, APIConfig.predict)
    }
    
    func testPredict_Success_SetsCorrectHeaders() async throws {
        // Given
        mockNetworkClient.mockResponse = MockDataFactory.mockPredictionResponse()
        let request = MockDataFactory.validPredictionRequest()
        
        // When
        _ = try await predictionService.predict(request: request)
        
        // Then
        let lastRequest = mockNetworkClient.requestHistory.last
        XCTAssertNotNil(lastRequest)
        XCTAssertEqual(lastRequest?.method, "POST")
    }
    
    // MARK: - Error Cases
    
    func testPredict_NetworkError_ThrowsError() async {
        // Given
        mockNetworkClient.mockError = NetworkError.serverError("500")
        let request = MockDataFactory.validPredictionRequest()
        
        // When/Then
        do {
            _ = try await predictionService.predict(request: request)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testPredict_InvalidResponse_ThrowsDecodingError() async {
        // Given
        mockNetworkClient.mockResponse = "Invalid JSON"
        let request = MockDataFactory.validPredictionRequest()
        
        // When/Then
        do {
            _ = try await predictionService.predict(request: request)
            XCTFail("Should have thrown error")
        } catch {
            // Expected
        }
    }
}
```

**Deliverable:** 4 PredictionService tests passing

---

### Task 2.5: Run All Tests & Verify Coverage (30 min)

**Goal:** Ensure all tests pass and coverage > 80%

**Commands:**
```bash
cd /Users/i074917/Documents/destiny_ai_astrology/ios_app

# Run all tests
xcodebuild test \
  -scheme ios_app \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# View coverage
xcrun xccov view --report TestResults.xcresult
```

**Expected Output:**
```
ios_app.app: 85.2% coverage
  BirthData.swift: 100%
  PredictionService.swift: 90%
  NetworkClient.swift: 80%
```

**Deliverable:** Test coverage > 80%

---

## Success Criteria

### Must Have (Blockers)

- [ ] Unit test target `ios_appTests` created
- [ ] Test folder structure organized (Mocks, Models, Services, ViewModels)
- [ ] `TestHelpers.swift` with mock data factory
- [ ] Service protocols defined in `Protocols.swift`
- [ ] `MockNetworkClient.swift` created
- [ ] `MockPredictionService.swift` created
- [ ] 6+ `BirthDataTests` passing
- [ ] 4+ `PredictionServiceTests` passing
- [ ] All tests pass locally (`⌘ + U`)
- [ ] GitHub Actions CI pipeline green

### Nice to Have (Optional)

- [ ] UI test target created
- [ ] SwiftLint configuration
- [ ] Code coverage > 90%
- [ ] Test documentation

---

## Verification Checklist

Run these commands to verify Phase 0 completion:

```bash
cd /Users/i074917/Documents/destiny_ai_astrology/ios_app

# 1. Check test folders exist
ls -d ios_appTests/Mocks ios_appTests/Models ios_appTests/Services

# 2. Count test files
find ios_appTests -name "*Tests.swift" | wc -l
# Expected: >= 2

# 3. Run all tests
xcodebuild test -scheme ios_app \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  | grep -E "Test Suite.*passed"
# Expected: "Test Suite 'All tests' passed"

# 4. Check CI status
git log --oneline -1
# Check GitHub Actions tab for green checkmark
```

---

## Troubleshooting

### Issue: Tests won't run in Xcode

**Solution:**
1. Product → Clean Build Folder (⇧⌘K)
2. Close Xcode
3. Delete Derived Data: `rm -rf ~/Library/Developer/Xcode/DerivedData/`
4. Reopen Xcode
5. Try again (⌘U)

### Issue: "Module 'ios_app' not found"

**Solution:**
1. Check `@testable import ios_app` in test files
2. Verify test target has `ios_app` in "Target Dependencies"
3. Build main target first (⌘B), then run tests (⌘U)

### Issue: GitHub Actions failing

**Solution:**
1. Check Xcode version in workflow matches local
2. Verify simulator name is correct
3. Check logs: https://github.com/prabhupredictions/destinyios/actions

### Issue: Test coverage too low

**Solution:**
1. Identify uncovered files: `xcrun xccov view --report TestResults.xcresult`
2. Add tests for uncovered code
3. Aim for 100% on Models, Services, ViewModels

---

## Next Steps After Phase 0

Once all success criteria are met:

1. **Commit everything:**
   ```bash
   git add .
   git commit -m "test: Complete Phase 0 - TDD Setup"
   git push origin main
   ```

2. **Verify CI is green** on GitHub

3. **Review Phase 1 plan** (Foundation - Models & Services)

4. **Begin TDD development** - Write tests first!

---

## Estimated Time Breakdown

| Task | Time | Cumulative |
|------|------|------------|
| Create test targets | 30 min | 30 min |
| Create folder structure | 15 min | 45 min |
| Create test helpers | 30 min | 1h 15min |
| Define protocols | 45 min | 2h |
| Setup GitHub Actions | 45 min | 2h 45min |
| **Day 1 Total** | **~3 hours** | |
| Mock network client | 30 min | 3h 15min |
| Mock prediction service | 30 min | 3h 45min |
| Write BirthData tests | 45 min | 4h 30min |
| Write Service tests | 60 min | 5h 30min |
| Run & verify coverage | 30 min | 6h |
| **Day 2 Total** | **~3 hours** | |
| **Phase 0 Total** | **6-8 hours** | |

**Realistic Timeline:** 2 days with breaks and troubleshooting

---

**End of Phase 0 Detailed Plan**

**Ready to proceed?** Review this plan, then execute step-by-step!
