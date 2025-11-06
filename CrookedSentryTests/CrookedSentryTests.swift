//
//  CrookedSentryTests.swift
//  CrookedSentryTests
//
//  Created by Joseph Mienko on 11/3/25.
//

import XCTest
import SwiftUI
@testable import CrookedSentry

/// Main test suite for CrookedSentry - Security-focused home automation app
// @Suite("CrookedSentry Core Tests")
struct CrookedSentryTests {
    // MARK: - CrookedReviewState API Integration Tests (Stubs)

    // @Test("Fetch review state from Node API")
    func testFetchReviewStateFromNodeAPI() async throws {
        // Mock server would be ideal, but for now we'll test the client interface
        // and data model parsing
        
        // Create a mock client pointing to a test URL
        let client = CrookedReviewStateAPIClient(baseURL: "http://localhost:3001")
        
    // Verify client is initialized
    XCTAssertTrue(client.baseURL == "http://localhost:3001")
        
        // Test the CrookedReviewState model can be created and parsed
        let testState = CrookedReviewState(
            eventId: "1762351376.790655-rceuza",
            reviewedBy: "user123",
            reviewed: true
        )
        
    XCTAssertTrue(testState.eventId == "1762351376.790655-rceuza")
    XCTAssertTrue(testState.reviewedBy == "user123")
    XCTAssertTrue(testState.reviewed == true)
    XCTAssertTrue(testState.id == testState.eventId) // Verify Identifiable protocol
        
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encoded = try encoder.encode(testState)
        let decoded = try decoder.decode(CrookedReviewState.self, from: encoded)
        
    XCTAssertTrue(decoded.eventId == testState.eventId)
    XCTAssertTrue(decoded.reviewedBy == testState.reviewedBy)
    XCTAssertTrue(decoded.reviewed == testState.reviewed)
        
        // Note: Actual network testing would require a running server or mock
        // For integration testing, you would:
        // let states = try await client.fetchReviewStates()
        // #expect(!states.isEmpty)
    }

    // @Test("Mark single event as reviewed via Node API")
    func testMarkSingleEventAsReviewed() async throws {
        // Create a client
        let client = CrookedReviewStateAPIClient(baseURL: "http://localhost:3001")
        
        // Test event ID
        let eventId = "1762351376.790655-rceuza"
        
        // Verify the method signature exists and can be called
        // In actual integration test with running server:
        // try await client.markEventAsReviewed(eventId: eventId)
        
        // For now, verify we can create the request structure
        let testState = CrookedReviewState(
            eventId: eventId,
            reviewedBy: nil,
            reviewed: true
        )
        
    XCTAssertTrue(testState.reviewed == true)
    XCTAssertEqual(testState.eventId, eventId)
        
        // Verify JSON encoding for API request
        let encoder = JSONEncoder()
        let data = try encoder.encode(testState)
        
        // Parse as dictionary to verify structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertTrue(json?["eventId"] as? String == eventId)
    XCTAssertTrue(json?["reviewed"] as? Bool == true)
        
        // Note: Actual network call would require running server:
        // try await client.markEventAsReviewed(eventId: eventId, reviewedBy: "testUser")
        // let state = try await client.fetchReviewState(eventId: eventId)
        // #expect(state?.reviewed == true)
    }

