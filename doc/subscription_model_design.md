# Flexible Subscription Model Design

## Overview

A **config-driven entitlement system** that allows subscription plans, features, and usage limits to be modified through database/admin changes without code deployments.

> **Research Sources:** RevenueCat entitlements pattern, SaaS tiered pricing best practices, usage-based billing patterns from Twilio, Zapier, AWS

---

## Key Design Principles (From Research)

| Principle | Implementation |
|-----------|---------------|
| **Entitlements abstract features** | Check entitlement, not product ID |
| **Config-only changes** | Add features, modify limits without code deploy |
| **Feature isolation** | Each feature has independent limits |
| **Daily + Overall limits** | Prevents abuse while allowing fair usage |
| **Value alignment** | Pricing correlates with customer value |

---

## Architecture: 3-Table Entitlement System

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CONFIGURATION LAYER                               │
│                    (Changeable without code deploy)                      │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐    ┌──────────────────┐    ┌───────────────────┐  │
│  │  subscription_   │    │    features      │    │ plan_entitlements │  │
│  │     plans        │    │                  │    │ (junction table)  │  │
│  │                  │◀──▶│ - chat           │◀──▶│                   │  │
│  │ - free_guest     │    │ - compatibility  │    │ plan + feature +  │  │
│  │ - free_registered│    │ - calibration    │    │ daily_limit +     │  │
│  │ - core           │    │ - dasha          │    │ enabled           │  │
│  │ - advanced       │    │ - muhurta        │    │                   │  │
│  │ - premium        │    │ ...              │    │                   │  │
│  └──────────────────┘    └──────────────────┘    └───────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER DATA LAYER                                 │
│                       (Runtime tracking)                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                      user_subscriptions                           │   │
│  │  - plan_id (FK to subscription_plans)                            │   │
│  │  - overall_usage, daily_usage, last_usage_date                   │   │
│  │  - feature_usage (JSON: {chat: 5, compatibility: 2})             │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### 1. `subscription_plans` (Plan Definitions)

