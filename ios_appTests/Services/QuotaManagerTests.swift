import XCTest
@testable import ios_app

// NOTE: These tests reference removed types (UserType, QuotaStatus) and are disabled until updated.
#if false
final class QuotaManagerTests: XCTestCase {
    
    // MARK: - UserType Tests
    
    func testUserType_Guest_HasLimit3() {
        let userType = UserType.guest
        XCTAssertEqual(userType.questionLimit, 3)
    }
    
    func testUserType_Registered_HasLimit10() {
        let userType = UserType.registered
        XCTAssertEqual(userType.questionLimit, 10)
    }
    
    func testUserType_Premium_HasUnlimitedQuestions() {
        let userType = UserType.premium
        XCTAssertEqual(userType.questionLimit, Int.max)
    }
    
    func testUserType_Guest_CanUpgrade() {
        XCTAssertTrue(UserType.guest.canUpgrade)
    }
    
    func testUserType_Registered_CanUpgrade() {
        XCTAssertTrue(UserType.registered.canUpgrade)
    }
    
    func testUserType_Premium_CannotUpgrade() {
        XCTAssertFalse(UserType.premium.canUpgrade)
    }
    
    func testUserType_DisplayNames() {
        XCTAssertEqual(UserType.guest.displayName, "Guest")
        XCTAssertEqual(UserType.registered.displayName, "Free User")
        XCTAssertEqual(UserType.premium.displayName, "Premium")
    }
    
    func testUserType_UpgradeMessages() {
        XCTAssertFalse(UserType.guest.upgradeMessage.isEmpty)
        XCTAssertFalse(UserType.registered.upgradeMessage.isEmpty)
        XCTAssertTrue(UserType.premium.upgradeMessage.isEmpty)
    }
    
    // MARK: - QuotaStatus Tests
    
    func testQuotaStatus_Guest_CanAsk_WhenUnderLimit() {
        let status = QuotaStatus(userType: .guest, questionsUsed: 2)
        XCTAssertTrue(status.canAsk)
        XCTAssertEqual(status.remainingQuestions, 1)
    }
    
    func testQuotaStatus_Guest_CannotAsk_WhenAtLimit() {
        let status = QuotaStatus(userType: .guest, questionsUsed: 3)
        XCTAssertFalse(status.canAsk)
        XCTAssertEqual(status.remainingQuestions, 0)
    }
    
    func testQuotaStatus_Guest_CannotAsk_WhenOverLimit() {
        let status = QuotaStatus(userType: .guest, questionsUsed: 5)
        XCTAssertFalse(status.canAsk)
        XCTAssertEqual(status.remainingQuestions, 0)
    }
    
    func testQuotaStatus_Premium_AlwaysCanAsk() {
        let status = QuotaStatus(userType: .premium, questionsUsed: 1000)
        XCTAssertTrue(status.canAsk)
    }
    
    func testQuotaStatus_Progress_Guest() {
        let status = QuotaStatus(userType: .guest, questionsUsed: 1)
        XCTAssertEqual(status.progress, 1.0/3.0, accuracy: 0.01)
    }
    
    func testQuotaStatus_Progress_Premium_AlwaysFull() {
        let status = QuotaStatus(userType: .premium, questionsUsed: 50)
        XCTAssertEqual(status.progress, 1.0)
    }
    
    func testQuotaStatus_StatusText_Guest() {
        let status = QuotaStatus(userType: .guest, questionsUsed: 1)
        XCTAssertEqual(status.statusText, "2 of 3 questions remaining")
    }
    
    func testQuotaStatus_StatusText_Premium() {
        let status = QuotaStatus(userType: .premium, questionsUsed: 100)
        XCTAssertEqual(status.statusText, "Unlimited questions")
    }
    
    func testQuotaStatus_ShortStatus_Guest() {
        let status = QuotaStatus(userType: .guest, questionsUsed: 1)
        XCTAssertEqual(status.shortStatus, "2")
    }
    
