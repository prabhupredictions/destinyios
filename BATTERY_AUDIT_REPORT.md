# iOS App Battery Audit Report

**Date:** March 15, 2026  
**App:** Destiny AI Astrology (ios_app)  
**Reported Issue:** ~30% battery drain in 1 hour  
**Auditor:** Cascade AI  

---

## Executive Summary

The app has **37 continuous `repeatForever` animations across 23 files**, **4 active repeating Timers**, **41 instantiations of CosmicBackgroundView** (each with 2 continuous animations), **115 shadow modifiers**, **24 blur modifiers**, and **multiple MotionManager instances** that each allocate a CMMotionManager. These compound to keep the GPU and CPU perpetually active, preventing the device from entering low-power idle states — the primary cause of the 30%/hour battery drain.

---

## CATEGORY 1: CRITICAL — Continuous Animations (repeatForever)

### Finding 1.1 — CosmicBackgroundView: 41 instantiations, each with 2 animations
- **File:** `Views/Components/CosmicBackgroundView.swift`
- **Issue:** Instantiated **41 times** across 35 different files. Each instance runs:
  - Nebula rotation: `.linear(duration: N).repeatForever` 
  - Star brightness breathing: `.easeInOut(duration: 3).repeatForever`
- **Also:** Each instance has 3 `motionParallax` modifiers, 4 `.blur()` calls, and renders ~N star circles
- **Impact:** **~82 concurrent GPU animations** + blur compositing on every visible screen
- **Severity:** 🔴 CRITICAL

> **Proposal:** Replace `CosmicBackgroundView` with a **single static pre-rendered image** (`Image("cosmic_bg")`). Export the current cosmic look as a dark PNG asset. This eliminates 82+ animations, 120+ blur passes, and 120+ motionParallax modifier instances in one change. For screens that need visual differentiation, use 2-3 static variant images. **Estimated battery saving: 40-50% of current drain.**

### Finding 1.2 — TransitInfluenceCard: 3 animations per card × N cards
- **File:** `Views/Home/Components/TransitInfluenceCard.swift`
- **Affected views:** `TransitInfluenceCard` (shimmer border) + `TransitOrbView` (floating + shimmer border)
- **Issue:** Each `TransitOrbView` runs:
  1. Floating hover: `.easeInOut(duration: 2.5).repeatForever` with random delay
  2. Shimmer border rotation: `.linear(duration: 10).repeatForever`
  3. Dynamic shadow opacity tied to hover state
- With 9 planets visible, that's **~27 concurrent animations** in the transit section alone
- **Severity:** 🔴 CRITICAL

> **Proposal:** Remove all 3 animations. Use static gold border (matching comparison card style already applied to other cards). Remove floating hover effect — planets should be stationary. Remove `AngularGradient` shimmer. **Estimated saving: 10-15% of drain.**

### Finding 1.3 — CosmicStatusStrip: Infinite marquee scroll
- **File:** `Design/Components/Transits/CosmicStatusStrip.swift`
- **Issue:** Uses `.linear(duration: N).repeatForever` to infinitely scroll content. Content is **triplicated** for seamless loop. Each transit pair has `RadialGradient` + `Path` + double `shadow`.
- **Severity:** 🟡 MEDIUM (single animation, but always visible on Home)

> **Proposal:** Replace infinite marquee with a **static horizontal ScrollView** that users can manually swipe. This is more accessible and eliminates the perpetual animation. Alternatively, use `TimelineView(.animation(paused: scenePhase != .active))` to pause when backgrounded (currently missing).

### Finding 1.4 — GlowingOrbView: Pulse animation
- **File:** `Design/Components/Transits/GlowingOrbView.swift`
- **Issue:** Continuous pulse scale + shadow animation: `.easeInOut(duration: 3).repeatForever`
- **Severity:** 🟡 MEDIUM

> **Proposal:** Make static. Remove `isPulsing` state and animation. Use fixed shadow and scale.

### Finding 1.5 — KalsarpaDoshaSheet: 2 continuous animations
- **File:** `Views/Compatibility/Sheets/KalsarpaDoshaSheet.swift`
- **Issue:** Snake animation + orbit rotation both `repeatForever`, active whenever sheet is open
- **Severity:** 🟢 LOW (only visible when sheet is open)

> **Proposal:** Remove `repeatForever`. Use a single entrance animation that settles to static state.

### Finding 1.6 — OrbitAshtakootView: Pulse animation
- **File:** `Views/Compatibility/Components/OrbitAshtakootView.swift`
- **Issue:** Pulse scale animation on selected orb: `.easeInOut(duration: 1.5).repeatForever`
- **Severity:** 🟢 LOW (only on compatibility result screen)

> **Proposal:** Remove pulse. Use static highlighted state for selected orb.

### Finding 1.7 — FloatingContextButton: Ring pulse
- **File:** `Views/Compatibility/Components/FloatingContextButton.swift`
- **Issue:** Ring scale/opacity animation: `.easeInOut(duration: 1.5).repeatForever`
- **Severity:** 🟢 LOW

> **Proposal:** Remove animation. Use static ring indicator.

