# Subscription System - Complete Data Model

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CONFIGURATION TABLES                               │
│                        (Admin-managed, rarely changes)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────┐         ┌──────────────────────────┐          │
│  │   subscription_plans     │         │      features            │          │
│  ├──────────────────────────┤         ├──────────────────────────┤          │
│  │ PK plan_id VARCHAR(50)   │         │ PK feature_id VARCHAR(50)│          │
│  │    display_name          │         │    display_name          │          │
│  │    description           │         │    description           │          │
│  │    is_free               │         │    category              │          │
│  │    is_default_guest      │         │    icon_name             │          │
│  │    is_default_registered │         │    requires_quota BOOL   │ ◄── NEW  │
│  │    price_monthly         │         │    is_active             │          │
│  │    price_yearly          │         │    sort_order            │          │
│  │    currency              │         │    created_at            │          │
│  │    apple_product_id_mo   │         └──────────────────────────┘          │
│  │    apple_product_id_yr   │                    │                          │
│  │    google_product_id_mo  │                    │                          │
│  │    google_product_id_yr  │                    │                          │
│  │    is_active             │                    │                          │
│  │    sort_order            │                    │                          │
│  │    created_at            │                    │                          │
│  │    updated_at            │                    │                          │
│  └──────────────────────────┘                    │                          │
│              │                                    │                          │
│              │                                    │                          │
│              ▼                                    ▼                          │
│  ┌───────────────────────────────────────────────────────────────────┐      │
│  │                      plan_entitlements                             │      │
│  ├───────────────────────────────────────────────────────────────────┤      │
│  │ PK id INTEGER AUTO                                                 │      │
│  │ FK plan_id VARCHAR(50) ────────────────────► subscription_plans   │      │
│  │ FK feature_id VARCHAR(50) ─────────────────► features             │      │
│  │    is_enabled BOOLEAN                                              │      │
│  │    daily_limit INT (-1 = unlimited)                                │      │
│  │    overall_limit INT (-1 = unlimited)                              │      │
│  │    UNIQUE(plan_id, feature_id)                                     │      │
│  └───────────────────────────────────────────────────────────────────┘      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ FK plan_id
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             USER DATA TABLE                                  │
│                          (Per-user, changes often)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────┐      │
│  │                      user_subscriptions                            │      │
│  ├───────────────────────────────────────────────────────────────────┤      │
│  │ PK user_email VARCHAR(255)  ◄──── UNIQUE KEY (email-based)        │      │
│  │ FK plan_id VARCHAR(50) ─────────► subscription_plans              │      │
│  │                                                                    │      │
│  │ -- Usage Tracking --                                               │      │
│  │    total_questions_asked INT                                       │      │
│  │    daily_questions_asked INT                                       │      │
│  │    daily_usage_date DATE                                           │      │
│  │    feature_usage JSON   ◄── {"chat": {"daily": 5, "overall": 45}}  │      │
│  │                                                                    │      │
│  │ -- Subscription Details --                                         │      │
│  │    subscription_platform VARCHAR(20)   apple/google/stripe/manual  │      │
│  │    subscription_id VARCHAR(100)                                    │      │
│  │    product_id VARCHAR(100)                                         │      │
│  │    subscription_status VARCHAR(30)     active/expired/grace_period │      │
│  │    subscription_start_at DATETIME                                  │      │
│  │    subscription_expires_at DATETIME                                │      │
│  │    platform_reference_id VARCHAR(150)  For webhook lookups         │      │
│  │    environment VARCHAR(20)             Sandbox/Production          │      │
│  │                                                                    │      │
│  │ -- Birth Profile --                                                │      │
│  │    user_name VARCHAR(255)                                          │      │
│  │    is_generated_email BOOLEAN                                      │      │
│  │    date_of_birth DATE                                              │      │
│  │    time_of_birth VARCHAR(10)           HH:MM format                │      │
│  │    city_of_birth VARCHAR(255)                                      │      │
│  │    latitude FLOAT                                                  │      │
│  │    longitude FLOAT                                                 │      │
│  │    gender VARCHAR(20)                                              │      │
│  │    birth_time_unknown BOOLEAN                                      │      │
│  │                                                                    │      │
│  │ -- Identity Linking --                                             │      │
│  │    google_id VARCHAR(255) UNIQUE                                   │      │
│  │    apple_id VARCHAR(255) UNIQUE                                    │      │
│  │                                                                    │      │
│  │ -- Timestamps --                                                   │      │
│  │    created_at DATETIME                                             │      │
│  │    updated_at DATETIME                                             │      │
│  │    last_question_at DATETIME                                       │      │
│  └───────────────────────────────────────────────────────────────────┘      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Table 1: `subscription_plans` (NEW)

