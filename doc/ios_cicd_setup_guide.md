# iOS CI/CD Complete Setup Guide

A comprehensive step-by-step guide for setting up automated iOS app deployment to TestFlight using GitHub Actions and Fastlane.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Apple Developer Setup](#step-1-apple-developer-setup)
3. [GitHub Repository Setup](#step-2-github-repository-setup)
4. [Fastlane Configuration](#step-3-fastlane-configuration)
5. [Match Certificate Setup](#step-4-match-certificate-setup)
6. [GitHub Secrets](#step-5-github-secrets)
7. [Testing the Pipeline](#step-6-testing-the-pipeline)
8. [Daily Usage](#daily-usage)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

| Requirement | Details |
|-------------|---------|
| **Apple Developer Account** | $99/year - https://developer.apple.com |
| **GitHub Account** | Free - https://github.com |
| **macOS** | For local development and Xcode |
| **Xcode** | Latest version from App Store |
| **Homebrew** | Package manager - https://brew.sh |

---

## Step 1: Apple Developer Setup

### 1.1 Get Your Team ID

1. Go to: https://developer.apple.com/account
2. Sign in with your Apple ID
3. Click **Membership Details** in the sidebar
4. Note your **Team ID** (format: `XXXXXXXXXX`)

```
Example: GTP5DH5548
```

### 1.2 Register Your App ID (if not done)

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click **"+"** to register a new identifier
3. Select **App IDs** → Continue
4. Select **App** → Continue
5. Enter:
   - Description: `Destiny AI Astrology`
   - Bundle ID: `com.destinyai.astrology` (Explicit)
6. Enable capabilities you need (e.g., Push Notifications)
7. Click **Continue** → **Register**

### 1.3 Create App Store Connect API Key

> This key allows automated access to App Store Connect without password.

1. Go to: https://appstoreconnect.apple.com
2. Sign in → Click your name → **Users and Access**
3. Click **Integrations** tab → **App Store Connect API**
4. Stay on **Team Keys** tab
5. Click **"+"** or **"Generate API Key"**
6. Fill in:
   - **Name:** `GitHub Actions`
   - **Access:** `App Manager`
7. Click **Generate**
8. **⚠️ IMPORTANT:** Click **Download** to save the `.p8` file (you can only download it ONCE!)
9. Note down:
   - **Issuer ID** (shown at top of page): `c6f093d2-60b4-49ab-8b7c-786b41fcedcb`
   - **Key ID** (shown in table): `T4ZF792TPK`

### 1.4 Create App in App Store Connect (if not done)

1. Go to: https://appstoreconnect.apple.com/apps
2. Click **"+"** → **New App**
3. Fill in:
   - **Platforms:** iOS
   - **Name:** Destiny AI Astrology
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select your registered bundle ID
   - **SKU:** `destinyaiastrology`
4. Click **Create**

---

## Step 2: GitHub Repository Setup

### 2.1 App Repository Structure

Your app repository should have this structure:

```
ios_app/
├── .github/
│   └── workflows/
│       └── ios-deploy.yml       # CI/CD workflow
├── Config/
│   ├── Local.xcconfig           # Local development
│   ├── Test.xcconfig            # Test environment
│   └── Production.xcconfig      # Production environment
├── fastlane/
│   ├── Fastfile                 # Automation lanes
│   ├── Appfile                  # App configuration
│   └── Matchfile                # Code signing config
├── ios_app/
│   └── ... (your app code)
└── ios_app.xcodeproj
```

### 2.2 Create Branches

Set up the branch structure:

```bash
# Ensure you have main and test branches
git checkout main
git checkout -b test
git push origin test
```

| Branch | Purpose |
|--------|---------|
| `main` | Production builds → TestFlight (Prod API) |
| `test` | Test builds → TestFlight (Test API) |

### 2.3 Create Private Certificates Repository

> ⚠️ This repository stores encrypted signing certificates. **MUST BE PRIVATE!**

1. Go to: https://github.com/new
2. Fill in:
   - **Repository name:** `certificates`
   - **Description:** `iOS signing certificates (encrypted)`
   - **Visibility:** ⚠️ **PRIVATE** (very important!)
   - **Do NOT** add README, .gitignore, or license
3. Click **Create repository**

---

## Step 3: Fastlane Configuration

### 3.1 Install Fastlane

```bash
# Using Homebrew (recommended)
brew install fastlane

# Verify installation
fastlane --version
```

### 3.2 Create Fastfile

Create `ios_app/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  
  desc "Run unit tests"
  lane :test do
    run_tests(
      scheme: "ios_app",
      device: "iPhone 15 Pro",
      clean: true
    )
  end

  desc "Deploy TEST build to TestFlight"
  lane :beta_test do
    setup_ci if ENV['CI']
    
    match(type: "appstore", readonly: is_ci)
    
    increment_build_number(
      build_number: ENV['GITHUB_RUN_NUMBER'] || Time.now.to_i.to_s
    )
    
    build_app(
      scheme: "ios_app",
      configuration: "Test",
      export_method: "app-store"
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      changelog: "Test build - #{ENV['GITHUB_SHA'] || 'local'}"
    )
  end

  desc "Deploy PRODUCTION build to TestFlight"
  lane :beta_prod do
    setup_ci if ENV['CI']
    
    match(type: "appstore", readonly: is_ci)
    
    increment_build_number(
      build_number: ENV['GITHUB_RUN_NUMBER'] || Time.now.to_i.to_s
    )
    
    build_app(
      scheme: "ios_app",
      configuration: "Release",
      export_method: "app-store"
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      changelog: "Production build - #{ENV['GITHUB_SHA'] || 'local'}"
    )
  end

  def is_ci
    ENV['CI'] == 'true'
  end
end
```

### 3.3 Create Appfile

Create `ios_app/fastlane/Appfile`:

```ruby
# Your App's Bundle Identifier
app_identifier("com.destinyai.astrology")

# Your Apple Developer Account Email
apple_id("support@destinyaiastrology.com")

# Your Apple Developer Team ID
team_id("GTP5DH5548")

# App Store Connect Team ID (same as team_id for individuals)
itc_team_id("GTP5DH5548")
```

### 3.4 Create Matchfile

Create `ios_app/fastlane/Matchfile`:

```ruby
# Git repo containing certificates (PRIVATE!)
git_url("https://github.com/prabhupredictions/certificates.git")

# Storage mode
storage_mode("git")

# Type of signing
type("appstore")

# App identifier
app_identifier("com.destinyai.astrology")

# Your team ID
team_id("GTP5DH5548")

# Apple ID
username("support@destinyaiastrology.com")
```

---

## Step 4: Match Certificate Setup

### 4.1 Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Fill in:
   - **Note:** `Match Certificates`
   - **Expiration:** No expiration (or choose a long duration)
   - **Scopes:** Check `repo` (Full control of private repositories)
4. Click **Generate token**
5. **Copy the token immediately** (you can only see it once!)

```
Example: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 4.2 Create Base64 Authorization

Run this command (replace `YOUR_TOKEN` with your actual token):

```bash
echo -n "YOUR_GITHUB_USERNAME:YOUR_TOKEN" | base64
```

Example:
```bash
echo -n "yourusername:ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" | base64
# Output: eW91cnVzZXJuYW1lOmdocF94eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHg=
```

### 4.3 Create App Store Connect API Key JSON

Create a file `~/private_keys/api_key.json`:

```json
{
  "key_id": "T4ZF792TPK",
  "issuer_id": "c6f093d2-60b4-49ab-8b7c-786b41fcedcb",
  "key": "-----BEGIN PRIVATE KEY-----\nYOUR_KEY_CONTENT_HERE\n-----END PRIVATE KEY-----",
  "in_house": false
}
```

> Note: Copy the content of your .p8 file into the "key" field. Keep newlines as `\n`.

### 4.4 Generate Certificates with Match

Run this command (replace values as needed):

```bash
cd ios_app

# Set environment variables
export MATCH_PASSWORD='YourSecureMatchPassword'
export MATCH_GIT_BASIC_AUTHORIZATION='YOUR_BASE64_ENCODED_AUTH'

# Run match with API key
fastlane match appstore --api_key_path ~/private_keys/api_key.json
```

When prompted:
- **Keychain password:** Enter your Mac login password

This will:
1. Create distribution certificate on Apple Developer Portal
2. Create provisioning profile
3. Encrypt and push to your certificates repo
4. Install locally on your Mac

---

## Step 5: GitHub Secrets

### 5.1 Navigate to Repository Secrets

Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`

### 5.2 Add Required Secrets

Click **"New repository secret"** for each:

| Secret Name | Value | Where to Get It |
|-------------|-------|-----------------|
| `TEAM_ID` | `GTP5DH5548` | Apple Developer Portal → Membership |
| `APP_STORE_CONNECT_KEY_ID` | `T4ZF792TPK` | App Store Connect → Integrations |
| `APP_STORE_CONNECT_ISSUER_ID` | `c6f093d2-60b4-...` | App Store Connect → Integrations |
| `APP_STORE_CONNECT_KEY` | `-----BEGIN PRIVATE KEY-----...` | Contents of your .p8 file |
| `MATCH_PASSWORD` | `YourSecureMatchPassword` | Password you chose for Match encryption |
| `MATCH_GIT_URL` | `https://github.com/.../certificates.git` | Your certificates repo URL |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `cHJhYmh1cHJlZGlj...` | Base64 from Step 4.2 |

---

## Step 6: Testing the Pipeline

### 6.1 Trigger a Test Build

```bash
cd ios_app

# Switch to test branch
git checkout test

# Make a small change or empty commit
git commit --allow-empty -m "Test CI/CD pipeline"

# Push to trigger workflow
git push origin test
```

### 6.2 Monitor the Build

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`
2. Click on the latest workflow run
3. Watch the logs in real-time

### 6.3 Check TestFlight

1. Go to: https://appstoreconnect.apple.com
2. Click **My Apps** → Your App → **TestFlight**
3. Wait for build to appear (may take 5-10 minutes)

---

## Daily Usage

### Development Workflow

```bash
# Work on test branch
git checkout test
git pull origin test

# Make changes...
# Test locally...

# Push to deploy to TestFlight (test API)
git add .
git commit -m "Feature: Add new feature"
git push origin test
# → Automatically deploys to TestFlight with TEST API

# When ready for production
git checkout main
git merge test
git push origin main
# → Automatically deploys to TestFlight with PROD API
```

### Quick Reference

| Action | Command |
|--------|---------|
| Deploy to Test | `git push origin test` |
| Deploy to Prod | `git push origin main` |
| Run tests locally | `fastlane test` |
| Build locally | `fastlane beta_test` (or `beta_prod`) |

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Match authentication failed** | Check `MATCH_GIT_BASIC_AUTHORIZATION` is correct |
| **Certificate not found** | Run `fastlane match appstore` locally first |
| **App Store Connect API error** | Verify API key contents in `APP_STORE_CONNECT_KEY` secret |
| **Build failed - code signing** | Ensure certificates are generated with Match |
| **Provisioning profile expired** | Run `fastlane match appstore --force` to regenerate |

### Regenerate Certificates

If certificates expire or need replacement:

```bash
cd ios_app
export MATCH_PASSWORD='YourMatchPassword'
export MATCH_GIT_BASIC_AUTHORIZATION='YourBase64Auth'
fastlane match appstore --force --api_key_path ~/private_keys/api_key.json
```

### View Installed Certificates

```bash
# List certificates in keychain
security find-identity -v -p codesigning

# List provisioning profiles
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/
```

---

## Summary of Created Resources

| Resource | Location/Value |
|----------|----------------|
| **Team ID** | `GTP5DH5548` |
| **Bundle ID** | `com.destinyai.astrology` |
| **Apple ID** | `support@destinyaiastrology.com` |
| **App Repo** | `prabhupredictions/destinyios` |
| **Certificates Repo** | `prabhupredictions/certificates` |
| **Certificate ID** | `28LX5A99UR` |
| **Profile Name** | `match AppStore com.destinyai.astrology` |

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-06 | 1.0 | Initial setup complete |

---

**Author:** CI/CD Setup Guide
**Last Updated:** 2026-01-06
