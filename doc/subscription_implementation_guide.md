# Subscription System - Complete Implementation Guide

## Table of Contents
1. [Plan Configuration Design](#plan-configuration-design)
2. [Current vs New Architecture](#current-vs-new-architecture)
3. [Database Changes](#database-changes)
4. [Backend Changes](#backend-changes)
5. [iOS Changes](#ios-changes)
6. [End-to-End Flows](#end-to-end-flows)
7. [StoreKit Integration](#storekit-integration)

---

## Plan Configuration Design

### Where Plans Are Configured

**Database Table: `subscription_plans`** - Single source of truth for all plan definitions.

```sql
CREATE TABLE subscription_plans (
    plan_id VARCHAR(50) PRIMARY KEY,
    display_name VARCHAR(100) NOT NULL,
    
    -- Plan Type Flags
    is_free BOOLEAN DEFAULT FALSE,           -- Free plan (no purchase required)
    is_default_guest BOOLEAN DEFAULT FALSE,  -- Auto-assign to new guests
    is_default_registered BOOLEAN DEFAULT FALSE,  -- Auto-assign on login
    
    -- Limits
    overall_question_limit INT DEFAULT -1,   -- -1 = unlimited
    daily_question_limit INT DEFAULT -1,
    
    -- Pricing (for paid plans)
    price_monthly DECIMAL(10,2) DEFAULT 0,
    price_yearly DECIMAL(10,2) DEFAULT 0,
    
    -- App Store Integration
    apple_product_id_monthly VARCHAR(100),   -- 'com.daa.core.monthly'
    apple_product_id_yearly VARCHAR(100),
    google_product_id_monthly VARCHAR(100),
    google_product_id_yearly VARCHAR(100),
    
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0
);
```

### Sample Plan Configuration

| plan_id | display_name | is_free | default_guest | default_registered | daily | overall | price |
|---------|-------------|---------|---------------|-------------------|-------|---------|-------|
| `free_guest` | Free (Guest) | ✓ | ✓ | | 3 | 3 | $0 |
| `free_registered` | Free | ✓ | | ✓ | 10 | 10 | $0 |
| `core` | Core | | | | 20 | 100 | $4.99 |
| `advanced` | Advanced | | | | 50 | 500 | $9.99 |
| `premium` | Premium | | | | ∞ | ∞ | $19.99 |

### How Automatic Plan Assignment Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AUTOMATIC PLAN ASSIGNMENT                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────┐         ┌─────────────────┐         ┌───────────┐  │
│  │ New User    │  auto   │  is_default_    │  query  │ Database  │  │
│  │ (no email)  │ ──────► │  guest = true   │ ◄────── │ Plans     │  │
│  └─────────────┘         │  → free_guest   │         └───────────┘  │
│                          └─────────────────┘                        │
│                                                                      │
│  ┌─────────────┐         ┌─────────────────┐         ┌───────────┐  │
│  │ User Signs  │  auto   │  is_default_    │  query  │ Database  │  │
│  │ In (Apple)  │ ──────► │  registered=true│ ◄────── │ Plans     │  │
│  └─────────────┘         │  → free_reg     │         └───────────┘  │
│                          └─────────────────┘                        │
│                                                                      │
│  ┌─────────────┐         ┌─────────────────┐         ┌───────────┐  │
│  │ User Buys   │ verify  │ Look up plan by │ match   │ Database  │  │
│  │ Subscription│ ──────► │ apple_product_id│ ◄────── │ Plans     │  │
│  └─────────────┘         │ → core/premium  │         └───────────┘  │
│                          └─────────────────┘                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Current vs New Architecture

### Current Architecture (Hardcoded)

| Component | Current Implementation |
|-----------|----------------------|
| **Backend QUOTA_LIMITS** | `{"guest": 3, "registered": 10, "premium": 999999}` |
| **Backend user_type** | String enum: guest/registered/premium |
| **iOS UserType** | Swift enum with hardcoded `questionLimit` property |
| **Plan assignment** | Derived from authentication state |

### New Architecture (Config-Driven)

| Component | New Implementation |
|-----------|-------------------|
| **Backend plans** | `subscription_plans` table with all limits |
| **Backend user.plan_id** | FK to subscription_plans.plan_id |
| **iOS plan_id** | String received from server |
| **Features** | `plan_entitlements` table for feature access |
| **Plan assignment** | Query database for `is_default_*` flag |

---

## Database Changes

### 1. Add New Tables

```sql
-- Table 1: subscription_plans (plan definitions)
CREATE TABLE subscription_plans (
    plan_id VARCHAR(50) PRIMARY KEY,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Type flags
    is_free BOOLEAN DEFAULT FALSE,
    is_default_guest BOOLEAN DEFAULT FALSE,
    is_default_registered BOOLEAN DEFAULT FALSE,
    
    -- Limits
    overall_question_limit INT DEFAULT -1,
    daily_question_limit INT DEFAULT -1,
    
    -- Pricing
    price_monthly DECIMAL(10,2) DEFAULT 0,
    price_yearly DECIMAL(10,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- App Store product IDs
    apple_product_id_monthly VARCHAR(100),
    apple_product_id_yearly VARCHAR(100),
    google_product_id_monthly VARCHAR(100),
    google_product_id_yearly VARCHAR(100),
    
    -- Metadata
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    features_json TEXT,  -- Quick feature list for UI
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Table 2: features (feature catalog)
CREATE TABLE features (
    feature_id VARCHAR(50) PRIMARY KEY,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    icon_name VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0
);

-- Table 3: plan_entitlements (feature access matrix)
CREATE TABLE plan_entitlements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plan_id VARCHAR(50) REFERENCES subscription_plans(plan_id),
    feature_id VARCHAR(50) REFERENCES features(feature_id),
    is_enabled BOOLEAN DEFAULT TRUE,
    daily_limit INT DEFAULT -1,
    overall_limit INT DEFAULT -1,
    UNIQUE(plan_id, feature_id)
);
```

### 2. Modify user_subscriptions

```sql
-- Add new columns to existing table
ALTER TABLE user_subscriptions ADD COLUMN plan_id VARCHAR(50) REFERENCES subscription_plans(plan_id);
ALTER TABLE user_subscriptions ADD COLUMN daily_questions_asked INT DEFAULT 0;
ALTER TABLE user_subscriptions ADD COLUMN daily_usage_date DATE;
ALTER TABLE user_subscriptions ADD COLUMN feature_usage TEXT;  -- JSON

-- Migration: Set plan_id based on existing user_type
UPDATE user_subscriptions SET plan_id = 'free_guest' WHERE user_type = 'guest';
UPDATE user_subscriptions SET plan_id = 'free_registered' WHERE user_type = 'registered';
UPDATE user_subscriptions SET plan_id = 'premium' WHERE user_type = 'premium';
```

### 3. Seed Data

```sql
-- Insert default plans
INSERT INTO subscription_plans VALUES
    ('free_guest', 'Free (Guest)', 'Limited free access', TRUE, TRUE, FALSE, 3, 3, 0, 0, 'USD', NULL, NULL, NULL, NULL, TRUE, 0, '["chat", "compatibility"]', NOW(), NOW()),
    ('free_registered', 'Free', 'Free tier for signed-in users', TRUE, FALSE, TRUE, 10, 10, 0, 0, 'USD', NULL, NULL, NULL, NULL, TRUE, 1, '["chat", "compatibility", "dasha"]', NOW(), NOW()),
    ('core', 'Core', 'Essential features', FALSE, FALSE, FALSE, 100, 20, 4.99, 49.99, 'USD', 'com.daa.core.monthly', 'com.daa.core.yearly', NULL, NULL, TRUE, 2, '["chat", "compatibility", "calibration", "dasha"]', NOW(), NOW()),
    ('advanced', 'Advanced', 'Advanced features', FALSE, FALSE, FALSE, 500, 50, 9.99, 99.99, 'USD', 'com.daa.advanced.monthly', 'com.daa.advanced.yearly', NULL, NULL, TRUE, 3, '["all"]', NOW(), NOW()),
    ('premium', 'Premium', 'Unlimited access', FALSE, FALSE, FALSE, -1, -1, 19.99, 199.99, 'USD', 'com.daa.premium.monthly', 'com.daa.premium.yearly', NULL, NULL, TRUE, 4, '["all", "priority_support"]', NOW(), NOW());

-- Insert features
INSERT INTO features VALUES
    ('chat', 'AI Chat', 'Ask questions about your horoscope', 'core', 'message.fill', TRUE, 0),
    ('compatibility', 'Kundali Match', 'Check compatibility', 'core', 'heart.fill', TRUE, 1),
    ('birth_calibration', 'Birth Time Calibration', 'Precise birth time', 'advanced', 'clock.fill', TRUE, 2),
    ('dasha_analysis', 'Dasha Analysis', 'Life period analysis', 'astrology', 'calendar', TRUE, 3),
    ('muhurta', 'Muhurta', 'Auspicious timing', 'advanced', 'star.fill', TRUE, 4),
    ('remedies', 'Remedies', 'Personalized remedies', 'premium', 'sparkles', TRUE, 5),
    ('pdf_export', 'PDF Export', 'Download reports', 'premium', 'doc.fill', TRUE, 6);
```

---

## Backend Changes

### 1. New Model: SubscriptionPlan

```python
# app/core/shared_services/subscription/models.py

class SubscriptionPlan(Base):
    """Plan definitions - configuration table"""
    __tablename__ = "subscription_plans"
    
    plan_id = Column(String(50), primary_key=True)
    display_name = Column(String(100), nullable=False)
    description = Column(Text)
    
    # Type flags
    is_free = Column(Boolean, default=False)
    is_default_guest = Column(Boolean, default=False)
    is_default_registered = Column(Boolean, default=False)
    
    # Limits
    overall_question_limit = Column(Integer, default=-1)
    daily_question_limit = Column(Integer, default=-1)
    
    # Pricing
    price_monthly = Column(Float, default=0)
    price_yearly = Column(Float, default=0)
    
    # App Store product IDs
    apple_product_id_monthly = Column(String(100))
    apple_product_id_yearly = Column(String(100))
    
    @property
    def is_unlimited(self):
        return self.overall_question_limit == -1
```

### 2. Enhanced QuotaService

```python
# app/core/shared_services/subscription/quota_service.py

class QuotaService:
    
    def get_default_plan(self, user_type: str) -> str:
        """Get default plan_id based on user type"""
        with self.db.get_session() as session:
            if user_type == "guest":
                plan = session.query(SubscriptionPlan).filter(
                    SubscriptionPlan.is_default_guest == True,
                    SubscriptionPlan.is_active == True
                ).first()
            else:
                plan = session.query(SubscriptionPlan).filter(
                    SubscriptionPlan.is_default_registered == True,
                    SubscriptionPlan.is_active == True
                ).first()
            return plan.plan_id if plan else ("free_guest" if user_type == "guest" else "free_registered")
    
    def get_plan_by_product_id(self, apple_product_id: str) -> Optional[SubscriptionPlan]:
        """Find plan by Apple product ID (used after purchase)"""
        with self.db.get_session() as session:
            return session.query(SubscriptionPlan).filter(
                (SubscriptionPlan.apple_product_id_monthly == apple_product_id) |
                (SubscriptionPlan.apple_product_id_yearly == apple_product_id)
            ).first()
    
    def can_access_feature(self, email: str, feature_id: str) -> dict:
        """Check if user can access a specific feature"""
        with self.db.get_session() as session:
            user = session.query(UserSubscription).filter(
                UserSubscription.user_email == email
            ).first()
            
            if not user:
                return {"can_access": False, "reason": "user_not_found"}
            
            # Get entitlement
            entitlement = session.query(PlanEntitlement).filter(
                PlanEntitlement.plan_id == user.plan_id,
                PlanEntitlement.feature_id == feature_id
            ).first()
            
            if not entitlement or not entitlement.is_enabled:
                return {
                    "can_access": False,
                    "reason": "feature_not_available",
                    "upgrade_cta": self._get_upgrade_cta(feature_id)
                }
            
            # Check limits
            usage = self._get_feature_usage(user, feature_id)
            
            # Daily limit check
            if entitlement.daily_limit != -1 and usage["daily"] >= entitlement.daily_limit:
                return {
                    "can_access": False,
                    "reason": "daily_limit_reached",
                    "limits": {"daily": {"used": usage["daily"], "limit": entitlement.daily_limit}},
                    "reset_at": self._get_next_reset_time()
                }
            
            # Overall limit check
            if entitlement.overall_limit != -1 and usage["overall"] >= entitlement.overall_limit:
                return {
                    "can_access": False,
                    "reason": "overall_limit_reached",
                    "limits": {"overall": {"used": usage["overall"], "limit": entitlement.overall_limit}},
                    "upgrade_cta": self._get_upgrade_cta(feature_id)
                }
            
            return {
                "can_access": True,
                "feature": feature_id,
                "plan": user.plan_id,
                "limits": {
                    "daily": {"used": usage["daily"], "limit": entitlement.daily_limit},
                    "overall": {"used": usage["overall"], "limit": entitlement.overall_limit}
                }
            }
```

### 3. New API Endpoints

```python
# app/core/api/subscription_router.py

@router.get("/can-access")
async def check_feature_access(email: str, feature: str):
    """Check if user can access a specific feature"""
    quota_service = get_quota_service()
    return quota_service.can_access_feature(email, feature)

@router.post("/record-usage")
async def record_feature_usage(email: str, feature: str):
    """Record usage of a specific feature"""
    quota_service = get_quota_service()
    return quota_service.record_feature_usage(email, feature)

@router.get("/plans")
async def get_available_plans(include_features: bool = False):
    """Get all available subscription plans for paywall"""
    quota_service = get_quota_service()
    return quota_service.get_available_plans(include_features)
```

---

## iOS Changes

### 1. New API Response Models

```swift
// Models/SubscriptionModels.swift

struct PlanInfo: Codable {
    let planId: String
    let displayName: String
    let isUnlimited: Bool
    let dailyLimit: Int
    let overallLimit: Int
    let features: [String]
    
    enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case displayName = "display_name"
        case isUnlimited = "is_unlimited"
        case dailyLimit = "daily_limit"
        case overallLimit = "overall_limit"
        case features
    }
}

struct FeatureAccess: Codable {
    let canAccess: Bool
    let feature: String
    let plan: String?
    let reason: String?
    let limits: FeatureLimits?
    let upgradeCTA: UpgradeCTA?
    let resetAt: String?
    
    enum CodingKeys: String, CodingKey {
        case canAccess = "can_access"
        case feature, plan, reason, limits
        case upgradeCTA = "upgrade_cta"
        case resetAt = "reset_at"
    }
}

struct FeatureLimits: Codable {
    let daily: UsageLimit?
    let overall: UsageLimit?
}

struct UsageLimit: Codable {
    let used: Int
    let limit: Int
    
    var remaining: Int { max(0, limit - used) }
    var isUnlimited: Bool { limit == -1 }
}
```

### 2. Enhanced QuotaManager

```swift
// Services/QuotaManager.swift

@MainActor
class QuotaManager: ObservableObject {
    
    // NEW: Feature-specific access check
    func canAccess(feature: String) async -> FeatureAccess {
        guard let email = getCurrentUserEmail() else {
            return FeatureAccess(canAccess: false, feature: feature, reason: "no_user")
        }
        
        var components = URLComponents(string: APIConfig.baseURL + "/subscription/can-access")!
        components.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "feature", value: feature)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(FeatureAccess.self, from: data)
        } catch {
            // Fallback to local check
            return FeatureAccess(
                canAccess: canAsk,
                feature: feature,
                reason: nil
            )
        }
    }
    
    // NEW: Record feature usage
    func recordUsage(feature: String) async {
        guard let email = getCurrentUserEmail() else { return }
        
        var components = URLComponents(string: APIConfig.baseURL + "/subscription/record-usage")!
        components.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "feature", value: feature)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        _ = try? await URLSession.shared.data(for: request)
        recordQuestion()  // Also update local count
    }
    
    // EXISTING: canAsk (backward compatible via canAccess("chat"))
    var canAsk: Bool {
        currentStatus.canAsk
    }
}
```

### 3. Feature Gating at Entry Points

```swift
// Views/Chat/ChatView.swift

Button("Send") {
    Task {
        let access = await QuotaManager.shared.canAccess(feature: "chat")
        if access.canAccess {
            await viewModel.sendMessage()
            await QuotaManager.shared.recordUsage(feature: "chat")
        } else {
            showFeaturePaywall(access: access)
        }
    }
}

// Views/Compatibility/CompatibilityView.swift

Button("Analyze Match") {
    Task {
        let access = await QuotaManager.shared.canAccess(feature: "compatibility")
        if access.canAccess {
            await viewModel.analyzeMatch()
            await QuotaManager.shared.recordUsage(feature: "compatibility")
        } else {
            showFeaturePaywall(access: access)
        }
    }
}
```

---

## End-to-End Flows

### Flow 1: New Guest User

```
User opens app for first time
         │
         ▼
┌─────────────────────────────────────────┐
│ iOS: User enters birth data             │
│ iOS: Generate email from birth data     │
│ iOS: Call POST /subscription/register   │
│      {email, user_type: "guest"}        │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Backend: Query SELECT plan_id FROM      │
│   subscription_plans WHERE              │
│   is_default_guest = TRUE               │
│                                         │
│ Result: plan_id = "free_guest"          │
│                                         │
│ Backend: Create user with plan_id       │
│ Backend: Return limits from plan        │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ iOS: User has 3 questions (from plan)   │
│ iOS: Chat/Compatibility enabled         │
│ iOS: Advanced features locked           │
└─────────────────────────────────────────┘
```

### Flow 2: Guest Signs In → Free Registered

```
Guest user taps "Sign In with Apple"
         │
         ▼
┌─────────────────────────────────────────┐
│ iOS: Authenticate with Apple            │
│ iOS: Get real email                     │
│ iOS: Call POST /subscription/upgrade    │
│      {old_email, new_email,             │
│       new_type: "registered"}           │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Backend: Query SELECT plan_id FROM      │
│   subscription_plans WHERE              │
│   is_default_registered = TRUE          │
│                                         │
│ Result: plan_id = "free_registered"     │
│                                         │
│ Backend: Update user plan_id            │
│ Backend: Carry over questions_asked     │
│ Backend: Return new limits (10/day)     │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ iOS: User now has 10 questions          │
│ iOS: Dasha feature unlocked             │
│ iOS: Calibration still locked           │
└─────────────────────────────────────────┘
```

### Flow 3: User Purchases Core Plan

```
User taps "Upgrade to Core" in SubscriptionView
         │
         ▼
┌─────────────────────────────────────────┐
│ iOS: StoreKit purchase flow             │
│      Product: com.daa.core.monthly      │
│ Apple: Process payment                  │
│ iOS: Receive Transaction                │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ iOS: Call POST /subscription/verify     │
│      {jws, email, platform: "apple"}    │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Backend: Verify JWS with Apple          │
│ Backend: Extract product_id             │
│                                         │
│ Backend: Query SELECT plan_id FROM      │
│   subscription_plans WHERE              │
│   apple_product_id_monthly =            │
│   'com.daa.core.monthly'                │
│                                         │
│ Result: plan_id = "core"                │
│                                         │
│ Backend: Update user plan_id = "core"   │
│ Backend: Set subscription_expires_at    │
│ Backend: Return new limits (20/day)     │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ iOS: User now has 100 questions         │
│ iOS: 20/day limit                       │
│ iOS: Calibration unlocked!              │
└─────────────────────────────────────────┘
```

### Flow 4: Daily Limit Reached

```
User asks 20th question on Core plan
         │
         ▼
┌─────────────────────────────────────────┐
│ iOS: Call GET /subscription/can-access  │
│      ?email=x&feature=chat              │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Backend: Check plan_entitlements        │
│   daily_limit = 20 for chat on core     │
│                                         │
│ Backend: Check feature_usage JSON       │
│   chat.daily = 20                       │
│                                         │
│ Backend: Return:                        │
│   {can_access: false,                   │
│    reason: "daily_limit_reached",       │
│    reset_at: "2026-01-04T00:00:00Z"}    │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ iOS: Show "Daily limit reached"         │
│ iOS: "Resets at midnight" message       │
│ iOS: Offer upgrade to Advanced/Premium  │
└─────────────────────────────────────────┘
```

### Flow 5: Subscription Renewal (Webhook)

```
Apple sends renewal notification
         │
         ▼
┌─────────────────────────────────────────┐
│ POST /subscription/webhook/apple        │
│ {signedPayload: "..."}                  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Backend: Decode JWS                     │
│ Backend: notificationType = DID_RENEW   │
│ Backend: Find user by original_txn_id   │
│ Backend: Update subscription_expires_at │
│                                         │
│ (plan_id stays the same - core)         │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ User continues with Core plan           │
│ Seamless experience                     │
└─────────────────────────────────────────┘
```

### Flow 6: Subscription Expires

```
Subscription expires (no renewal)
         │
         ▼
┌─────────────────────────────────────────┐
│ Apple Webhook: EXPIRED notification     │
│ OR                                       │
│ Backend: Fallback expiry check          │
│   (subscription_expires_at < now)       │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ Backend: Query SELECT plan_id FROM      │
│   subscription_plans WHERE              │
│   is_default_registered = TRUE          │
│                                         │
│ Backend: Update user:                   │
│   plan_id = "free_registered"           │
│   subscription_status = "expired"       │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│ iOS: Next canAccess() returns new limits│
│ iOS: User downgraded to 10 questions    │
│ iOS: Advanced features locked again     │
└─────────────────────────────────────────┘
```

---

## StoreKit Integration

### Product ID Mapping in Database

The `subscription_plans` table contains Store product IDs, enabling:

1. **Dynamic product loading** - iOS can fetch plans from server
2. **Automatic plan matching** - After purchase, find plan by product ID
3. **Multiple billing periods** - Monthly and yearly mapped to same plan

```swift
// SubscriptionManager.swift

/// Load products from database-configured product IDs
func loadProductsFromServer() async {
    // 1. Fetch available plans from server
    let plans = await fetchPlansFromServer()
    
    // 2. Extract all product IDs
    var productIDs: Set<String> = []
    for plan in plans {
        if let monthly = plan.appleProductIdMonthly { productIDs.insert(monthly) }
        if let yearly = plan.appleProductIdYearly { productIDs.insert(yearly) }
    }
    
    // 3. Request products from StoreKit
    products = try await Product.products(for: productIDs)
}
```

---

## Summary

| Question | Answer |
|----------|--------|
| **Where are plans configured?** | `subscription_plans` database table |
| **How is guest plan assigned?** | Query `is_default_guest = TRUE` |
| **How is login plan assigned?** | Query `is_default_registered = TRUE` |
| **How is paid plan assigned?** | Query by `apple_product_id_*` after purchase |
| **Can plans change without code?** | Yes, update database rows |
| **Can features change without code?** | Yes, update `plan_entitlements` table |