**Purpose:** Define all available subscription plans with pricing and default assignment.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `plan_id` | VARCHAR(50) | **PK** Unique plan identifier | `"free_guest"`, `"core"` |
| `display_name` | VARCHAR(100) | UI display name | `"Free (Guest)"` |
| `description` | TEXT | Plan description | `"Basic free access"` |
| `is_free` | BOOLEAN | Is this a free plan? | `TRUE` |
| `is_default_guest` | BOOLEAN | Auto-assign to new guests? | `TRUE` for free_guest only |
| `is_default_registered` | BOOLEAN | Auto-assign on login? | `TRUE` for free_registered only |
| `price_monthly` | DECIMAL(10,2) | Monthly price | `4.99` |
| `price_yearly` | DECIMAL(10,2) | Yearly price | `49.99` |
| `currency` | VARCHAR(3) | Currency code | `"USD"` |
| `apple_product_id_monthly` | VARCHAR(100) | App Store monthly product ID | `"com.daa.core.monthly"` |
| `apple_product_id_yearly` | VARCHAR(100) | App Store yearly product ID | `"com.daa.core.yearly"` |
| `google_product_id_monthly` | VARCHAR(100) | Play Store monthly product ID | `"core_monthly"` |
| `google_product_id_yearly` | VARCHAR(100) | Play Store yearly product ID | `"core_yearly"` |
| `is_active` | BOOLEAN | Show in plan selection? | `TRUE` |
| `sort_order` | INT | Display order in UI | `0`, `1`, `2` |
| `created_at` | DATETIME | Record creation time | |
| `updated_at` | DATETIME | Last update time | |

**Seed Data (SQL-Ready):**

| plan_id | display_name | description | is_free | is_default_guest | is_default_registered | price_monthly | price_yearly | currency | apple_product_id_monthly | apple_product_id_yearly | is_active | sort_order |
|---------|-------------|-------------|---------|------------------|----------------------|---------------|--------------|----------|--------------------------|-------------------------|-----------|------------|
| `free_guest` | Free (Guest) | Basic access for guest users | TRUE | TRUE | FALSE | 0.00 | 0.00 | USD | NULL | NULL | TRUE | 0 |
| `free_registered` | Free | Basic access for registered users | TRUE | FALSE | TRUE | 0.00 | 0.00 | USD | NULL | NULL | TRUE | 1 |
| `core` | Core | Essential features for enthusiasts | FALSE | FALSE | FALSE | 4.99 | 49.99 | USD | com.daa.core.monthly | com.daa.core.yearly | TRUE | 2 |
| `advanced` | Advanced | Full access with higher limits | FALSE | FALSE | FALSE | 9.99 | 99.99 | USD | com.daa.advanced.monthly | com.daa.advanced.yearly | TRUE | 3 |
| `premium` | Premium | Unlimited access to all features | FALSE | FALSE | FALSE | 19.99 | 199.99 | USD | com.daa.premium.monthly | com.daa.premium.yearly | TRUE | 4 |

---

## Table 2: `features` (NEW)

**Purpose:** Catalog of all app features that can be gated by subscription.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `feature_id` | VARCHAR(50) | **PK** Unique feature identifier | `"chat"`, `"compatibility"` |
| `display_name` | VARCHAR(100) | UI display name | `"AI Chat"` |
| `description` | TEXT | Feature description | `"Ask questions about horoscope"` |
| `category` | VARCHAR(50) | Feature category | `"core"`, `"astrology"`, `"premium"` |
| `icon_name` | VARCHAR(50) | SF Symbol / icon name | `"message.fill"` |
| `requires_quota` | BOOLEAN | Does this feature consume quota? | `TRUE` for LLM features, `FALSE` for history |
| `is_active` | BOOLEAN | Is feature available? | `TRUE` |
| `sort_order` | INT | Display order | `0`, `1`, `2` |
| `created_at` | DATETIME | Record creation time | |

> [!IMPORTANT]
> `requires_quota = FALSE` means the feature can be accessed without consuming quota limits (e.g., viewing history).
> Access can still be restricted per plan via `plan_entitlements.is_enabled`.

### 4.2 Marketing Features (Paywall Display)

| Feature | free | core | plus |
|---------|------|------|------|
| **personalized_transit** | ❌ | ✅ "Daily transit insights..." | ✅ "Daily transit insights..." |
| **early_access** | ❌ | ✅ "Try new features first" | ✅ "Try new features first" |
| **alerts** | ❌ | ❌ | ✅ "(coming soon)" |

---

## 5. Key Code References

