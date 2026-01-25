# Subscription Master Plan & System Analysis
**Date:** 2026-01-16
**Status:** Live System Configuration (Verified)

## 1. Executive Summary
This document serves as the "Source of Truth" for the Destiny AI Astrology subscription system. It reflects the live database state as of **2026-01-16** and details the data model, plan configurations, and feature entitlements.

### System Health
- **Active Plans:** Core, Plus (Top Tier).
- **Feature Gating:** Fully operational.
- **Legacy Cleanup:** Obsolete plans (`advanced`, `premium`) and features (`chat`) have been removed.
- **Critical Fix Applied:** `Plus` plan now correctly includes the `switch_profile` entitlement.

---

## 2. High-Level Entity Relationship Diagram (ASCII)

```
                      +------------------+
                      | user_subscriptions|
                      +------------------+
                      | user_email (PK)  |
                      | plan_id (FK)     |
                      | status           |
       +--------------+ feature_usage    +--------------+
       |              | created_at       |              |
       |              +--------+---------+              |
       |                       |                        |
       | defines               | subscribes_to          | initiates
       v                       v                        v
+------+---------+    +--------+---------+    +---------+--------+
| partner_profiles|    | subscription_plans|    | chat_threads      |
+-----------------+    +------------------+    +-------------------+
| id (PK)         |    | plan_id (PK)     |    | id (PK)           |
| user_email (FK) |    | price_monthly    |    | user_email (FK)   |
| is_self         |    | is_active        |    | profile_id (FK)   |
| is_active       |    +--------+---------+    +---------+---------+
+-----------------+             |                        |
                                | defines                | contains
                                v                        v
                      +---------+----------+   +---------+---------+
                      | plan_entitlements  |   | chat_messages     |
                      +--------------------+   +-------------------+
                      | id (PK)            |   | id (PK)           |
                      | plan_id (FK)       |   | thread_id (FK)    |
                      | feature_id (FK)    |   | content           |
                      | daily_limit        |   +-------------------+
                      +---------+----------+
                                |
                                | grants
                                v
                      +---------+----------+
                      | features           |
                      +--------------------+
                      | feature_id (PK)    |
                      | requires_quota     |
                      +--------------------+
```

---

## 3. Subscription Data Source of Truth (Live Verified)

### 3.1 Table: `subscription_plans`
Currently active subscription tiers available for purchase.

| plan_id | display_name | description | is_free | price_monthly | product_id_monthly | is_active |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `free_guest` | Free (Guest) | Basic trial access | 1 | 0.0 | | 1 |
| `free_registered` | Free | Signed in, no subscription | 1 | 0.0 | | 1 |
| `core` | Core | Personal, ongoing clarity | 0 | 4.99 | com.daa.core.monthly | 1 |
| `plus` | Plus | Clarity through relationships | 0 | 7.99 | com.daa.plus.monthly | 1 |

### 3.2 Table: `features`
Global registry of system features.

| feature_id | display_name | description | category |
| :--- | :--- | :--- | :--- |
| `ai_questions` | Chat | Chat with the astrologer | core |
| `compatibility` | Compatibility | Match your chart to understand relationship compatibility | core |
| `history` | Chat History | Access past conversations | core |
| `higher_accuracy` | Higher Accuracy | | core |
| `personal_profile` | Personal Profile | | core |
| `maintain_profile` | Maintain Profiles | Save profiles for friends and family | core |
| `multiple_profile_match` | Multiple Profiles | Match multiple profile in one click | plus |
| `alerts` | Custom Alerts | Get notified on days that matter to you based on your chart | plus |
| `early_access` | Early Access | Try new features first | plus |
| `switch_profile` | Switch Profile | Switch app context to view as a different profile | core |

### 3.3 Table: `plan_entitlements`
Defines exactly what each plan allows. (`-1` = unlimited)