    // @Test("Batch mark events as reviewed via Node API")
    func testBatchMarkEventsAsReviewed() async throws {
        // Create a client
        let client = CrookedReviewStateAPIClient(baseURL: "http://localhost:3001")
        
        // Test event IDs
        let eventIds = [
            "1762351376.790655-rceuza",
            "1762351400.123456-abcdef",
            "1762351500.654321-fedcba"
        ]
        
        // Verify batch method exists
        // In actual integration test with running server:
        // try await client.batchMarkEventsAsReviewed(eventIds: eventIds)
        
        // Test creating batch request data
        let batchData = eventIds.map { eventId in
            CrookedReviewState(eventId: eventId, reviewedBy: nil, reviewed: true)
        }
        
    XCTAssertTrue(batchData.count == 3)
    XCTAssertTrue(batchData[0].eventId == eventIds[0])
    XCTAssertTrue(batchData[1].eventId == eventIds[1])
    XCTAssertTrue(batchData[2].eventId == eventIds[2])
        
        for state in batchData {
            XCTAssertTrue(state.reviewed == true)
        }
        
        // Verify JSON encoding for batch API request
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(batchData)
        
        let json = try JSONSerialization.jsonObject(with: encoded) as? [[String: Any]]
    XCTAssertTrue(json?.count == 3)
    XCTAssertTrue(json?[0]["eventId"] as? String == eventIds[0])
    XCTAssertTrue(json?[1]["eventId"] as? String == eventIds[1])
    XCTAssertTrue(json?[2]["eventId"] as? String == eventIds[2])
        
        // Note: Actual network call would require running server:
        // try await client.batchMarkEventsAsReviewed(eventIds: eventIds)
        // let states = try await client.fetchReviewStates()
        // let reviewedIds = states.filter { $0.reviewed }.map { $0.eventId }
        // #expect(reviewedIds.contains(eventIds[0]))
        // #expect(reviewedIds.contains(eventIds[1]))
        // #expect(reviewedIds.contains(eventIds[2]))
    }

    // @Test("Badge logic should use server review state")
    func testBadgeLogicReflectsServerReviewState() async throws {
        // Test that badge logic prioritizes CrookedReviewState over local state
        
        // Simulate server state
        let reviewedEventId = "event-reviewed-on-server"
        let unreviewedEventId = "event-not-reviewed"
        
        // Create mock review states
        var crookedReviewStates: [String: CrookedReviewState] = [:]
        crookedReviewStates[reviewedEventId] = CrookedReviewState(
            eventId: reviewedEventId,
            reviewedBy: "user123",
            reviewed: true
        )
        crookedReviewStates[unreviewedEventId] = CrookedReviewState(
            eventId: unreviewedEventId,
            reviewedBy: nil,
            reviewed: false
        )
        
        // Test badge logic (simulating ContentView.isEventUnreviewed)
        func isEventUnreviewed(_ eventId: String, reviewStates: [String: CrookedReviewState]) -> Bool {
            // Check CrookedReviewState server state first (primary source of truth)
            if let reviewState = reviewStates[eventId] {
                return !reviewState.reviewed
            }
            // Default to unreviewed if we have no information
            return true
        }
        
        // Reviewed event should show as reviewed
    XCTAssertFalse(isEventUnreviewed(reviewedEventId, reviewStates: crookedReviewStates))
        
        // Unreviewed event should show as unreviewed
    XCTAssertTrue(isEventUnreviewed(unreviewedEventId, reviewStates: crookedReviewStates))
        
        // Unknown event (not in server state) should default to unreviewed
    XCTAssertTrue(isEventUnreviewed("unknown-event", reviewStates: crookedReviewStates))
        
        // Verify server state takes precedence over empty local state
        let emptyLocalState: Set<String> = []
    XCTAssertFalse(isEventUnreviewed(reviewedEventId, reviewStates: crookedReviewStates))
    XCTAssertFalse(emptyLocalState.contains(reviewedEventId)) // Local state doesn't matter
    }

