# App Store Submission Checklist

**Target:** CrookedSentry v1.0 on App Store  
**Status:** Pre-Submission Phase  
**Last Updated:** November 6, 2025

---

## Phase 1: Prerequisites ⏳ (Week 1)

### Apple Developer Account
- [ ] **Enroll in Apple Developer Program** ($99/year)
  - Visit: https://developer.apple.com/programs/enroll/
  - Approval time: 24-48 hours
  - Status: ⏳ PENDING

### Privacy & Legal
- [x] **Privacy Policy Created** ✅
  - Location: `/PRIVACY_POLICY.md`
  - [ ] **Action Required:** Update email address (line 216)
  - [ ] **Action Required:** Host on GitHub Pages or website
  - [ ] **Get URL for App Store Connect**

- [ ] **Support URL** (Required for App Store)
  - Options:
    - GitHub repo: https://github.com/josephmienko/CrookedSentry-HomeAutomation
    - Create support page with FAQ
    - Personal website with contact form
  - [ ] **Decision:** Choose URL format
  - [ ] **Action:** Test URL is publicly accessible

---

## Phase 2: Xcode Project Configuration 🛠️ (Week 1)

### Open Xcode & Configure

```bash
# Open project
cd ~/CrookedSentry-HomeAutomation
open CrookedSentry.xcodeproj
```

### A. Signing & Capabilities
- [ ] **Configure Signing**
  1. Select "CrookedSentry" target (left sidebar)
  2. Go to "Signing & Capabilities" tab
  3. ✓ Check "Automatically manage signing"
  4. Select your Apple Developer Team from dropdown
  5. Verify Bundle ID: `Me.CrookedSentry`
  
- [ ] **Add Required Capabilities**
  - [ ] Personal VPN (if using VPN features)
  - [ ] Background Modes → Background fetch (if refreshing events in background)
  - [ ] Network Extensions (if using packet tunnel)

### B. Privacy Permissions (Required!)

**Add to project settings** (Xcode → Target → Info tab):

- [ ] **NSCameraUsageDescription**
  ```
  Value: "CrookedSentry displays live camera feeds from your Frigate security system."
  ```

- [ ] **NSLocalNetworkUsageDescription** (REQUIRED)
  ```
  Value: "CrookedSentry needs local network access to connect to your self-hosted Frigate server and camera feeds."
  ```

- [ ] **NSPhotoLibraryAddUsageDescription** (if saving images)
  ```
  Value: "Save event snapshots from your security cameras to your photo library."
  ```

**How to add in Xcode:**
```
1. Select CrookedSentry target
2. Click "Info" tab
3. Hover over any key → click "+"
4. Start typing "Privacy - " and select from dropdown
5. Add description text
```

### C. App Icon (REQUIRED)

- [ ] **Verify App Icon Exists**
  - Location: `CrookedSentry/Assets.xcassets/AppIcon.appiconset/`
  - Current: cc-logo-dark-iOS-Dark-1024x1024@1x.icon
  - Required: 1024x1024 px PNG
  - No transparency, no alpha channel
  - [ ] **Test:** Open in Preview and verify

- [ ] **Create Missing Sizes** (if needed)
  - Xcode will generate from 1024x1024 automatically
  - Or use: https://appicon.co to generate all sizes

### D. Version & Build Numbers

Current Settings:
```
Marketing Version: 1.0
Build Number: 1
```

- [ ] **For first TestFlight build:** Keep as 1.0 (1)
- [ ] **For subsequent builds:** Increment build number: 2, 3, 4...
- [ ] **For App Store release:** Use 1.0 or 1.0.0

**Update in Xcode:**
```
Target → General → Identity section
- Version: 1.0 (shown to users)
- Build: 1 (internal tracking)
```

### E. Build Settings Check

- [ ] **Deployment Target**
  - Recommended: iOS 15.0 or later
  - Check: Target → General → Deployment Info
  
- [ ] **Supported Devices**
  - iPhone ✓
  - iPad ✓ (or uncheck if iPhone-only)