| Plan | Feature | Daily Limit | Overall Limit | Marketing Text |
| :--- | :--- | :--- | :--- | :--- |
| **Free Guest** | Chat | - | 3 | |
| | History | - | Unlimited | |
| **Free Registered** | Chat | - | 10 | |
| | Compatibility | - | 1 | |
| | Maintain Profile | - | 2 | Save up to 2 profiles |
| | Switch Profile | - | 2 | Switch between profiles |
| | Multi Profile Match | - | 1 | |
| | History | - | Unlimited | |
| **Core** ($4.99) | Chat | 100 | Unlimited | Ask unlimited personal questions |
| | Compatibility | 100 | Unlimited | Match your chart with anyone |
| | Maintain Profile | - | 5 | Maintain up to 5 profiles |
| | Switch Profile | - | 5 | Switch between profiles |
| | Multi Profile Match | - | 1 | |
| | Higher Accuracy | - | Unlimited | More accurate and personalized |
| | Personal Profile | - | 1 | |
| | History | - | Unlimited | |
| **Plus** ($7.99) | Chat | 200 | Unlimited | Ask unlimited personal questions |
| | Compatibility | 200 | Unlimited | Match with anyone |
| | Maintain Profile | - | Unlimited | Maintain unlimited profiles |
| | Switch Profile | - | Unlimited | Switch between unlimited profiles |
| | Multi Profile Match | 10 | Unlimited | Match multiple profiles in one click |
| | Higher Accuracy | - | Unlimited | |
| | Alerts | - | Unlimited | Get notified on days that matter |
| | Early Access | - | Unlimited | Try new features first |
| | History | - | Unlimited | |

---

## 4. Feature Flow Reference

### 4.1 Switch Profile Flow
1.  **User Action:** Taps "Switch Profile" icon.
2.  **App Check:** `QuotaManager.hasFeature(.switchProfile)`.
3.  **Result:**
    - `Core` / `Free`: Returns `false` -> Prompt Upgrade to Plus.
    - `Plus`: Returns `true` -> Open Profile Switcher.

### 4.2 Chat / Feature Use
1.  **User Action:** Asks a question.
2.  **App Check:** `QuotaManager.checkLimit(.aiQuestions)` (displayed as Chat).
3.  **Backend Check:** Checks `ai_questions` entitlement limit.

---

## 5. Maintenance Notes
- **New Plans:** To add a plan, insert into `subscription_plans` AND add rows to `plan_entitlements`.
- **New Features:** Add to `features` table first, then map to plans in `plan_entitlements`.

## 6. Verified Plan Configuration & Enforcement

### Plan: Free Guest (`free_guest`)
| Feature | Limit | Checked At | Code Check |
| :--- | :--- | :--- | :--- |
| **Chat** (`ai_questions`) | 3 | `ChatView` / `ChatViewModel` | `QuotaManager.shared.canAsk(.aiQuestions)` |
| **Compatibility** | 0 (Blocked) | `CompatibilityView` | `QuotaManager.shared.canAccessFeature(.compatibility)` |
| **Maintain Profile** | 0 | `ProfileSwitcherSheet` (create blocked) | Backend Check (`POST /partners`) |
| **Switch Profile** | 0 | `ProfileSwitcherSheet` | `ProfileContextManager.canSwitchProfiles()` |
| **Multiple Profile Match** | 0 | `CompatibilityView` | Backend Check |
| **History** | Unlimited | `ChatHistoryView` | None (Always available) |

### Plan: Free Registered (`free_registered`)
| Feature | Limit | Checked At | Code Check |
| :--- | :--- | :--- | :--- |
| **Chat** (`ai_questions`) | 10 | `ChatView` / `ChatViewModel` | `QuotaManager.shared.canAsk(.aiQuestions)` |
| **Compatibility** | 1 | `CompatibilityView` | `QuotaManager.shared.canAccessFeature(.compatibility)` |
| **Maintain Profile** | 0 | `ProfileSwitcherSheet` | Backend Check (`POST /partners`) |
| **Switch Profile** | 0 | `ProfileSwitcherSheet` | `ProfileContextManager.canSwitchProfiles()` |
| **Multiple Profile Match** | 0 | `CompatibilityView` | Backend Check |
| **History** | Unlimited | `ChatHistoryView` | None (Always available) |

### Plan: Core (`core`)
| Feature | Limit | Checked At | Code Check |
| :--- | :--- | :--- | :--- |
| **Chat** (`ai_questions`) | 100/day | `ChatView` | `QuotaManager.shared.canAsk(.aiQuestions)` |
| **Compatibility** | 3 | `CompatibilityView` | `QuotaManager.shared.canAccessFeature(.compatibility)` |
| **Maintain Profile** | 5 | `ProfileSwitcherSheet` | Backend Check (`POST /partners`) |
| **Switch Profile** | Unlimited | `ProfileSwitcherSheet` | `ProfileContextManager.canSwitchProfiles()` |
| **Multiple Profile Match** | 0 (Feature incomplete in iOS) | `CompatibilityView` | Backend Check |
| **History** | Unlimited | `ChatHistoryView` | None |