    func testQuotaStatus_ShortStatus_Premium() {
        let status = QuotaStatus(userType: .premium, questionsUsed: 100)
        XCTAssertEqual(status.shortStatus, "∞")
    }
    
    // MARK: - SubscriptionStatus Decoding Tests
    
    func testSubscriptionStatus_DecodesFromJSON() throws {
        let json = """
        {
            "user_email": "test@example.com",
            "user_type": "registered",
            "questions_asked": 5,
            "questions_limit": 10,
            "questions_remaining": 5,
            "can_ask": true,
            "is_premium": false,
            "subscription_status": null,
            "subscription_expires_at": null
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let status = try decoder.decode(QuotaManager.SubscriptionStatus.self, from: json)
        
        XCTAssertEqual(status.userEmail, "test@example.com")
        XCTAssertEqual(status.userType, "registered")
        XCTAssertEqual(status.questionsAsked, 5)
        XCTAssertEqual(status.questionsLimit, 10)
        XCTAssertEqual(status.questionsRemaining, 5)
        XCTAssertTrue(status.canAsk)
        XCTAssertFalse(status.isPremium)
    }
    
    func testSubscriptionStatus_DecodesFromJSON_Premium() throws {
        let json = """
        {
            "user_email": "premium@example.com",
            "user_type": "premium",
            "questions_asked": 100,
            "questions_limit": 999999,
            "questions_remaining": 999899,
            "can_ask": true,
            "is_premium": true,
            "subscription_status": "active",
            "subscription_expires_at": "2025-01-24T00:00:00"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let status = try decoder.decode(QuotaManager.SubscriptionStatus.self, from: json)
        
        XCTAssertEqual(status.userType, "premium")
        XCTAssertTrue(status.isPremium)
        XCTAssertEqual(status.subscriptionStatus, "active")
        XCTAssertNotNil(status.subscriptionExpiresAt)
    }
    
    // MARK: - API Config Tests
    
    func testAPIConfig_HasSubscriptionEndpoints() {
        XCTAssertEqual(APIConfig.subscriptionRegister, "/subscription/register")
        XCTAssertEqual(APIConfig.subscriptionStatus, "/subscription/status")
        XCTAssertEqual(APIConfig.subscriptionRecord, "/subscription/record")
        XCTAssertEqual(APIConfig.subscriptionUpgrade, "/subscription/upgrade")
        XCTAssertEqual(APIConfig.subscriptionVerify, "/subscription/verify")
    }
    
    func testAPIConfig_DebugHasAPIKey() {
        #if DEBUG
        XCTAssertFalse(APIConfig.apiKey.isEmpty)
        #endif
    }
}

/// Tests for SubscriptionManager StoreKit integration
final class SubscriptionManagerTests: XCTestCase {
    
    func testProductIDs_AreConfigured() {
        XCTAssertEqual(SubscriptionManager.monthlyProductID, "com.destinyai.premium.monthly")
        XCTAssertEqual(SubscriptionManager.yearlyProductID, "com.destinyai.premium.yearly")
    }
    
    func testSubscriptionError_HasLocalizedDescription() {
        XCTAssertEqual(SubscriptionError.verificationFailed.errorDescription, "Transaction verification failed")
        XCTAssertEqual(SubscriptionError.purchaseFailed.errorDescription, "Purchase could not be completed")
        XCTAssertEqual(SubscriptionError.productNotFound.errorDescription, "Product not found")
    }
}

#endif

// MARK: - Guest Email Detection (iOS-12)

/// Tests for `QuotaManager.isGuestEmail` — single source of truth for guest detection.
///
/// Replaces the prior substring heuristic
/// `email.contains("guest") || email.contains("@gen.com")`
/// which misclassified real users like `bguest@example.com` as guests.
final class QuotaManagerGuestEmailTests: XCTestCase {