---

## Phase 3: Create Archive 📦 (After Approval)

### Prerequisites Check
- [ ] Apple Developer enrollment approved
- [ ] Signing configured in Xcode
- [ ] Privacy descriptions added
- [ ] App icon verified
- [ ] iPhone connected OR "Any iOS Device" selected

### Archive Steps

1. **Clean Build Folder**
   ```
   Xcode → Product → Clean Build Folder (⇧⌘K)
   ```

2. **Select Device**
   ```
   Top-left dropdown → "Any iOS Device" (not simulator!)
   ```

3. **Create Archive**
   ```
   Product → Archive (⌘B to test first)
   Wait 5-10 minutes for build
   ```

4. **Troubleshooting Common Errors**

   - [ ] **"No signing certificate found"**
     - Solution: Xcode → Settings → Accounts → Download Manual Profiles
   
   - [ ] **"Failed to register bundle identifier"**
     - Solution: Check Bundle ID is unique at developer.apple.com
   
   - [ ] **"Code signing error"**
     - Solution: Enable "Automatically manage signing"
   
   - [ ] **Build errors**
     - Solution: Fix code issues, run tests first

---

## Phase 4: App Store Connect Setup 🌐 (After Approval)

### A. Create App Record

Visit: https://appstoreconnect.apple.com

- [ ] **Create New App**
  ```
  My Apps → "+" button → New App
  
  Platform: iOS
  Name: CrookedSentry (or preferred name)
  Primary Language: English
  Bundle ID: Me.CrookedSentry (must match Xcode)
  SKU: crookedsentry-ios (internal reference)
  User Access: Full Access
  ```

### B. App Information

- [ ] **Category**
  - Primary: Utilities
  - Secondary: Lifestyle (optional)

- [ ] **App Description** (4000 char max)
  ```
  Self-hosted home security monitoring for Frigate NVR systems.
  
  CrookedSentry brings your Frigate security cameras to iOS with:
  • Real-time event notifications
  • Live camera feed streaming  
  • Clip and snapshot review
  • Multi-camera support
  • Secure VPN integration
  • Dark mode support
  
  Requires self-hosted Frigate NVR server.
  Open source: github.com/josephmienko/CrookedSentry-HomeAutomation
  ```

- [ ] **Keywords** (100 char max, comma-separated)
  ```
  frigate,nvr,cctv,security,camera,home automation,surveillance,home assistant,self-hosted
  ```

- [ ] **Support URL** (REQUIRED)
  ```
  https://github.com/josephmienko/CrookedSentry-HomeAutomation
  ```

- [ ] **Marketing URL** (Optional)
  ```
  https://github.com/josephmienko/CrookedSentry-HomeAutomation
  ```

- [ ] **Privacy Policy URL** (REQUIRED)
  ```
  [Your hosted privacy policy URL from Phase 1]
  Example: https://josephmienko.github.io/CrookedSentry-HomeAutomation/privacy
  ```

### C. Pricing & Availability

- [ ] **Price** 
  - Recommended: Free (for beta/v1.0)
  - Can add In-App Purchases later

- [ ] **Availability**
  - All countries (default)
  - Or select specific regions

### D. Screenshots (REQUIRED - Create Later)

**Required Sizes:**
- [ ] 6.5" Display (1290 x 2796 px) - iPhone 15 Pro Max
  - Minimum: 1 screenshot
  - Recommended: 3-5 screenshots

- [ ] 5.5" Display (1242 x 2208 px) - iPhone 8 Plus
  - Minimum: 1 screenshot
  - Can be same as 6.5" scaled down

**Screenshot Ideas:**
1. Home screen with event list
2. Live camera feed view
3. Event detail with clip playback
4. Settings/configuration screen
5. Multi-camera grid view

**Tools to Create:**
- Xcode Simulator → Capture Screen (⌘S)
- Add text overlays in Preview/Keynote/Figma
- Or use: https://screenshots.pro

---

## Phase 5: Upload to TestFlight 🚀 (After Archive)

