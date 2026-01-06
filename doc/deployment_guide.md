# iOS App - Deployment & CI/CD Guide

## Overview

This guide covers the automated CI/CD pipeline for the Destiny AI Astrology iOS app.

---

## Architecture

```
git push test   → Build + Deploy to TestFlight (Test API)
git push main   → Build + Deploy to TestFlight (Prod API)
```

---

## Environments

| Environment | Branch | API URL | API Key |
|-------------|--------|---------|---------|
| **Local** | - | `http://127.0.0.1:8000` | Dev key |
| **Test** | `test` | `https://astroapi-test-dsqvza5jza-el.a.run.app` | Prod key |
| **Production** | `main` | `https://astroapi-prod-dsqvza5jza-el.a.run.app` | Prod key |

---

## Project Details

| Property | Value |
|----------|-------|
| **Bundle ID** | `com.destinyai.astrology` |
| **Apple ID** | `support@destinyaiastrology.com` |
| **Team** | Ganga Jamuna Penchala |
| **GitHub Repo** | `prabhupredictions/destinyios` |

---

## Files Created

| File | Purpose |
|------|---------|
| `Config/Local.xcconfig` | Local development configuration |
| `Config/Test.xcconfig` | Test environment configuration |
| `Config/Production.xcconfig` | Production configuration |
| `fastlane/Fastfile` | Automation lanes |
| `fastlane/Appfile` | App configuration |
| `fastlane/Matchfile` | Code signing configuration |
| `.github/workflows/ios-deploy.yml` | GitHub Actions workflow |

---

## Setup Required (One Time)

### Step 1: Get Your Team ID

1. Go to: https://developer.apple.com/account
2. Click **Membership Details**
3. Note your **Team ID**

### Step 2: Create App Store Connect API Key

1. Go to: https://appstoreconnect.apple.com/access/api
2. Click **"+"** to create a new key
3. Name: `GitHub Actions`
4. Access: `App Manager`
5. **Download the .p8 file** (only downloadable once!)
6. Note: **Issuer ID** and **Key ID**

### Step 3: Create Private Certificates Repository

1. Create private GitHub repo: `prabhupredictions/certificates`
2. This stores encrypted signing certificates

### Step 4: Setup Match (Code Signing)

```bash
cd ios_app
fastlane match init
# Enter your certificates repo URL

# Generate App Store certificates
fastlane match appstore
```

### Step 5: Add GitHub Secrets

Go to: `https://github.com/prabhupredictions/destinyios/settings/secrets/actions`

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `TEAM_ID` | Your Apple Team ID |
| `APP_STORE_CONNECT_KEY_ID` | API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_KEY` | Contents of .p8 file |
| `MATCH_PASSWORD` | Password for certificate encryption |
| `MATCH_GIT_URL` | `https://github.com/prabhupredictions/certificates.git` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 of `username:token` |

---

## Development Workflow

### Daily Development

```bash
# 1. Work on test branch
git checkout test
git pull origin test

# 2. Make changes
# ... code ...

# 3. Test locally
# Run on Simulator (uses localhost API)

# 4. Push to trigger TestFlight build
git add . && git commit -m "Feature: XYZ"
git push origin test
# → Deploys to TestFlight with TEST API
```

### Production Release

```bash
# When test is verified
git checkout main
git merge test
git push origin main
# → Deploys to TestFlight with PROD API
```

### App Store Submission

```bash
# After TestFlight testing is complete
fastlane release
```

---

## Configuration Files

### APIConfig.swift

Automatically selects the correct API based on environment:

```swift
struct APIConfig {
    static var baseURL: String {
        // Reads from Info.plist (set by xcconfig)
        // Falls back based on build configuration
    }
}
```

### Xcode Schemes

Create 3 schemes for different environments:
- `ios_app` (Debug) → Local API
- `ios_app` (Test) → Test Cloud API
- `ios_app` (Release) → Production Cloud API

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Match authentication failed | Check `MATCH_GIT_BASIC_AUTHORIZATION` secret |
| Code signing error | Run `fastlane match appstore` locally first |
| API Key invalid | Verify .p8 file contents in secret |
| Build failed | Check Xcode version compatibility |

---

## Quick Reference

### Git Commands

```bash
git checkout test          # Development
git push origin test       # Deploy to TestFlight (test)

git checkout main
git merge test
git push origin main       # Deploy to TestFlight (prod)
```

### Fastlane Commands

```bash
fastlane test              # Run tests locally
fastlane beta_test         # Build and deploy test version
fastlane beta_prod         # Build and deploy prod version
fastlane release           # Submit to App Store
```

---

## Created

- **Date**: 2026-01-05
- **Author**: Automated CI/CD Setup
- **Version**: 1.0
