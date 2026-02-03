# Login & Upgrade Test Plan

Comprehensive test plan for authentication flows, account deduplication, and guest-to-registered upgrade scenarios.

---

## Test Environment Setup

```
API_BASE_URL: http://127.0.0.1:8000
API_KEY: astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic
iOS Simulator: iPhone 17 Pro
```

---

## Section 1: Guest User Login Scenarios

### 1.1 Fresh Guest Login (No Conflicts)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch app | AuthView displayed |
| 2 | Tap "Continue as Guest" | BirthDataView displayed |
| 3 | Enter unique birth data (DOB: 2000-01-15, Time: 10:30, City: Bangalore) | Fields populated |
| 4 | Tap "Continue" | ProfileSetupLoadingView shown |
| 5 | Wait for completion | HomeView displayed |
| 6 | Check `UserDefaults.isGuest` | Should be `true` |
| 7 | Check email format | `20000115_1030_Ban_12_77@daa.com` |

**Status:** ⬜ Not Tested

---

### 1.2 Guest Login with Conflicting Birth Data (409 Error)

**Precondition:** Registered user `testuser@gmail.com` exists with:
- DOB: 1990-06-15, Time: 10:30, City: Mumbai (19.076, 72.877)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch app | AuthView displayed |
| 2 | Tap "Continue as Guest" | BirthDataView displayed |
| 3 | Enter matching birth data (DOB: 1990-06-15, Time: 10:30, Location near Mumbai) | Fields populated |
| 4 | Tap "Continue" | API returns 409 |
| 5 | ProfileSetupLoadingView | Should be cancelled |
| 6 | Error message shown | "An account already exists with your birth data" |
| 7 | Masked email displayed | `te****@gmail.com` |
| 8 | Sign-in prompt shown | User prompted to sign in |

**Status:** ⬜ Not Tested

---

### 1.3 Guest Login with Fuzzy Time Match (±5 min)

**Precondition:** Registered user exists with Time: 10:30

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch app as guest | BirthDataView displayed |
| 2 | Enter same DOB, same location | Fields populated |
| 3 | Enter time: 10:32 (within ±5 min) | Time field set |
| 4 | Tap "Continue" | 409 Conflict expected |
| 5 | Error message | Conflict detected (within tolerance) |

**Status:** ⬜ Not Tested

---

### 1.4 Guest Login with Distant Time (>5 min)

**Precondition:** Registered user exists with Time: 10:30

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch app as guest | BirthDataView displayed |
| 2 | Enter same DOB, same location | Fields populated |
| 3 | Enter time: 10:40 (>5 min diff) | Time field set |
| 4 | Tap "Continue" | 200 OK - Guest created |
| 5 | HomeView displayed | New guest account works |

**Status:** ⬜ Not Tested

---

### 1.5 Guest Login with Fuzzy Location Match (150km radius)

**Precondition:** Registered user exists with Mumbai (19.076, 72.877)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter same DOB, same time | Fields set |
| 2 | Enter location: Thane (~30km from Mumbai) | Location in range |
| 3 | Tap "Continue" | 409 Conflict expected |
| 4 | Enter location: Pune (~150km from Mumbai) | Location out of range |
| 5 | Tap "Continue" | 200 OK - Guest created |

**Status:** ⬜ Not Tested

---

## Section 2: Registered User Login Scenarios

### 2.1 Fresh Apple Sign-In (No Existing Account)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch app | AuthView displayed |
| 2 | Tap "Sign in with Apple" | Apple sign-in sheet |
| 3 | Complete Apple authentication | Registration API called |
| 4 | HTTP 200 response | User created |
| 5 | BirthDataView displayed | Awaiting birth data |
| 6 | `UserDefaults.isGuest` | Should be `false` |

**Status:** ⬜ Not Tested

---

### 2.2 Fresh Google Sign-In (No Existing Account)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Sign in with Google" | Google sign-in flow |
| 2 | Complete Google authentication | Registration API called |
| 3 | HTTP 200 response | User created |
| 4 | BirthDataView displayed | Awaiting birth data |

**Status:** ⬜ Not Tested

---

### 2.3 Returning Registered User (Has Account)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Launch app | AuthView displayed |
| 2 | Sign in with existing Apple/Google account | Existing user found |
| 3 | HTTP 200 response | User data returned |
| 4 | If `hasBirthData == true` | HomeView displayed |
| 5 | If `hasBirthData == false` | BirthDataView displayed |

**Status:** ⬜ Not Tested

---

### 2.4 Registered User Birth Data Conflict

**Precondition:** User A (`existinguser@gmail.com`) has birth data set

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Sign in with NEW Apple account (User B) | Registration succeeds |
| 2 | BirthDataView displayed | Awaiting birth data |
| 3 | Enter SAME birth data as User A | Fields populated |
| 4 | Tap "Continue" | API returns 409 `birth_data_taken` |
| 5 | ProfileSetupLoadingView cancelled | Loading stops |
| 6 | BirthDataConflictSheet displayed | Two options shown |
| 7 | Masked email displayed | `ex****@gmail.com` |
| 8 | Tap "Sign In to Existing Account" | Signs out, shows AuthView |
| 9 | Alternatively: Tap "Go Back and Edit" | Sheet dismisses, can edit data |

**Status:** ⬜ Not Tested

---

## Section 3: Guest-to-Registered Upgrade Scenarios