### Plan: Plus (`plus`)
| Feature | Limit | Checked At | Code Check |
| :--- | :--- | :--- | :--- |
| **Chat** (`ai_questions`) | 100/day | `ChatView` | `QuotaManager.shared.canAsk(.aiQuestions)` |
| **Compatibility** | 100/day | `CompatibilityView` | `QuotaManager.shared.canAccessFeature(.compatibility)` |
| **Maintain Profile** | Unlimited | `ProfileSwitcherSheet` | Backend Check (`POST /partners`) |
| **Switch Profile** | Unlimited | `ProfileSwitcherSheet` | `ProfileContextManager.canSwitchProfiles()` |
| **Multiple Profile Match** | Unlimited | `CompatibilityView` | Backend Check |
| **Alerts** | Unlimited | `HomeView` | `QuotaManager.shared.hasFeature(.alerts)` |

> **Note:** `Maintain Profile` and `Multiple Profile Match` limits are currently enforced by the Backend API (`POST /partners` and `POST /compatibility/analyze`). The iOS client handles the failure response but does not pre-validate using `QuotaManager` in the current implementation.

---

## 7. maintain_profile Implementation Details

### Feature ID Registration
`QuotaManager.swift` - `FeatureID` enum:
```swift
case maintainProfile = "maintain_profile"
```

### Quota Check Method
`QuotaManager.swift` - `canAddProfile(email:currentCount:)`:
```swift
func canAddProfile(email: String, currentCount: Int) async -> (canAdd: Bool, limit: Int, showUpgrade: Bool)
```
Returns:
- `canAdd`: true if user can add another profile
- `limit`: maximum allowed (-1 = unlimited)
- `showUpgrade`: true if upgrade prompt should be shown

### UI Enforcement Points

| View | Entry Point | Quota Check |
| :--- | :--- | :--- |
| `PartnerManagerView` | Header "Add" button, Empty state button | `checkAndShowAddForm()` |
| `PartnerPickerSheet` | "Add New Profile" button | `checkAndShowAddForm()` |
| `ProfileSwitcherSheet` | "Add Partner Profile" button | `checkAndShowAddForm()` |

### User Experience

| Plan | Behavior on Add Click |
| :--- | :--- |
| **Free** | Shows `SubscriptionView` immediately |
| **Core** (1-4 profiles) | Shows `PartnerFormView` |
| **Core** (5 profiles) | Shows alert: "You can save up to 5 profiles. Upgrade to Plus for unlimited profiles." |
| **Plus** | Always shows `PartnerFormView` |

---

## 8. End-to-End Quota Flow (Technical)

### 8.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ iOS App (Client)                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │ ChatView    │    │CompatView   │    │ProfileSheet │    │PartnerMgr   │  │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘  │
│         │                  │                  │                  │          │
│         ▼                  ▼                  ▼                  ▼          │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        QuotaManager                                   │   │
│  │  • canAccessFeature(.feature, email) → FeatureAccessResponse         │   │
│  │  • canAddProfile(email, count) → (canAdd, limit, showUpgrade)        │   │
│  │  • hasFeature(.feature) → Bool (cached)                               │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
└────────────────────────────────────┼─────────────────────────────────────────┘
                                     │ HTTP
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Backend API (FastAPI)                                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ subscription_router.py                                                │   │
│  │  • GET /subscription/can-access?email=X&feature=Y                     │   │
│  │  • POST /subscription/use (records usage after action)                │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│                                    ▼                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ QuotaService                                                          │   │
│  │  • can_access_feature(email, feature_id) → dict                       │   │
│  │  • record_feature_usage(email, feature_id) → dict                     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│                                    ▼                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ Database Tables                                                       │   │
│  │  • user_subscriptions.feature_usage (JSON: {feature: {daily, total}}) │   │
│  │  • plan_entitlements (daily_limit, overall_limit per feature)         │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Implemented Features & Quota Checks

