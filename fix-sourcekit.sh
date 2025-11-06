#!/bin/bash
# Fix SourceKit "No such module 'XCTest'" error

echo "🔧 Fixing SourceKit XCTest module issue..."

# 1. Kill SourceKit
echo "1️⃣ Killing SourceKit processes..."
killall -9 SourceKitService 2>/dev/null || true

# 2. Clear DerivedData
echo "2️⃣ Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/CrookedSentry-*

# 3. Clear module cache
echo "3️⃣ Clearing module cache..."
rm -rf ~/Library/Developer/Xcode/UserData/ModuleCache.noindex/*

# 4. Rebuild test target
echo "4️⃣ Rebuilding test target..."
cd "$(dirname "$0")"
xcodebuild build-for-testing \
  -workspace CrookedSentry.xcworkspace \
  -scheme CrookedSentryTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -quiet

echo "✅ Done! Now:"
echo "   1. Close Xcode (Cmd+Q)"
echo "   2. Reopen: open CrookedSentry.xcworkspace"
echo "   3. Build (Cmd+B)"
echo "   4. If still broken: Editor → SourceKit → Restart SourceKit Service"