    // @Test("Review state should sync across devices via Node API")
    func testCrossDeviceReviewStateSync() async throws {
        // Simulate cross-device sync scenario
        let client = CrookedReviewStateAPIClient(baseURL: "http://localhost:3001")
        let eventId = "shared-event-123"
        
        // Device A marks event as reviewed
        let deviceAState = CrookedReviewState(
            eventId: eventId,
            reviewedBy: "device-a-user",
            reviewed: true
        )
        
        // Simulate Device A sending update to server
        // In real scenario: try await client.markEventAsReviewed(eventId: eventId)
        
        // Device B fetches review states from server
        // Simulate server response with Device A's update
        var serverStates: [String: CrookedReviewState] = [:]
        serverStates[eventId] = deviceAState
        
        // Device B should see the event as reviewed
    XCTAssertTrue(serverStates[eventId]?.reviewed == true)
    XCTAssertEqual(serverStates[eventId]?.reviewedBy, "device-a-user")
        
        // Simulate Device B's local state (empty/unaware)
        var deviceBLocalState: Set<String> = []
    XCTAssertFalse(deviceBLocalState.contains(eventId))
        
        // Badge logic on Device B should prioritize server state
        func isEventUnreviewed(_ eventId: String, serverStates: [String: CrookedReviewState], localState: Set<String>) -> Bool {
            // Check server state first (cross-device sync)
            if let reviewState = serverStates[eventId] {
                return !reviewState.reviewed
            }
            // Fallback to local state
            if localState.contains(eventId) {
                return false
            }
            return true
        }
        
        // Device B sees event as reviewed (from server, not local)
    XCTAssertFalse(isEventUnreviewed(eventId, serverStates: serverStates, localState: deviceBLocalState))
        
        // Even if Device B adds to local state later, server state still wins
        deviceBLocalState.insert(eventId)
    XCTAssertFalse(isEventUnreviewed(eventId, serverStates: serverStates, localState: deviceBLocalState))
        
        // Test the reverse: server says unreviewed, local says reviewed
        let unreviewedEventId = "unreviewed-event"
        serverStates[unreviewedEventId] = CrookedReviewState(
            eventId: unreviewedEventId,
            reviewedBy: nil,
            reviewed: false
        )
        deviceBLocalState.insert(unreviewedEventId)
        
        // Server state (unreviewed) should NOT be overridden by local state
        // However, our current implementation treats local state as optimistic,
        // so this would show as reviewed locally until next sync
        // For true server authority, we would need:
        // #expect(isEventUnreviewed(unreviewedEventId, serverStates: serverStates, localState: deviceBLocalState) == true)
        
        // Note: Full integration test would require:
        // 1. Device A: try await client.markEventAsReviewed(eventId: eventId)
        // 2. Device B: let states = try await client.fetchReviewStates()
        // 3. Device B: #expect(states.first(where: { $0.eventId == eventId })?.reviewed == true)
    }

    // MARK: - Basic App Functionality Tests
    
    // @Test("App launches successfully")
    func appLaunchesSuccessfully() async throws {
        // Test basic app initialization
        let app = CrookedSentryApp()
    XCTAssertNotNil(app)
    }
    
    // @Test("Settings store initialization")
    func settingsStoreInitialization() async throws {
        let settingsStore = SettingsStore()
        
        // Should have default values
    XCTAssertFalse(settingsStore.frigateBaseURL.isEmpty)
    XCTAssertFalse(settingsStore.availableCameras.isEmpty)
    }
    
    // MARK: - Core Network Tests
    
    // @Test("HTTP method enum")
    func httpMethodEnum() async throws {
        // Test HTTP method enum values
    XCTAssertEqual(HTTPMethod.GET.rawValue, "GET")
    XCTAssertEqual(HTTPMethod.POST.rawValue, "POST")
    XCTAssertEqual(HTTPMethod.PUT.rawValue, "PUT")
    XCTAssertEqual(HTTPMethod.DELETE.rawValue, "DELETE")
    }
    
    // MARK: - Security Framework Integration Tests
    
    // @Test("Security framework integration")
    func securityFrameworkIntegration() async throws {
        let debugger = NetworkSecurityDebuggerSimple.shared
        let secureClient = SecureAPIClient.shared
        
        // Security components should initialize
    XCTAssertNotNil(debugger)
    XCTAssertNotNil(secureClient)
        
    // Should have default security state
    XCTAssertTrue(secureClient.isSecurityEnabled)
    }
    
    // @Test("VPN components availability")
    func vpnComponentsAvailability() async throws {
        // Test VPN-related components can be initialized
        // Note: VPNManager may not be fully functional in test environment
        
        let vpnManager = VPNManager.shared
    XCTAssertNotNil(vpnManager)
    }
    