### A. Validate Archive

In Xcode Organizer:
- [ ] **Click "Validate App"**
  - Distribution: App Store Connect
  - Options: ✓ Upload symbols, ✓ Manage version
  - Signing: Automatically manage
  - Click "Validate"
  - Wait ~2-5 minutes
  - Fix any errors that appear

### B. Upload to App Store Connect

- [ ] **Click "Distribute App"**
  - Distribution: App Store Connect
  - Destination: Upload
  - Same options as validation
  - Click "Upload"
  - Wait 10-30 minutes
  - Email notification when processing complete

### C. TestFlight Configuration

- [ ] **Add Test Information**
  ```
  TestFlight tab → Build [version]
  
  What to Test:
  "Beta v1.0 - Please test:
  - Connecting to your Frigate server
  - Viewing live camera feeds
  - Reviewing event clips and snapshots
  - Switching between cameras
  - Dark/light mode appearance
  
  Known issues: [list any known bugs]
  
  Feedback appreciated via TestFlight or GitHub!"
  ```

- [ ] **Export Compliance**
  - Question: "Does your app use encryption?"
  - If no VPN features: Select "No"
  - If using VPN: Select "Yes" → follow prompts

### D. Add Internal Testers (Instant Access)

- [ ] **Create Internal Group**
  ```
  TestFlight → Internal Testing → "+"
  Group name: "Alpha Testers"
  ```

- [ ] **Add Testers by Email**
  - Add 5-10 people (max 100)
  - Must have Apple IDs
  - They get email instantly
  - No review required

### E. Add External Testers (Requires Review)

- [ ] **Create External Group**
  ```
  TestFlight → External Testing → "+"
  Group name: "Beta Testers"
  ```

- [ ] **Add Beta Tester Emails**
  - Up to 10,000 testers
  - Public link option available

- [ ] **Submit for Beta App Review**
  - Apple reviews in 24-48 hours
  - Less strict than App Store review
  - Tests basic functionality only

---

## Phase 6: Beta Testing Period 🧪 (2-4 Weeks)

### Week 1-2: Internal Alpha
- [ ] Test with 5-10 close testers
- [ ] Fix critical bugs
- [ ] Gather feedback via TestFlight screenshots
- [ ] Update build if needed (increment build number)

### Week 3-4: External Beta
- [ ] Expand to 50-100 testers
- [ ] Test on various devices and iOS versions
- [ ] Monitor crash reports in App Store Connect
- [ ] Polish UI/UX based on feedback

### Throughout Beta
- [ ] Track issues in GitHub
- [ ] Respond to tester feedback
- [ ] Update "What to Test" notes for each build
- [ ] Keep changelog of fixes

---

## Phase 7: App Store Submission 🎉 (After Beta)

### A. Final Pre-Submission Tasks

- [ ] **All Beta Issues Resolved**
  - [ ] No critical bugs remaining
  - [ ] UI/UX polished
  - [ ] Performance optimized

- [ ] **Screenshots Created** (see Phase 4D)
  - [ ] 6.5" display: 3-5 screenshots
  - [ ] 5.5" display: 3-5 screenshots
  - [ ] Optional: App Preview video (up to 30 seconds)

- [ ] **App Store Description Finalized**
  - [ ] Compelling copy
  - [ ] Feature list clear
  - [ ] Requirements stated (self-hosted Frigate)
  - [ ] Proofread for typos

- [ ] **Final Archive Built**
  - Version: 1.0.0 (or 1.0)
  - Build: [next sequential number]
  - All features complete
  - All tests passing

### B. Submit for App Review

1. **Upload Final Build** (same as TestFlight process)

2. **In App Store Connect:**
   ```
   My Apps → CrookedSentry → App Store tab
   
   - Select build from TestFlight
   - Add screenshots (all sizes)
   - Finalize app information
   - Set release option:
     □ Manually release (you control when it goes live)
     ☑ Automatically release (live immediately after approval)
   ```

