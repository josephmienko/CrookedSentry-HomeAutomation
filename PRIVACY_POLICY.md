# Privacy Policy for CrookedSentry

**Last Updated:** November 6, 2025

## Introduction

CrookedSentry ("we", "our", or "the app") is a home automation and security camera monitoring application developed by Joseph Mienko. This privacy policy explains how the app handles your information.

## Our Commitment to Privacy

**CrookedSentry is designed with privacy as a core principle.** The app is built for self-hosted home automation systems and does not collect, store, or transmit any personal data to third parties or external servers operated by us.

## Information We Don't Collect

CrookedSentry does **NOT** collect:
- Personal identification information
- Usage analytics or statistics
- Crash reports sent to third parties
- Location data sent to external servers
- Device information sent to external servers
- Any form of tracking or profiling data

## How the App Works

### Local Network Communication
- CrookedSentry connects directly to **your self-hosted Frigate server** on your local network
- All video streams, event data, and camera feeds are transmitted directly between your iOS device and your local Frigate server
- No video, images, or event data passes through our servers (we don't operate any servers)
- You maintain complete control over your data on your own infrastructure

### Data Storage on Your Device

CrookedSentry stores the following information **locally on your iOS device**:

1. **User Preferences:**
   - Frigate server URL and connection settings
   - Camera selection and filtering preferences
   - Display preferences (theme, layout, stream quality)
   - Review state tracking (which events you've viewed)

2. **Authentication Credentials:**
   - VPN configuration (if you enable VPN features)
   - Camera authentication credentials (username/password)
   - Optional API tokens for Frigate access
   - All credentials are stored securely in iOS Keychain

3. **Temporary Cache:**
   - Thumbnail images from your Frigate server
   - Event metadata for faster loading
   - This cache is automatically cleared when you uninstall the app

### iOS Keychain Security
All sensitive credentials (passwords, tokens, VPN configurations) are stored using iOS Keychain, which provides:
- Hardware-level encryption
- Secure enclave protection (on compatible devices)
- Automatic deletion when app is uninstalled
- Protection against unauthorized access

## Network Access

### Local Network Access (Required)
The app requires access to your local network to:
- Connect to your Frigate server
- Stream live camera feeds
- Retrieve event recordings and snapshots
- Communicate with your Home Assistant instance (optional)

**iOS will prompt you to allow local network access when you first use the app.**

### VPN Features (Optional)
If you enable VPN features:
- VPN connections are established directly between your device and your VPN server
- We do not operate VPN servers or have access to your VPN traffic
- VPN credentials are stored securely in iOS Keychain
- You can disable VPN features at any time in Settings

### Internet Access (Optional)
The app may access the internet only for:
- Checking for app updates (through the App Store)
- Accessing your Frigate server remotely (if you expose it via VPN or reverse proxy)
- All remote access is configured and controlled by you

## Third-Party Services

CrookedSentry does **NOT** use:
- Analytics services (Google Analytics, Firebase, etc.)
- Advertising networks
- Social media integrations
- Cloud storage providers
- Push notification services operated by us
- Any third-party tracking or data collection services

**Note:** The app communicates exclusively with services **you** configure and control (your Frigate server, your VPN, your network).

## Camera and Photo Library Access

### Camera Feed Viewing
- The app displays camera feeds from your Frigate server
- Video streams are transmitted directly from your server to your device
- No video or images are uploaded to external servers

### Photo Library Access (Optional)
If you choose to save event snapshots to your device:
- iOS will prompt you for Photos permission
- Images are saved directly to your device's photo library
- We do not access or transmit these images
- You can revoke this permission at any time in iOS Settings

## Data Sharing and Disclosure

**We do not share, sell, rent, or disclose your data to anyone** because we don't collect or have access to your data.

The only data transmission occurs between:
- Your iOS device ↔ Your Frigate server (on your network)
- Your iOS device ↔ Your VPN server (if configured by you)
- Your iOS device ↔ Your Home Assistant instance (if configured by you)

## Your Rights and Control

You have complete control over your data:

### Delete All App Data
- Uninstall the app to permanently delete all locally stored data
- Go to Settings → General → iPhone Storage → CrookedSentry → Delete App

### Manage Permissions
- Go to iOS Settings → CrookedSentry to manage:
  - Local Network access
  - Photo Library access
  - Background app refresh

### Reset Settings
- Within the app, you can clear:
  - Server URLs and connection settings
  - Stored credentials (removes from Keychain)
  - Camera preferences and filters
  - Cached thumbnails and event data

## Children's Privacy

CrookedSentry is not intended for use by children under 13 years of age. We do not knowingly collect information from children. The app is designed for adults managing their home security systems.

## Security

We take security seriously:

- **Credentials:** Stored in iOS Keychain with hardware encryption
- **Network Communication:** Uses HTTPS/TLS when available (depends on your Frigate server configuration)
- **No Cloud Storage:** All data remains on your device and your infrastructure
- **Open Source:** The app's source code is available for review at: https://github.com/josephmienko/CrookedSentry-HomeAutomation
- **Regular Updates:** Security patches and bug fixes are released regularly

**Recommendation:** We strongly recommend:
- Using HTTPS for your Frigate server
- Securing your Frigate server with authentication
- Using a VPN for remote access instead of exposing ports to the internet
- Keeping your iOS device and the app updated

## Changes to This Privacy Policy

We may update this privacy policy from time to time to reflect:
- Changes in app features
- Updates to iOS privacy requirements
- User feedback and best practices

**How you'll be notified:**
- Updated "Last Updated" date at the top
- In-app notification for significant changes
- Updates posted on GitHub repository

**Your continued use of the app after changes constitutes acceptance of the updated policy.**

## International Users

CrookedSentry can be used worldwide. Since all data remains on your local network and device:
- No international data transfers occur through our services
- Compliance with local privacy laws depends on your own infrastructure setup
- You are responsible for ensuring your self-hosted setup complies with local regulations

## Legal Basis for Processing (GDPR)

For users in the European Union:
- **Consent:** By using the app, you consent to local storage of your preferences
- **Legitimate Interest:** Processing is necessary for the app to function
- **Data Minimization:** We only store what's necessary for the app to work
- **Right to Erasure:** Uninstall the app to delete all data

## California Privacy Rights (CCPA)

For California residents:
- **Right to Know:** We've disclosed what data is stored (see "Data Storage" section)
- **Right to Delete:** Uninstall the app to delete all data
- **Right to Opt-Out:** Not applicable (we don't sell personal information)
- **Non-Discrimination:** Not applicable (we don't collect data that could be sold)

## Open Source Transparency

CrookedSentry is open source software:
- **Source Code:** Available at https://github.com/josephmienko/CrookedSentry-HomeAutomation
- **Issue Tracking:** Report privacy concerns via GitHub Issues
- **Code Review:** Anyone can review how the app handles data
- **Community:** Join discussions about privacy and security

## Contact Information

If you have questions or concerns about this privacy policy or how the app handles data:

**Developer:** Joseph Mienko

**Email:** [Your Email Address]

**GitHub:** https://github.com/josephmienko/CrookedSentry-HomeAutomation

**Issues/Support:** https://github.com/josephmienko/CrookedSentry-HomeAutomation/issues

We aim to respond to privacy inquiries within 5 business days.

## Disclaimer

CrookedSentry is provided "as is" for self-hosted home automation systems. While we prioritize privacy and security in the app's design:
- You are responsible for securing your own infrastructure (Frigate server, network, VPN)
- We cannot guarantee the security of your self-hosted systems
- You should follow security best practices for your home network and servers

## Acknowledgments

CrookedSentry integrates with:
- **Frigate** - Open source NVR (https://frigate.video)
- **Home Assistant** - Open source home automation (https://www.home-assistant.io)

These are third-party services that you host and control. Please review their privacy policies separately.

---

## Summary (TL;DR)

✅ **No data collection** - We don't collect, store, or transmit your personal data  
✅ **Local only** - Everything stays on your device and your network  
✅ **Your control** - You host and manage all servers and data  
✅ **Secure storage** - Credentials protected by iOS Keychain  
✅ **No tracking** - No analytics, ads, or third-party services  
✅ **Open source** - Code is public and reviewable  
✅ **Easy deletion** - Uninstall app to remove all data  

**Questions?** Open an issue on GitHub or contact us directly.

---

*This privacy policy is effective as of November 6, 2025 and applies to all versions of CrookedSentry.*
