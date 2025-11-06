# Frigate Review Architecture - Current vs Refactored

## Current Architecture (BROKEN)

```
┌─────────────────────────────────────────────────────────────┐
│ ContentView.swift                                           │
│                                                             │
│  @State events: [FrigateEvent] ←── Primary display source  │
│  @State reviewItems: [FrigateReviewItem] ←── UNUSED!       │
│  @State viewedEventIds: Set<String> ←── Client tracking    │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│ refreshEvents() async                                       │
│                                                             │
│  1. await fetchEvents() ←── Called FIRST, results used     │
│  2. await fetchReviewItems() ←── Called but ignored!       │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│ FrigateEventAPIClient.swift                                 │
│                                                             │
│  fetchEvents()                                              │
│    → GET /api/events?limit=100  ✅ WORKS                    │
│    → Returns [FrigateEvent]                                 │
│    → Logs: "🌐 Fetching events..." (seen in terminal)      │
│                                                             │
│  fetchReviewItems()                                         │
│    → GET /api/review?reviewed=0  ❌ NEVER CALLED            │
│    → Returns [FrigateReviewItem]                            │
│    → Logs: "🌐 Fetching review..." (NEVER seen!)           │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│ UI Display Layer                                            │
│                                                             │
│  List(homePageEvents) ←── Uses events array                │
│    ForEach(events) { event in                              │
│      EventCardView(                                         │
│        event: event,                                        │
│        isUnreviewed: isEventUnreviewed(event) ←── Client   │
│      )                                                      │
│    }                                                        │
│                                                             │
│  isEventUnreviewed(event) {                                │
│    // Checks client-side viewedEventIds                    │
│    // Never uses server's has_been_reviewed!               │
│    return !viewedEventIds.contains(event.id)               │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘

PROBLEM: Review API exists but is completely bypassed!


## Refactored Architecture (CORRECT)

```
┌─────────────────────────────────────────────────────────────┐
│ ContentView.swift                                           │
│                                                             │
│  @State reviewItems: [FrigateReviewItem] ←── PRIMARY       │
│  @State events: [FrigateEvent] ←── Detail view only        │
│  // viewedEventIds REMOVED - use server state              │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│ refreshReviews() async                                      │
│                                                             │
│  1. await fetchReviewItems() ←── PRIMARY data source        │
│  2. // fetchEvents() only if needed for detail views       │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│ FrigateEventAPIClient.swift                                 │
│                                                             │
│  fetchReviewItems(reviewed: 0)                              │
│    → GET /api/review?cameras=all&reviewed=0&limit=100       │
│    → Returns [FrigateReviewItem]                            │
│    → Each item has:                                         │
│        - id: String                                         │
│        - has_been_reviewed: Bool ←── Server state!          │
│        - start_time, end_time: Double                       │
│        - data.objects: [String] (person, car, etc.)         │
│        - thumb_path: String                                 │
│                                                             │
│  markEventAsReviewed(eventId: String)                       │
│    → POST /api/reviews/viewed                               │
│    → Body: {"ids": ["eventId"]}                             │
│    → Updates server's has_been_reviewed flag               │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│ UI Display Layer                                            │
│                                                             │
│  List(homePageReviews) ←── Uses reviewItems array          │
│    ForEach(filteredReviews) { review in                    │
│      ReviewItemCardView(                                    │
│        review: review                                       │
│      )                                                      │
│      .onTapGesture {                                        │
│        showDetail(review)                                   │
│      }                                                      │
│      .onDisappear {                                         │
│        if !review.has_been_reviewed {                      │
│          markAsViewed(review.id)                           │
│        }                                                    │
│      }                                                      │
│    }                                                        │
│                                                             │
│  filteredReviews = reviewItems.filter {                    │
│    // Show if not reviewed                                 │
│    if !$0.has_been_reviewed { return true }                │
│                                                             │
│    // OR if reviewed within 3 days                         │
│    let threeDaysAgo = Date().addingTimeInterval(-259200)   │
│    return $0.start_time > threeDaysAgo.timeIntervalSince1970│
│  }                                                          │
└─────────────────────────────────────────────────────────────┘

SUCCESS: Review API is primary data source, server state drives UI


## Data Model Comparison

### FrigateEvent (Individual Object Detection)
```swift
{
  "id": "1234567890.123-abc",
  "camera": "front_door",
  "label": "person",
  "start_time": 1234567890.123,
  "end_time": 1234567895.456,
  "has_clip": true,
  "zones": ["porch"],
  // ... other fields
}
```
**Use case**: Detail view for specific object detection
**Problem**: No has_been_reviewed field from server!