### Finding 1.8 — Auth/Splash/Onboarding animations
- **Files:** `AuthView.swift`, `GuestSignInPromptView.swift`, `SplashView.swift`, `LanguageSelectionView.swift`
- **Issue:** Orbit rotations (`.linear(duration: 30).repeatForever`), floating icons, sparkle animations
- **Severity:** 🟢 LOW (transient screens, user passes through quickly)

> **Proposal:** Acceptable on transient screens. No change needed unless user stays on auth screen.

### Finding 1.9 — MultiPartnerStreamingView: Pulse during streaming
- **File:** `Views/Compatibility/MultiPartnerStreamingView.swift`
- **Issue:** `.easeInOut(duration: 1.0).repeatForever` during active streaming
- **Severity:** 🟢 LOW (only during active streaming)

> **Proposal:** Acceptable — only runs during active operation.

---

## CATEGORY 2: HIGH — Active Timers

### Finding 2.1 — TypewriterText cursor blink (NEVER INVALIDATED)
- **File:** `Views/Components/PremiumComponents.swift:177`
- **Issue:** `Timer.scheduledTimer(withTimeInterval: N, repeats: true)` for cursor blink — **never invalidated**. Once this view appears, the timer runs forever until app termination.
- **Severity:** 🔴 CRITICAL (memory leak + perpetual CPU wake)

> **Proposal:** Replace with SwiftUI `.onAppear`/`.onDisappear` pattern using `@State` + `withAnimation(.easeInOut.repeatForever)`. Or invalidate timer in `onDisappear`.

### Finding 2.2 — BioRhythmModifier heartbeat timer
- **File:** `Views/Components/PremiumComponents.swift:391`
- **Issue:** `Timer.scheduledTimer` at 60 BPM = fires every 1 second. Triggers haptic + visual animation each pulse. Used on `AuthView`, `GuestSignInPromptView`, `SplashView`.
- **Severity:** 🟡 MEDIUM (transient screens, but haptic engine is battery-heavy)

> **Proposal:** Remove `bioRhythm` modifier entirely. A single entrance haptic is sufficient. Continuous haptics drain battery significantly.

### Finding 2.3 — MarkdownTextView bouncing animation timer
- **File:** `Components/Chat/MarkdownTextView.swift:697`
- **Issue:** `Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true)` — fires 3.3 times/second for a bouncing dot animation. **Never invalidated.**
- **Severity:** 🟡 MEDIUM (only during active chat, but timer leak)

> **Proposal:** Replace with `withAnimation(.repeatForever)` SwiftUI pattern, or ensure timer is invalidated on view disappear.

### Finding 2.4 — MessageBubble elapsed time timer
- **File:** `Components/Chat/MessageBubble.swift:459`
- **Issue:** `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)` for showing elapsed seconds during AI thinking. Properly invalidated when done.
- **Severity:** 🟢 LOW (short-lived, properly managed)

> **Proposal:** No change needed.

---

## CATEGORY 3: HIGH — MotionManager Overhead

### Finding 3.1 — MotionManager instantiated but disabled
- **File:** `Services/MotionManager.swift`
- **Issue:** `start()` has an early `return` (disabled), but `MotionManager` is still **allocated as `@StateObject`** in 3 separate modifiers:
  - `MotionParallaxModifier` (used via `.motionParallax()`)
  - `Tilt3DModifier` (used via `.tilt3D()`)
  - `InertiaModifier` (used via `.premiumInertia()`)
- Each allocates a `CMMotionManager` + `OperationQueue` even though motion is disabled
- **Usage count:** ~17 call sites = 17 unnecessary `CMMotionManager` allocations

- **Severity:** 🟡 MEDIUM (wasted memory, no CPU drain since disabled)

> **Proposal:** Make the modifiers **no-op pass-throughs** when motion is disabled. Check a static flag and return `content` unchanged:
> ```swift
> func body(content: Content) -> some View {
>     content // No-op: motion disabled
> }
> ```
> This eliminates 17 unnecessary `@StateObject` allocations.

---

## CATEGORY 4: MEDIUM — GPU-Heavy View Composition

### Finding 4.1 — DivineGlassCard: 7 layers per card
- **File:** `Views/Components/DivineGlassCard.swift`
- **Issue:** Each card renders 7 overlapping layers:
  1. Crystal base (LinearGradient)
  2. `.ultraThinMaterial` overlay
  3. Inner depth stroke + `.blur(radius: 6)`
  4. Surface gloss (LinearGradient + `.blendMode(.overlay)`)
  5. Rim light bevel (LinearGradient stroke)
  6. Ambient glow stroke + `.blur(radius: 10)`
  7. Content
  - Plus: `.tilt3D()` + `.premiumInertia()` + `.shadow(radius: 15)`
- **Used in:** `PremiumTabBar` (each tab pill is a DivineGlassCard), `ComparisonOverviewView`, `HomeView`
- **Severity:** 🟡 MEDIUM (GPU compositing cost, especially in lists)

> **Proposal:** Simplify to 3 layers max: solid background fill + border stroke + content. Remove `.ultraThinMaterial` (expensive real-time blur), remove inner depth blur, remove ambient glow blur. Remove `.tilt3D()` and `.premiumInertia()` modifiers. This matches the clean card style already being adopted.

