# Frigate Review Refactoring Plan

## Executive Summary
The current implementation mixes Events API and Review API concepts. This plan refactors to use Review API as the primary data source, aligning with Frigate's canonical review workflow.

## Current Architecture Issues

### Issue 1: Data Source Confusion
- **Problem**: Fetching Events (`/api/events`) but trying to apply Review logic
- **Impact**: Review API never called, `reviewItems` array unused
- **Evidence**: Terminal logs show events fetch every 2 seconds, zero review API calls

### Issue 2: Model Mismatch
- **Problem**: Using `FrigateEvent` model for display, not `FrigateReviewItem`
- **Impact**: Can't access `has_been_reviewed` property from server
- **Solution**: Switch primary model to `FrigateReviewItem` for home feed

### Issue 3: Dual Tracking Complexity
- **Problem**: Both server (`reviewItems`) and client (`viewedEventIds`) tracking
- **Impact**: State synchronization issues, unnecessary complexity
- **Solution**: Use server `has_been_reviewed` as source of truth

## Recommended Architecture

### Phase 1: Core Data Flow (HIGH PRIORITY)

#### Step 1.1: Replace Events with Review Items
**File**: `ContentView.swift`

**Current**:
```swift
@State private var events: [FrigateEvent] = []
@State private var reviewItems: [FrigateReviewItem] = [] // Unused!
```

**Refactored**:
```swift
@State private var reviewItems: [FrigateReviewItem] = [] // PRIMARY data source
@State private var events: [FrigateEvent] = [] // Keep for detail view only
```

**Changes**:
1. Remove `events` from home page display
2. Use `reviewItems` array for ListView
3. Keep `events` for backward compatibility with detail views

#### Step 1.2: Fix API Call Priority
**File**: `ContentView.swift` → `refreshEvents()` function

**Current** (lines ~240-250):
```swift
func refreshEvents() async {
    await fetchEvents() // Called FIRST
    await fetchReviewItems() // Called but results ignored
}
```

**Refactored**:
```swift
func refreshEvents() async {
    // Fetch review items for home feed
    await fetchReviewItems()
    
    // Only fetch events if we need detail view data
    // OR remove entirely if review items provide enough info
    // await fetchEvents() 
}
```

**Rationale**: Review API should be primary data source for home feed

#### Step 1.3: Update Display Logic
**File**: `ContentView.swift` → `homePageEvents` computed property

**Current**:
```swift
var homePageEvents: [FrigateEvent] {
    return applyFilters(events: events)
}
```

**Refactored**:
```swift
var homePageReviews: [FrigateReviewItem] {
    return applyReviewFilters(reviews: reviewItems)
}

private func applyReviewFilters(reviews: [FrigateReviewItem]) -> [FrigateReviewItem] {
    return reviews.filter { review in
        // Apply camera/label/zone filters
        let cameraMatch = selectedCamera == "all" || review.camera == selectedCamera
        
        // Apply 3-day review filter
        let reviewCutoff = Date().addingTimeInterval(-3 * 24 * 60 * 60).timeIntervalSince1970
        let shouldShow = !review.has_been_reviewed || review.start_time > reviewCutoff
        
        return cameraMatch && shouldShow
    }
}
```

### Phase 2: UI Updates (MEDIUM PRIORITY)

#### Step 2.1: Create ReviewItemCardView
**New File**: `CrookedSentry/ReviewItemCardView.swift`

**Purpose**: Display review items (time periods) instead of events (individual objects)

**Key Differences from EventCardView**:
```swift
struct ReviewItemCardView: View {
    let review: FrigateReviewItem
    var isUnreviewed: Bool { !review.has_been_reviewed }
    
    var body: some View {
        HStack {
            // Thumbnail from review.thumb_path
            // ...
            
            VStack(alignment: .leading) {
                // Title: "<<objects.count>> objects detected in <<camera>>"
                Text("\(objectCount) \(objectLabel) in \(review.camera)")
                    .fontWeight(isUnreviewed ? .bold : .regular)
                
                // Badge: 6px red dot if isUnreviewed
                if isUnreviewed {
                    Circle()
                        .fill(Color.error)
                        .frame(width: 6, height: 6)
                }
                
                // Timestamp: "<<start_time>> - <<end_time>>"
                // Duration: "<<duration>>"
                // Zones: if review.data?.zones exists
            }
        }
    }
    
    private var objectCount: Int {
        review.data?.objects?.count ?? 0
    }
    
    private var objectLabel: String {
        guard let objects = review.data?.objects else { return "objects" }
        // Pluralize appropriately
        return objectCount == 1 ? objects.first ?? "object" : "objects"
    }
}
```

#### Step 2.2: Update ContentView List
**File**: `ContentView.swift` → List/ForEach

**Current**:
```swift
ForEach(homePageEvents) { event in
    EventCardView(event: event, isUnreviewed: isEventUnreviewed(event))
}
```

**Refactored**:
```swift
ForEach(homePageReviews) { review in
    ReviewItemCardView(review: review)
        .onTapGesture {
            selectedReview = review
            showingDetail = true
        }
}
```

### Phase 3: Mark as Reviewed Workflow (HIGH PRIORITY)

#### Step 3.1: Update Review State on View
**File**: `ContentView.swift` → `markEventAsReviewed()`

**Current Issue**: Function marks event as reviewed but doesn't update UI immediately

