# Design Consistency Audit: Existing Screens vs. Proposed Home

## Executive Summary
**Verdict:** ✅ **Aligned in Soul, Needs Upgrade in Physics.**
The proposed "Sensory Home" mockup shares the same DNA (Navy/Gold, Cosmic) as your existing screens (`Splash`, `Auth`, `Language`), but it introduces a higher tier of **"Material Reality"**.

The current screens use **Flat Glassmorphism** (2D transparency).
The proposed Home uses **Physical Glass** (3D depth, chamfered edges, lighting).

To make the app feel like one cohesive universe, we must upgrade the existing screens to match the Home View's "Physicality".

---

## Detailed Component Comparison

| Scope | Current Implementation | Proposed Home Standard | Action Required |
| :--- | :--- | :--- | :--- |
| **Material** | `UltraThinMaterial` (Flat) | **"Divine Glass"** (Thick, Gold Rim, Shadow) | Apply `.divineGlass()` modifier to Auth & Language cards. |
| **Motion** | Static or simple linear rotation | **3D Parallax & Inertia** | Apply `.tilt3D()` and `.premiumInertia()` to Logo & Cards. |
| **Typography** | Standard System Fonts | **"Soul" Typography** (Playfair Display) | Update Headers in `AuthView` & `LanguageView`. |
| **Haptics** | Standard `.selection` feedback | **"Bio-Sync" Heartbeat** | Inject `HapticManager.playHeartbeat()` into loading states. |

---

## Screen-by-Screen Upgrade Plan

### 1. Splash Screen (`SplashView.swift`)
*   **Status:** Good base, needs depth.
*   **Gap:** Stars and Rings are 2D.
*   **Fix:** Added `.premiumInertia()` to stars and `.tilt3D()` to rings (Done in previous step).

### 2. Language Selection (`LanguageSelectionView.swift`)
*   **Status:** Flat Cards.
*   **Gap:** Cards look like UI elements, not physical tiles.
*   **Fix:**
    *   Replace `RoundedRectangle` stroke with **Gradient Gold Borders**.
    *   Add `Tilt3DModifier` to the *selected* card so it "pops" out.

### 3. Auth Screen (`AuthView.swift`)
*   **Status:** Good "Gold Slab" button.
*   **Gap:** The Logo is flat.
*   **Fix:** Apply `.tilt3D(intensity: 15)` to the Logo container so it glimmers when the phone moves.

### 4. Birth Data Screen (`BirthDataView.swift`)
*   **Status:** Standard Form.
*   **Gap:** Input fields feel "digital".
*   **Fix:** Add "Weight" to the scroll view using `.premiumInertia()`.

## Conclusion
The Home Mockup is the **North Star**. It represents the "Version 2.0" aesthetic. The existing screens are valid "Version 1.5". We should accept the Home Mockup and perform the **Sensory Upgrades** defined above to bring the rest of the app to that level.
