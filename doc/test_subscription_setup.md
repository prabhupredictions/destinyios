# 🍎 iOS Test Subscription Setup Guide

Now that the code is updated (`SubscriptionManager.swift` now supports the `Plus` plan), follow these steps to configure App Store Connect for testing.

## 1. Prerequisites
- [x] **Agreements**: "Paid Apps" agreement must be active in *App Store Connect > Agreements, Tax, and Banking*.
- [x] **Backend**: Plans are seeded (Core/Plus).
- [x] **App Code**: Updated to support `com.daa.core.*` and `com.daa.plus.*`.

## 2. Create Subscriptions in App Store Connect

1.  Go to **[App Store Connect](https://appstoreconnect.apple.com) > My Apps > Destiny AI**.
2.  In the sidebar, scroll down to **Subscriptions**.
3.  Click **(+)** next to "Subscription Groups" and create a group named **"Destiny Plans"**.

### Create "Core" Plan Products
Inside "Destiny Plans", click **(+) Create Subscription**:
*   **Reference Name**: `Core Monthly`
*   **Product ID**: `com.daa.core.monthly`
*   **Family Sharing**: On
*   **Price**: $4.99 (Tier 5)
*   **Duration**: 1 Month

Repeat for Yearly:
*   **Reference Name**: `Core Yearly`
*   **Product ID**: `com.daa.core.yearly`
*   **Price**: $49.99 (Tier 40)
*   **Duration**: 1 Year

### Create "Plus" Plan Products
Inside "Destiny Plans", click **(+) Create Subscription**:
*   **Reference Name**: `Plus Monthly`
*   **Product ID**: `com.daa.plus.monthly`
*   **Price**: $7.99 (Tier 8)
*   **Duration**: 1 Month

Repeat for Yearly:
*   **Reference Name**: `Plus Yearly`
*   **Product ID**: `com.daa.plus.yearly`
*   **Price**: $79.99 (Tier 70)
*   **Duration**: 1 Year

> **Important**: Ensure specific Product IDs match exactly. The app code expects these exact strings.

## 3. Configure Localization (Optional for Test, Required for submission)
For each product, add "Localization":
*   **Display Name**: `Core Plan` or `Plus Plan`
*   **Description**: `Unlock daily insights` (or similar)

## 4. Create a Sandbox Tester
To test purchases without real money:
1.  Go to **App Store Connect > Users and Access > Sandbox Testers**.
2.  Click **(+)**.
3.  Enter a **NEW** email address (cannot be an existing Apple ID).
    *   *Tip: use `you+sandbox1@example.com`.*
4.  Set a password (e.g., `Test1234!`).
5.  Region: United States.

## 5. Testing on Device (TestFlight)
1.  Install the app via TestFlight (wait for the Build `98b67f7` or later).
2.  Open **Settings > App Store > Sandbox Account** (bottom).
3.  Sign in with your **Sandbox Tester** credentials.
4.  Open the App.
5.  Go to Subscription screen.
6.  Tap a plan. You should see the system popup `[Environment: Sandbox]`.
7.  Verify purchase works and unlocks features.

## 6. Troubleshooting
*   **"Product not found"**: Ensure Product IDs match exactly and status is "Ready to Submit" (yellow dot is fine for sandbox).
*   **"Purchase Failed"**: Check if your Agreements are active.