**Refactored**:
```swift
func markReviewAsViewed(_ reviewId: String) async {
    // 1. Call API to mark as reviewed
    await apiClient.markEventAsReviewed(eventId: reviewId)
    
    // 2. Update local state IMMEDIATELY for responsive UI
    if let index = reviewItems.firstIndex(where: { $0.id == reviewId }) {
        var updatedReview = reviewItems[index]
        // Note: has_been_reviewed is let, so we need to recreate
        reviewItems[index] = FrigateReviewItem(
            id: updatedReview.id,
            camera: updatedReview.camera,
            start_time: updatedReview.start_time,
            end_time: updatedReview.end_time,
            has_been_reviewed: true, // ← Update here
            severity: updatedReview.severity,
            thumb_path: updatedReview.thumb_path,
            data: updatedReview.data
        )
    }
    
    // 3. Refresh from server to confirm
    await fetchReviewItems()
}
```

**Call site** (in detail view or card tap handler):
```swift
.onDisappear {
    if !review.has_been_reviewed {
        Task {
            await markReviewAsViewed(review.id)
        }
    }
}
```

#### Step 3.2: Make FrigateReviewItem Mutable
**File**: `FrigateEvent.swift`

**Current**:
```swift
struct FrigateReviewItem: Codable, Identifiable {
    let has_been_reviewed: Bool // Immutable
}
```

**Refactored**:
```swift
struct FrigateReviewItem: Codable, Identifiable {
    var has_been_reviewed: Bool // Now mutable for local updates
}
```

**Alternative**: Keep immutable and use functional update pattern (shown in Step 3.1)

### Phase 4: Debugging & Verification (CRITICAL)

#### Step 4.1: Verify Review API Endpoint Exists
**Test in terminal**:
```bash
curl -X GET "http://192.168.0.200:5000/api/review?cameras=all&labels=all&reviewed=0&limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected**: JSON array of review items
**If fails**: Your Frigate version might not support Review API

#### Step 4.2: Add Enhanced Logging
**File**: `FrigateEventAPIClient.swift` → `fetchReviewItems()`

**Add at start of function**:
```swift
print("🔍 REVIEW API DEBUG:")
print("  - Base URL: \(baseURL)")
print("  - Endpoint: /api/review")
print("  - Parameters: cameras=\(cameras), reviewed=\(reviewed)")
print("  - Full URL: \(url.absoluteString)")
```

**Add after response**:
```swift
print("📡 REVIEW API RESPONSE:")
print("  - Status: \(httpResponse.statusCode)")
print("  - Body length: \(data.count) bytes")
if let jsonString = String(data: data, encoding: .utf8) {
    print("  - Body preview: \(jsonString.prefix(200))")
}
```

#### Step 4.3: Check Frigate Version Compatibility
**Action**: Verify Frigate 0.16.2 supports `/api/review`

**Documentation states**: Review API introduced in v0.14
**Your version**: 0.16.2-4d58206

**Likely supported**, but test with curl to confirm endpoint exists.

## Implementation Priority

### CRITICAL (Do First)
1. ✅ Verify `/api/review` endpoint works with curl
2. ✅ Add debug logging to `fetchReviewItems()`
3. ✅ Switch `refreshEvents()` to prioritize review API

### HIGH (Core Functionality)
4. ✅ Replace events display with reviewItems in ContentView
5. ✅ Create ReviewItemCardView component
6. ✅ Implement mark-as-reviewed with immediate UI update

### MEDIUM (Enhancement)
7. ✅ Add proper error handling for API failures
8. ✅ Implement pull-to-refresh for review items
9. ✅ Add loading states for review fetch

### LOW (Polish)
10. ✅ Remove client-side viewedEventIds tracking (use server state)
11. ✅ Clean up unused Events API code if not needed
12. ✅ Add analytics/logging for review workflow

## Testing Checklist

- [ ] Review API endpoint returns data (curl test)
- [ ] Review items display with correct badge state
- [ ] Tapping review item shows detail view
- [ ] Marking as reviewed updates badge immediately
- [ ] Badge disappears when has_been_reviewed = true
- [ ] Items older than 3 days disappear after being reviewed
- [ ] Filters (camera/label/zone) work with review items
- [ ] Pull-to-refresh updates review state
- [ ] Works in both light and dark mode

## Rollback Strategy

If Review API doesn't work:
1. Keep current Events API as primary
2. Use client-side viewedEventIds as fallback
3. Document limitation for future Frigate upgrade

## Questions to Answer

1. **Does your Frigate instance support `/api/review`?**
   - Test with curl command above
   - Check Frigate docs for your specific version

2. **Do you want to keep Events API at all?**
   - Could use Review API exclusively
   - Events API only needed if detail view requires it

3. **Should reviewed items be hidden immediately?**
   - Current: 3-day grace period
   - Alternative: Hide instantly after marking reviewed

4. **How to handle review items with multiple object types?**
   - Example: Review has 3 persons + 1 car
   - Display as "4 objects" or "3 persons, 1 car"?

## Next Steps

1. Test Review API endpoint availability (curl)
2. Add debug logging to identify why API isn't called
3. Refactor data flow to use reviewItems as primary source
4. Create ReviewItemCardView component
5. Test complete workflow end-to-end

---

## Code Quality Improvements

### Error Handling
Add proper error handling to Review API calls:
```swift
func fetchReviewItems() async {
    do {
        reviewItems = try await apiClient.fetchReviewItems(...)
    } catch {
        print("❌ Failed to fetch review items: \(error)")
        // Show error to user
        errorMessage = "Could not load reviews. Using cached data."
    }
}
```

### Loading States
Add loading indicators:
```swift
@State private var isLoadingReviews = false

var body: some View {
    if isLoadingReviews {
        ProgressView("Loading reviews...")
    } else {
        List(homePageReviews) { ... }
    }
}
```

### State Management
Consider using @Published in ObservableObject for better state management:
```swift
class ReviewStore: ObservableObject {
    @Published var reviews: [FrigateReviewItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func refresh() async {
        // ...
    }
}
```

This would replace scattered @State variables and provide cleaner architecture.
