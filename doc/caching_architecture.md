# Caching Architecture

> End-to-end caching mechanism for Destiny AI Astrology App

## Overview

The app implements a multi-layer caching strategy to optimize performance, reduce API costs, and provide offline capabilities. Caching happens at both **Backend** (Python/FastAPI) and **iOS** (Swift) levels.

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

## Column Definitions

| Column | Meaning |
|--------|---------|
| **Stateless** | No user context needed; same input = same output |
| **Backend Cache** | Server-side caching (Redis/in-memory) |
| **UI Cache** | iOS local caching (UserDefaults, SwiftData) |
| **Backend History** | Persistent storage in backend database |
| **iOS History** | User-visible browsable history in app |
| **Sync on Clear** | Recoverable from backend when iOS data cleared |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS APP                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐ │
│  │   UI CACHE (Fast)   │  │  iOS HISTORY (View) │  │   SYNC SERVICES     │ │
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
| **Cache Key** | `chart_{birthHash}`, `dasha_{birthHash}_{year}`, `transits_{birthHash}_{year}` |
| **TTL** | Forever (until birth data changes) |
| **Invalidation** | When user updates birth details |

```swift
// AstroDataCache.swift
func getFullChart(birthHash: String) -> UserAstroDataResponse?
func getDasha(birthHash: String, year: Int) -> DashaResponse?
func getTransits(birthHash: String, year: Int) -> TransitResponse?
```

---

### 2. `/todays-prediction` - Daily AI Insight

| Property | Value |
|----------|-------|
| **Backend Cache** | ✅ `CacheService` with 24h TTL |
| **iOS Cache** | ✅ `TodaysPredictionCache.swift` |
| **Cache Key** | `todays_prediction:{email}:{date}` |
| **TTL** | 24 hours (expires at midnight) |
| **Invalidation** | Automatic at midnight |

```python
# Backend (todays_prediction.py)
cache_key = f"todays_prediction:{user_email}:{target_date.isoformat()}"
cache.set(cache_key, response.model_dump(), ttl=86400)  # 24h
```

```swift
// iOS (TodaysPredictionCache.swift)
func get() -> TodaysPredictionResponse?  // Returns nil if date changed
func set(_ response: TodaysPredictionResponse)
```

---

### 3. `/predict/*` - Ask Destiny (Chat)

| Property | Value |
|----------|-------|
| **Backend Cache** | ✅ `QuerySecurityService` (session-based) |
| **iOS Cache** | ✅ `SwiftData` (LocalChatThread, LocalChatMessage) |
| **Backend History** | ✅ `ChatHistoryService` |
| **iOS History** | ✅ Visible in History tab |
| **Sync on Clear** | ✅ `ChatHistorySyncService.syncFromServer()` |

**Flow:**
1. User sends query → Backend validates via QuerySecurity
2. Response stored in ChatHistory (backend DB)
3. iOS saves to SwiftData locally
4. On reinstall → `ChatHistorySyncService` fetches all threads

---

### 4. `/compatibility/*` - Match Analysis

| Property | Value |
|----------|-------|
| **Backend Cache** | ✅ Session-based (QuerySecurity) |
| **iOS Cache** | ✅ `CompatibilityHistoryService` (UserDefaults) |
| **Backend History** | ✅ `ChatHistoryService` (area="compatibility") |
| **iOS History** | ✅ Visible in Match History |
| **Sync on Clear** | ✅ `CompatibilityHistoryService.syncFromServer()` |

```python
# Backend (compatibility.py) - stores to history
chat_history.create_thread(
    user_id=user_email,
    thread_id=f"compat_{session_id}",
    title=f"Match: {boy.name} & {girl.name}",
    area="compatibility"
)
```

---

### 5. `/subscription/*` - User Profile & Quota

| Property | Value |
|----------|-------|
| **Backend Cache** | ❌ None (real-time quota needed) |
| **iOS Cache** | ✅ `UserDefaults` (quota, premium status) |
| **Backend History** | ✅ Profile DB |
| **iOS History** | ✅ `UserDefaults` |
| **Sync on Clear** | ✅ `ProfileService.fetchProfile()` → `restoreProfileLocally()` |

---

## iOS Cache Services Summary

| Service | Storage | Purpose | TTL |
|---------|---------|---------|-----|
| `TodaysPredictionCache` | UserDefaults | Daily AI insight | Daily (midnight) |
| `AstroDataCache` | UserDefaults | Chart, Dasha, Transits | Forever |
| `DataManager` | SwiftData | Chat threads/messages | Forever |
| `CompatibilityHistoryService` | UserDefaults | Match results | Forever |
| `QuotaManager` | UserDefaults | Quota status | Per-session |

---

## Cross-Device Sync Flow

When user logs in on a new device:

```
┌──────────────────────┐
│   User Logs In       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────────┐
│                    PARALLEL SYNC                              │
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
```

---

## Cache Invalidation Rules

| Trigger | Caches Invalidated |
|---------|-------------------|
| Midnight (date change) | `TodaysPredictionCache` |
| Birth data updated | `AstroDataCache.clearAll()` |
| Logout | All local caches |
| App reinstall | Sync from backend restores history |

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
- [`TodaysPredictionCache.swift`](../ios_app/Services/TodaysPredictionCache.swift)
- [`AstroDataCache.swift`](../ios_app/Services/AstroDataCache.swift)
- [`CompatibilityHistoryService.swift`](../ios_app/Services/CompatibilityHistoryService.swift)
- [`ChatHistorySyncService.swift`](../ios_app/Services/ChatHistorySyncService.swift)
- [`DataManager.swift`](../ios_app/Services/DataManager.swift)

### Backend Cache Files
- [`cache/service.py`](../../astrology_api/astroapi-v2/app/core/shared_services/cache/service.py)
- [`query_security/__init__.py`](../../astrology_api/astroapi-v2/app/core/shared_services/query_security/__init__.py)
- [`chat_history/service.py`](../../astrology_api/astroapi-v2/app/core/shared_services/chat_history/service.py)

---

*Last Updated: 2026-01-02*
