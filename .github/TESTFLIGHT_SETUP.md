# TestFlight Deployment Setup Guide

## Manual TestFlight Deployment (First Time)

### Prerequisites Checklist

- [ ] Apple Developer Program membership ($99/year)
- [ ] App created in App Store Connect
- [ ] Bundle ID registered: `Me.CrookedSentry`
- [ ] Development/Distribution certificates created
- [ ] Provisioning profiles created

### Step-by-Step Manual Upload

#### 1. Configure Xcode Project

**Signing & Capabilities:**
```
1. Open CrookedSentry.xcodeproj in Xcode
2. Select CrookedSentry target
3. Go to "Signing & Capabilities" tab
4. ✓ Automatically manage signing
5. Select your Team from dropdown
6. Verify Bundle Identifier: Me.CrookedSentry
```

**Build Settings:**
```
1. Select "Any iOS Device" from device menu
2. Verify version numbers:
   - Marketing Version: 1.0
   - Current Project Version: 1 (increment for each build)
```

#### 2. Create Archive

```
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Archive (⌘B might show errors; archive must use real device)
3. Wait for archive to complete (~5-10 minutes)
4. Organizer window opens automatically
```

#### 3. Validate Archive

```
1. Click "Validate App" button
2. Distribution method: App Store Connect
3. App Store Connect distribution options:
   ✓ Upload your app's symbols
   ✓ Manage Version and Build Number (Xcode will increment)
4. Select signing: Automatically manage signing
5. Click "Validate"
6. Wait for validation (~2-5 minutes)
7. Fix any errors that appear
```

#### 4. Upload to App Store Connect

```
1. Click "Distribute App" button
2. Distribution method: App Store Connect
3. Destination: Upload
4. Same options as validation
5. Click "Upload"
6. Wait for upload to complete (~10-30 minutes)
7. You'll receive email when processing completes
```

#### 5. Configure in App Store Connect

**Go to: https://appstoreconnect.apple.com**

```
1. My Apps → CrookedSentry → TestFlight tab
2. iOS Builds section: Your build will appear (may take 10-60 min)
3. Click on build number
4. Add "What to Test" notes for testers
5. Export Compliance: 
   - If no encryption: Select "No" 
   - If using VPN: Select "Yes" → follow prompts
```

#### 6. Add Testers

**Internal Testing (Instant, no review):**
```
1. TestFlight → Internal Testing
2. Click "+" to add group
3. Add tester emails (must have Apple IDs)
4. Save → Testers get email immediately
```

**External Testing (Requires Apple review ~24-48 hours):**
```
1. TestFlight → External Testing
2. Click "+" to add group
3. Name group (e.g., "Beta Testers")
4. Add tester emails
5. Submit for Review
6. Wait for approval
7. Testers get email when approved
```

### Common Issues & Solutions

**Issue: "No signing certificate found"**
```
Solution:
1. Xcode → Settings → Accounts
2. Select your Apple ID
3. Download Manual Profiles
4. Or: Enable "Automatically manage signing"
```

**Issue: "Bundle identifier cannot be used"**
```
Solution:
1. Go to developer.apple.com → Certificates, IDs & Profiles
2. Register new Bundle ID: Me.CrookedSentry
3. Or change in Xcode to unique identifier
```

**Issue: "Archive failed - No such module"**
```
Solution:
1. Product → Clean Build Folder
2. Delete DerivedData: ~/Library/Developer/Xcode/DerivedData
3. Restart Xcode
4. Try archive again
```

**Issue: "Upload failed - Invalid provisioning profile"**
```
Solution:
1. Delete old profiles: ~/Library/MobileDevice/Provisioning Profiles
2. Xcode → Settings → Accounts → Download Manual Profiles
3. Try upload again
```

**Issue: "Missing privacy usage descriptions"**
```
Solution: Add to Info.plist:
- NSCameraUsageDescription
- NSLocalNetworkUsageDescription
- NSPhotoLibraryUsageDescription (if saving images)
```

---

## Automated TestFlight Deployment (GitHub Actions)

### Required Secrets Setup

Add these to GitHub Settings → Secrets and variables → Actions:

#### 1. Apple Developer Credentials

**TEAM_ID:**
```bash
# Find your Team ID
1. Go to: https://developer.apple.com/account
2. Membership section → Team ID
3. Copy 10-character ID (e.g., "AB12CD34EF")
```

**APP_STORE_CONNECT_API_KEY_ID:**
**APP_STORE_CONNECT_API_KEY_ISSUER_ID:**
**APP_STORE_CONNECT_API_KEY_CONTENT:**
```bash
# Create App Store Connect API Key
1. Go to: https://appstoreconnect.apple.com/access/api
2. Keys tab → "+" to create key
3. Name: "GitHub Actions CI"
4. Access: Admin or App Manager
5. Download .p8 file (one-time only!)
6. Note Key ID (10 characters)
7. Note Issuer ID (36-character UUID)
8. Store .p8 file contents in APP_STORE_CONNECT_API_KEY_CONTENT secret
```

#### 2. Certificates & Profiles

