# Destiny AI Astrology - User Journey Analysis

> **Core Principle:** Birth Data = Identity (Same DOB/Time/Place = Same Person)

## Quick Reference Matrix

| # | Scenario | Outcome | Protection |
|---|----------|---------|------------|
| 1 | Guest → Register (direct) | History migrated, guest archived | Migration |
| 2 | Guest → Logout → Register → Same DOB | History migrated, guest archived | Migration |
| 3 | Archived Guest → Guest (same DOB) | Blocked → Sign-in prompt | ArchivedGuestError |
| 4 | Guest A registers, Guest B (diff DOB) | New account created | None needed |
| 5 | Registered → Guest (same DOB) | Blocked → Sign-in prompt | BirthDataTakenError |
| 6 | Registered A, Registered B (same DOB) | Blocked | BirthDataTakenError |
| 7 | Guest reopens app | Resume session | Session restore |
| 8 | Guest erases data → Guest (same DOB) | Recovers guest account | Email pattern match |
| 9 | Guest erases data → Registers | History migrates | Migration |
| 10 | Registered logout → Different account | New session | Clean separation |

---

## Detailed Scenarios

### 1. Guest → Register (Direct Upgrade)
**Path:** Guest using app → Sign In → Apple/Google

**Flow:**
1. `performSignIn` captures guest birth data before sign-in
2. Apple/Google auth completes
3. `saveGuestBirthDataForRegisteredUser()` called
4. Backend: `save_profile` → `migrate_guest_history_by_birth_data()`
5. Guest archived: `is_archived=True`, `upgraded_to_email=<registered>`
6. User lands on Home with history

**Result:** ✅ Seamless upgrade

---

### 2. Guest → Logout → Register → Same Birth Data
**Path:** Guest → Sign Out → Sign In → BirthDataView → Enter same DOB

**Flow:**
1. Guest signs out → local data cleared
2. Signs in as registered → no birth data on server
3. BirthDataView shown, enters same DOB
4. `save_profile` called → migration triggered
5. History migrated, guest archived

**Result:** ✅ Works correctly

---

### 3. Archived Guest Tries Guest Mode
**Path:** Was guest → upgraded → later tries guest with same DOB

**Flow:**
1. User taps "Continue as Guest"
2. Enters same birth data → generates same email pattern
3. `/register` with `is_generated_email=True`
4. Backend finds archived guest
5. `ArchivedGuestError` raised → HTTP 409
6. iOS shows: "Please sign in to your registered account"

**Result:** ✅ Blocked correctly

---

### 4. Different People, Different Birth Data
**Path:** Guest A registers, Guest B uses app

**Flow:**
1. Guest A: `19800701_0632_Bhi_21_81@daa.com` → registers → archived
2. Guest B: Different DOB → `19950315_1430_Mum_19_72@daa.com`
3. No conflict, unique email pattern

**Result:** ✅ No issue

---

### 5. Registered User Tries Guest (Same DOB)
**Path:** Registered first → Logout → Guest → Same DOB

**Flow:**
1. Registered: `user@gmail.com` with DOB 1980-07-01
2. User logs out
3. Taps "Continue as Guest", enters same DOB
4. `save_profile` called
5. `find_registered_user_by_birth_data()` finds `user@gmail.com`
6. `BirthDataTakenError` raised
7. iOS shows: "This birth data belongs to user@gmail.com"

**Result:** ✅ Blocked correctly

---

### 6. Two Registered Users, Same Birth Data
**Path:** User A registered, User B tries same DOB

**Flow:**
1. User A: `a@gmail.com` has DOB 1980-07-01
2. User B: `b@gmail.com` tries to save same DOB
3. `find_registered_user_by_birth_data()` finds User A
4. `BirthDataTakenError` raised

**Result:** ✅ Blocked (only one account per birth data)

---

### 7. Guest Reopens App
**Path:** Guest uses app → closes → reopens

**Flow:**
1. App launch → `checkExistingSession()`
2. Keychain has userId → `isAuthenticated = true`
3. UserDefaults has birth data → UI restored
4. Chat history synced from server

**Result:** ✅ Seamless resume

---

### 8. Guest Erases Data → Guest Again (Same DOB)
**Path:** Guest → Reinstall app → Guest → Same DOB

**Flow:**
1. Guest account exists on server
2. App reinstalled, local data gone
3. Taps "Continue as Guest", enters same DOB
4. Email pattern regenerated: `19800701_0632_Bhi_21_81@daa.com`
5. `/register` finds **existing** (not archived) guest
6. Returns existing user
7. Chat history synced

**Result:** ✅ Recovers existing guest account

---

### 9. Guest Erases Data → Registers
**Path:** Guest → Reinstall → Sign In (registers) → Same DOB

**Flow:**
1. Old guest account on server (not archived)
2. User signs in with Apple/Google
3. Enters same DOB in BirthDataView
4. `save_profile` → migration triggered
5. Old guest history → new registered user
6. Old guest archived

**Result:** ✅ History recovered and migrated

---

### 10. Registered Logout → Different Account
**Path:** User A logged in → Logout → User B signs in

**Flow:**
1. User A signs out → session cleared
2. User B signs in → new session
3. User B enters their own birth data
4. User A's data untouched (user-scoped storage)

**Result:** ✅ Clean account separation

---

## Technical Implementation

### Key Database Fields
```
UserSubscription:
  - is_generated_email: Boolean  # True=Guest, False=Registered
  - is_archived: Boolean         # True=Upgraded guest
  - upgraded_to_email: String    # Registered email after upgrade
  - date_of_birth, time_of_birth, city_of_birth, latitude, longitude
```

### Key Functions
| Function | Purpose |
|----------|---------|
| `find_registered_user_by_birth_data()` | Blocks duplicate registered accounts |
| `migrate_guest_history_by_birth_data()` | Moves history + archives guest |
| `ArchivedGuestError` | Blocks re-use of archived guest DOB |
| `BirthDataTakenError` | Blocks registered DOB conflict |

### Guest Email Pattern
```
Format: YYYYMMDD_HHMM_CityPrefix_LatInt_LngInt@daa.com
Example: 19800701_0632_Bhi_21_81@daa.com
```

---

## Edge Cases Handled

| Edge Case | Protection |
|-----------|------------|
| Guest upgrades, tries guest again | ArchivedGuestError |
| Registered tries guest (own DOB) | BirthDataTakenError |
| Twin babies (same DOB) | Different time of birth |
| App reinstall | Email pattern regenerates same |
| Offline usage | Local data preserved |
