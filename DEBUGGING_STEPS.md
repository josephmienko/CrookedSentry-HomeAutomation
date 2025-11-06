# Debugging Steps - Execute These First

## Step 1: Test Review API Endpoint Directly

### Test if `/api/review` endpoint exists on your Frigate instance

```bash
# Test 1: Basic review endpoint (no auth)
curl -v "http://192.168.0.200:5000/api/review?cameras=all&labels=all&reviewed=0&limit=10"

# Test 2: With authentication (if Frigate requires it)
curl -v "http://192.168.0.200:5000/api/review?cameras=all&labels=all&reviewed=0&limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Test 3: Check Frigate version
curl "http://192.168.0.200:5000/api/version"

# Test 4: List all available endpoints
curl "http://192.168.0.200:5000/api/"
```

### Expected Results

**If Review API EXISTS (v0.14+):**
```json
[
  {
    "id": "1234567890.123",
    "camera": "front_door",
    "start_time": 1234567890.0,
    "end_time": 1234567900.0,
    "has_been_reviewed": false,
    "severity": "alert",
    "thumb_path": "/media/frigate/...",
    "data": {
      "objects": ["person"],
      "zones": ["porch"]
    }
  }
]
```

**If Review API DOESN'T EXIST:**
```json
{
  "error": "Not Found"
}
```
or
```
404 Not Found
```

### What to Do Based on Results

#### ✅ If API Works (Returns JSON Array)
→ **Proceed to Step 2** - The problem is in the Swift code, not Frigate

#### ❌ If API Returns 404/Not Found
→ **Your Frigate version doesn't support Review API**
→ **Options:**
   1. Upgrade Frigate to v0.14 or later
   2. Continue using Events API with client-side tracking
   3. Implement a hybrid approach

#### ⚠️ If API Returns 401/403 (Authentication Error)
→ **Check authentication headers**
→ **Verify your SettingsStore has correct credentials**
→ **Compare with working Events API headers**

---

## Step 2: Add Debug Logging to Swift Code

### File: `FrigateEventAPIClient.swift`

Find the `fetchReviewItems()` function and add extensive logging:

```swift
func fetchReviewItems(
    cameras: String = "all",
    labels: String = "all",
    zones: String = "all",
    reviewed: Int = 0,
    limit: Int = 1000,
    severity: String? = nil,
    before: Double? = nil,
    after: Double? = nil
) async throws -> [FrigateReviewItem] {
    
    // ⭐️ ADD THESE DEBUG LOGS
    print("🔍🔍🔍 ============================================")
    print("🔍 FETCH REVIEW ITEMS CALLED")
    print("🔍 Base URL: \(baseURL)")
    print("🔍 Cameras: \(cameras)")
    print("🔍 Labels: \(labels)")
    print("🔍 Reviewed: \(reviewed)")
    print("🔍 Limit: \(limit)")
    
    var components = URLComponents(string: "\(baseURL)/api/review")!
    
    // Build query parameters
    var queryItems: [URLQueryItem] = [
        URLQueryItem(name: "cameras", value: cameras),
        URLQueryItem(name: "labels", value: labels),
        URLQueryItem(name: "zones", value: zones),
        URLQueryItem(name: "reviewed", value: String(reviewed)),
        URLQueryItem(name: "limit", value: String(limit))
    ]
    
    if let severity = severity {
        queryItems.append(URLQueryItem(name: "severity", value: severity))
    }
    
    if let before = before {
        queryItems.append(URLQueryItem(name: "before", value: String(before)))
    }
    
    if let after = after {
        queryItems.append(URLQueryItem(name: "after", value: String(after)))
    }
    
    components.queryItems = queryItems
    
    guard let url = components.url else {
        print("❌ Invalid URL for review items")
        throw NetworkError.invalidURL
    }
    
    // ⭐️ ADD THIS LOG
    print("🔍 Full URL: \(url.absoluteString)")
    print("🔍🔍🔍 ============================================")
    
    print("🌐 FrigateAPIClient: Fetching review items from: \(url.absoluteString)")
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    // Add headers (authentication, etc.)
    if let headers = headers {
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        // ⭐️ ADD THIS LOG
        print("🔍 Headers: \(headers)")
    } else {
        print("⚠️ No headers provided")
    }
    
    do {
        print("📡 Making request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw NetworkError.invalidResponse
        }
        
        // ⭐️ ADD THESE LOGS
        print("📡 Response Status: \(httpResponse.statusCode)")
        print("📡 Response Headers: \(httpResponse.allHeaderFields)")
        print("📡 Response Body Length: \(data.count) bytes")
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Response Body Preview: \(jsonString.prefix(500))")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            if let errorBody = String(data: data, encoding: .utf8) {
                print("❌ Error Body: \(errorBody)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let reviewItems = try decoder.decode([FrigateReviewItem].self, from: data)
        print("✅ Successfully decoded \(reviewItems.count) review items")
        
        // ⭐️ ADD THIS LOG
        if let firstItem = reviewItems.first {
            print("✅ First item: id=\(firstItem.id), camera=\(firstItem.camera), has_been_reviewed=\(firstItem.has_been_reviewed)")
        }
        
        return reviewItems
        
    } catch let decodingError as DecodingError {
        print("❌ Decoding error: \(decodingError)")
        // Print detailed decoding error
        switch decodingError {
        case .keyNotFound(let key, let context):
            print("❌ Missing key: \(key), context: \(context)")
        case .typeMismatch(let type, let context):
            print("❌ Type mismatch: \(type), context: \(context)")
        case .valueNotFound(let type, let context):
            print("❌ Value not found: \(type), context: \(context)")
        case .dataCorrupted(let context):
            print("❌ Data corrupted: \(context)")
        @unknown default:
            print("❌ Unknown decoding error")
        }
        throw decodingError
    } catch {
        print("❌ Network error: \(error.localizedDescription)")
        throw error
    }
}
```