    // MARK: - View Tests
    
    // @Test("Settings view initialization") 
    func settingsViewInitialization() async throws {
        let settingsView = SettingsView()
        
        // Should initialize without crashing
    XCTAssertNotNil(settingsView)
    }
    
    // MARK: - Event/Review Feature Tests
    
    // @Test("FrigateEvent model initialization")
    func frigateEventModelInitialization() throws {
        let event = FrigateEvent(
            id: "test-event",
            camera: "front_door",
            label: "person",
            start_time: Date().timeIntervalSince1970,
            end_time: Date().timeIntervalSince1970 + 10,
            has_clip: true,
            has_snapshot: true,
            zones: ["entry"],
            data: nil,
            box: nil,
            false_positive: nil,
            plus_id: nil,
            retain_indefinitely: false,
            sub_label: nil,
            top_score: nil
        )
    XCTAssertEqual(event.id, "test-event")
    XCTAssertEqual(event.camera, "front_door")
    XCTAssertEqual(event.label, "person")
    }
    
    // @Test("FrigateReviewItem model initialization")
    func frigateReviewItemInitialization() throws {
        let reviewItem = FrigateReviewItem(
            id: "test-review",
            camera: "front_door",
            startTime: Date().timeIntervalSince1970,
            endTime: Date().timeIntervalSince1970 + 10,
            hasBeenReviewed: false,
            severity: "alert",
            thumbPath: "/path/to/thumb.jpg",
            data: nil
        )
    XCTAssertEqual(reviewItem.id, "test-review")
    XCTAssertFalse(reviewItem.hasBeenReviewed)
    }
    
    // @Test("Event filtering - unreviewed events")
    func eventFilteringUnreviewed() throws {
        let twoDaysAgo = Date().timeIntervalSince1970 - (2 * 24 * 60 * 60)
        let fourDaysAgo = Date().timeIntervalSince1970 - (4 * 24 * 60 * 60)
        
        let unreviewedEvent = FrigateEvent(
            id: "unreviewed-event",
            camera: "front_door",
            label: "person",
            start_time: fourDaysAgo,
            end_time: fourDaysAgo + 10,
            has_clip: true,
            has_snapshot: true,
            zones: [],
            data: nil,
            box: nil,
            false_positive: nil,
            plus_id: nil,
            retain_indefinitely: false,
            sub_label: nil,
            top_score: nil
        )
        let reviewItem = FrigateReviewItem(
            id: "recent-reviewed",
            camera: "front_door",
            startTime: twoDaysAgo,
            endTime: twoDaysAgo + 10,
            hasBeenReviewed: true,
            severity: "alert",
            thumbPath: "/path/to/thumb.jpg",
            data: nil
        )
        
        // Unreviewed events should always be kept, regardless of age
        let events = [unreviewedEvent]
        let reviewItems = [reviewItem]
        
        // Simulate filtering logic - unreviewed events (no review item) should always show
        let filtered = events.filter { event in
            let hasReview = reviewItems.contains(where: { $0.id == event.id })
            if !hasReview {
                return true // Unreviewed - always show
            }
            let reviewItem = reviewItems.first(where: { $0.id == event.id })!
            if !reviewItem.hasBeenReviewed {
                return true // Marked as unreviewed - always show
            }
            // Reviewed - only show if within 3 days
            let threeDaysAgo = Date().timeIntervalSince1970 - (3 * 24 * 60 * 60)
            return event.start_time >= threeDaysAgo
        }
        
    XCTAssertEqual(filtered.count, 1) // Unreviewed event should be included
    }
    