| Feature ID | iOS Check Location | Backend Records Usage | Notes |
| :--- | :--- | :--- | :--- |
| `ai_questions` | `ChatViewModel.sendMessage()` | `predict.py` (after response) | ✅ Fully implemented |
| `compatibility` | `CompatibilityView.analyzeAction()` (single) | `compatibility.py` (after analysis) | ✅ Fully implemented |
| `multiple_profile_match` | `CompatibilityView.analyzeAction()` (multi) | `compatibility.py` | ✅ Implemented |
| `maintain_profile` | `PartnerManagerView`, `PartnerPickerSheet`, `ProfileSwitcherSheet` | `POST /partners` (backend limit) | ✅ Implemented |
| `switch_profile` | `ProfileContextManager.switchTo()` | `POST /profiles/switch` | ✅ Implemented |
| `alerts` | Not yet implemented | - | ⏳ Coming Soon |
| `history` | Always allowed | - | ✅ No quota needed |

### 8.3 Quota Check Flow (Detailed)

```
User taps "Check Compatibility" or "Compare All"
                    │
                    ▼
        ┌───────────────────────┐
        │ Is partners.count > 1?│
        └───────────┬───────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
         ▼                     ▼
    Single Partner        Multi Partner
         │                     │
         ▼                     ▼
  Check .compatibility    Check .profiles
         │                     │
         └──────────┬──────────┘
                    ▼
    ┌───────────────────────────────┐
    │ QuotaManager.canAccessFeature │
    │ GET /subscription/can-access  │
    └───────────────┬───────────────┘
                    │
                    ▼
    ┌───────────────────────────────┐
    │ Backend checks:               │
    │ 1. User's plan                │
    │ 2. Feature entitlement        │
    │ 3. Daily usage vs limit       │
    │ 4. Overall usage vs limit     │
    └───────────────┬───────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
   can_access: true        can_access: false
        │                       │
        ▼                       ▼
  Proceed with           Show error/upgrade
  analysis               │
        │                ├─→ "daily_limit_reached" → Banner
        │                ├─→ "overall_limit_reached" → Upgrade Sheet
        │                └─→ "feature_not_available" → Upgrade Sheet
        ▼
  Backend records usage
  after successful response
```

---

## 9. Plan Configuration Examples

### 9.1 Free Guest User Journey

**Scenario:** First-time user, no sign-in

| Action | Feature | Allowed | Remaining After |
| :--- | :--- | :--- | :--- |
| Ask astrology question | ai_questions | ✅ Yes | 2 of 3 |
| Ask another question | ai_questions | ✅ Yes | 1 of 3 |
| Ask third question | ai_questions | ✅ Yes | 0 of 3 |
| Ask fourth question | ai_questions | ❌ No | Show upgrade |
| Try Match | compatibility | ❌ No | Not entitled |
| Try Switch Profile | switch_profile | ❌ No | Not entitled |
| Try Save Profile | maintain_profile | ❌ No | Not entitled |

**UX:** After 3 chats, app shows "Sign up or subscribe to continue"

---

### 9.2 Free Registered User Journey

**Scenario:** User signed in with Google/Apple

| Action | Feature | Allowed | Remaining After |
| :--- | :--- | :--- | :--- |
| Chat (1-10) | ai_questions | ✅ Yes | 10 → 0 |
| Chat (11th) | ai_questions | ❌ No | Show upgrade |
| Match 1 person | compatibility | ✅ Yes | 0 of 1 |
| Match 2nd person | compatibility | ❌ No | Subscribe to continue |
| Save profile 1 | maintain_profile | ✅ Yes | 1 of 2 |
| Save profile 2 | maintain_profile | ✅ Yes | 0 of 2 |
| Save profile 3 | maintain_profile | ❌ No | Limit reached |
| Switch profile 1 | switch_profile | ✅ Yes | 1 of 2 |
| Switch profile 2 | switch_profile | ✅ Yes | 0 of 2 |
| Compare All (2) | multiple_profile_match | ✅ Yes | 0 of 1 |
| Compare All again | multiple_profile_match | ❌ No | Subscribe for more |

**UX:** Generous trial limits to experience all features

---

### 9.3 Core Subscriber Journey ($4.99/mo)

**Scenario:** Paid Core subscriber

| Action | Feature | Allowed | Notes |
| :--- | :--- | :--- | :--- |
| Chat unlimited | ai_questions | ✅ Yes | 100/day limit |
| Chat 101st today | ai_questions | ❌ No | "Resets at midnight" |
| Match unlimited | compatibility | ✅ Yes | 100/day limit |
| Save profile 1-5 | maintain_profile | ✅ Yes | Up to 5 profiles |
| Save profile 6 | maintain_profile | ❌ No | "Upgrade to Plus for unlimited" |
| Switch profile 1-5 | switch_profile | ✅ Yes | Up to 5 switches |
| Compare All (once) | multiple_profile_match | ✅ Yes | 1 total allowed |
| Compare All again | multiple_profile_match | ❌ No | Upgrade to Plus |

