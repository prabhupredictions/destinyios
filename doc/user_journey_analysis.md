# User Journey Analysis & Gap Identification

**Date:** 2026-01-16  
**Purpose:** Document complete user journeys, identify logical gaps, and recommend fixes

---

## Table of Contents
1. [Current Plan Entitlements Summary](#1-current-plan-entitlements-summary)
2. [Journey 1: Guest User](#2-journey-1-guest-user)
3. [Journey 2: Guest → Registered Transition](#3-journey-2-guest--registered-transition)
4. [Journey 3: Free Registered User](#4-journey-3-free-registered-user)
5. [Journey 4: Core Subscriber](#5-journey-4-core-subscriber)
6. [Journey 5: Plus Subscriber](#6-journey-5-plus-subscriber)
7. [Critical Logical Gaps Identified](#7-critical-logical-gaps-identified)
8. [Abuse Prevention Analysis](#8-abuse-prevention-analysis)
9. [Recommendations](#9-recommendations)

---

## 1. Current Plan Entitlements Summary

| Feature | Guest | Registered | Core ($4.99) | Plus ($7.99) |
|---------|-------|------------|--------------|--------------|
| ai_questions | 3 total | 10 total | 100/day | 200/day |
| compatibility | ❌ | 1 total | 100/day | 200/day |
| maintain_profile | ❌ | 2 total | 5 total | Unlimited |
| switch_profile | ❌ | 2 total | 5 total | Unlimited |
| multiple_profile_match | ❌ | 1 total | 1 total | 10/day |
| history | ✅ | ✅ | ✅ | ✅ |

---

## 2. Journey 1: Guest User

### 2.1 Entry Point
User downloads app → Opens without sign-in → System creates generated email using birth details

**Email Format:** `YYYYMMDD_HHMM_CityPrefix_LatInt_LngInt@daa.com`  
**Example:** `19900715_1430_Kar_17_78@daa.com`

### 2.2 Core Principle

> [!IMPORTANT]
> **Guest Rule:** NEVER show "Subscribe" option. Guest users should ONLY see "Sign In" prompts.
> **Match Tab Rule:** Guest cannot ENTER Match tab at all. Sign-in required on tab click.

### 2.3 Complete Action Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ GUEST USER - COMPLETE ACTION MAP                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ══════════════════════════════════════════════════════════════════════════  │
│  HOME TAB                                                                    │
│  ══════════════════════════════════════════════════════════════════════════  │
│                                                                              │
│  [Profile Header - Top Right]                                                │
│       │                                                                      │
│       └─→ Tap Profile Icon → Opens Profile/Settings (allowed)               │
│                                                                              │
│  [Switch Profile Button]                                                     │
│       │                                                                      │
│       └─→ Tap → ❌ Show Sign In Modal                                        │
│              "Sign in to switch between profiles"                            │
│                                                                              │
│  ══════════════════════════════════════════════════════════════════════════  │
│  ASK TAB (Chat)                                                              │
│  ══════════════════════════════════════════════════════════════════════════  │
│                                                                              │
│  [Ask AI Question Input]                                                     │
│       │                                                                      │
│       ├─→ Question 1 ✅ → Response → Saved to history                        │
│       ├─→ Question 2 ✅ → Response → Saved to history                        │
│       ├─→ Question 3 ✅ → Response → Saved to history                        │
│       └─→ Question 4 ❌ → Show Sign In Modal                                 │
│              "Sign in to continue asking questions"                          │
│              [Google Sign In] [Apple Sign In]                                │
│              ❌ NO Subscribe button for guest                                │
│                                                                              │
│  ══════════════════════════════════════════════════════════════════════════  │
│  MATCH TAB (Compatibility) - BLOCKED FOR GUEST                               │
│  ══════════════════════════════════════════════════════════════════════════  │
│                                                                              │
│  [Tap Match Tab in Bottom Bar]                                               │
│       │                                                                      │
│       └─→ ❌ IMMEDIATELY Show Sign In Modal                                  │
│              "Sign in to check compatibility"                                │
│              [Google Sign In] [Apple Sign In]                                │
│                                                                              │
│       Guest NEVER enters Match screen.                                       │
│       No partner entry, no compatibility check, nothing.                     │
│                                                                              │
│  ══════════════════════════════════════════════════════════════════════════  │
│  HISTORY                                                                     │
│  ══════════════════════════════════════════════════════════════════════════  │
│                                                                              │
│  [View History]                                                              │
│       │                                                                      │
│       ├─→ ✅ Can view past chat conversations                                │
│       └─→ No compatibility history (never ran any)                           │
│                                                                              │
│  [Tap on History Item]                                                       │
│       │                                                                      │
│       └─→ Opens read-only view                                               │
│           └─→ Try to continue conversation → ❌ Show Sign In Modal           │
│                  "Sign in to continue this conversation"                     │
│                                                                              │
│  ══════════════════════════════════════════════════════════════════════════  │
│  SAVED PROFILES                                                              │
│  ══════════════════════════════════════════════════════════════════════════  │
│                                                                              │
│  [Saved Profiles Screen]                                                     │
│       │                                                                      │
│       └─→ Opens → ❌ Empty state with Sign In prompt                         │
│              "Sign in to save and manage profiles"                           │
│              [Google Sign In] [Apple Sign In]                                │
│                                                                              │
│  ══════════════════════════════════════════════════════════════════════════  │
│  SETTINGS / PROFILE                                                          │
│  ══════════════════════════════════════════════════════════════════════════  │
│                                                                              │
│  [All Settings Options]                                                      │
│       │                                                                      │
│       └─→ ✅ FULLY ACCESSIBLE (no restrictions)                              │
│              - View account info                                             │
│              - Change preferences                                            │
│              - App settings                                                  │
│                                                                              │
│  [Sign Out Button]                                                           │
│       │                                                                      │
│       └─→ ✅ Available (guest IS signed in via generated email)              │
│              Signs out → App returns to fresh guest state                    │
│                                                                              │
│  [Subscription / Plans]                                                      │
│       │                                                                      │
│       └─→ Tap → ❌ Show Sign In Modal                                        │
│              "Sign in to view subscription plans"                            │
│              [Google Sign In] [Apple Sign In]                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.4 Guest Modal/Popup Behavior

> [!IMPORTANT]
> **Single Modal Type for Guest:** Always show Sign In modal, never Subscription modal.

| Trigger | Modal Message | Buttons |
|---------|---------------|---------|
| 4th AI question | "Sign in to continue asking questions" | [Google] [Apple] |
| Match Tab click | "Sign in to check compatibility" | [Google] [Apple] |
| Switch Profile | "Sign in to switch between profiles" | [Google] [Apple] |
| Saved Profiles | "Sign in to save and manage profiles" | [Google] [Apple] |
| View Plans | "Sign in to view subscription plans" | [Google] [Apple] |
| Continue History | "Sign in to continue this conversation" | [Google] [Apple] |

### 2.5 What Guest CAN Do

| Action | Location | Notes |
|--------|----------|-------|
| Ask 3 AI questions | Ask Tab | Quota enforced |
| View chat history | History | Read-only |
| Access all settings | Settings | Full access |
| Sign out | Settings | Returns to fresh state |

### 2.6 What Guest CANNOT Do

| Action | Block Point | Message |
|--------|-------------|---------|
| Enter Match Tab | Bottom bar tap | Sign In modal |
| Add/Search/Delete partners | N/A (can't enter Match) | N/A |
| Check compatibility | N/A (can't enter Match) | N/A |
| Save profiles | Saved Profiles screen | Sign In modal |
| Switch profiles | Home header | Sign In modal |
| View subscription plans | Settings | Sign In modal |
| Continue chat from history | History item | Sign In modal |
| Ask 4th+ question | Chat input | Sign In modal |

### 2.7 Implementation Checklist - ALL FIXED ✅

| # | Screen | Action | Required Behavior | Status |
|---|--------|--------|-------------------|--------|
| 1 | **Bottom Bar** | Tap Match Tab | Show Sign In modal immediately | ✅ FIXED - `GuestSignInPromptView` |
| 2 | **Ask Tab** | 4th question | Show Sign In (NOT subscribe) | ✅ FIXED - Uses localized key |
| 3 | **Home** | Switch Profile | Show Sign In modal | ⚠️ Verify separately |
| 4 | **Saved Profiles** | Open screen | Empty + Sign In prompt | ⚠️ Verify separately |
| 5 | **Settings** | View Plans | Show Sign In modal | ✅ FIXED - Shows `GuestSignInPromptView` |
| 6 | **Settings** | Sign Out | Allow (functional) | ✅ Working |
| 7 | **History** | Continue chat | Show Sign In modal | ⚠️ Verify separately |

### 2.8 Identified Gaps - FIXED ✅

> [!NOTE]
> **All 3 Critical Gaps Have Been Fixed** as of 2026-01-17

#### ✅ FIX 1: Match Tab Now Blocked for Guest
**File:** `MainTabView.swift`  
**Change:** Added `isGuestUser` computed property and conditional rendering  
**Result:** Guest users now see `GuestSignInPromptView` instead of `CompatibilityView`

#### ✅ FIX 2: Correct Message for Guest (Sign In only, no Subscribe)
**Files:** `ChatViewModel.swift`, `CompatibilityView.swift`  
**Change:** Changed hardcoded "Sign In or Subscribe" to `"sign_in_to_continue_asking".localized`  
**Result:** Guests only see "Sign in to continue" without subscribe option

#### ✅ FIX 3: Subscription View Blocked for Guest
**File:** `ProfileView.swift`  
**Change:** Added `isGuestUser` check before showing `SubscriptionView`, shows `GuestSignInPromptView` sheet instead  
**Result:** Guest users see sign-in prompt when tapping subscription section

### 2.9 New Components Created

| File | Purpose |
|------|---------|
| `GuestSignInPromptView.swift` | Full-screen sign-in prompt with Google/Apple buttons |
| Localization keys added | 7 new keys for guest sign-in messages |

---

## 3. Journey 2: Guest → Registered Transition

### 3.1 Trigger Points
User clicks "Sign In" from:
- Quota exhausted message (4th question)
- Settings menu
- Feature block prompt (Match tab, etc.)

### 3.2 Transition Rules

> [!IMPORTANT]
> **Key Thumb Rules for Guest → Registered:**
> 1. **No quota carryover** - Registered user gets FULL entitlements as per `free_registered` plan
> 2. **Chat history migration** - Copy chat_threads from guest to new email
> 3. **No partner profiles for guest** - Guest never had any (can't access Match)
> 4. **Guest usage count is NOT transferred** - Fresh start for registered user

```
┌─────────────────────────────────────────────────────────────────┐
│ GUEST → REGISTERED TRANSITION                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Guest: 19900715_1430_Kar_17_78@daa.com]                        │
│       │                                                          │
│       ├─ 3 AI questions asked (used up guest quota)              │
│       ├─ 0 profiles saved (guest cannot save profiles)           │
│       └─ History contains 3 chat threads                         │
│                                                                  │
│       ▼ [Signs in with Google: john@gmail.com]                   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ BACKEND ACTIONS:                                            │  │
│  │ 1. Create new user: john@gmail.com (free_registered plan)  │  │
│  │ 2. Migrate chat_threads from guest to john@gmail.com       │  │
│  │ 3. NO partner profiles to copy (guest never had any)       │  │
│  │ 4. NO quota carryover - fresh entitlements                 │  │
│  │ 5. Archive/delete guest record                             │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  [Registered: john@gmail.com]                                    │
│       │                                                          │
│       ├─ Gets FULL 10 AI questions (fresh start)                 │
│       ├─ Gets 2 profile slots                                    │
│       ├─ Gets 1 compatibility check                              │
│       ├─ Gets 1 multi-profile match                              │
│       └─ History shows migrated conversations                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 Implementation Status - ALL FIXED ✅

> [!NOTE]
> **All Migration Gaps Have Been Fixed** as of 2026-01-18

#### Implemented Migration Flow:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ BACKEND-CENTRIC GUEST MIGRATION (2026-01-18)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. USER SIGNS IN WITH APPLE/GOOGLE                                          │
│     └─→ New email: user@gmail.com                                            │
│                                                                              │
│  2. USER SAVES BIRTH PROFILE → POST /subscription/profile                    │
│     └─→ DOB: 1990-07-15, Time: 14:30, City: Karnal                          │
│                                                                              │
│  3. BACKEND GENERATES GUEST EMAIL FROM BIRTH DATA                            │
│     └─→ Generated: 19900715_1430_Kar_17_78@daa.com                          │
│                                                                              │
│  4. BACKEND CHECKS FOR MATCHING GUEST HISTORY                                │
│     └─→ Query: SELECT * FROM chat_threads WHERE user_email = <generated>   │
│                                                                              │
│  5. IF FOUND → MIGRATE HISTORY                                               │
│     ├─→ UPDATE chat_threads SET user_email = 'user@gmail.com'               │
│     └─→ ARCHIVE GUEST: is_archived=true, upgraded_to_email='user@gmail.com'│
│                                                                              │
│  6. USER SEES MIGRATED HISTORY                                               │
│     └─→ Works even after app reinstall (backend-centric, not flag-based)   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Edge Case Handling Matrix:

| Scenario | User Type | Birth Data Matches | HTTP Status | Action |
|----------|-----------|-------------------|-------------|--------|
| Normal guest | Guest | N/A | 200 | Create guest account |
| Normal registered | Registered | N/A | 200 | Create registered + migrate guest if exists |
| Guest tries same birth as archived | Guest | Archived Guest | 409 `archived_guest` | Show sign-in prompt |
| Registered tries same birth as another registered | Registered | Another Registered | 409 `birth_data_taken` | Show sign-in prompt |
| Guest shares birth data | Guest | Active Guest | 200 | Share same guest record (same astro chart) |

#### Files Modified:

| File | Change |
|------|--------|
| `models.py` | Added `is_archived`, `upgraded_to_email`, `archived_at` columns |
| `quota_service.py` | Added `migrate_guest_history_by_birth_data()`, `_generate_guest_email_from_birth()`, `find_registered_user_by_birth_data()`, `ArchivedGuestError`, `BirthDataTakenError` |
| `subscription_router.py` | Updated `save_profile` to trigger migration, added 409 error handling |
| `auto_init.py` | Added Migrations 3-5 for new columns |
| `QuotaManager.swift` | Added `ArchivedGuestError` struct, 409 handling in `registerUser()` |
| `BirthDataView.swift` | Added UI handling to catch `ArchivedGuestError` and show error message |

#### Gap Analysis Table - ALL FIXED ✅

| # | Expected Behavior | Status | Implementation |
|---|-------------------|--------|----------------|
| 1 | Migrate `chat_threads` | ✅ FIXED | `migrate_guest_history_by_birth_data()` |
| 2 | Archive guest record | ✅ FIXED | Sets `is_archived=true`, `upgraded_to_email`, `archived_at` |
| 3 | No quota carryover | ✅ OK | Fresh user with `free_registered` plan |
| 4 | Birth data uniqueness | ✅ FIXED | `find_registered_user_by_birth_data()` check |
| 5 | Archived guest re-entry | ✅ FIXED | Returns 409 with `archived_guest` error |
| 6 | UI for sign-in prompt | ✅ FIXED | `BirthDataView` catches error, shows message |

### 3.4 What Registered User CAN Do

| Action | Limit | Notes |
|--------|-------|-------|
| Ask AI questions | 10 total | Lifetime limit for free tier |
| Run compatibility match | 1 total | NEW matches only count |
| Save partner profiles | 2 total | Based on active profile count |
| Switch profiles | 2 unique | Between Self + 2 others |
| Compare All | 1 total | Multi-profile comparison |
| Access full settings | ✅ Unlimited | All settings accessible |
| View/export charts | ✅ Unlimited | No quota |
| Access history | ✅ Unlimited | Read, replay, continue |

### 3.5 What Registered User CANNOT Do (Requires Subscribe)

| Action | Block Point | Message | Shows |
|--------|-------------|---------|-------|
| 11th AI question | Chat input | "Subscribe to continue" | Core + Plus plans |
| 2nd new match | Match analysis | "Subscribe for more matches" | Core + Plus plans |
| 3rd profile | Add profile | "Subscribe to save more" | Core + Plus plans |
| 3rd unique switch | Switch action | "Subscribe for more switches" | Core + Plus plans |
| 2nd Compare All | Compare All button | "Subscribe for Compare All" | Core + Plus plans |

### 3.6 Registered User Implementation Checklist

| # | Feature | Required Behavior | Current Status | Gap |
|---|---------|-------------------|----------------|-----|
| 1 | History migration | Migrate chat_threads on sign-in | ✅ FIXED (`_migrate_chat_history()`) | - |
| 2 | Fresh quota | 10 questions, 1 match, 2 profiles | ✅ OK | - |
| 3 | Subscription CTA | Show Core + Plus options | ✅ OK | - |
| 4 | Rematch free | Same partner = no quota use | ✅ FIXED (iOS cache + backend check) | - |
| 5 | Return switch free | Already-switched profile = free | ✅ FIXED (`first_switched_at` column) | - |
| 6 | Profile count | Based on active profiles | ✅ OK | - |

### 3.7 Unique Usage Detection Logic

> [!TIP]
> **IMPLEMENTED:** Usage count only increases for NEW operations.
> Revisiting existing data is FREE (fetch from local cache or synced history).
> **Same person = same DOB + same birth time** (not just DOB)

#### ✅ FIXED - is_new_match Check (compatibility.py)
Backend now checks existing threads before recording usage:
```python
# Record quota usage ONLY for NEW matches (DOB + Time)
is_new_match = True
if user_email != "anonymous@user.com":
    existing_threads = chat_history.list_threads(user_email, area="compatibility")
    for thread in existing_threads:
        metadata = thread.get("metadata", {})
        existing_boy = metadata.get("boy", {})
        existing_girl = metadata.get("girl", {})
        # Match on DOB + Time (same person = same DOB + same birth time)
        if (existing_boy.get("date_of_birth") == request.boy.dob and 
            existing_boy.get("time_of_birth") == request.boy.time and
            existing_girl.get("date_of_birth") == request.girl.dob and
            existing_girl.get("time_of_birth") == request.girl.time):
            is_new_match = False  # Rematch - FREE
            break

if is_new_match:
    quota_service.record_feature_usage(user_email, quota_feature)
else:
    logger.info("Rematch detected - not counting against quota")
```

##### For Switch Profile - Profile-Scoped Storage Analysis

> [!IMPORTANT]
> **Each profile has SEPARATE isolated storage** using `profileScopedKey()` format:
> `{baseKey}_{ownerEmail}_{profileId}`

**Current Implementation (ProfileContextManager.swift line 141):**
```swift
func profileScopedKey(_ baseKey: String) -> String {
    "\(baseKey)_\(ownerEmail)_\(activeProfileId)"
}
```

**What is profile-scoped:**
| Service | Storage Key Example | Scope |
|---------|---------------------|-------|
| CompatibilityHistoryService | `compatibility_history_john@gmail.com_123` | Per profile |
| TodaysPredictionCache | `todaysPrediction_john@gmail.com_123` | Per profile |
| AstroDataCache | `fullChart_john@gmail.com_123_{birthHash}` | Per profile |
| ChatHistory | Backend: `chat_threads.profile_id` | Per profile |

**Scenario Analysis:**
```
User: john@gmail.com
├── Self (profile_id = "self")
│   ├── Questions asked → Stored in chat_threads (self)
│   ├── Matches run → Stored in compatibility_history_john@gmail.com_self
│   └── Predictions → Stored in todaysPrediction_john@gmail.com_self
│
├── Profile A (profile_id = "123")
│   ├── Questions asked → Stored in chat_threads (123)
│   ├── Matches run → Stored in compatibility_history_john@gmail.com_123
│   └── Predictions → Stored in todaysPrediction_john@gmail.com_123
│
└── Profile B (profile_id = "456")
    ├── Questions asked → Stored in chat_threads (456)
    └── ... separate storage
```

##### Data Recovery Flow (iPhone Data Erased)

**Existing Sync Mechanism:**
- `syncFromServer()` exists in CompatibilityHistoryService and ChatHistorySyncService
- Called during login (AuthViewModel) and birth data setup (BirthDataViewModel)

```swift
// AuthViewModel.swift line 344-345 (on login)
await ChatHistorySyncService.shared.syncFromServer(userEmail: email, dataManager: DataManager.shared)
await CompatibilityHistoryService.shared.syncFromServer(userEmail: email)

// BirthDataViewModel.swift line 254-255 (on profile setup)
await ChatHistorySyncService.shared.syncFromServer(userEmail: email, dataManager: dataManager)
await CompatibilityHistoryService.shared.syncFromServer(userEmail: email)
```

**Recovery Flow:**
```
┌─────────────────────────────────────────────────────────────────┐
│ USER CLEARS iPHONE DATA / REINSTALLS APP                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Step 1: User signs in → AuthViewModel triggers sync             │
│       │                                                          │
│       ├─→ syncFromServer(userEmail) called                       │
│       │       │                                                  │
│       │       ├─→ Fetch chat_threads from backend               │
│       │       ├─→ Fetch compatibility threads from backend       │
│       │       └─→ Populate local UserDefaults                    │
│                                                                  │
│  Step 2: User switches to Profile A                              │
│       │                                                          │
│       ├─→ Backend returns profile_id for Profile A               │
│       ├─→ Local key changes to: {key}_{email}_123                │
│       └─→ syncFromServer syncs ALL threads, UI filters by profile│
│                                                                  │
│  Step 3: User asks question for Profile A (already asked before) │
│       │                                                          │
│       ├─→ Check local cache → Not found                          │
│       ├─→ Check synced history → FOUND! (synced from backend)    │
│       ├─→ Load from history → Show response                      │
│       └─→ ✅ NO API call → NO quota consumed                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

##### Correct Sync & Display Logic

> [!IMPORTANT]
> **Sync Rule:** Fetch ALL history for user (all profiles) from backend to local.
> **Display Rule:** UI filters history by current active profile_id.
> **Usage Count Rule:** Only count when FRESH LLM/backend call is triggered, NOT when loading from local/history.

**Current `syncFromServer()` behavior:**
- ✅ Syncs ALL threads for `userEmail` (correct)
- ✅ Backend stores `profile_id` in thread metadata
- ⚠️ Verify: UI correctly filters display by active profile_id

**Key Principle - Usage Count = LLM Consumption:**
```
┌─────────────────────────────────────────────────────────────────┐
│ USAGE COUNT LOGIC                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Scenario A: Data found in LOCAL cache                           │
│       → Load from cache                                          │
│       → NO API call                                              │
│       → ✅ Usage count = 0                                       │
│                                                                  │
│  Scenario B: Data NOT in local, but found in HISTORY (synced)    │
│       → Load from history                                        │
│       → NO LLM call triggered                                    │
│       → ✅ Usage count = 0                                       │
│                                                                  │
│  Scenario C: Data NOT in local AND NOT in history (truly NEW)    │
│       → Call backend API                                         │
│       → LLM call triggered (consumes resources)                  │
│       → ❌ Usage count += 1                                      │
│       → Save to local cache + history for reuse                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

##### Switch Profile Quota Logic - Corrected

```python
# Backend: Track unique profiles switched (not total switch count)
def is_new_profile_switch(user_email: str, profile_id: int) -> bool:
    """Check if user has ever switched to this profile before"""
    from app.core.shared_services.subscription.models import UserProfileSwitch
    
    with db.get_session() as session:
        existing = session.query(UserProfileSwitch).filter(
            UserProfileSwitch.user_email == user_email,
            UserProfileSwitch.profile_id == profile_id
        ).first()
        
        if existing:
            return False  # Already switched before - FREE
        
        # First time switching to this profile - counts against quota
        return True

# In switch_profile endpoint:
if profile.is_self:
    # Self is always free
    pass
elif is_new_profile_switch(user_email, profile_id):
    # First time switching to this profile
    access = service.can_access_feature(email, "switch_profile")
    if not access.get("can_access"):
        raise HTTPException(403)
    service.record_feature_usage(email, "switch_profile")
    # Record this profile as "switched"
    record_profile_switch(user_email, profile_id)
else:
    # Already switched to this profile before - FREE (back-and-forth)
    logger.info(f"Return switch to profile {profile_id} - FREE")
```

##### iOS Client Side - Prefer Local/History:
```swift
// CompatibilityViewModel.swift - before calling API
func runCompatibility() async {
    // 1. First check if this match exists in local history
    let existingMatch = CompatibilityHistoryService.shared.findMatch(
        boyDob: boyBirthDate,
        girlDob: girlBirthDate
    )
    
    if let existing = existingMatch {
        // Load from history - FREE, no API call
        loadFromHistory(existing)
        return
    }
    
    // 2. If not in local, check backend history
    // 3. Only if truly new, call API (which will count against quota)
    await analyzeCompatibility()
}
```

### 3.8 Data Reuse Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ USER REQUESTS MATCH: "Check compatibility with Partner X"        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Step 1: Check LOCAL Cache (iOS UserDefaults)                    │
│       │                                                          │
│       ├─→ Found? → Load from cache → Show result → END (FREE)   │
│       │                                                          │
│       └─→ Not found? → Continue to Step 2                        │
│                                                                  │
│  Step 2: Check HISTORY (synced from backend)                     │
│       │                                                          │
│       ├─→ Found? → Load from history → Show result → END (FREE) │
│       │                                                          │
│       └─→ Not found? → Continue to Step 3                        │
│                                                                  │
│  Step 3: NEW MATCH - Call API (LLM consumed)                     │
│       │                                                          │
│       ├─→ Check quota: can_access_feature("compatibility")       │
│       │       │                                                  │
│       │       ├─→ No? → Show subscribe modal → END               │
│       │       │                                                  │
│       │       └─→ Yes? → Run analysis (LLM call)                 │
│       │                                                          │
│       ├─→ Record usage: record_feature_usage()                   │
│       ├─→ Save to backend history                                │
│       ├─→ Save to local cache                                    │
│       └─→ Show result → END (COUNTED AS USAGE)                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.9 Implementation Verification Checklist

| # | Component | Expected Behavior | Code Location | Status |
|---|-----------|-------------------|---------------|--------|
| 1 | **Sync on login** | Fetch ALL threads for user | `AuthViewModel.swift:344-345` | ✅ Exists |
| 2 | **Sync on birth data** | Fetch ALL threads after profile setup | `BirthDataViewModel.swift:254-255` | ✅ Exists |
| 3 | **UI filters by profile_id** | History view shows only active profile's items | `CompatibilityHistoryService.loadAll()` | ✅ Implemented |
| 4 | **Single match: cache check** | Check cache before API call | `analyzeMatch()` calls `findExistingMatch()` | ✅ FIXED |
| 5 | **Single match: history check** | Check synced history before LLM | `findExistingMatch()` checks synced history | ✅ FIXED |
| 6 | **Multi-match: cache check** | Check cache for each partner | `analyzeAllPartners()` calls `findExistingMatch()` | ✅ FIXED |
| 7 | **Multi-match: history check** | Check history for each partner | `findExistingMatch()` per partner | ✅ FIXED |
| 8 | **Backend is_new_match** | Only record usage for NEW matches | `compatibility.py` checks existing threads | ✅ FIXED |
| 9 | **Backend is_new_switch** | Only record usage for FIRST switch | `subscription_router.py` uses `first_switched_at` | ✅ FIXED |
| 10 | **Save to history after match** | Store result in chat_threads | `compatibility.py:146-164` | ✅ Exists |

### 3.10 Summary of Fixes Applied

> [!TIP]
> **All 6 Gaps Fixed!** Usage now only counts when FRESH LLM/backend calls are triggered.

| Priority | Gap | Fix Applied |
|----------|-----|-------------|
| P0 | iOS Single: Check local cache | `findExistingMatch(boyDob:girlDob:)` called before API |
| P0 | iOS Single: Check history | `findExistingMatch()` checks synced history in loadAll() |
| P0 | iOS Multi: Check local cache per partner | Each partner checked via `findExistingMatch()` before API |
| P0 | iOS Multi: Check history per partner | Cached results loaded, skips API call |
| P0 | Backend: is_new_match check | `compatibility.py` checks existing threads before recording |
| P1 | Backend: is_new_switch check | `subscription_router.py` uses `first_switched_at` column |

### Files Modified

| File | Changes |
|------|---------|
| `CompatibilityHistoryService.swift` | Added `findExistingMatch(boyDob:girlDob:)` helper |
| `CompatibilityViewModel.swift` | Added cache check in `analyzeMatch()` and `analyzeAllPartners()` |
| `compatibility.py` | Added is_new_match logic before `record_feature_usage()` |
| `subscription_router.py` | Added is_new_switch logic with `first_switched_at` tracking |
| `models.py` | Added `first_switched_at` column to `PartnerProfile` |

---

## 4. Journey 3: Free Registered User

### 4.0 Core Business Logic Rules

> [!IMPORTANT]
> **Thumb Rules for ALL Users:**
> 1. **Usage count increases ONLY for NEW operations** (new profile switch, new partner match)
> 2. **Revisiting existing data is FREE** - fetch from local cache or history
> 3. **Back-and-forth navigation is FREE** - switching between already-accessed profiles
> 4. **Terminology:** "Subscribe" = Free→Paid, "Upgrade" = Core→Plus

### 4.1 Complete Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ FREE REGISTERED USER FLOW (10 chat, 1 compat, 2 profiles, 2 sw) │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─ AI QUESTIONS (10 total) ─────────────────────────────────┐   │
│  │ Q1 ✅ → Q2 ✅ → ... → Q10 ✅                                │   │
│  │ Q11 ❌ → Show subscription view (Core + Plus plans)        │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ COMPATIBILITY (1 total) ─────────────────────────────────┐   │
│  │                                                            │   │
│  │ NEW Partner Match:                                         │   │
│  │   Match 1 ✅ → Usage count +1                              │   │
│  │   Match 2 ❌ → "Subscribe for more matches"                │   │
│  │                (show Core + Plus plans)                    │   │
│  │                                                            │   │
│  │ SAME Partner Rematch (already matched):                    │   │
│  │   → ✅ FREE - Fetch from local cache or history            │   │
│  │   → No usage count increment                               │   │
│  │   → No recalculation triggered                             │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ PROFILE MANAGEMENT (2 total) ────────────────────────────┐   │
│  │                                                            │   │
│  │  [Add Profile]                                             │   │
│  │       │                                                    │   │
│  │       ├─→ Profile 1 (Friend A) ✅ → Count = 1              │   │
│  │       ├─→ Profile 2 (Friend B) ✅ → Count = 2              │   │
│  │       └─→ Profile 3 ❌ "Subscribe to save more profiles"   │   │
│  │                                                            │   │
│  │  [Delete Profile 1]                                        │   │
│  │       │                                                    │   │
│  │       └─→ ✅ Deleted → Active count = 1, Can add new!      │   │
│  │                                                            │   │
│  │  [Add Profile 3] ✅ Active count = 2 (allowed)             │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ SWITCH PROFILE (based on unique profiles switched) ──────┐   │
│  │                                                            │   │
│  │  User has: Self + Profile A + Profile B                    │   │
│  │                                                            │   │
│  │  FIRST-TIME SWITCH to new profile:                         │   │
│  │       ├─→ Self → Friend A ✅ (unique switch count: 1)      │   │
│  │       ├─→ Friend A → Friend B ✅ (unique switch count: 2)  │   │
│  │       └─→ Friend B → Profile C ❌ "Subscribe for more"     │   │
│  │                                                            │   │
│  │  RETURNING to already-switched profile (FREE):             │   │
│  │       ├─→ Friend B → Self ✅ (FREE - returning home)       │   │
│  │       ├─→ Self → Friend A ✅ (FREE - already switched)     │   │
│  │       └─→ Friend A → Friend B ✅ (FREE - already switched) │   │
│  │                                                            │   │
│  │  Data for return switches:                                 │   │
│  │       → Fetch from local cache first                       │   │
│  │       → If not in cache, fetch from history                │   │
│  │       → NO recalculation triggered                         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ MULTI-PROFILE MATCH (1 total) ───────────────────────────┐   │
│  │                                                            │   │
│  │  NEW Compare All:                                          │   │
│  │   [Compare All (2 partners)] ✅ → Usage count +1           │   │
│  │   [Compare All new partners] ❌ "Subscribe for Compare All"│   │
│  │                                                            │   │
│  │  SAME Compare All (already done):                          │   │
│  │   → ✅ FREE - Fetch from local cache or history            │   │
│  │   → No usage count increment                               │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Profile & Switch Logic Clarification

#### Scenario: User creates 2 profiles, switches both, deletes one, adds new

```
Step 1: User creates Profile A                    → Active: 1, Ever created: 1
Step 2: User creates Profile B                    → Active: 2, Ever created: 2
Step 3: User switches Self → A (FIRST TIME)       → Unique switches: 1
Step 4: User switches A → B (FIRST TIME)          → Unique switches: 2
Step 5: User switches B → Self (FREE)             → Unique switches: 2 (no change)
Step 6: User switches Self → A (FREE)             → Unique switches: 2 (no change)
Step 7: User deletes Profile A                    → Active: 1, Ever created: 2
Step 8: User creates Profile C                    → Active: 2 ✅ (allowed)
Step 9: User switches B → C (FIRST TIME)          → ❌ BLOCKED - unique switch limit = 2
```

> [!WARNING]
> **Switch quota = unique NEW profiles switched to**
> User can switch back and forth between already-switched profiles forever for FREE.
> But switching to a NEW profile counts against quota.

### 4.3 Data Reuse Strategy

| Scenario | Data Source | Usage Count |
|----------|-------------|-------------|
| New match (never run before) | Calculate via API | +1 |
| Same match (run before) | Local cache → History → API | 0 |
| Switch to new profile | Load profile data | +1 |
| Switch to already-used profile | Local cache → History | 0 |
| Rematch same partners | Local cache → History | 0 |

---

## 5. Journey 4: Core Subscriber

### 5.0 Core User Philosophy

> [!TIP]
> **Core = Registered Free + Higher Caps + Daily Resets**
> All business logic (cache check, unique usage, etc.) is IDENTICAL to registered free.
> Only the numbers change.

### 5.1 Core User Limits (Implemented ✅)

> [!IMPORTANT]
> **Dual Limit System:** Daily + Overall (Lifetime)
> When EITHER limit is exhausted, user is blocked.
> When OVERALL (lifetime) is exhausted → Contact support@destinyaiastrology.com for fair usage review.

| Feature | Daily Limit | Overall Limit | On Daily Exhausted | On Overall Exhausted |
|---------|-------------|---------------|--------------------|-----------------------|
| AI Questions | 100 | 300 | "Resets at midnight" | Contact support |
| Compatibility | 25 | 100 | "Resets at midnight" | Contact support |
| Profiles | 5 | 50 | "Resets at midnight" | Upgrade to Plus |
| Unique Switches | 5 | 50 | "Resets at midnight" | Upgrade to Plus |
| Multi-Match | 1 | 5 | "Resets at midnight" | Upgrade to Plus |

### 5.2 Seed Data Updated ✅

| Feature | Seed Data (daily/overall) | Status |
|---------|---------------------------|--------|
| `ai_questions` | 100/300 | ✅ DONE |
| `compatibility` | 25/100 | ✅ DONE |
| `maintain_profile` | 5/50 | ✅ ADDED |
| `switch_profile` | 5/50 | ✅ ADDED |
| `multi_profile_match` | 1/5 | ✅ ADDED |

**Updated in:** `migrations.py` lines 280-302

### 5.3 Backend Check Logic (Already Implemented ✅)

```python
# quota_service.py lines 141-169
# Daily limit check
if entitlement.daily_limit != -1 and daily_used >= entitlement.daily_limit:
    return {"can_access": False, "reason": "daily_limit_reached", ...}

# Overall limit check  
if entitlement.overall_limit != -1 and overall_used >= entitlement.overall_limit:
    return {"can_access": False, "reason": "overall_limit_reached", ...}
```

✅ Both daily and overall checks ARE in place in `can_access_feature()`

### 5.4 Features Added ✅ (Migration Complete)

New features added to `migrations.py`:

| Feature ID | Display Name | Daily | Overall |
|------------|--------------|-------|---------|
| `maintain_profile` | Partner Profiles | 5 | 50 |
| `switch_profile` | Switch Profile | 5 | 50 |
| `multi_profile_match` | Compare All | 1 | 5 |

**Migration run:** 2026-01-17 ✅

### 5.5 Core Implementation Checklist

| # | Feature | Backend | Seed | Status |
|---|---------|---------|------|--------|
| 1 | Daily limit check | ✅ | - | ✅ DONE |
| 2 | Overall limit check | ✅ | - | ✅ DONE |
| 3 | Daily reset logic | ✅ | - | ✅ DONE |
| 4 | ai_questions 100/300 | ✅ | ✅ | ✅ DONE |
| 5 | compatibility 25/100 | ✅ | ✅ | ✅ DONE |
| 6 | maintain_profile 5/50 | ✅ | ✅ | ✅ DONE |
| 7 | switch_profile 5/50 | ✅ | ✅ | ✅ DONE |
| 8 | multi_profile_match 1/5 | ✅ | ✅ | ✅ DONE |
| 9 | Cache check before API | ✅ | - | ✅ DONE |
| 10 | Rematch = FREE | ✅ | - | ✅ DONE |
| 11 | Return switch = FREE | ✅ | - | ✅ DONE |

### 5.6 Core User Flow (Implemented ✅)

```
┌─────────────────────────────────────────────────────────────────┐
│ CORE SUBSCRIBER FLOW ($4.99/mo)                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─ AI QUESTIONS (100/day, 300 overall) ─────────────────────┐   │
│  │ Day 1: Q1...Q100 ✅ → Q101 ❌ "Resets at 12:00 AM"        │   │
│  │ After 300 total: ❌ "Contact support@destinyaiastrology.com  │
│  │                      for fair usage review"               │   │
│  │ Cached responses = FREE (no count)                         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ COMPATIBILITY (25/day, 100 overall) ─────────────────────┐   │
│  │ Day 1: Match1...Match25 ✅ → 26th ❌ "Resets at 12:00 AM" │   │
│  │ After 100 total: ❌ "Contact support for fair usage review"│   │
│  │ Rematches (same DOB+time pair) = FREE                      │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ PROFILES (5/day, 50 overall) ────────────────────────────┐   │
│  │ Add 5 profiles today ✅ → 6th ❌ "Resets at 12:00 AM"      │   │
│  │ After 50 total: ❌ "Upgrade to Plus"                       │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ SWITCH PROFILE (5 unique/day, 50 overall) ───────────────┐   │
│  │ First switch to 5 NEW profiles today ✅                    │   │
│  │ Return switches = FREE (already switched)                  │   │
│  │ After 50 unique profiles ever: ❌ "Upgrade to Plus"        │   │
│  │ Uses `first_switched_at` column for tracking               │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ MULTI-PROFILE MATCH (1/day, 5 overall) ──────────────────┐   │
│  │ 1 Compare All today ✅ → 2nd ❌ "Resets at 12:00 AM"       │   │
│  │ After 5 total: ❌ "Upgrade to Plus"                        │   │
│  │ Same group = FREE (from cache)                             │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Journey 5: Plus Subscriber

### 6.0 Plus User Philosophy

> [!TIP]
> **Plus = "Worry-Free" Experience**
> Removes friction for power users.
> - **Unlimited** Profiles & Switching (No decision fatigue on who to save)
> - **Higher** AI/Match limits (Daily exploration without hitting walls)
> - **Exclusive** Access (Alerts, Early Access)

### 6.1 Plus User Limits (Implemented ✅)

| Feature | Daily Limit | Overall Limit | On Daily Exhausted | On Overall Exhausted |
|---------|-------------|---------------|--------------------|-----------------------|
| AI Questions | 100 | 600 | "Resets at midnight" | Contact support |
| Compatibility | 50 | 200 | "Resets at midnight" | Contact support |
| Profiles | Unlimited | Unlimited | - | - |
| Unique Switches | Unlimited | Unlimited | - | - |
| Multi-Match | 10 | 100 | "Resets at midnight" | Contact support |

> [!NOTE]
> **Why Limits on "Worry-Free"?**
> Even Plus has abuse caps (600/200) to prevent automated scraping or account sharing, but they are high enough that 99% of humans won't hit them.

### 6.2 Seed Data Verified ✅

| Feature | Seed Data (Plus) | Status |
|---------|------------------|--------|
| `ai_questions` | 100/600 | ✅ VERIFIED |
| `compatibility` | 50/200 | ✅ VERIFIED |
| `maintain_profile` | Unlimited (-1/-1) | ✅ VERIFIED |
| `switch_profile` | Unlimited (-1/-1) | ✅ VERIFIED |
| `multi_profile_match` | 10/100 | ✅ VERIFIED |

**Code Location:** `migrations.py` lines 305-346

### 6.3 Plus User Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ PLUS SUBSCRIBER FLOW ($7.99/mo)                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─ AI QUESTIONS (100/day, 600 overall) ─────────────────────┐   │
│  │ "Ask Anything" - Deep dive sessions                        │   │
│  │ Cap at 600 prevents LLM cost abuse                         │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ COMPATIBILITY (50/day, 200 overall) ─────────────────────┐   │
│  │ "Match Everyone" - Check fit with anyone                   │   │
│  │ 50/day is functionally unlimited for manual use            │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ PROFILES & SWITCHING (Unlimited) ────────────────────────┐   │
│  │ Save everyone you know (Friends, Family, Exes)             │   │
│  │ Switch freely - No "Unique Switch" counter visible         │   │
│  │ ⭐️ CORE VALUE: Never having to delete a profile            │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─ MULTI-PROFILE MATCH (10/day, 100 overall) ───────────────┐   │
│  │ Compare All groups (e.g. "Who looks best today?")          │   │
│  │ 10 times/day is effectively unlimited for standard use     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 Plus Implementation Checklist

| # | Feature | Backend | Seed | Status |
|---|---------|---------|------|--------|
| 1 | Daily limit check | ✅ | - | ✅ DONE |
| 2 | Overall limit check | ✅ | - | ✅ DONE |
| 3 | ai_questions 100/600 | ✅ | ✅ | ✅ DONE |
| 4 | compatibility 50/200 | ✅ | ✅ | ✅ DONE |
| 5 | profiles UNLIMITED | ✅ | ✅ | ✅ DONE |
| 6 | switches UNLIMITED | ✅ | ✅ | ✅ DONE |
| 7 | multi_match 10/100 | ✅ | ✅ | ✅ DONE |
| 8 | Alerts (Placeholder) | ✅ | ✅ | ✅ DONE |


---

## 7. Critical Logical Gaps Summary

### All Gaps Status

| # | Gap | Status |
|---|-----|--------|
| 1 | History migration on guest→registered | ✅ FIXED |
| 2 | Rematch detection (DOB+time) | ✅ FIXED |
| 3 | Return switch detection | ✅ FIXED |
| 4 | Local cache check before API | ✅ FIXED |
| 5 | Multi-partner cache check | ✅ FIXED |
| 6 | Backend is_new_match check | ✅ FIXED |
| 7 | Backend is_new_switch check | ✅ FIXED |
| 8 | LLM response caching | ✅ Already exists |

---

## 8. Abuse Prevention Analysis

### 8.1 Potential Abuse Scenarios

| Abuse Type | Scenario | Current Prevention | Recommendation |
|------------|----------|-------------------|----------------|
| **Account cycling** | Create guest → use 3 chats → create new guest | New device/reinstall = new guest | ✅ Acceptable loss |
| **Sign-in cycling** | Guest → register → new guest → register again | Same email can't register twice | ✅ OK |
| **Profile deletion cycling** | Add 2 → delete 1 → add new (repeat) | Count total created (free) | ✅ Implemented |
| **Multi-device** | Same account on 2 devices | Server-side quota is per email | ✅ OK - shared quota |
| **Timezone abuse** | Change timezone to reset daily limit | Server uses UTC for reset | ✅ If implemented |
| **Refund churning** | Subscribe → use heavily → refund | App Store/Play Store handles | ⚠️ Monitor |

### 8.2 Cost vs. Benefit Analysis

Each LLM call costs ~$0.01-0.05. Overall limits cap lifetime consumption.

**Updated Limits vs. Cost (Based on OVERALL Limits):**

| Plan | AI Questions | Compat Matches | Est. LLM Calls | Est. Cost | Revenue | Margin |
|------|--------------|----------------|----------------|-----------|---------|--------|
| Guest | 3 | 0 | 3 | $0.15 | $0 | -$0.15 |
| Registered | 10 | 1 | 11 | $0.55 | $0 | -$0.55 |
| Core | 300 | 100 | 400 | $20 | $4.99/mo | ⚠️ Break-even ~4mo |
| Plus | 600 | 200 | 800 | $40 | $7.99/mo | ⚠️ Break-even ~5mo |

> [!TIP]
> **Analysis:** With overall (lifetime) limits, costs are now bounded:
> - **Guest:** Max $0.15 loss - acceptable for conversion
> - **Registered:** Max $0.55 loss - acceptable for conversion  
> - **Core:** $20 lifetime max - breaks even after ~4 months
> - **Plus:** $40 lifetime max - breaks even after ~5 months
> 
> **Protection:** Once overall limit exhausted → manual review required (support@destinyaiastrology.com)

---

## 9. Recommendations

### 9.1 Immediate Fixes Required

#### Fix 1: History Migration on Upgrade
```python
# POST /subscription/upgrade
def upgrade_to_registered(old_email, new_email):
    # 1. Migrate chat_threads
    db.execute("UPDATE chat_threads SET user_email = ? WHERE user_email = ?", 
               (new_email, old_email))
    # 2. Migrate partner_profiles
    db.execute("UPDATE partner_profiles SET user_email = ? WHERE user_email = ?",
               (new_email, old_email))
    # 3. Migrate feature_usage
    db.execute("UPDATE user_subscriptions SET ... WHERE user_email = ?", ...)
    # 4. Delete old guest record
    db.execute("DELETE FROM user_subscriptions WHERE user_email = ?", (old_email,))
```

#### Fix 2: Switch to Self Should Be Free
```python
# POST /subscription/profiles/switch
if profile.is_self:
    # Skip quota check - always allow returning to self
    logger.info(f"User {email} switched back to self (free)")
else:
    access = service.can_access_feature(email, "switch_profile")
    if not access.get("can_access"):
        raise HTTPException(403)
    service.record_feature_usage(email, "switch_profile")
```

#### Fix 3: Redesign switch_profile Limits
```sql
-- Change from overall_limit to daily_limit for paid plans
UPDATE plan_entitlements 
SET daily_limit = 100, overall_limit = -1 
WHERE plan_id = 'core' AND feature_id = 'switch_profile';

UPDATE plan_entitlements 
SET daily_limit = -1, overall_limit = -1 
WHERE plan_id = 'plus' AND feature_id = 'switch_profile';
```

### 9.2 Recommended Plan Adjustments

| Feature | Current Core | Recommended Core | Current Plus | Recommended Plus |
|---------|--------------|------------------|--------------|------------------|
| multi_profile_match | 1 total | 5/day | 10/day | 10/day ✅ |
| switch_profile | 5 total | Unlimited | Unlimited ✅ | Unlimited ✅ |
| maintain_profile | 5 total | 10 total | Unlimited ✅ | Unlimited ✅ |

### 9.3 Future Considerations

1. **Usage Analytics Dashboard** - Track actual usage patterns to tune limits
2. **Smart Throttling** - Instead of hard block, slow down response time
3. **Carry-over Credits** - Unused daily quota carries to next day (max 2x)
4. **Family Plan** - Share Plus across 5 family members

---

## 10. Implementation Priority

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| P0 | Fix "Switch to Self" bug | 2 hours | User locked out of own profile |
| P0 | History migration on upgrade | 4 hours | User loses data |
| P1 | Redesign switch_profile limits | 1 hour | Core users stuck |
| P1 | Increase Core multi_match | 1 hour | Better value prop |
| P2 | Quota carryover logic | 4 hours | Fair transition |
| P3 | Usage analytics | 8 hours | Tune limits |
