# Caching Architecture

> End-to-end caching mechanism for Destiny AI Astrology App

## Overview

The app implements a multi-layer caching strategy to optimize performance, reduce API costs, and provide offline capabilities. Caching happens at both **Backend** (Python/FastAPI) and **iOS** (Swift) levels.

**All caches are user-scoped using `userEmail` to prevent data mixing between accounts.**

---

## Complete Storage Matrix

| Endpoint | Stateless | Backend Cache | UI Cache | Backend History | iOS History | Sync on Clear |
|----------|-----------|---------------|----------|-----------------|-------------|---------------|
| `/tools/*` | ✅ | ❌ | ❌ | ❌ | ❌ | N/A |
| `/astrodata/*` | ✅ | ❌ | ✅ Forever | ❌ | ❌ | N/A |
| `/todays-prediction` | ❌ | ✅ 24h | ✅ Daily | ❌ | ❌ | N/A |
| `/predict/*` | ❌ | ✅ Session | ✅ SwiftData | ✅ | ✅ | ✅ |
| `/compatibility/*` | ❌ | ✅ Session | ✅ UserDefaults | ✅ | ✅ | ✅ |
| `/chat-history/*` | ❌ | **IS DB** | ✅ SwiftData | **IS DB** | ✅ | ✅ |
| `/feedback/*` | ✅ | ❌ | ❌ | ❌ | ❌ | N/A |
| `/subscription/*` | ❌ | ❌ | ✅ UserDefaults | ✅ | ✅ | ✅ |

---

## 🔐 User Data Isolation

**All caches are keyed by `userEmail` to prevent data mixing:**

| Cache | Key Format | Example |
|-------|------------|---------|
| `UserBirthData` (Storage) | `userBirthData_{email}` | `userBirthData_user@icloud.com` |
| `TodaysPredictionCache` | `todaysPrediction_response_{email}` | `todaysPrediction_response_user@icloud.com` |
| `AstroDataCache` (chart) | `astro_chart_{email}_{birthHash}` | `astro_chart_user@icloud.com_a1b2c3d4` |
| `AstroDataCache` (dasha) | `astro_dasha_{email}_{birthHash}_{year}` | `astro_dasha_user@icloud.com_a1b2c3d4_2026` |
| `AstroDataCache` (transits) | `astro_transits_{email}_{birthHash}_{year}` | `astro_transits_user@icloud.com_a1b2c3d4_2026` |
| `CompatibilityHistoryService` | `compatibility_history_{email}` | `compatibility_history_user@icloud.com` |
| `DataManager` (SwiftData) | Filtered by `userEmail` field | `WHERE userEmail = 'user@icloud.com'` |

### Guest Users
- Guest users are keyed as `guest` until they sign in
- On sign-in, new cache entries are created for their email

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS APP                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐ │
│  │   UI CACHE (Fast)   │  │  iOS HISTORY (View) │  │   SYNC SERVICES     │ │
│  │   🔐 Per-User Keys  │  │   🔐 Per-User Query │  │                     │ │
│  ├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤ │
│  │ TodaysPrediction    │  │ LocalChatThread     │  │ ChatHistorySyncSvc  │ │
│  │   Cache.swift       │  │ LocalChatMessage    │  │ CompatHistorySync   │ │
│  │                     │  │ CompatHistoryItem   │  │ ProfileService      │ │
│  │ AstroDataCache      │  │                     │  │                     │ │
│  │   .swift            │  │ (SwiftData +        │  │ (Fetch from backend │ │
│  │                     │  │  UserDefaults)      │  │  on login)          │ │
│  │ (UserDefaults)      │  │                     │  │                     │ │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘ │
│           │                         │                        │             │
│           ▼                         ▼                        ▼             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         API LAYER (Services)                        │   │
│  │  PredictionService | UserChartService | CompatibilityService        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
└────────────────────────────────────┼───────────────────────────────────────┘
                                     │ HTTPS
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND (FastAPI)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐ │
│  │   BACKEND CACHE     │  │  QUERY SECURITY     │  │   CHAT HISTORY      │ │
│  │   🔐 Per-User Keys  │  │                     │  │   🔐 Per-User DB    │ │
│  ├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤ │
│  │ CacheService        │  │ QuerySecuritySvc    │  │ ChatHistoryService  │ │
│  │ (Redis/In-Memory)   │  │                     │  │                     │ │
│  │                     │  │ - Cache by email    │  │ - Threads           │ │
│  │ - todays_prediction │  │ - Session tracking  │  │ - Messages          │ │
│  │   :{email}:{date}   │  │ - Guard checks      │  │ - User settings     │ │
│  │                     │  │                     │  │                     │ │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Endpoint-by-Endpoint Details