### Finding 4.2 — 115 shadow modifiers across 62 files
- **Issue:** Each `.shadow()` requires an offscreen render pass. Multiple shadows on nested views compound.
- **Severity:** 🟡 MEDIUM (individually cheap, collectively significant in ScrollViews)

> **Proposal:** Audit and remove redundant/invisible shadows (e.g., shadows on elements inside cards that already have a card-level shadow). Limit to 1 shadow per card container.

### Finding 4.3 — 24 blur modifiers across 18 files
- **Issue:** `.blur()` is one of the most expensive modifiers — requires full offscreen render + Gaussian convolution. `CosmicBackgroundView` alone has 4 blurs per instance × 41 instances.
- **Severity:** 🟡 MEDIUM (eliminated if Finding 1.1 is addressed)

> **Proposal:** Most blurs are in `CosmicBackgroundView` — solved by Finding 1.1 proposal. For remaining: replace `.blur()` with pre-blurred image assets where possible.

### Finding 4.4 — StoryOrbView: Heavy per-orb composition
- **File:** `Views/Home/Components/StoryOrbView.swift`
- **Issue:** Each orb has: outer ring, radial gradient glow, blur, CosmicBackgroundView background, AngularGradient border, plus icon + text layers. 8 orbs on Home screen.
- **Severity:** 🟡 MEDIUM

> **Proposal:** Remove `CosmicBackgroundView()` from inside StoryOrbView (it's a background for a tiny 72px orb — overkill). Use a simple solid/gradient fill instead. Remove AngularGradient border — use plain circle stroke.

---

## CATEGORY 5: LOW — Miscellaneous

### Finding 5.1 — No scenePhase awareness on animations
- **Issue:** Only `LiquidGoldBackground` pauses when app is backgrounded. All other 37 `repeatForever` animations continue running in background, wasting GPU cycles.
- **Severity:** 🟡 MEDIUM

> **Proposal:** For any animation that remains after optimization, add `scenePhase` awareness to pause when `.background` or `.inactive`.

### Finding 5.2 — Chat animations (typing indicator, cursor blink)
- **Files:** `TypingIndicator.swift`, `MessageBubble.swift`, `ThinkingProgressView.swift`
- **Issue:** Typing dots, cursor blink, thinking dots — all `repeatForever`
- **Severity:** 🟢 LOW (only during active chat interaction, short-lived)

> **Proposal:** Acceptable — these are standard UX patterns and only active during user interaction.

### Finding 5.3 — FluidBackground (LiquidGoldBackground) uses TimelineView
- **File:** `Design/FluidBackground.swift`
- **Issue:** `TimelineView(.animation)` redraws every frame with Canvas API. Used in `BirthDataView` and `CompatibilityView`.
- **Severity:** 🟡 MEDIUM (60fps Canvas redraw)

> **Proposal:** Already has `scenePhase` pause — good. Consider replacing with static gradient background on those screens, or reducing to `.animation(minimumInterval: 1/15)` for 15fps instead of 60fps.

---

## Priority Implementation Plan

| Priority | Finding | Est. Battery Saving | Effort |
|----------|---------|-------------------|--------|
| **P0** | 1.1 — Replace CosmicBackgroundView with static image | **40-50%** | Medium |
| **P0** | 1.2 — Remove TransitInfluenceCard/TransitOrbView animations | **10-15%** | Small |
| **P1** | 2.1 — Fix TypewriterText timer leak | **2-3%** | Small |
| **P1** | 2.3 — Fix MarkdownTextView timer leak | **1-2%** | Small |
| **P1** | 4.1 — Simplify DivineGlassCard (remove blurs/materials) | **5-8%** | Medium |
| **P1** | 3.1 — Make motion modifiers no-op | **1-2%** | Small |
| **P2** | 1.3 — Replace marquee with static ScrollView | **2-3%** | Small |
| **P2** | 2.2 — Remove BioRhythm haptic timer | **2-3%** | Small |
| **P2** | 4.4 — Simplify StoryOrbView | **3-5%** | Small |
| **P2** | 5.1 — Add scenePhase to remaining animations | **2-3%** | Small |
| **P3** | 4.2 — Reduce redundant shadows | **1-2%** | Medium |
| **P3** | 1.4-1.8 — Remove misc sheet animations | **1-2%** | Small |
| **P3** | 5.3 — Reduce FluidBackground frame rate | **1-2%** | Small |

**Total estimated improvement:** P0 alone should reduce battery drain from ~30%/hour to ~12-15%/hour. P0+P1 should bring it to ~8-10%/hour (normal for a content app).

---

## Key Principle

> **The #1 battery optimization in iOS is: stop doing work when the user can't see it.**  
> Every `repeatForever` animation, every running Timer, and every blur/shadow compositing pass keeps the GPU/CPU awake. The app currently never stops working — even static screens have 10+ concurrent animations running. The fix is straightforward: make things static by default, animate only on user interaction, and pause everything when backgrounded.

---

*End of audit report.*
