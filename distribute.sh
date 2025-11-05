#!/bin/bash

# CrookedSentry Distribution Helper Script
# This script helps prepare the app for distribution to testers

echo "🚀 CrookedSentry Distribution Helper"
echo "=================================="

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "CrookedSentry.xcworkspace" ]; then
    echo -e "${RED}❌ Error: CrookedSentry.xcworkspace not found"
    echo -e "   Please run this script from the project root directory${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Current App Configuration:${NC}"
echo "   • Bundle ID: Me.CrookedSentry"
echo "   • Version: 1.0"
echo "   • Build: 1"
echo ""

echo -e "${YELLOW}🛠  Distribution Options:${NC}"
echo "1. TestFlight Distribution (Requires Apple Developer Account)"
echo "2. Ad Hoc Distribution (Free - requires device UDID)"
echo "3. Development Build (Direct install via Xcode)"
echo "4. Just show instructions"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo -e "${GREEN}📱 TestFlight Distribution Selected${NC}"
        echo ""
        echo "Steps to distribute via TestFlight:"
        echo "1. Open Xcode and load CrookedSentry.xcworkspace"
        echo "2. Select 'Any iOS Device (arm64)' as destination"
        echo "3. Product → Archive"
        echo "4. In Organizer, select 'Distribute App'"
        echo "5. Choose 'App Store Connect'"
        echo "6. Upload for TestFlight testing"
        echo "7. Add external testers in App Store Connect"
        echo ""
        echo -e "${BLUE}💡 Tip: Make sure your Apple Developer account is configured in Xcode${NC}"
        ;;
    
    2)
        echo -e "${GREEN}📦 Ad Hoc Distribution Selected${NC}"
        echo ""
        echo "Steps for Ad Hoc distribution:"
        echo "1. Get your friend's device UDID:"
        echo "   • iPhone: Settings → General → About → tap multiple times on device info"
        echo "   • Or use this shortcut: https://www.icloud.com/shortcuts/f9b1ad7128274e84877a5a4eab8b0e72"
        echo ""
        echo "2. Register device in Xcode:"
        echo "   • Window → Devices and Simulators"
        echo "   • Click '+' to add device"
        echo "   • Enter name and UDID"
        echo ""
        echo "3. Create Ad Hoc build:"
        echo "   • Product → Archive"
        echo "   • Distribute App → Ad Hoc"
        echo "   • Export IPA file"
        echo ""
        echo "4. Share IPA file with friend"
        echo "5. Friend installs via AltStore, Sideloadly, or Apple Configurator"
        ;;
    
    3)
        echo -e "${GREEN}🔧 Development Build Selected${NC}"
        echo ""
        echo "Steps for development build:"
        echo "1. Connect friend's iPhone to your Mac via USB"
        echo "2. Trust the device when prompted"
        echo "3. In Xcode, select the connected device"
        echo "4. Product → Run"
        echo "5. App will install directly to device"
        echo ""
        echo -e "${YELLOW}⚠️  Note: App will expire in 7 days without Apple Developer account${NC}"
        ;;
    
    4)
        echo -e "${GREEN}📖 Instructions Generated${NC}"
        echo ""
        echo "Distribution guide created at: DISTRIBUTION_GUIDE.md"
        ;;
    
    *)
        echo -e "${RED}❌ Invalid option selected${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}🧪 Testing Checklist for Your Friend:${NC}"
echo "□ App launches without crashes"
echo "□ Can configure Frigate server URL in settings"
echo "□ Events display in Security tab"
echo "□ Live feeds work (test VPN detection)"
echo "□ Navigation drawer opens and functions"
echo "□ Material 3 design looks good"
echo "□ Performance is smooth"

echo ""
echo -e "${GREEN}✅ Distribution helper complete!${NC}"
echo -e "${BLUE}📚 For detailed instructions, see: DISTRIBUTION_GUIDE.md${NC}"