import XCTest
@testable import ios_app

/// Tests for QuotaManager and related subscription functionality
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