```sql
CREATE TABLE subscription_plans (
    plan_id VARCHAR(50) PRIMARY KEY,        -- 'free_guest', 'core', 'premium'
    display_name VARCHAR(100) NOT NULL,     -- 'Free Guest', 'Core Plan'
    description TEXT,
    
    -- Pricing
    price_monthly DECIMAL(10,2) DEFAULT 0,
    price_yearly DECIMAL(10,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Overall Limits
    overall_question_limit INT DEFAULT -1,  -- -1 = unlimited
    
    -- Daily Limits (global for plan)
    daily_question_limit INT DEFAULT -1,    -- -1 = unlimited
    
    -- Plan metadata
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,               -- Display ordering
    app_store_product_id VARCHAR(100),      -- 'com.daa.core.monthly'
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**Sample Data:**
| plan_id | display_name | overall_limit | daily_limit | price_monthly |
|---------|-------------|---------------|-------------|---------------|
| `free_guest` | Free (Guest) | 3 | 3 | 0 |
| `free_registered` | Free (Registered) | 10 | 10 | 0 |
| `core` | Core | 100 | 20 | 4.99 |
| `advanced` | Advanced | 500 | 50 | 9.99 |
| `premium` | Premium | -1 (unlimited) | -1 | 19.99 |

---

### 2. `features` (Feature Catalog)

```sql
CREATE TABLE features (
    feature_id VARCHAR(50) PRIMARY KEY,     -- 'chat', 'compatibility'
    display_name VARCHAR(100) NOT NULL,     -- 'AI Chat'
    description TEXT,
    category VARCHAR(50),                   -- 'core', 'astrology', 'advanced'
    
    -- Feature metadata
    icon_name VARCHAR(50),                  -- 'message.fill'
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Features for DestinyAI:**
| feature_id | display_name | category |
|-----------|-------------|----------|
| `chat` | AI Chat Predictions | core |
| `compatibility` | Kundali Matching | core |
| `birth_calibration` | Birth Time Calibration | advanced |
| `dasha_analysis` | Dasha Period Analysis | astrology |
| `muhurta` | Auspicious Timing | advanced |
| `remedies` | Personalized Remedies | premium |
| `pdf_export` | PDF Report Export | premium |
| `chart_comparison` | Chart Comparison | astrology |

---

### 3. `plan_entitlements` (Feature Access Matrix)

```sql
CREATE TABLE plan_entitlements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    plan_id VARCHAR(50) REFERENCES subscription_plans(plan_id),
    feature_id VARCHAR(50) REFERENCES features(feature_id),
    
    -- Access control
    is_enabled BOOLEAN DEFAULT TRUE,
    daily_limit INT DEFAULT -1,             -- Feature-specific daily limit (-1 = unlimited)
    overall_limit INT DEFAULT -1,           -- Feature-specific overall limit
    
    -- Optional overrides
    custom_message TEXT,                    -- "Upgrade to unlock X"
    
    UNIQUE(plan_id, feature_id)
);
```

**Full Feature Matrix:**

| Plan | chat | compatibility | birth_calibration | dasha | muhurta | remedies | pdf_export |
|------|------|--------------|-------------------|-------|---------|----------|------------|
| **free_guest** | 3/day, 3 total | 1/day, 1 total | ✗ | ✗ | ✗ | ✗ | ✗ |
| **free_registered** | 10/day, 10 total | 3/day, 5 total | ✗ | ✓ (3) | ✗ | ✗ | ✗ |
| **core** | 20/day, 100 total | 5/day, 30 total | 2/day, 10 | ✓ (∞) | 3/day | ✗ | ✗ |
| **advanced** | 50/day, 500 total | 20/day, 100 total | 5/day, 50 | ✓ (∞) | 10/day | 5/day | 3/month |
| **premium** | ∞ | ∞ | ∞ | ∞ | ∞ | ∞ | ∞ |

---

### 4. `user_subscriptions` (User State - Enhanced)

```sql
CREATE TABLE user_subscriptions (
    user_email VARCHAR(255) PRIMARY KEY,
    plan_id VARCHAR(50) REFERENCES subscription_plans(plan_id),
    
    -- Overall usage
    total_questions_asked INT DEFAULT 0,
    
    -- Daily usage (reset at midnight)
    daily_questions_asked INT DEFAULT 0,
    daily_usage_date DATE,                  -- Last date daily counter was updated
    
    -- Feature-specific usage (JSON for flexibility)
    feature_usage JSON,                     -- {"chat": {"daily": 5, "overall": 23}}
    feature_usage_date DATE,                -- Last date feature daily counters reset
    
    -- Existing subscription fields (unchanged)
    subscription_platform VARCHAR(20),
    subscription_status VARCHAR(30),
    subscription_expires_at TIMESTAMP,
    platform_reference_id VARCHAR(150),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**Feature Usage JSON Structure:**
```json
{
  "chat": {"daily": 5, "overall": 45},
  "compatibility": {"daily": 2, "overall": 12},
  "birth_calibration": {"daily": 0, "overall": 0}
}
```

---

## Backend API

### 1. Check Feature Access

```http
GET /subscription/can-access?email={email}&feature={feature}
```

**Success Response:**
```json
{
  "can_access": true,
  "feature": "chat",
  "plan": "core",
  "limits": {
    "daily": { "used": 5, "limit": 20, "remaining": 15 },
    "overall": { "used": 45, "limit": 100, "remaining": 55 }
  }
}
```

**Limit Reached Response:**
```json
{
  "can_access": false,
  "feature": "compatibility",
  "plan": "free_guest",
  "reason": "daily_limit_reached",
  "limits": {
    "daily": { "used": 1, "limit": 1, "remaining": 0 },
    "overall": { "used": 1, "limit": 1, "remaining": 0 }
  },
  "upgrade_cta": {
    "message": "Upgrade to Core for 30 compatibility checks",
    "suggested_plan": "core",
    "next_reset": "2026-01-04T00:00:00Z"
  }
}
```

### 2. Record Feature Usage

```http
POST /subscription/record-usage?email={email}&feature={feature}
```

### 3. Get All Plans (For Paywall)

```http
GET /subscription/plans?include_features=true
```

---

## iOS Implementation

### 1. Enhanced QuotaManager

```swift
// NEW: Feature-specific access check
struct FeatureAccess: Codable {
    let canAccess: Bool
    let feature: String
    let plan: String
    let limits: FeatureLimits
    let upgradeCTA: UpgradeCTA?
}

struct FeatureLimits: Codable {
    let daily: UsageLimit
    let overall: UsageLimit
}

struct UsageLimit: Codable {
    let used: Int
    let limit: Int
    let remaining: Int
}

// QuotaManager additions
extension QuotaManager {
    // Check specific feature access
    func canAccess(feature: String) async -> FeatureAccess
    
    // Record feature usage after successful action
    func recordUsage(feature: String) async
}
```

### 2. Feature Gating Pattern (All Entry Points)

```swift
// Standard pattern for ALL feature entry points
Button("Check Compatibility") {
    Task {
        let access = await QuotaManager.shared.canAccess(feature: "compatibility")
        
        if access.canAccess {
            await analyzeCompatibility()
            await QuotaManager.shared.recordUsage(feature: "compatibility")
        } else {
            showFeaturePaywall(access: access)
        }
    }
}
```

### 3. Feature-Specific Paywall

```swift
struct FeaturePaywallView: View {
    let access: FeatureAccess
    
    var body: some View {
        VStack {
            Text("Upgrade Required")
            Text(access.upgradeCTA?.message ?? "Upgrade for more access")
            
            if access.limits.daily.remaining == 0 {
                Text("Daily limit reached. Resets at midnight.")
            }
            
            Button("Upgrade to \(access.upgradeCTA?.suggestedPlan ?? "Premium")") {
                showSubscriptionView(highlightPlan: access.upgradeCTA?.suggestedPlan)
            }
        }
    }
}
```

---

## Configuration Examples

### Add New Feature (No Code Changes)

```sql
-- 1. Add feature
INSERT INTO features (feature_id, display_name, category) 
VALUES ('yearly_forecast', 'Yearly Forecast', 'premium');

-- 2. Set entitlements for each plan
INSERT INTO plan_entitlements (plan_id, feature_id, is_enabled, daily_limit, overall_limit)
VALUES 
    ('free_guest', 'yearly_forecast', FALSE, 0, 0),
    ('core', 'yearly_forecast', TRUE, 1, 4),
    ('premium', 'yearly_forecast', TRUE, -1, -1);
```

### Modify Daily Limits (Instant Effect)

```sql
UPDATE plan_entitlements 
SET daily_limit = 30 
WHERE plan_id = 'core' AND feature_id = 'chat';
```

### Holiday Promo (Double All Limits)

```sql
-- Enable promo
UPDATE subscription_plans 
SET daily_question_limit = daily_question_limit * 2;

-- Disable promo (revert)
UPDATE subscription_plans 
SET daily_question_limit = daily_question_limit / 2;
```

---

## Migration Path

| Phase | Description | Timeframe |
|-------|-------------|-----------|
| **Phase 1** | Create new tables, keep existing system working | Week 1 |
| **Phase 2** | Add `plan_id` to user_subscriptions, migrate `user_type` values | Week 2 |
| **Phase 3** | Implement feature-level tracking with JSON storage | Week 3 |
| **Phase 4** | Update iOS to use `canAccess(feature:)` pattern | Week 4 |
| **Phase 5** | Admin dashboard for plan/feature management | Week 5+ |

---

## Benefits Summary

| Benefit | Description |
|---------|-------------|
| ✅ **Config-only changes** | Add features, modify limits without code deploy |
| ✅ **Feature isolation** | Each feature has independent daily+overall limits |
| ✅ **Flexible plans** | Easy to create new tiers (student, family, enterprise) |
| ✅ **Dynamic paywalls** | UI shows relevant upgrade based on blocked feature |
| ✅ **Backward compatible** | Existing `canAsk` still works via `canAccess("chat")` |
| ✅ **Platform agnostic** | Works with Apple, Google, Stripe subscriptions |
| ✅ **Analytics ready** | Feature usage JSON enables detailed analytics |
