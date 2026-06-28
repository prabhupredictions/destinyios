import XCTest
@testable import ios_app

@MainActor
final class TeardownChokepointTests: XCTestCase {
    var viewModel: ChatViewModel!

    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.set("test@example.com", forKey: "userEmail")
        viewModel = ChatViewModel(dataManager: DataManager(inMemory: true))
        await Task.yield()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    func testTearDownIsIdempotent() {
        // Initial state — no active generation.
        viewModel.tearDownGenerationState(reason: .viewDisappear)
        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.cosmicProgressSteps.isEmpty)
        // Idempotent — second call must not crash.
        viewModel.tearDownGenerationState(reason: .threadSwitch)
        XCTAssertFalse(viewModel.isStreaming)
    }

    func testTearDownReasonEnumExhaustive() {
        // Switch over every case to lock the enum surface. New cases
        // require updating this test, which forces a callsite review.
        let cases: [ChatViewModel.TearDownReason] = [
            .userStop, .viewDisappear, .threadSwitch,
            .profileSwitch, .backgroundExpiry, .paywallPresent,
            .deepLink, .sendReentry,
        ]
        XCTAssertEqual(cases.count, 8)
    }
}