### File: `ContentView.swift`

Find the `refreshEvents()` function and add logging:

```swift
func refreshEvents() async {
    print("🔄🔄🔄 ============================================")
    print("🔄 REFRESH EVENTS CALLED")
    print("🔄🔄🔄 ============================================")
    
    // Fetch events
    print("🔄 Fetching events...")
    await fetchEvents()
    print("🔄 Events fetched: \(events.count)")
    
    // Fetch review items
    print("🔄 Fetching review items...")
    await fetchReviewItems()
    print("🔄 Review items fetched: \(reviewItems.count)")
    
    print("🔄🔄🔄 ============================================")
}
```

Find the `fetchReviewItems()` function and add logging:

```swift
func fetchReviewItems() async {
    print("📋📋📋 ============================================")
    print("📋 FETCH REVIEW ITEMS (ContentView) CALLED")
    print("📋📋📋 ============================================")
    
    do {
        let items = try await apiClient.fetchReviewItems(
            cameras: "all",
            labels: "all",
            zones: "all",
            reviewed: 0,
            limit: 1000
        )
        
        print("📋 Received \(items.count) review items")
        
        reviewItems = items
        
        print("📋 Updated reviewItems array: \(reviewItems.count) items")
        
        // Log first few items
        for (index, item) in reviewItems.prefix(3).enumerated() {
            print("📋 Item \(index): id=\(item.id), camera=\(item.camera), reviewed=\(item.has_been_reviewed)")
        }
        
    } catch {
        print("❌ Error fetching review items: \(error)")
        print("❌ Error type: \(type(of: error))")
        print("❌ Error description: \(error.localizedDescription)")
    }
    
    print("📋📋📋 ============================================")
}
```

---

## Step 3: Run the App and Collect Logs

### In Xcode:
1. Open the app in Xcode
2. Open the **Console** (View → Debug Area → Activate Console)
3. Run the app
4. Watch for log output

### What to Look For:

#### ✅ Success Pattern:
```
🔄🔄🔄 ============================================
🔄 REFRESH EVENTS CALLED
🔄🔄🔄 ============================================
🔄 Fetching events...
🌐 FrigateAPIClient: Fetching events...
✅ Successfully decoded 100 events
🔄 Events fetched: 100
🔄 Fetching review items...
📋📋📋 ============================================
📋 FETCH REVIEW ITEMS (ContentView) CALLED
📋📋📋 ============================================
🔍🔍🔍 ============================================
🔍 FETCH REVIEW ITEMS CALLED
🔍 Base URL: http://192.168.0.200:5000
🔍 Full URL: http://192.168.0.200:5000/api/review?cameras=all&reviewed=0...
🔍🔍🔍 ============================================
🌐 FrigateAPIClient: Fetching review items from: ...
📡 Response Status: 200
📄 Response Body Preview: [{"id":"123"...
✅ Successfully decoded 50 review items
📋 Received 50 review items
📋 Updated reviewItems array: 50 items
```

#### ❌ Failure Pattern 1 (API Never Called):
```
🔄 REFRESH EVENTS CALLED
🔄 Fetching events...
✅ Successfully decoded 100 events
🔄 Events fetched: 100
🔄 Fetching review items...
// ← NO "📋 FETCH REVIEW ITEMS (ContentView) CALLED"
// ← This means fetchReviewItems() is never executed
```
**Diagnosis**: Check if `fetchReviewItems()` is actually being called in `refreshEvents()`