**UX:** Ample daily limits, clear upgrade path to Plus for power users

---

### 9.4 Plus Subscriber Journey ($7.99/mo)

**Scenario:** Premium Plus subscriber

| Action | Feature | Allowed | Notes |
| :--- | :--- | :--- | :--- |
| Chat unlimited | ai_questions | ✅ Yes | 200/day (generous) |
| Match unlimited | compatibility | ✅ Yes | 200/day |
| Save unlimited profiles | maintain_profile | ✅ Yes | No limit |
| Switch unlimited | switch_profile | ✅ Yes | No limit |
| Compare All (10/day) | multiple_profile_match | ✅ Yes | 10/day limit |
| Alerts | alerts | ✅ Yes | Coming soon |
| Early Access | early_access | ✅ Yes | Beta features |

**UX:** Power user experience with virtually no restrictions

---

## 10. End-User Experience Audit

### ✅ What Works Well
1. **Clear upgrade prompts** - Shows specific limit reached
2. **Daily vs Overall distinction** - Daily limits show reset time
3. **Graceful degradation** - Features work within limits
4. **Immediate feedback** - Quota checked before action starts

### ⚠️ Areas for Improvement

| Issue | Impact | Recommendation |
| :--- | :--- | :--- |
| No usage counter in UI | User doesn't know remaining quota | Add "X of Y remaining" badge |
| compare_all + compatibility confusion | User may be confused which is which | Rename button to "Compare All Profiles" |
| Alerts feature not implemented | Plus feature advertised but not working | Complete alerts feature or remove from paywall |

### 🎯 Professional Standards Checklist

| Standard | Status | Details |
| :--- | :--- | :--- |
| Quota checked before action | ✅ | All features check first |
| Clear error messages | ✅ | Specific reason provided |
| Upgrade CTAs | ✅ | Actionable upgrade buttons |
| Reset time shown for daily limits | ✅ | Shows "Resets at X" |
| Graceful offline handling | ⚠️ | Fails open (allows on error) |
| Usage tracking accuracy | ✅ | Backend records after success |
| Plan change sync | ✅ | syncStatus() updates local state |

---

## 11. Bug Fixes Applied (2026-01-16)

### 11.1 Issues Found & Fixed

| Issue | Location | Fix Applied |
| :--- | :--- | :--- |
| `maintain_profile` quota not checked | `POST /partners` | Added `can_access_feature` check before creating partner |
| `maintain_profile` usage not recorded | `POST /partners` | Added `record_feature_usage` after successful creation |
| `switch_profile` usage not recorded | `POST /profiles/switch` | Added `record_feature_usage` after successful switch |
| Wrong feature for Compare All | `/compatibility/analyze` | Now uses `multiple_profile_match` when `comparison_group_id` is set |

### 11.2 Files Modified

**Backend:**
- `subscription_router.py`: Added quota check + usage recording for `POST /partners` and `POST /profiles/switch`
- `compatibility.py`: Uses `quota_feature` variable based on `is_multi_profile`

**iOS:**
- `CompatibilityView.swift`: Already correctly checks `.profiles` for multi-partner
- `PartnerManagerView.swift`, `PartnerPickerSheet.swift`, `ProfileSwitcherSheet.swift`: Already have client-side checks

### 11.3 Verification Status

| Feature | iOS Check | Backend Check | Usage Recorded |
| :--- | :--- | :--- | :--- |
| `ai_questions` | ✅ ChatViewModel | ✅ predict.py | ✅ predict.py |
| `compatibility` | ✅ CompatibilityView | ✅ compatibility.py | ✅ compatibility.py |
| `multiple_profile_match` | ✅ CompatibilityView | ✅ compatibility.py | ✅ compatibility.py |
| `maintain_profile` | ✅ PartnerManagerView et al | ✅ subscription_router.py | ✅ subscription_router.py |
| `switch_profile` | ✅ ProfileContextManager | ✅ subscription_router.py | ✅ subscription_router.py |
| `alerts` | ⏳ Not implemented | - | - |