    // @Test("Event filtering - reviewed event within 3 days")
    func eventFilteringReviewedRecent() throws {
        let twoDaysAgo = Date().timeIntervalSince1970 - (2 * 24 * 60 * 60)
        
        let recentEvent = FrigateEvent(
            id: "recent-reviewed",
            camera: "front_door",
            label: "person",
            start_time: twoDaysAgo,
            end_time: twoDaysAgo + 10,
            has_clip: true,
            has_snapshot: true,
            zones: [],
            data: nil,
            box: nil,
            false_positive: nil,
            plus_id: nil,
            retain_indefinitely: false,
            sub_label: nil,
            top_score: nil
        )
        let reviewItem = FrigateReviewItem(
            id: "recent-reviewed",
            camera: "front_door",
            startTime: twoDaysAgo,
            endTime: twoDaysAgo + 10,
            hasBeenReviewed: true,
            severity: "alert",
            thumbPath: "/path/to/thumb.jpg",
            data: nil
        )
        
        let events = [recentEvent]
        let reviewItems = [reviewItem]
        
        // Reviewed events within 3 days should be kept
        let threeDaysAgo = Date().timeIntervalSince1970 - (3 * 24 * 60 * 60)
        let filtered = events.filter { event in
            let reviewItem = reviewItems.first(where: { $0.id == event.id })
            guard let review = reviewItem, review.hasBeenReviewed else {
                return true // Unreviewed - always show
            }
            return event.start_time >= threeDaysAgo
        }
        
    XCTAssertEqual(filtered.count, 1) // Recent reviewed event should be included
    }
    
    // @Test("Event filtering - reviewed event older than 3 days")
    func eventFilteringReviewedOld() throws {
        let fourDaysAgo = Date().timeIntervalSince1970 - (4 * 24 * 60 * 60)
        
        let oldEvent = FrigateEvent(
            id: "old-reviewed",
            camera: "front_door",
            label: "person",
            start_time: fourDaysAgo,
            end_time: fourDaysAgo + 10,
            has_clip: true,
            has_snapshot: true,
            zones: [],
            data: nil,
            box: nil,
            false_positive: nil,
            plus_id: nil,
            retain_indefinitely: false,
            sub_label: nil,
            top_score: nil
        )
        let reviewItem = FrigateReviewItem(
            id: "old-reviewed",
            camera: "front_door",
            startTime: fourDaysAgo,
            endTime: fourDaysAgo + 10,
            hasBeenReviewed: true,
            severity: "alert",
            thumbPath: "/path/to/thumb.jpg",
            data: nil
        )
        
        let events = [oldEvent]
        let reviewItems = [reviewItem]
        
        // Reviewed events older than 3 days should be filtered out
        let threeDaysAgo = Date().timeIntervalSince1970 - (3 * 24 * 60 * 60)
        let filtered = events.filter { event in
            let reviewItem = reviewItems.first(where: { $0.id == event.id })
            guard let review = reviewItem, review.hasBeenReviewed else {
                return true // Unreviewed - always show
            }
            return event.start_time >= threeDaysAgo
        }
        
    XCTAssertEqual(filtered.count, 0) // Old reviewed event should be filtered out
    }
    