### Backend
- [migrations.py](file:///Users/i074917/Documents/destiny_ai_astrology/astrology_api/astroapi-v2/app/core/shared_services/subscription/migrations.py) - Plan/Feature/Entitlement seeding
- [quota_service.py](file:///Users/i074917/Documents/destiny_ai_astrology/astrology_api/astroapi-v2/app/core/shared_services/subscription/quota_service.py) - Quota enforcement logic
- [subscription_router.py](file:///Users/i074917/Documents/destiny_ai_astrology/astrology_api/astroapi-v2/app/core/api/subscription_router.py) - REST API endpoints

### iOS
- [SubscriptionManager.swift](file:///Users/i074917/Documents/destiny_ai_astrology/ios_app/ios_app/Services/SubscriptionManager.swift) - StoreKit 2 integration
- [QuotaManager.swift](file:///Users/i074917/Documents/destiny_ai_astrology/ios_app/ios_app/Services/QuotaManager.swift) - Backend sync
- [SubscriptionView.swift](file:///Users/i074917/Documents/destiny_ai_astrology/ios_app/ios_app/Views/Subscription/SubscriptionView.swift) - Paywall UI

---

## 6. How Features Appear in Paywall

Features show in the paywall **only if they have `marketing_text`** in their entitlement.

```python
# migrations.py - Feature that WILL show in paywall
{"plan_id": "core", "feature_id": "ai_questions", 
 "marketing_text": "Ask unlimited personal questions...",  # ← Shown
 ...}

# Feature that will NOT show in paywall  
{"plan_id": "free_guest", "feature_id": "ai_questions", 
 "marketing_text": None,  # ← Hidden
 ...}
```

For "(coming soon)" features, use `display_name_override`:

```python
{"plan_id": "plus", "feature_id": "alerts", 
 "marketing_text": "Get notified on days that matter...",
 "display_name_override": "Custom Astrological Alerts (coming soon)",  # ← Shows in UI
 ...}
```

iOS checks dynamically:
```swift
private var isComingSoon: Bool {
    feature.displayName.lowercased().contains("coming soon")
}
```


---

## Table 4: `user_subscriptions` (MODIFIED)

**Purpose:** User-specific subscription data and usage tracking.

### Field Changes Summary

| Field | Status | Description |
|-------|--------|-------------|
| `user_email` | ✅ KEEP | **PK** - Email remains unique key |
| `user_type` | ❌ REMOVE | Replaced by `plan_id` |
| `questions_limit` | ❌ REMOVE | Now derived from `plan_id` → `subscription_plans` |
| `questions_asked` | 🔄 RENAME | → `total_questions_asked` |
| `plan_id` | ✨ NEW | **FK** → subscription_plans |
| `daily_questions_asked` | ✨ NEW | Daily counter (resets at midnight) |
| `daily_usage_date` | ✨ NEW | Date for daily reset tracking |
| `feature_usage` | ✨ NEW | JSON for per-feature tracking |
| *(all other fields)* | ✅ KEEP | No changes |

### Complete Schema

| Column | Type | Status | Description |
|--------|------|--------|-------------|
| `user_email` | VARCHAR(255) | ✅ KEEP | **PK** Unique identifier (generated or real email) |
| `plan_id` | VARCHAR(50) | ✨ NEW | **FK** → subscription_plans |
| `total_questions_asked` | INT | 🔄 RENAME | Total questions asked (was `questions_asked`) |
| `daily_questions_asked` | INT | ✨ NEW | Questions asked today |
| `daily_usage_date` | DATE | ✨ NEW | Date of last daily reset |
| `feature_usage` | TEXT (JSON) | ✨ NEW | Per-feature usage tracking |
| `user_name` | VARCHAR(255) | ✅ KEEP | Display name |
| `is_generated_email` | BOOLEAN | ✅ KEEP | True for guest-generated emails |
| `subscription_platform` | VARCHAR(20) | ✅ KEEP | apple/google/stripe/manual |
| `subscription_id` | VARCHAR(100) | ✅ KEEP | Platform subscription ID |
| `product_id` | VARCHAR(100) | ✅ KEEP | Purchased product ID |
| `subscription_status` | VARCHAR(30) | ✅ KEEP | active/expired/grace_period/canceled |
| `subscription_start_at` | DATETIME | ✅ KEEP | Subscription start time |
| `subscription_expires_at` | DATETIME | ✅ KEEP | Subscription expiry time |
| `platform_reference_id` | VARCHAR(150) | ✅ KEEP | For webhook lookups |
| `environment` | VARCHAR(20) | ✅ KEEP | Sandbox/Production |
| `date_of_birth` | DATE | ✅ KEEP | Birth date |
| `time_of_birth` | VARCHAR(10) | ✅ KEEP | Birth time (HH:MM) |
| `city_of_birth` | VARCHAR(255) | ✅ KEEP | Birth city |
| `latitude` | FLOAT | ✅ KEEP | Birth location lat |
| `longitude` | FLOAT | ✅ KEEP | Birth location lon |
| `gender` | VARCHAR(20) | ✅ KEEP | User gender |
| `birth_time_unknown` | BOOLEAN | ✅ KEEP | Birth time unknown flag |
| `google_id` | VARCHAR(255) | ✅ KEEP | Google identity ID |
| `apple_id` | VARCHAR(255) | ✅ KEEP | Apple identity ID |
| `created_at` | DATETIME | ✅ KEEP | Record creation |
| `updated_at` | DATETIME | ✅ KEEP | Last update |
| `last_question_at` | DATETIME | ✅ KEEP | Last question timestamp |

### Feature Usage JSON Structure

```json
{
  "chat": {
    "daily": 5,
    "overall": 45,
    "last_used": "2026-01-03T12:00:00Z"
  },
  "compatibility": {
    "daily": 2,
    "overall": 12,
    "last_used": "2026-01-03T10:30:00Z"
  },
  "birth_calibration": {
    "daily": 0,
    "overall": 3,
    "last_used": "2026-01-02T15:00:00Z"
  }
}
```

---

## Removed Fields

| Field | Was In | Reason |
|-------|--------|--------|
| `user_type` | user_subscriptions | Replaced by `plan_id` FK to get plan details |
| `questions_limit` | user_subscriptions | Now derived from `plan_id` → `subscription_plans.overall_question_limit` |
| `QUOTA_LIMITS` dict | models.py | Replaced by `subscription_plans` table |

---

## Relationships

```
subscription_plans (1) ←──────── (N) user_subscriptions
       │                              │
       │                              │ user_email is PK
       │                              │
       │ (1)                          │
       │                              │
       └────────► (N) plan_entitlements ◄──── (1) features
                        │
                        │ Defines which features
                        │ are available in which
                        │ plans with what limits
```

---

## Key Points

| Question | Answer |
|----------|--------|
| **What is the unique key for users?** | `user_email` (STRING) - same as current |
| **How is plan determined?** | `plan_id` FK → `subscription_plans` table |
| **How are limits determined?** | From `subscription_plans` (global) or `plan_entitlements` (per-feature) |
| **What happens on daily reset?** | `daily_questions_asked` → 0, `daily_usage_date` → today |
| **How is feature usage tracked?** | `feature_usage` JSON column |
| **Is user_type still used?** | ❌ NO - removed, use `plan_id` instead |

---

## API Endpoints

### API Change Summary

| Endpoint | Status | Description |
|----------|--------|-------------|
| `POST /subscription/register` | 🔄 MODIFIED | Now assigns `plan_id` from DB |
| `GET /subscription/status` | 🔄 MODIFIED | New response fields |
| `POST /subscription/record` | ❌ REMOVED | Replaced by `/use` with feature |
| `POST /subscription/use` | ✨ NEW | Record feature-specific usage |
| `GET /subscription/can-access` | ✨ NEW | Check feature access |
| `POST /subscription/upgrade` | 🔄 MODIFIED | Now queries default plan |
| `POST /subscription/verify` | 🔄 MODIFIED | Looks up plan by product_id |
| `GET /subscription/plans` | ✨ NEW | Get available plans for UI |
| `GET /subscription/profile` | 🔄 MODIFIED | Includes `plan_id` |
| `POST /subscription/profile` | ✅ KEEP | No changes |
| `POST /webhook/apple` | ✅ KEEP | No changes |

---

### API 1: `POST /subscription/register` 🔄 MODIFIED

**Purpose:** Register a new user with auto-assigned plan.

**Changes:**
- ❌ Removed: `user_type` field (now derived from plan)
- ✨ New: Auto-assigns `plan_id` based on `is_default_guest` or `is_default_registered` flag

**Request:**
```json
{
  "email": "19900715_1430_Kar@daa.com",
  "is_generated_email": true
}
```

**Response:**
```json
{
  "user_email": "19900715_1430_Kar@daa.com",
  "plan_id": "free_guest",
  "plan": {
    "display_name": "Free (Guest)",
    "daily_limit": 3,
    "overall_limit": 3,
    "is_free": true
  },
  "usage": {
    "total_questions_asked": 0,
    "daily_questions_asked": 0
  },
  "features": ["chat", "compatibility"],
  "can_ask": true
}
```

---

### API 2: `GET /subscription/status` 🔄 MODIFIED

**Purpose:** Get current subscription status and limits.

**Query:** `?email={email}`

**Changes:**
- ❌ Removed: `user_type`, `questions_limit` (derived from plan)
- ✨ New: `plan_id`, `plan` object, `daily_*` fields, `features` array

**Response:**
```json
{
  "user_email": "user@gmail.com",
  "plan_id": "core",
  "plan": {
    "display_name": "Core",
    "daily_limit": 20,
    "overall_limit": 100,
    "is_free": false,
    "expires_at": "2026-02-03T12:00:00Z"
  },
  "usage": {
    "total_questions_asked": 45,
    "daily_questions_asked": 12,
    "daily_reset_at": "2026-01-04T00:00:00Z"
  },
  "limits": {
    "daily_remaining": 8,
    "overall_remaining": 55
  },
  "features": ["chat", "compatibility", "birth_calibration", "dasha_analysis"],
  "can_ask": true,
  "subscription_status": "active",
  "birth_profile": { ... }
}
```

---

### API 3: `POST /subscription/record` ❌ REMOVED

**Replaced by:** `POST /subscription/use` with feature parameter.

---

### API 4: `POST /subscription/use` ✨ NEW

**Purpose:** Record usage of a specific feature.

**Query:** `?email={email}&feature={feature}`

**Request:**
```json
{
  "email": "user@gmail.com",
  "feature": "chat"
}
```

**Response:**
```json
{
  "success": true,
  "feature": "chat",
  "usage": {
    "daily": { "used": 13, "limit": 20, "remaining": 7 },
    "overall": { "used": 46, "limit": 100, "remaining": 54 }
  }
}
```

---

### API 5: `GET /subscription/can-access` ✨ NEW

**Purpose:** Check if user can access a specific feature before performing action.

**Query:** `?email={email}&feature={feature}`

**Response (Success):**
```json
{
  "can_access": true,
  "feature": "chat",
  "plan_id": "core",
  "limits": {
    "daily": { "used": 5, "limit": 20, "remaining": 15 },
    "overall": { "used": 45, "limit": 100, "remaining": 55 }
  }
}
```

**Response (Daily Limit Reached):**
```json
{
  "can_access": false,
  "feature": "compatibility",
  "plan_id": "core",
  "reason": "daily_limit_reached",
  "limits": {
    "daily": { "used": 5, "limit": 5, "remaining": 0 }
  },
  "reset_at": "2026-01-04T00:00:00Z",
  "upgrade_cta": null
}
```

**Response (Overall Limit Reached):**
```json
{
  "can_access": false,
  "feature": "chat",
  "plan_id": "core",
  "reason": "overall_limit_reached",
  "limits": {
    "overall": { "used": 100, "limit": 100, "remaining": 0 }
  },
  "upgrade_cta": {
    "message": "Upgrade to Advanced for 500 questions",
    "suggested_plan": "advanced"
  }
}
```

**Response (Feature Not Available):**
```json
{
  "can_access": false,
  "feature": "birth_calibration",
  "plan_id": "free_guest",
  "reason": "feature_not_available",
  "upgrade_cta": {
    "message": "Upgrade to Core to unlock Birth Time Calibration",
    "suggested_plan": "core"
  }
}
```

---

### API 6: `POST /subscription/upgrade` 🔄 MODIFIED

**Purpose:** Upgrade guest to registered (on sign-in).

**Changes:**
- ❌ Removed: `new_user_type` parameter
- ✨ New: Auto-assigns plan with `is_default_registered = TRUE`

**Request:**
```json
{
  "old_email": "19900715_1430_Kar@daa.com",
  "new_email": "user@gmail.com"
}
```

**Response:**
```json
{
  "success": true,
  "user_email": "user@gmail.com",
  "plan_id": "free_registered",
  "plan": {
    "display_name": "Free",
    "daily_limit": 10,
    "overall_limit": 10
  },
  "usage_carried_over": 2
}
```

---

### API 7: `POST /subscription/verify` 🔄 MODIFIED

**Purpose:** Verify purchase and assign subscription plan.

**Changes:**
- ✨ New: Looks up `plan_id` by matching `apple_product_id_*` in `subscription_plans` table

**Request:**
```json
{
  "signed_transaction": "eyJhbGciOiJFUzI1NiIsI...",
  "user_email": "user@gmail.com",
  "platform": "apple",
  "environment": "Sandbox"
}
```

**Response:**
```json
{
  "success": true,
  "user_email": "user@gmail.com",
  "plan_id": "core",
  "plan": {
    "display_name": "Core",
    "daily_limit": 20,
    "overall_limit": 100
  },
  "subscription": {
    "status": "active",
    "product_id": "com.daa.core.monthly",
    "expires_at": "2026-02-03T12:00:00Z"
  }
}
```

**Internal Logic:**
```sql
SELECT plan_id FROM subscription_plans 
WHERE apple_product_id_monthly = 'com.daa.core.monthly'
   OR apple_product_id_yearly = 'com.daa.core.monthly';
-- Result: plan_id = 'core'
```

---

### API 8: `GET /subscription/plans` ✨ NEW

**Purpose:** Get all available subscription plans for paywall UI.

**Query:** `?include_features=true&active_only=true`

**Response:**
```json
{
  "plans": [
    {
      "plan_id": "free_registered",
      "display_name": "Free",
      "description": "Basic access for registered users",
      "is_free": true,
      "daily_limit": 10,
      "overall_limit": 10,
      "price_monthly": 0,
      "price_yearly": 0,
      "features": [
        {"feature_id": "chat", "daily_limit": 10},
        {"feature_id": "compatibility", "daily_limit": 3}
      ],
      "apple_product_id_monthly": null
    },
    {
      "plan_id": "core",
      "display_name": "Core",
      "description": "Essential features for astrology enthusiasts",
      "is_free": false,
      "daily_limit": 20,
      "overall_limit": 100,
      "price_monthly": 4.99,
      "price_yearly": 49.99,
      "features": [
        {"feature_id": "chat", "daily_limit": 20},
        {"feature_id": "compatibility", "daily_limit": 5},
        {"feature_id": "birth_calibration", "daily_limit": 2}
      ],
      "apple_product_id_monthly": "com.daa.core.monthly",
      "apple_product_id_yearly": "com.daa.core.yearly"
    },
    {
      "plan_id": "premium",
      "display_name": "Premium",
      "description": "Unlimited access to all features",
      "is_free": false,
      "daily_limit": -1,
      "overall_limit": -1,
      "price_monthly": 19.99,
      "price_yearly": 199.99,
      "features": [
        {"feature_id": "chat", "daily_limit": -1},
        {"feature_id": "compatibility", "daily_limit": -1},
        {"feature_id": "remedies", "daily_limit": -1}
      ],
      "apple_product_id_monthly": "com.daa.premium.monthly",
      "apple_product_id_yearly": "com.daa.premium.yearly"
    }
  ]
}
```

---

### API 9: `GET /subscription/profile` 🔄 MODIFIED

**Purpose:** Get user profile with birth data.

**Changes:**
- ✨ New: Includes `plan_id` and `plan` object
- ❌ Removed: `user_type`, `questions_limit`

**Response:**
```json
{
  "user_email": "user@gmail.com",
  "plan_id": "core",
  "plan": {
    "display_name": "Core",
    "is_free": false
  },
  "birth_profile": {
    "date_of_birth": "1990-07-15",
    "time_of_birth": "14:30",
    "city_of_birth": "Bangalore",
    "latitude": 12.9716,
    "longitude": 77.5946
  }
}
```

---

### API 10: `POST /subscription/profile` ✅ KEEP

**Purpose:** Sync birth profile data to server.

**No changes required.**

---

### API 11: `POST /webhook/apple` ✅ KEEP

**Purpose:** Handle Apple subscription webhooks.

**No changes to endpoint.** Internal logic updated to:
1. Find user by `platform_reference_id`
2. On expiry: Reset to default registered plan (`is_default_registered = TRUE`)
3. On renewal: Keep current `plan_id`, update `expires_at`

---

## API Flow Diagrams

### User Registration Flow

```
iOS App                           Backend API
   │                                  │
   │  POST /subscription/register     │
   │  {email, is_generated_email}     │
   │─────────────────────────────────►│
   │                                  │
   │                                  │ Query: SELECT plan_id FROM
   │                                  │   subscription_plans WHERE
   │                                  │   is_default_guest = TRUE
   │                                  │
   │  {plan_id, plan, features,       │
   │   usage, can_ask}                │
   │◄─────────────────────────────────│
   │                                  │
```

### Feature Access Check Flow

```
iOS App                           Backend API
   │                                  │
   │  GET /can-access?                │
   │    email=x&feature=chat          │
   │─────────────────────────────────►│
   │                                  │
   │                                  │ 1. Get user.plan_id
   │                                  │ 2. Check plan_entitlements
   │                                  │    for (plan_id, feature)
   │                                  │ 3. Check daily/overall usage
   │                                  │
   │  {can_access, limits,            │
   │   upgrade_cta?}                  │
   │◄─────────────────────────────────│
   │                                  │
   │  If can_access == true:          │
   │  POST /subscription/use          │
   │    {email, feature: "chat"}      │
   │─────────────────────────────────►│
   │                                  │
```

### Purchase → Plan Assignment Flow

```
iOS App           Apple              Backend API
   │                │                    │
   │ Purchase       │                    │
   │───────────────►│                    │
   │                │                    │
   │ Transaction    │                    │
   │◄───────────────│                    │
   │                                     │
   │  POST /verify                       │
   │  {jws, email, platform: "apple"}    │
   │────────────────────────────────────►│
   │                                     │
   │                                     │ 1. Verify with Apple
   │                                     │ 2. Extract product_id
   │                                     │ 3. Query: SELECT plan_id
   │                                     │    WHERE apple_product_id_*
   │                                     │    = product_id
   │                                     │ 4. Update user.plan_id
   │                                     │
   │  {plan_id: "core", plan, sub}       │
   │◄────────────────────────────────────│
```

---

## iOS UI Impact Analysis

### Files That Will Be Changed

| File | Component | Current Usage | Changes Required |
|------|-----------|---------------|------------------|
| `QuotaManager.swift` | Service | Uses `UserType` enum, hardcoded limits | Replace with `plan_id`, add `canAccess(feature:)` method |
| `SubscriptionManager.swift` | Service | StoreKit purchase, backend verify | Update response parsing for new `plan_id` format |
| `ChatView.swift` | View | Uses `viewModel.canAskQuestion` | Update to use `canAccess(feature: "chat")` |
| `ChatViewModel.swift` | ViewModel | Calls `QuotaManager.recordQuestionOnServer` | Update to use `QuotaManager.recordUsage(feature:)` |
| `CompatibilityView.swift` | View | Uses `QuotaManager.shared.canAsk` | Update to use `canAccess(feature: "compatibility")` |
| `CompatibilityResultView.swift` | View | Uses `QuotaManager.shared.canAsk` | Update to use `canAccess(feature: "compatibility")` |
| `HomeViewModel.swift` | ViewModel | Uses `quotaManager.syncStatusFromServer` | Update response parsing for new format |
| `ProfileView.swift` | View | Uses `subscriptionManager.isPremium` | Add plan display, feature list |
| `SubscriptionView.swift` | View | Shows monthly/yearly products | Fetch plans from server, show all tiers |
| `BirthDataView.swift` | View | Calls `registerWithServer` | Update response handling |
| `ProfileService.swift` | Service | Parses subscription status | Update `SubscriptionStatus` struct |

---

### Impact by Screen

#### 1. Chat Screen (`ChatView.swift`)

| Current | New |
|---------|-----|
| `viewModel.canAskQuestion` (boolean) | `await QuotaManager.shared.canAccess(feature: "chat")` |
| Shows generic paywall on limit | Shows feature-specific paywall with daily/overall limits |

**Changes:**
```swift
// BEFORE
if viewModel.canAskQuestion {
    await sendMessage()
}

// AFTER
let access = await QuotaManager.shared.canAccess(feature: "chat")
if access.canAccess {
    await sendMessage()
    await QuotaManager.shared.recordUsage(feature: "chat")
} else {
    showPaywall(access: access)  // Shows daily/overall limit info
}
```

#### 2. Compatibility Screen (`CompatibilityView.swift`)

| Current | New |
|---------|-----|
| `QuotaManager.shared.canAsk` | `canAccess(feature: "compatibility")` |
| Same limit as chat | Independent daily/overall limits |

#### 3. Compatibility Result Follow-up (`CompatibilityResultView.swift`)

| Current | New |
|---------|-----|
| `QuotaManager.shared.canAsk` | `canAccess(feature: "compatibility")` |
| Blocks if overall quota exceeded | Can show "daily limit reached, resets at midnight" |

#### 4. Profile Screen (`ProfileView.swift`)

| Current | New |
|---------|-----|
| Shows "Premium" or "Free" | Shows plan name (Core, Advanced, Premium) |
| `subscriptionManager.isPremium` | Check `plan.is_free == false` |

**New UI elements:**
- Current plan name and tier
- Feature list for current plan
- Daily/overall usage progress bars
- Upgrade path suggestions

#### 5. Subscription/Paywall (`SubscriptionView.swift`)

| Current | New |
|---------|-----|
| Hardcoded monthly/yearly products | Fetch plans from `GET /subscription/plans` |
| Two products only | Multiple tiers (Core, Advanced, Premium) |

**Changes:**
```swift
// BEFORE: Hardcoded product IDs
static let monthlyProductID = "com.destinyai.premium.monthly"
static let yearlyProductID = "com.destinyai.premium.yearly"

// AFTER: Dynamic from server
let plans = await SubscriptionManager.shared.fetchPlans()
// Plans include all tiers with their product IDs
```

#### 6. Home Screen (`HomeViewModel.swift`)

| Current | New |
|---------|-----|
| Syncs overall quota | Syncs plan + daily + overall + features |
| Shows "X questions remaining" | Shows "Plan: Core • 15/20 today • 55/100 total" |

---

### Non-Impacted Components

These components **WILL NOT BE AFFECTED** by the changes:

| Component | Reason |
|-----------|--------|
| Birth data entry flow | Uses same `/register` endpoint (request unchanged) |
| Chart generation | No quota dependency |
| Daily horoscope | No quota dependency (or use new feature check) |
| Settings screens | No subscription dependency |
| Localization system | No changes |
| Authentication flow | Uses same upgrade endpoint |
| Birth profile sync | Uses same `/profile` endpoint |

---

## Safety Measures

### 1. Backward Compatibility Layer

During transition, maintain backward compatibility:

```swift
// QuotaManager.swift - Keep old API working

/// OLD API (deprecated but still works)
var canAsk: Bool {
    // Internally calls new feature-based check for "chat"
    return canAccessSync(feature: "chat")
}

/// NEW API
func canAccess(feature: String) async -> FeatureAccess {
    // Calls server API
}

/// Fallback for offline/error
private func canAccessSync(feature: String) -> Bool {
    // Uses cached plan data
    guard let plan = cachedPlan else { return false }
    return plan.features.contains(feature)
}
```

### 2. Offline Fallback

```swift
struct CachedPlanData: Codable {
    let planId: String
    let dailyLimit: Int
    let overallLimit: Int
    let features: [String]
    let cachedAt: Date
}

extension QuotaManager {
    /// Cache plan data for offline use
    private func cachePlanData(_ status: SubscriptionStatus) {
        let cached = CachedPlanData(
            planId: status.planId,
            dailyLimit: status.plan.dailyLimit,
            overallLimit: status.plan.overallLimit,
            features: status.features,
            cachedAt: Date()
        )
        UserDefaults.standard.set(try? JSONEncoder().encode(cached), forKey: "cachedPlanData")
    }
    
    /// Use cached data if server unavailable
    private func useCachedDataIfNeeded() -> CachedPlanData? {
        guard let data = UserDefaults.standard.data(forKey: "cachedPlanData"),
              let cached = try? JSONDecoder().decode(CachedPlanData.self, from: data)
        else { return nil }
        
        // Cache valid for 24 hours
        if Date().timeIntervalSince(cached.cachedAt) < 86400 {
            return cached
        }
        return nil
    }
}
```

### 3. Graceful Degradation

```swift
func canAccess(feature: String) async -> FeatureAccess {
    do {
        // Try server first
        return try await checkAccessFromServer(feature: feature)
    } catch {
        // Fallback to cached data
        if let cached = useCachedDataIfNeeded() {
            return FeatureAccess(
                canAccess: cached.features.contains(feature),
                feature: feature,
                plan: cached.planId,
                reason: nil,
                limits: nil,  // Unknown in offline mode
                upgradeCTA: nil
            )
        }
        
        // Ultimate fallback: Allow with warning
        print("⚠️ Quota check failed, allowing access in offline mode")
        return FeatureAccess(canAccess: true, feature: feature)
    }
}
```

### 4. Feature Flags for Rollout

```swift
struct FeatureFlags {
    /// Use new plan-based quota system
    static var useNewQuotaSystem: Bool {
        // Can be controlled via remote config
        RemoteConfig.shared.bool(forKey: "use_plan_based_quota")
    }
}

// Usage in views
if FeatureFlags.useNewQuotaSystem {
    let access = await QuotaManager.shared.canAccess(feature: "chat")
    // New flow
} else {
    if QuotaManager.shared.canAsk {
        // Old flow
    }
}
```

### 5. Testing Strategy

| Test Type | What to Test |
|-----------|-------------|
| **Unit Tests** | `QuotaService` plan assignment, limit checks, daily reset |
| **Integration Tests** | Full API flow: register → use → limit reached → upgrade |
| **UI Tests** | Paywall appears on limit, correct plan displayed |
| **Offline Tests** | App works with cached data when server unavailable |
| **Migration Tests** | Existing users get correct plan after migration |

### 6. Rollback Plan

If issues are detected post-deployment:

| Scenario | Rollback Action |
|----------|-----------------|
| Backend issues | Revert QuotaService to use hardcoded `QUOTA_LIMITS` |
| iOS issues | Ship hotfix with `FeatureFlags.useNewQuotaSystem = false` |
| Database issues | Keep `user_type` column populated, switch FK back to enum |

---

## Migration Checklist

### Phase 1: Backend (No User Impact)
- [ ] Create new database tables
- [ ] Seed plan data
- [ ] Add `plan_id` column to `user_subscriptions`
- [ ] Implement new QuotaService methods
- [ ] Add new API endpoints (keep old ones working)
- [ ] Test with Postman/curl

### Phase 2: Backend Cutover
- [ ] Migrate existing users: `user_type` → `plan_id`
- [ ] Update existing endpoints to return `plan_id`
- [ ] Remove `user_type` from responses
- [ ] Test all endpoints

### Phase 3: iOS Update
- [ ] Update `QuotaManager` with new methods
- [ ] Update `SubscriptionManager` response parsing
- [ ] Update all views to use `canAccess(feature:)`
- [ ] Update paywall to show multiple plans
- [ ] Add offline fallback
- [ ] Test all flows

### Phase 4: Cleanup
- [ ] Remove deprecated `canAsk` property (or keep as wrapper)
- [ ] Remove `UserType` enum (replaced by `plan_id`)
- [ ] Remove hardcoded product IDs (fetch from server)
- [ ] Update documentation

---

## Verification Checklist

Before release, verify:

| Scenario | Expected Behavior |
|----------|-------------------|
| New guest opens app | Assigned `free_guest` plan, 3/3 quota |
| Guest asks 3 questions | Quota shows 0/3, paywall appears |
| Guest signs in | Plan changes to `free_registered`, quota 10/10 |
| User purchases Core | Plan changes to `core`, quota 100/100 |
| User hits daily limit | "Daily limit reached, resets at midnight" message |
| User offline | Uses cached plan data, can still use app |
| Subscription expires | Plan reverts to `free_registered` |
| App update (existing user) | Plan correctly assigned based on current state |