### 3.1 Guest Upgrades via Apple Sign-In

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as guest, enter birth data | Guest account created |
| 2 | Use app features, create chat history | Data stored under guest email |
| 3 | Open GuestSignInPromptView (quota limit) | Sign-in options shown |
| 4 | Tap "Sign in with Apple" | Apple sign-in flow |
| 5 | Complete with NEW Apple account | Registration succeeds |
| 6 | Enter SAME birth data as guest | Profile save API called |
| 7 | HTTP 200 response | Migration triggered |
| 8 | Chat history preserved | Guest threads migrated |
| 9 | Guest account archived | `is_archived = true` |

**Status:** ⬜ Not Tested

---

### 3.2 Guest Upgrades via Google Sign-In

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Log in as guest, enter birth data | Guest account created |
| 2 | Open GuestSignInPromptView | Sign-in options shown |
| 3 | Tap "Sign in with Google" | Google sign-in flow |
| 4 | Complete with NEW Google account | Registration succeeds |
| 5 | Enter SAME birth data as guest | Profile save API called |
| 6 | HTTP 200 response | Migration triggered |
| 7 | Check guest account | Archived with upgrade trail |

**Status:** ⬜ Not Tested

---

### 3.3 Archived Guest Retry (Post-Upgrade)

**Precondition:** Guest was previously upgraded to registered

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attempt to use old guest email | Register API called |
| 2 | Backend checks archived status | Guest is archived |
| 3 | HTTP 409 `archived_guest` | Error returned |
| 4 | Error message displayed | "This account was upgraded to..." |
| 5 | `upgraded_to_email` shown | Points to registered email |

**Status:** ⬜ Not Tested

---

### 3.4 Data Migration Verification

| Step | Verification | Expected |
|------|--------------|----------|
| 1 | ChatThreads | Migrated to registered email |
| 2 | LLM Usage Stats | Preserved or transferred |
| 3 | Partner Profiles | Migrated if applicable |
| 4 | Birth Data | Copied to registered user |
| 5 | Quota Usage | Reset for registered tier |

**Status:** ⬜ Not Tested

---

## Section 4: Edge Cases

### 4.1 Twins Scenario

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User A registers with DOB/Time/Place | Account created |
| 2 | Twin (User B) tries same exact data | 409 Conflict |
| 3 | Resolution | Contact support for manual override |

**Status:** ⬜ Not Tested

---

### 4.2 Midnight Time Wrap

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User A: Time 23:58 | Account created |
| 2 | User B: Time 00:02 (same DOB+1) | Should match (4 min diff) |
| 3 | Conflict detected | Within ±5 min tolerance |

**Status:** ⬜ Not Tested

---

### 4.3 Network Failure During Registration

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Start registration | API call initiated |
| 2 | Simulate network failure | Request times out |
| 3 | Error handling | Graceful error message |
| 4 | Retry | Can attempt again |

**Status:** ⬜ Not Tested

---

### 4.4 Multiple Devices Same Account

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Sign in on Device A | Account active |
| 2 | Sign in on Device B (same account) | Both devices work |
| 3 | Check data sync | Consistent across devices |

**Status:** ⬜ Not Tested

---

## Section 5: API Curl Verification Commands

### Quick Backend Tests

```bash
# Set environment
export API_KEY="astro_ios_G5iY3-1Z7ymE46hYwKTbK1bSz2x5Vn4BeymPOvyy3ic"
export BASE="http://127.0.0.1:8000"

# Test 1: Guest conflict detection
curl -s -w "\nHTTP: %{http_code}" -X POST "$BASE/subscription/register" \
  -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
  -d '{"email": "19900615_1030_Mum_19_72@daa.com", "is_generated_email": true}'
# Expected: 409 with masked_email

# Test 2: Registered user registration
curl -s -w "\nHTTP: %{http_code}" -X POST "$BASE/subscription/register" \
  -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
  -d '{"email": "newuser@gmail.com", "is_generated_email": false}'
# Expected: 200 OK

# Test 3: Profile save with migration
curl -s -w "\nHTTP: %{http_code}" -X POST "$BASE/subscription/profile" \
  -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
  -d '{"email": "newuser@gmail.com", "is_generated_email": false, "birth_profile": {"date_of_birth": "1985-03-15", "time_of_birth": "09:00", "city_of_birth": "Pune", "latitude": 18.52, "longitude": 73.85}}'
# Expected: 200 OK, triggers migration if matching guest exists

# Test 4: Check user status
curl -s "$BASE/subscription/status?email=newuser@gmail.com" \
  -H "Authorization: Bearer $API_KEY"
```

---

## Test Summary Checklist

| Section | Test Cases | Passed | Failed | Blocked |
|---------|------------|--------|--------|---------|
| 1. Guest Login | 5 | ⬜ | ⬜ | ⬜ |
| 2. Registered Login | 4 | ⬜ | ⬜ | ⬜ |
| 3. Upgrade Flows | 4 | ⬜ | ⬜ | ⬜ |
| 4. Edge Cases | 4 | ⬜ | ⬜ | ⬜ |
| **Total** | **17** | **0** | **0** | **0** |

---

## Notes

- **Fuzzy Location Threshold**: 150km (accounts for integer lat/lng in guest emails)
- **Fuzzy Time Threshold**: ±5 minutes
- **Email Masking Format**: `te****@gmail.com` (first 2 chars + `****`)

---

*Last Updated: 2026-02-01*