**BUILD_CERTIFICATE_BASE64:**
**P12_PASSWORD:**
```bash
# Export Distribution Certificate
1. Open Keychain Access
2. Find "Apple Distribution: Your Name (TEAM_ID)"
3. Right-click → Export → Save as .p12
4. Set password (save for P12_PASSWORD secret)
5. Convert to base64:
   base64 -i Certificates.p12 | pbcopy
6. Paste into BUILD_CERTIFICATE_BASE64 secret
```

**PROVISIONING_PROFILE_BASE64:**
**PROVISIONING_PROFILE_NAME:**
```bash
# Download Provisioning Profile
1. Go to: https://developer.apple.com/account/resources/profiles
2. Find/Create "App Store" profile for CrookedSentry
3. Download .mobileprovision file
4. Convert to base64:
   base64 -i CrookedSentry_AppStore.mobileprovision | pbcopy
5. Paste into PROVISIONING_PROFILE_BASE64 secret
6. Profile name (without .mobileprovision) → PROVISIONING_PROFILE_NAME secret
```

**KEYCHAIN_PASSWORD:**
```bash
# Generate secure random password
openssl rand -base64 32

# Save to KEYCHAIN_PASSWORD secret (used temporarily during CI)
```

### Usage

**Trigger Automated Upload:**
```bash
# Create beta tag
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1

# Or manually trigger from GitHub Actions tab
```

**Process:**
```
1. GitHub Actions builds archive
2. Signs with your certificates
3. Uploads to App Store Connect
4. Creates GitHub release
5. Email notification when ready
```

### Incrementing Versions

**Marketing Version (displayed to users):**
```
# Update in Xcode or directly in project.pbxproj
MARKETING_VERSION = 1.0  → 1.1  → 2.0
```

**Build Number (internal tracking):**
```
# Auto-incremented by CI workflow
# Or manually in Xcode: Target → General → Build
1 → 2 → 3 → 4...
```

**Tag Format:**
```
v1.0.0-beta.1  # First beta of v1.0.0
v1.0.0-beta.2  # Second beta
v1.0.0         # Final release (use release.yml workflow)
```

---

## Privacy Policy Template

TestFlight requires a privacy policy URL. Here's a simple one:

```markdown
# CrookedSentry Privacy Policy

Last updated: November 6, 2025

## Data Collection

CrookedSentry does not collect, store, or transmit any personal data to third parties.

## Local Network Access

The app connects to your local Frigate server on your home network. All communication stays within your local network.

## Camera Access

The app displays camera feeds from your self-hosted Frigate server. No video or images are stored or transmitted outside your local network.

## VPN Usage

Optional VPN features allow secure remote access to your home network. VPN credentials are stored securely in iOS Keychain.

## Third-Party Services

CrookedSentry does not use any third-party analytics, advertising, or tracking services.

## Changes

Any changes to this policy will be posted in the app and on GitHub.

## Contact

For questions: [Your Email] or https://github.com/josephmienko/CrookedSentry-HomeAutomation
```

**Host Options:**
- GitHub Pages: Create `docs/privacy.md` → Enable in repo settings
- GitHub README: Link to `PRIVACY.md` in repo
- Personal website

---

## Useful Commands

**Check current version:**
```bash
xcodebuild -showBuildSettings -project CrookedSentry.xcodeproj -scheme CrookedSentry | grep -E "(MARKETING_VERSION|CURRENT_PROJECT_VERSION)"
```

**Validate archive from command line:**
```bash
xcrun altool --validate-app -f CrookedSentry.ipa -t ios --apiKey YOUR_KEY_ID --apiIssuer YOUR_ISSUER_ID
```

**Upload from command line:**
```bash
xcrun altool --upload-app -f CrookedSentry.ipa -t ios --apiKey YOUR_KEY_ID --apiIssuer YOUR_ISSUER_ID
```

**List all archives:**
```bash
ls ~/Library/Developer/Xcode/Archives
```

---

## TestFlight Tester Links

**Share with testers:**
```
Internal: Invite by email only
External: Public link or email invites

Public Link Format:
https://testflight.apple.com/join/XXXXXXXX
```

**TestFlight App:**
- Testers install TestFlight app from App Store
- Accept invitation email/link
- Install beta build
- Provide feedback via screenshot shake gesture

---

## Recommended Testing Flow

1. **Internal Alpha** (Week 1):
   - You + close friends/family
   - 5-10 testers
   - Test core functionality

2. **External Beta** (Week 2-4):
   - Broader audience
   - 50-100 testers
   - Test edge cases, devices

3. **Pre-Production** (Week 5+):
   - Final round
   - Fix critical bugs
   - Polish UI/UX

4. **Production Release**:
   - Remove beta features
   - Final testing
   - Submit for App Store review

---

## Resources

- **App Store Connect:** https://appstoreconnect.apple.com
- **Developer Portal:** https://developer.apple.com/account
- **TestFlight Docs:** https://developer.apple.com/testflight/
- **Human Interface Guidelines:** https://developer.apple.com/design/human-interface-guidelines/
- **App Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/

---

## Questions?

Feel free to reach out or open an issue on GitHub!