    /// Anonymous-id format from AppleAuthService: `guest_<uuid8>`.
    func testIsGuestEmail_recognizesGuestPrefix() {
        XCTAssertTrue(QuotaManager.isGuestEmail("guest_abc12345_deadbeef@guest.destiny.ai"))
        XCTAssertTrue(QuotaManager.isGuestEmail("guest_a1b2c3d4"))
    }

    /// Generated-email suffixes recognized by this codebase:
    ///   `@daa.com` — current `EmailGenerator` output
    ///   `@gen.com` — legacy suffix still present on existing accounts
    /// Spec also references `@guest.destiny.ai`; covered via the `guest_` prefix.
    func testIsGuestEmail_recognizesGuestSuffix() {
        XCTAssertTrue(QuotaManager.isGuestEmail("19800701_0000_bhi_21_81@daa.com"))
        XCTAssertTrue(QuotaManager.isGuestEmail("legacy_user@gen.com"))
    }

    /// KEY TEST proving iOS-12 is fixed: a real user whose local-part *contains*
    /// "guest" must NOT be misclassified as a guest by the substring heuristic.
    func testIsGuestEmail_realUserContainingGuest_isFalse() {
        XCTAssertFalse(QuotaManager.isGuestEmail("bguest@example.com"))
        XCTAssertFalse(QuotaManager.isGuestEmail("myguest@gmail.com"))
        XCTAssertFalse(QuotaManager.isGuestEmail("guest.user@company.io"))
    }

    func testIsGuestEmail_emptyString_isFalse() {
        XCTAssertFalse(QuotaManager.isGuestEmail(""))
    }

    func testIsGuestEmail_realEmail_isFalse() {
        XCTAssertFalse(QuotaManager.isGuestEmail("user@gmail.com"))
        XCTAssertFalse(QuotaManager.isGuestEmail("prabhukushwaha@gmail.com"))
        XCTAssertFalse(QuotaManager.isGuestEmail("user@apple.com"))
    }
}

// MARK: - canAsk fail-open behavior (iOS-6)

/// Tests for `QuotaManager.canAsk` — must fail OPEN on network error so that
/// flaky-network users are not locked out of the predict pipeline. The server
/// (atomic `check_and_reserve` in `/vedic/api/predict/stream`) is the source
/// of truth and will reject the request if the user is truly out of quota.
///
/// Standardizes posture across `canAsk` (was: fails closed) and `canAddProfile`
/// (was: fails open) — both now fail open.
final class QuotaManagerCanAskFailOpenTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset()
        super.tearDown()
    }

    /// Server returns 500 → canAccessFeature throws → canAsk must return true
    /// (fail open) so the call site proceeds to the predict endpoint where the
    /// server-side check_and_reserve enforces quota authoritatively.
    func testCanAsk_networkError_failsOpen() async {
        MockURLProtocol.handler(for: "/subscription/can-access") { _ in
            return (500, Data("internal server error".utf8))
        }

        let result = await QuotaManager.shared.canAsk(email: "test@example.com")

        XCTAssertTrue(result, "canAsk must fail open on network error so flaky network does not lock users out; server enforces quota authoritatively")
    }

    /// Sanity: explicit can_access:false from the server is still respected.
    /// Fail-open only applies to network/decode errors, not to authoritative
    /// server denials.
    func testCanAsk_can_access_false_returnsFalse() async {
        MockURLProtocol.stubQuotaDeny(reason: "overall_limit_reached")

        let result = await QuotaManager.shared.canAsk(email: "test@example.com")

        XCTAssertFalse(result, "Authoritative server denial (can_access:false) must propagate; only network errors fail open")
    }

    /// Sanity: explicit can_access:true is respected.
    func testCanAsk_can_access_true_returnsTrue() async {
        MockURLProtocol.stubQuotaAllowAll()

        let result = await QuotaManager.shared.canAsk(email: "test@example.com")

        XCTAssertTrue(result)
    }
}