### 1. `/astrodata/*` - Static Chart Data

| Property | Value |
|----------|-------|
| **Backend Cache** | ❌ None (fast ~50ms calculation) |
| **iOS Cache** | ✅ `AstroDataCache.swift` |
| **Cache Key** | `astro_chart_{email}_{birthHash}`, `astro_dasha_{email}_{birthHash}_{year}` |
| **TTL** | Forever (until birth data changes) |
| **User Isolated** | ✅ Yes, by `userEmail` |

```swift
// AstroDataCache.swift - All keys include email
let key = "\(fullChartPrefix)\(email)_\(birthHash)"
```

---

### 2. `/todays-prediction` - Daily AI Insight

| Property | Value |
|----------|-------|
| **Backend Cache** | ✅ `CacheService` with 24h TTL |
| **iOS Cache** | ✅ `TodaysPredictionCache.swift` |
| **Cache Key** | `todaysPrediction_response_{email}`, `todaysPrediction_date_{email}` |
| **TTL** | 24 hours (expires at midnight) |
| **User Isolated** | ✅ Yes, by `userEmail` |

```swift
// TodaysPredictionCache.swift
let responseKey = "\(responsePrefixKey)\(email)"  // todaysPrediction_response_user@icloud.com
```

---

### 3. `/predict/*` - Ask Destiny (Chat)

| Property | Value |
|----------|-------|
| **Backend Cache** | ✅ `QuerySecurityService` (session-based) |
| **iOS Cache** | ✅ `SwiftData` (LocalChatThread, LocalChatMessage) |
| **Backend History** | ✅ `ChatHistoryService` |
| **iOS History** | ✅ Visible in History tab |
| **User Isolated** | ✅ Yes, filtered by `userEmail` field |
| **Sync on Clear** | ✅ `ChatHistorySyncService.syncFromServer()` |

```swift
// DataManager.swift - SwiftData queries filter by email
predicate = #Predicate<LocalChatThread> { $0.userEmail == userEmail }
```

---

### 4. `/compatibility/*` - Match Analysis

| Property | Value |
|----------|-------|
| **Backend Cache** | ✅ Session-based (QuerySecurity) |
| **iOS Cache** | ✅ `CompatibilityHistoryService` (UserDefaults) |
| **Backend History** | ✅ `ChatHistoryService` (area="compatibility") |
| **iOS History** | ✅ Visible in Match History |
| **User Isolated** | ✅ Yes, by `userEmail` |
| **Sync on Clear** | ✅ `CompatibilityHistoryService.syncFromServer()` |

```swift
// CompatibilityHistoryService.swift - Storage key includes email
private var storageKey: String {
    "\(Self.storageKeyPrefix)\(currentUserEmail)"  // compatibility_history_user@icloud.com
}
```

---

## iOS Cache Services Summary

| Service | Storage | User Isolated | Clear Method |
|---------|---------|---------------|--------------|
| `TodaysPredictionCache` | UserDefaults | ✅ `{email}` in key | `clear(forUser:)` |
| `AstroDataCache` | UserDefaults | ✅ `{email}` in key | `clearAll(forUser:)` |
| `CompatibilityHistoryService` | UserDefaults | ✅ `{email}` in key | `clearAll(forUser:)` |
| `DataManager` | SwiftData | ✅ Filter by `userEmail` | Intrinsic |