#### ❌ Failure Pattern 2 (API Called But Fails):
```
📋 FETCH REVIEW ITEMS (ContentView) CALLED
🔍 FETCH REVIEW ITEMS CALLED
📡 Response Status: 404
❌ HTTP Error: 404
❌ Error Body: {"error":"Not Found"}
```
**Diagnosis**: Frigate doesn't support `/api/review` endpoint

#### ❌ Failure Pattern 3 (Authentication Error):
```
📡 Response Status: 401
❌ HTTP Error: 401
```
**Diagnosis**: Check authentication headers

---

## Step 4: Check ContentView's refreshEvents() Call

### Verify the function is wired up correctly:

```swift
// Find where refreshEvents() is called
.task {
    await refreshEvents()
}

.refreshable {
    await refreshEvents()
}
```

### Check if there's a timer:
```swift
Timer.publish(every: 2, on: .main, in: .common)
    .autoconnect()
    .sink { _ in
        Task {
            await refreshEvents()
        }
    }
```

**Look for**: Any condition that might skip `fetchReviewItems()` call

---

## Step 5: Compare with Working Events API

### Side-by-side comparison:

```swift
// Events API (WORKS)
func fetchEvents() async {
    do {
        events = try await apiClient.fetchEvents(
            cameras: selectedCamera == "all" ? nil : selectedCamera,
            labels: selectedLabel == "all" ? nil : selectedLabel,
            zones: selectedZone == "all" ? nil : selectedZone,
            limit: 100
        )
    } catch {
        print("Error: \(error)")
    }
}

// Review API (DOESN'T WORK)
func fetchReviewItems() async {
    do {
        reviewItems = try await apiClient.fetchReviewItems(
            cameras: "all",
            labels: "all",
            zones: "all",
            reviewed: 0,
            limit: 1000
        )
    } catch {
        print("Error: \(error)")
    }
}
```

**Check**: Are they structured identically? Any differences that could cause one to work and not the other?

---

## Step 6: Test Review API Independently

### Create a test function in ContentView:

```swift
func testReviewAPI() async {
    print("🧪🧪🧪 TESTING REVIEW API 🧪🧪🧪")
    
    do {
        let items = try await apiClient.fetchReviewItems(reviewed: 0, limit: 10)
        print("🧪 SUCCESS: Got \(items.count) items")
        for item in items {
            print("🧪   - \(item.id): \(item.camera), reviewed=\(item.has_been_reviewed)")
        }
    } catch {
        print("🧪 FAILED: \(error)")
    }
    
    print("🧪🧪🧪 TEST COMPLETE 🧪🧪🧪")
}
```

### Call it from a button:

```swift
Button("Test Review API") {
    Task {
        await testReviewAPI()
    }
}
```

---

## Expected Timeline

### Phase 1: curl Testing (5 minutes)
- Run curl commands
- Verify endpoint exists
- Check response format

### Phase 2: Add Logging (15 minutes)
- Add debug logs to FrigateEventAPIClient
- Add debug logs to ContentView
- Rebuild app

### Phase 3: Run & Analyze (10 minutes)
- Run app in Xcode
- Watch console output
- Identify failure point

### Phase 4: Fix Issue (30-60 minutes)
- Based on logs, implement fix
- Could be authentication, endpoint, or code flow
- Test fix

**Total Time**: ~1-2 hours to debug

---

## Common Issues & Solutions

### Issue 1: Review API Not Called At All
**Symptom**: No "🔍 FETCH REVIEW ITEMS CALLED" in logs
**Solution**: Check if `fetchReviewItems()` is actually invoked in `refreshEvents()`

### Issue 2: 404 Not Found
**Symptom**: "Response Status: 404"
**Solution**: Upgrade Frigate or use Events API fallback

### Issue 3: Authentication Error
**Symptom**: "Response Status: 401"
**Solution**: Copy headers from working Events API call

### Issue 4: Decoding Error
**Symptom**: "Decoding error: keyNotFound..."
**Solution**: Check if response format matches `FrigateReviewItem` struct

### Issue 5: Silent Failure
**Symptom**: No logs, no errors
**Solution**: Check if function is inside a try-catch that swallows errors

---

## Next Steps After Debugging

Once you identify the issue:

1. **If Review API works**: Proceed with refactoring plan
2. **If Review API fails**: Decide on fallback strategy
3. **If authentication issue**: Fix headers and retry
4. **If version issue**: Upgrade Frigate or use Events API

Report back with:
- curl test results
- Console log output
- Any error messages
- Frigate version number

Then we can proceed with the appropriate solution! 🚀