### FrigateReviewItem (Time Period with Multiple Objects)
```swift
{
  "id": "1234567890.123",
  "camera": "front_door",
  "start_time": 1234567890.0,
  "end_time": 1234567900.0,
  "has_been_reviewed": false,  ←── KEY FIELD!
  "severity": "alert",
  "thumb_path": "/media/frigate/...",
  "data": {
    "objects": ["person", "person", "car"],
    "zones": ["porch", "driveway"]
  }
}
```
**Use case**: Home feed showing review items
**Benefit**: Server provides has_been_reviewed state!

## User Workflow Comparison

### Current (Broken)
```
1. User opens app
2. App fetches Events from /api/events
3. App checks client-side viewedEventIds
4. Events show with red badge if not in viewedEventIds
5. User taps event → detail view
6. App saves event.id to viewedEventIds (local only!)
7. Badge disappears based on local state
8. Server never knows event was reviewed
9. Other devices don't see review state
```
**Problems**: 
- No server synchronization
- Review state lost on reinstall
- Doesn't match Frigate's review workflow

### Refactored (Correct)
```
1. User opens app
2. App fetches Review Items from /api/review?reviewed=0
3. Review items show with red badge if has_been_reviewed=false
4. User taps review item → detail view
5. On view/dismiss, app POSTs to /api/reviews/viewed
6. Server sets has_been_reviewed=true
7. App updates local state immediately (optimistic update)
8. Next refresh shows updated state from server
9. Items older than 3 days + reviewed are filtered out
10. All devices see synchronized review state
```
**Benefits**:
- Server is source of truth
- Works across devices
- Matches Frigate's canonical workflow
- Persistent review state

## API Call Frequency

### Current
```
Every 2 seconds:
  - GET /api/events?limit=100  ✅ Called
  - GET /api/review?reviewed=0  ❌ Not called (code exists but skipped)
```

### Refactored
```
Every 2 seconds (or configurable):
  - GET /api/review?reviewed=0&limit=100  ✅ PRIMARY
  
On user interaction:
  - POST /api/reviews/viewed  ✅ When user views item
```

## Badge Logic Comparison

### Current (Client-Side)
```swift
func isEventUnreviewed(_ event: FrigateEvent) -> Bool {
    // Check client-side Set
    let notViewed = !viewedEventIds.contains(event.id)
    
    // Check if in reviewItems (but reviewItems is empty!)
    let notReviewed = reviewItems.first { $0.id == event.id }?.has_been_reviewed == false
    
    return notViewed || notReviewed
}
```
**Problem**: reviewItems is always empty, falls back to client state

### Refactored (Server-Side)
```swift
// In ReviewItemCardView
var isUnreviewed: Bool {
    return !review.has_been_reviewed
}
```
**Benefit**: Single source of truth from server

## File Changes Summary

### Files to Modify
- [x] `ContentView.swift` - Switch to reviewItems as primary
- [x] `FrigateEventAPIClient.swift` - Debug why review API not called
- [ ] `FrigateEvent.swift` - Make has_been_reviewed mutable

### Files to Create
- [ ] `ReviewItemCardView.swift` - New component for review items

### Files to Check
- [ ] `EventDetailView.swift` - Update to accept review items
- [ ] `SettingsView.swift` - Add review-specific settings?

## Migration Path

### Phase 1: Debug (1-2 hours)
1. Test `/api/review` endpoint with curl
2. Add logging to `fetchReviewItems()`
3. Identify why API call isn't executing

### Phase 2: Data Layer (2-3 hours)
1. Switch `refreshEvents()` to prioritize review API
2. Make `reviewItems` the primary display source
3. Update filter logic for review items

### Phase 3: UI Layer (3-4 hours)
1. Create `ReviewItemCardView` component
2. Update ContentView to use reviewItems
3. Implement mark-as-reviewed workflow

### Phase 4: Testing (2-3 hours)
1. Test complete review cycle
2. Verify 3-day filter works
3. Test cross-device synchronization
4. Polish UI/UX

**Total Estimate**: 8-12 hours

## Success Metrics

### Before Refactoring
- ❌ Review API never called
- ❌ Review state not synchronized
- ❌ Client-side tracking only
- ❌ No cross-device sync
- ❌ Review items unused

### After Refactoring
- ✅ Review API called every refresh
- ✅ Server provides review state
- ✅ Badge reflects server state
- ✅ Marking as reviewed updates server
- ✅ 3-day filter works correctly
- ✅ Cross-device synchronization
- ✅ Matches Frigate canonical workflow
