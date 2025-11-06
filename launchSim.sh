#!/usr/bin/env zsh

# --- Settings ---
DEVICE_NAME="iPhone 17 Pro"
DERIVED_DATA="./DerivedData"
SCHEME="CrookedSentry"
PROJECT="CrookedSentry.xcodeproj"
BUNDLE_ID="Me.CrookedSentry"

echo "🚀 Starting CrookedSentry build and launch sequence..."

# --- Step 1: Boot the simulator ---
echo "\n📱 Step 1: Booting simulator '${DEVICE_NAME}'..."
open -a "Simulator"
sleep 2

# Get device UDID
DEVICE_UDID=$(xcrun simctl list devices | grep "${DEVICE_NAME}" | grep -v "unavailable" | head -n 1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$DEVICE_UDID" ]; then
  echo "❌ Error: Could not find device '${DEVICE_NAME}'"
  exit 1
fi

echo "   Found device UDID: ${DEVICE_UDID}"

# Boot if not already booted
xcrun simctl boot "$DEVICE_UDID" 2>/dev/null || echo "   Simulator already booted"
xcrun simctl bootstatus "$DEVICE_UDID" -b
echo "   ✅ Simulator ready"

# --- Step 2: Build the app ---
echo "\n🔨 Step 2: Building app..."
xcodebuild build \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=${DEVICE_NAME}" \
  -derivedDataPath "${DERIVED_DATA}" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  ONLY_ACTIVE_ARCH=NO

BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
  echo "❌ Build failed"
  exit 1
fi

APP_PATH="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator/${SCHEME}.app"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ Error: App not found at ${APP_PATH}"
  exit 1
fi

echo "   ✅ Build succeeded: ${APP_PATH}"

# --- Step 3: Uninstall old version ---
echo "\n🗑️  Step 3: Removing old app version..."
xcrun simctl uninstall "$DEVICE_UDID" "${BUNDLE_ID}" 2>/dev/null || echo "   (No previous installation)"

# --- Step 4: Install the app ---
echo "\n📦 Step 4: Installing app..."
xcrun simctl install "$DEVICE_UDID" "${APP_PATH}"

if [ $? -ne 0 ]; then
  echo "❌ Installation failed"
  exit 1
fi

echo "   ✅ App installed"

# Wait a moment for installation to settle
sleep 1

# --- Step 5: Launch the app ---
echo "\n🚀 Step 5: Launching ${BUNDLE_ID}..."
xcrun simctl launch --console-pty "$DEVICE_UDID" "${BUNDLE_ID}"

if [ $? -ne 0 ]; then
  echo "❌ Launch failed"
  exit 1
fi

echo "\n✅ All done! CrookedSentry should be running on ${DEVICE_NAME}"