3. **Content Rights & Age Rating**
   - [ ] Complete Age Rating questionnaire
   - [ ] Declare if app has ads (No)
   - [ ] Declare if app has in-app purchases (No)

4. **App Review Information**
   - [ ] Contact information (phone/email)
   - [ ] Demo account (if login required)
     - Username: [test account]
     - Password: [test password]
     - Special instructions: "Requires self-hosted Frigate server. Demo credentials provided."
   - [ ] Notes for reviewer:
     ```
     "CrookedSentry connects to self-hosted Frigate NVR servers.
     A test server is available at: [provide test server details if possible]
     Or: This app requires user's own infrastructure and cannot be tested without it."
     ```

5. **Submit for Review**
   - [ ] Click "Submit for Review"
   - [ ] Wait for confirmation email
   - [ ] Review typically takes 24-48 hours
   - [ ] Check status in App Store Connect

### C. During App Review

**Status Tracking:**
- ⏳ Waiting for Review (queue time: 1-2 days)
- 🔍 In Review (active review: few hours)
- ✅ Approved → Live in 24 hours
- ❌ Rejected → Fix issues and resubmit

**If Rejected:**
- [ ] Read rejection reason carefully
- [ ] Fix issues mentioned
- [ ] Update build if needed
- [ ] Respond in Resolution Center
- [ ] Resubmit for review

---

## Phase 8: Post-Launch 🎊 (Ongoing)

### Launch Day
- [ ] Verify app is live in App Store
- [ ] Download and test from App Store
- [ ] Share with community (GitHub, Reddit, etc.)
- [ ] Create GitHub release matching App Store version

### Ongoing Maintenance
- [ ] Monitor reviews in App Store Connect
- [ ] Respond to user reviews (build engagement)
- [ ] Track crash reports and analytics
- [ ] Plan v1.1 features based on feedback
- [ ] Regular updates (every 2-3 months recommended)

### Version Updates
- [ ] Increment version: 1.0 → 1.1 → 2.0
- [ ] Update "What's New" in App Store
- [ ] Submit updated builds through same process
- [ ] Maintain backward compatibility

---

## Quick Reference: Timeline

| Phase | Duration | Can Start |
|-------|----------|-----------|
| Developer Enrollment | 1-2 days | **NOW** |
| Xcode Configuration | 2-3 hours | While waiting |
| Privacy Policy Hosting | 1 hour | **NOW** |
| First Archive & Upload | 1 hour | After approval |
| TestFlight Internal | 1-2 weeks | After upload |
| TestFlight External | 2-3 weeks | After internal |
| App Store Review | 1-3 days | After beta |
| **Total to App Store** | **4-6 weeks** | From today |

---

## Resources & Links

- **App Store Connect:** https://appstoreconnect.apple.com
- **Developer Portal:** https://developer.apple.com/account
- **TestFlight Guide:** https://developer.apple.com/testflight/
- **App Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
- **Human Interface Guidelines:** https://developer.apple.com/design/human-interface-guidelines/

---

## Current Status Summary

**Completed:**
- ✅ CI/CD pipeline setup
- ✅ Privacy policy created
- ✅ TestFlight setup guide
- ✅ Comprehensive test suite

**In Progress:**
- ⏳ Apple Developer enrollment

**Next Actions (Priority Order):**
1. 🔴 **HIGH:** Enroll in Apple Developer Program
2. 🔴 **HIGH:** Host privacy policy and get URL
3. 🟡 **MEDIUM:** Add privacy descriptions to Xcode
4. 🟡 **MEDIUM:** Verify app icon
5. 🟢 **LOW:** Plan screenshot designs

**Blockers:**
- Cannot create archive until Developer Program approved
- Cannot upload to App Store Connect until enrollment complete

---

## Questions or Issues?

- Check `TESTFLIGHT_SETUP.md` for detailed instructions
- Open GitHub issue for technical problems
- Review Apple's documentation for policy questions

---

**Last Updated:** November 6, 2025  
**Next Review:** After Developer Program approval
