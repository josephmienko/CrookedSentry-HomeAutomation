# CrookedSentry Distribution Guide

## 📱 TestFlight Distribution (Recommended)

### Prerequisites
- Apple Developer Account ($99/year)
- Xcode with your team configured
- Friend's Apple ID email

### Steps:

1. **Archive the App**
   ```bash
   # In Xcode:
   # Product → Archive
   # Wait for build to complete
   ```

2. **Upload to App Store Connect**
   - In Organizer → Distribute App
   - Choose "App Store Connect"
   - Upload for TestFlight Testing

3. **Add External Testers**
   - Go to App Store Connect
   - Select your app → TestFlight
   - Add External Testers
   - Enter your friend's Apple ID email
   - Send invitation

### Benefits:
✅ Professional distribution method
✅ Automatic updates
✅ Real device testing
✅ Crash reporting
✅ No device registration needed

---

## 🔧 Ad Hoc Distribution (Free Alternative)

### Prerequisites
- Free Apple Developer Account
- Friend's device UDID
- Xcode configured with your Apple ID

### Steps:

#### Step 1: Get Friend's Device UDID
Send your friend this shortcut: https://www.icloud.com/shortcuts/f9b1ad7128274e84877a5a4eab8b0e72

Or have them:
1. Connect iPhone to Mac
2. Open Finder → iPhone → General
3. Click on Serial Number until UDID appears
4. Copy and send to you

#### Step 2: Register Device
1. Open Xcode → Window → Devices and Simulators
2. Click "+" to add device
3. Enter name and UDID
4. Register device

#### Step 3: Create Archive
1. In Xcode: Product → Archive
2. Wait for build to complete

#### Step 4: Export Ad Hoc Build
1. In Organizer → Distribute App
2. Choose "Ad Hoc"
3. Select your team
4. Choose "Automatically manage signing"
5. Export to folder

#### Step 5: Share IPA File
- Upload .ipa file to cloud storage (iCloud, Dropbox, etc.)
- Share download link with friend

#### Step 6: Install on Friend's Device
Your friend needs to:
1. Download .ipa file on iPhone
2. Use AltStore, Sideloadly, or Apple Configurator 2 to install

---

## 🛠 Development Distribution (Easiest)

### If Your Friend is Nearby:

1. **Direct Install via Xcode**
   - Connect friend's iPhone to your Mac
   - Trust the device when prompted
   - In Xcode: Product → Run
   - App installs directly to device

2. **Benefits:**
   ✅ Instant testing
   ✅ No file sharing needed
   ✅ Live debugging possible

---

## 📋 Pre-Distribution Checklist

### 1. Test Configuration
- [ ] Ensure Frigate server URL is configurable
- [ ] Test with different network conditions
- [ ] Verify VPN detection works properly
- [ ] Check error handling for unreachable servers

### 2. Prepare Instructions for Your Friend
```
Hi! Here's how to test CrookedSentry:

1. Install the app using [method you chose]
2. Open the app
3. Tap the hamburger menu (≡) → Settings
4. Configure your Frigate server URL: http://YOUR_IP:5000
5. Test both Home and Security sections
6. Try the VPN features in Security → Live

Please let me know:
- Does the app launch properly?
- Can you see events in the Security tab?
- Do the live feeds work?
- Any crashes or errors?
- How's the overall performance?
```

### 3. Troubleshooting Tips for Friend
- **Can't install:** Device UDID might not be registered
- **App crashes:** Check iOS version compatibility
- **No events showing:** Verify Frigate server is accessible
- **VPN issues:** Try on different networks (home/cellular)

---

## 🚀 Quick Start (Easiest Method)

If you have an Apple Developer account:

```bash
# 1. Archive the project
# Xcode → Product → Archive

# 2. Upload to TestFlight
# Organizer → Distribute → App Store Connect

# 3. Add your friend as external tester
# App Store Connect → TestFlight → External Testing
```

If you don't have a developer account:
1. Get friend's device UDID
2. Register in Xcode
3. Build Ad Hoc distribution
4. Share .ipa file

---

## 📱 Installation Methods for Friend

### TestFlight (If using method 1)
1. Download TestFlight from App Store
2. Check email for invitation
3. Tap "Accept" in email
4. Install via TestFlight app

### Ad Hoc Installation
**Option A: AltStore (Free)**
1. Install AltStore from altstore.io
2. Download .ipa file
3. Open in AltStore → Install

**Option B: Apple Configurator 2 (Mac required)**
1. Download from Mac App Store
2. Add .ipa to device via Configurator

**Option C: Sideloadly**
1. Download from sideloadly.io
2. Install .ipa using tool

---

## 🔍 What to Test

### Core Functionality
- [ ] App launches without crashes
- [ ] Settings configuration works
- [ ] Events display properly
- [ ] Live feeds accessible
- [ ] Navigation drawer functions
- [ ] VPN integration works

### Network Testing
- [ ] Home WiFi performance
- [ ] Cellular data functionality
- [ ] VPN detection accuracy
- [ ] Server connectivity handling

### UI/UX Testing
- [ ] Material 3 design consistency
- [ ] Touch interactions responsive
- [ ] Animations smooth
- [ ] Dark/light mode switching
- [ ] Different screen sizes

---

## 📊 Feedback Collection

Ask your friend to test:
1. **Performance:** How smooth is the app?
2. **Usability:** Is navigation intuitive?
3. **Features:** Do all functions work as expected?
4. **Design:** How does the UI look and feel?
5. **Bugs:** Any crashes, freezes, or errors?

---

Choose the method that works best for your situation! TestFlight is most professional, but Ad Hoc works great for quick testing.