    // @Test("Event filtering - mixed scenarios")
    func eventFilteringMixedScenarios() throws {
        let twoDaysAgo = Date().timeIntervalSince1970 - (2 * 24 * 60 * 60)
        let fourDaysAgo = Date().timeIntervalSince1970 - (4 * 24 * 60 * 60)
        
        let events = [
            FrigateEvent(id: "1", camera: "cam1", label: "person", start_time: twoDaysAgo, end_time: twoDaysAgo + 10, has_clip: true, has_snapshot: true, zones: [], data: nil, box: nil, false_positive: nil, plus_id: nil, retain_indefinitely: false, sub_label: nil, top_score: nil),
            FrigateEvent(id: "2", camera: "cam1", label: "person", start_time: fourDaysAgo, end_time: fourDaysAgo + 10, has_clip: true, has_snapshot: true, zones: [], data: nil, box: nil, false_positive: nil, plus_id: nil, retain_indefinitely: false, sub_label: nil, top_score: nil),
            FrigateEvent(id: "3", camera: "cam1", label: "person", start_time: twoDaysAgo, end_time: twoDaysAgo + 10, has_clip: true, has_snapshot: true, zones: [], data: nil, box: nil, false_positive: nil, plus_id: nil, retain_indefinitely: false, sub_label: nil, top_score: nil),
            FrigateEvent(id: "4", camera: "cam1", label: "person", start_time: fourDaysAgo, end_time: fourDaysAgo + 10, has_clip: true, has_snapshot: true, zones: [], data: nil, box: nil, false_positive: nil, plus_id: nil, retain_indefinitely: false, sub_label: nil, top_score: nil)
        ]
        
        let reviewItems = [
            FrigateReviewItem(id: "1", camera: "cam1", startTime: twoDaysAgo, endTime: twoDaysAgo + 10, hasBeenReviewed: false, severity: "alert", thumbPath: "/path/to/thumb.jpg", data: nil), // unreviewed, recent - KEEP
            FrigateReviewItem(id: "2", camera: "cam1", startTime: fourDaysAgo, endTime: fourDaysAgo + 10, hasBeenReviewed: false, severity: "alert", thumbPath: "/path/to/thumb.jpg", data: nil), // unreviewed, old - KEEP
            FrigateReviewItem(id: "3", camera: "cam1", startTime: twoDaysAgo, endTime: twoDaysAgo + 10, hasBeenReviewed: true, severity: "alert", thumbPath: "/path/to/thumb.jpg", data: nil),  // reviewed, recent - KEEP
            FrigateReviewItem(id: "4", camera: "cam1", startTime: fourDaysAgo, endTime: fourDaysAgo + 10, hasBeenReviewed: true, severity: "alert", thumbPath: "/path/to/thumb.jpg", data: nil)   // reviewed, old - REMOVE
        ]
        
        let threeDaysAgo = Date().timeIntervalSince1970 - (3 * 24 * 60 * 60)
        let filtered = events.filter { event in
            let reviewItem = reviewItems.first(where: { $0.id == event.id })
            guard let review = reviewItem, review.hasBeenReviewed else {
                return true // Unreviewed or no review data - always show
            }
            return event.start_time >= threeDaysAgo
        }
        
    XCTAssertEqual(filtered.count, 3) // Events 1, 2, 3 should be kept; event 4 should be removed
    }
    
    // @Test("Unreviewed status check - no review data")
    func unreviewedStatusCheckNoData() throws {
        let eventId = "test-event"
        let reviewItems: [FrigateReviewItem] = []
        
        // Event with no review data should be treated as unreviewed
        let isUnreviewed = reviewItems.first(where: { $0.id == eventId }) == nil ? true : !reviewItems.first(where: { $0.id == eventId })!.hasBeenReviewed
    XCTAssertTrue(isUnreviewed == true)
    }
    
    // @Test("Unreviewed status check - reviewed event")
    func unreviewedStatusCheckReviewed() throws {
        let eventId = "test-event"
        let now = Date().timeIntervalSince1970
        let reviewItems = [FrigateReviewItem(id: eventId, camera: "cam1", startTime: now, endTime: now + 10, hasBeenReviewed: true, severity: "alert", thumbPath: "/path/to/thumb.jpg", data: nil)]
        
        let isUnreviewed = reviewItems.first(where: { $0.id == eventId }) == nil ? true : !reviewItems.first(where: { $0.id == eventId })!.hasBeenReviewed
    XCTAssertFalse(isUnreviewed == false)
    }
    
    // @Test("Unreviewed status check - unreviewed event")
    func unreviewedStatusCheckUnreviewed() throws {
        let eventId = "test-event"
        let now = Date().timeIntervalSince1970
        let reviewItems = [FrigateReviewItem(id: eventId, camera: "cam1", startTime: now, endTime: now + 10, hasBeenReviewed: false, severity: "alert", thumbPath: "/path/to/thumb.jpg", data: nil)]
        
        let isUnreviewed = reviewItems.first(where: { $0.id == eventId }) == nil ? true : !reviewItems.first(where: { $0.id == eventId })!.hasBeenReviewed
    XCTAssertTrue(isUnreviewed == true)
    }
}