---

## Logout Behavior

### Current Flow (Secure)

| Data Type | Guest Logout | Registered User Logout |
|-----------|--------------|------------------------|
| Auth state (keychain) | ✅ Cleared | ✅ Cleared |
| UserDefaults (isGuest, email, name) | ✅ Cleared | ✅ Cleared |
| Birth data (Session) | ✅ Cleared | ✅ Cleared (UI resets) |
| Birth data (Storage) | ✅ **Deleted** | 🔒 **Preserved** (isolated in `userBirthData_{email}`) |
| TodaysPredictionCache | 🔒 Isolated (guest key) | 🔒 Isolated (user key) |
| AstroDataCache | 🔒 Isolated (guest key) | 🔒 Isolated (user key) |
| CompatibilityHistoryService | 🔒 Isolated (guest key) | 🔒 Isolated (user key) |
| SwiftData (chat threads) | 🔒 Filtered by email | 🔒 Filtered by email |

**Key Insight:** Data is NOT cleared on logout, but it's isolated by user. When User B logs in, they see only their data, not User A's cached data.

---

## Cache Invalidation Rules

| Trigger | Action |
|---------|--------|
| Midnight (date change) | `TodaysPredictionCache` automatically returns nil |
| Birth data updated | Caller should call `AstroDataCache.clearAll()` |
| Logout | Data isolated by user key - no clearing needed |
| App reinstall | Sync from backend restores history for logged-in user |

---

## Cross-Device Sync Flow

When user logs in on a new device:

```
┌──────────────────────┐
│   User Logs In       │
│   email: user@...    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                    PARALLEL SYNC (by email)                   │
├──────────────────┬───────────────────┬───────────────────────┤
│ ProfileService   │ ChatHistorySync   │ CompatHistorySync     │
│ .fetchProfile()  │ .syncFromServer() │ .syncFromServer()     │
├──────────────────┼───────────────────┼───────────────────────┤
│ GET /subscription│ GET /chat-history │ GET /chat-history     │
│ /profile?email=  │ /threads/{email}  │ /threads/{email}      │
│                  │                   │ (filter: compatibility)│
├──────────────────┼───────────────────┼───────────────────────┤
│ Restores:        │ Restores:         │ Restores:             │
│ • Birth data     │ • All threads     │ • Match history       │
│ • Quota          │ • All messages    │ • Names, scores       │
│ • Premium status │                   │                       │
└──────────────────┴───────────────────┴───────────────────────┘
           │
           ▼
   All data stored with {email} key
   → Visible only to this user
```

---

## Performance Impact

| Endpoint | Without Cache | With Cache | Savings |
|----------|---------------|------------|---------|
| `/todays-prediction` | ~3s (LLM) | ~10ms (local) | **99.7%** |
| `/astrodata/full` | ~100ms (API) | ~5ms (local) | **95%** |
| `/predict` (repeat) | ~3s (LLM) | ~50ms (security check) | **98%** |

---

## File References

### iOS Cache Files
- [`TodaysPredictionCache.swift`](../ios_app/Services/TodaysPredictionCache.swift) - 🔐 User-isolated
- [`AstroDataCache.swift`](../ios_app/Services/AstroDataCache.swift) - 🔐 User-isolated
- [`CompatibilityHistoryService.swift`](../ios_app/Services/CompatibilityHistoryService.swift) - 🔐 User-isolated
- [`ChatHistorySyncService.swift`](../ios_app/Services/ChatHistorySyncService.swift)
- [`DataManager.swift`](../ios_app/Services/DataManager.swift) - 🔐 Queries filter by userEmail

### Backend Cache Files
- [`cache/service.py`](../../astrology_api/astroapi-v2/app/core/shared_services/cache/service.py)
- [`query_security/__init__.py`](../../astrology_api/astroapi-v2/app/core/shared_services/query_security/__init__.py)
- [`chat_history/service.py`](../../astrology_api/astroapi-v2/app/core/shared_services/chat_history/service.py)

---

*Last Updated: 2026-01-02*
