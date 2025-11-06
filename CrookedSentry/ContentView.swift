//
//  ContentView.swift
//  Crooked Sentry
//
//  Created by Chris LaPointe on 2024
//

import SwiftUI
import Foundation
import Combine

import Combine
import AVKit
import UIKit

@MainActor
struct ContentView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @StateObject private var apiClient: FrigateAPIClient
    @State private var reviewStateClient: CrookedReviewStateAPIClient?

    init() {
        _apiClient = StateObject(wrappedValue: FrigateAPIClient(baseURL: "")) // Initialized with empty string, will be updated in .onAppear
        print("🚀 ContentView initialized - Crooked Sentry is starting!")
    }

    @State private var events: [FrigateEvent] = []
    @State private var inProgressEvents: [FrigateEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var reviewItems: [FrigateReviewItem] = []
    
    // CrookedReviewState tracking (centralized server state)
    @State private var crookedReviewStates: [String: CrookedReviewState] = [:]
    
    // Client-side review tracking (persisted locally) - deprecated, using server state
    @State private var viewedEventIds: Set<String> = []
    private let viewedEventsKey = "viewedEventIds"    // Timers for polling
    @State private var inProgressTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    @State private var eventsTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    // Filtered events based on the settings
    private func applyFilters(to events: [FrigateEvent]) -> [FrigateEvent] {
        let labelFiltered = settingsStore.selectedLabels.isEmpty ? events : events.filter { settingsStore.selectedLabels.contains($0.label) }
        
        let zoneFiltered = settingsStore.selectedZones.isEmpty ? labelFiltered : labelFiltered.filter { event in
            !event.zones.isEmpty && !Set(event.zones).isDisjoint(with: settingsStore.selectedZones)
        }
        
        let cameraFiltered = settingsStore.selectedCameras.isEmpty ? zoneFiltered : zoneFiltered.filter { settingsStore.selectedCameras.contains($0.camera) }
        
        // Filter by review status: remove reviewed items older than 3 days
        let threeDaysAgo = Date().timeIntervalSince1970 - (3 * 24 * 60 * 60)
        let reviewFiltered = cameraFiltered.filter { event in
            // Check if event is unreviewed OR reviewed within last 3 days
            if isEventUnreviewed(event.id) {
                return true // Show all unreviewed events
            }
            // If reviewed, only show if within 3 days
            return event.start_time >= threeDaysAgo
        }
        
        return reviewFiltered
    }

    private var filteredEvents: [FrigateEvent] {
        applyFilters(to: events)
    }

    private var filteredInProgressEvents: [FrigateEvent] {
        applyFilters(to: inProgressEvents)
    }
    
    // Events for home page - apply 3-day review filter
    private var homePageEvents: [FrigateEvent] {
        let threeDaysAgo = Date().timeIntervalSince1970 - (3 * 24 * 60 * 60)
        return events.filter { event in
            // Show if unreviewed OR reviewed within last 3 days
            if isEventUnreviewed(event.id) {
                return true
            }
            return event.start_time >= threeDaysAgo
        }
    }
    
    // Helper to check if an event is unreviewed
    // MARK: - Review State Management
    
    // Use CrookedReviewState API as source of truth, fallback to Frigate Review API
    // Review items can match events by:
    //   1. Direct ID match (review.id == event.id)
    //   2. Detection match (event.id in review.data.detections)
    // Fallback to client-side tracking if not found in review items
    private func isEventUnreviewed(_ eventId: String) -> Bool {
        // 1) Check CrookedReviewState server state first (primary source of truth)
        if let reviewState = crookedReviewStates[eventId] {
            return !reviewState.reviewed
        }

        // 2) If we've locally marked this event as viewed, consider it reviewed immediately
        if viewedEventIds.contains(eventId) {
            return false
        }

        // 3) Check if this event ID exists as a review item and respect server state
        if let reviewItem = reviewItems.first(where: { $0.id == eventId }) {
            return !reviewItem.hasBeenReviewed
        }

        // 4) Check if this event is part of any review item's detections
        for reviewItem in reviewItems {
            if let detections = reviewItem.data?.detections, detections.contains(eventId) {
                return !reviewItem.hasBeenReviewed
            }
        }

        // 5) Default to unreviewed if we have no information
        return true
    }
    
    private func markEventAsViewed(_ eventId: String) {
        // Mark as viewed locally (for immediate UI update)
        viewedEventIds.insert(eventId)
        
        // Optimistically update CrookedReviewState
        crookedReviewStates[eventId] = CrookedReviewState(eventId: eventId, reviewedBy: nil, reviewed: true)
        
        // Persist to UserDefaults
        if let encoded = try? JSONEncoder().encode(Array(viewedEventIds)) {
            UserDefaults.standard.set(encoded, forKey: viewedEventsKey)
        }
        
        // Mark on CrookedReviewState server (primary)
        Task {
            if let client = reviewStateClient {
                do {
                    try await client.markEventAsReviewed(eventId: eventId)
                    print("✅ Successfully marked event \(eventId) as reviewed on CrookedReviewState API")
                } catch {
                    print("❌ Failed to mark event \(eventId) on CrookedReviewState API: \(error)")
                }
            }
            
            // Also mark on Frigate server (secondary/fallback)
            await markEventAsReviewed(eventId)
        }
    }
    
    private func loadViewedEvents() {
        if let data = UserDefaults.standard.data(forKey: viewedEventsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            viewedEventIds = Set(decoded)
            print("📋 ContentView: Loaded \(viewedEventIds.count) viewed event IDs from storage")
        }
    }

    @ViewBuilder
    private var eventsListView: some View {
        LazyVStack(spacing: 0) {
            // In Progress Events
            ForEach(Array(filteredInProgressEvents.enumerated()), id: \.element.id) { index, event in
                NavigationLink(destination: EventDetailView(event: event, onMarkAsReviewed: { eventId in
                    await markEventAsReviewed(eventId)
                }).environmentObject(settingsStore)) {
                    EventCardView(event: event, isInProgress: true, onMarkAsReviewed: { eventId in
                        await markEventAsReviewed(eventId)
                    })
                        .environmentObject(settingsStore)
                }
                .buttonStyle(.plain)
                
                // Add separator if not the last in-progress event or if there are regular events
                if index < filteredInProgressEvents.count - 1 || !filteredEvents.isEmpty {
                    Rectangle()
                        .fill(Color.outline)
                        .frame(height: 1)
                }
            }
            
            // Regular Events
            ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                NavigationLink(destination: EventDetailView(event: event, onMarkAsReviewed: { eventId in
                    await markEventAsReviewed(eventId)
                }).environmentObject(settingsStore)) {
                    EventCardView(event: event, isInProgress: false, isUnreviewed: isEventUnreviewed(event.id), onMarkAsReviewed: { eventId in
                        await markEventAsReviewed(eventId)
                    })
                        .environmentObject(settingsStore)
                }
                .buttonStyle(.plain)
                
                // Add separator if not the last event
                if index < filteredEvents.count - 1 {
                    Rectangle()
                        .fill(Color.outline)
                        .frame(height: 1)
                }
            }
        }
        .onAppear {
            preloadTopVideos()
        }
        .onDisappear {
            // Cancel any ongoing preloads when leaving the view
            VideoManager.shared.cancelAllPreloads()
        }
    }

    private func preloadTopVideos() {
        print("🚀 ContentView: Starting background preloading of top videos")

        // Preload first 6 videos for faster playback (3 completed + 3 in-progress)
        let eventsToPreload = filteredEvents.prefix(3) + filteredInProgressEvents.prefix(3)

        for event in eventsToPreload {
            if let videoURL = event.clipUrl(baseURL: settingsStore.frigateBaseURL) {
                VideoManager.shared.preloadVideo(for: event.id, from: videoURL)
            }
        }
    }

    var body: some View {
        Group {
            if settingsStore.frigateBaseURL.isEmpty {
                VStack(spacing: 20) {
                    Image("CrookedSentryIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text("Welcome to Crooked Sentry!")
                        .font(.title)
                        .foregroundColor(.onSurface)
                    Text("Please configure your Frigate server settings to get started.")
                        .font(.body)
                        .foregroundColor(.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                    Button("Open Settings") {
                        // This will trigger the settings sheet in the app
                    }
                    .padding()
                    .background(Color.primary)
                    .foregroundColor(.onPrimary)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                NavigationStack {
                    MainContainerView(
                        events: homePageEvents,
                        inProgressEvents: inProgressEvents,
                        errorMessage: errorMessage,
                        isLoading: isLoading,
                        eventsListView: eventsListView,
                        onRefreshEvents: { showLoading in
                            await refreshEvents(showLoadingIndicator: showLoading)
                        }
                    )
                    .environmentObject(settingsStore)
                }
            }
        }
        .onReceive(inProgressTimer) { _ in
            Task {
                // Only fetch if we have a valid base URL
                if !settingsStore.frigateBaseURL.isEmpty {
                    await fetchInProgressEvents(andRefresh: true)
                }
            }
        }
        .onReceive(eventsTimer) { _ in
            Task {
                // Only fetch if we have a valid base URL
                if !settingsStore.frigateBaseURL.isEmpty {
                    await fetchFrigateEvents()
                    await fetchReviewItems() // Also fetch review items on timer
                    await fetchCrookedReviewStates() // Also fetch CrookedReviewStates on timer
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .autoRetryConnection)) { _ in
            Task {
                print("🔄 Auto-retry triggered from notification")
                await refreshEvents(showLoadingIndicator: false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshFromMenu)) { _ in
            Task {
                print("🔄 Refresh triggered from menu")
                await refreshEvents(showLoadingIndicator: true)
            }
        }
        .onAppear {
            print("🚀🚀🚀 ContentView appeared - loading initial data")
            loadViewedEvents() // Load client-side tracking
            Task { 
                print("🚀 Calling refreshEvents on appear...")
                await refreshEvents(showLoadingIndicator: true) 
            }
        }
    }


    private func refreshEvents(showLoadingIndicator: Bool = false) async {
        if showLoadingIndicator {
            isLoading = true
        }
        errorMessage = nil
        apiClient.baseURL = settingsStore.frigateBaseURL
        
        // Initialize CrookedReviewState client if needed
        if reviewStateClient == nil || reviewStateClient?.baseURL != settingsStore.crookedReviewStateBaseURL {
            reviewStateClient = CrookedReviewStateAPIClient(baseURL: settingsStore.crookedReviewStateBaseURL)
            print("🔵 Initialized CrookedReviewState client with baseURL: \(settingsStore.crookedReviewStateBaseURL)")
        }
        
        // Add a 0.5-second delay to make the refresh indicator more visible
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await fetchFrigateEvents()
        await fetchInProgressEvents(andRefresh: false)
        await fetchAvailableCameras() // Fetch available cameras
        await fetchReviewItems() // Fetch review items from Frigate
        await fetchCrookedReviewStates() // Fetch review states from Node API
        if showLoadingIndicator {
            isLoading = false
        }
    }

    private func fetchFrigateEvents() async {
        print("🚀 ContentView: Starting fetchFrigateEvents()")
        print("🚀 ContentView: Using baseURL: \(settingsStore.frigateBaseURL)")
        print("🚀 ContentView: API client baseURL: \(apiClient.baseURL)")
        
        do {
            let fetchedEvents = try await apiClient.fetchEvents()
            print("✅ ContentView: Successfully fetched \(fetchedEvents.count) events")
            events = fetchedEvents
            updateAvailableFilters(from: fetchedEvents)
            // Clear any stored error time on successful fetch
            UserDefaults.standard.removeObject(forKey: "lastNetworkErrorTime")
            
            if fetchedEvents.isEmpty {
                print("⚠️ ContentView: Events array is empty - no events returned from API")
            } else {
                print("📋 ContentView: First event: \(fetchedEvents.first?.id ?? "unknown")")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ ContentView: Error fetching events: \(error)")
            print("❌ ContentView: Error type: \(type(of: error))")
            
            // Store the error time for auto-retry logic
            UserDefaults.standard.set(Date(), forKey: "lastNetworkErrorTime")
        }
    }

    private func fetchInProgressEvents(andRefresh: Bool = true) async {
        do {
            let previousInProgressIds = Set(inProgressEvents.map { $0.id })
            let currentInProgressEvents = try await apiClient.fetchEvents(inProgress: true)
            self.inProgressEvents = currentInProgressEvents
            
            // Also update filters from in-progress events
            updateAvailableFilters(from: currentInProgressEvents)

            if andRefresh {
                let currentInProgressIds = Set(currentInProgressEvents.map { $0.id })
                let finishedEventIds = previousInProgressIds.subtracting(currentInProgressIds)
                if !finishedEventIds.isEmpty {
                    print("🔄 In-progress event(s) finished: \(finishedEventIds). Refreshing main event list after a 1-second delay to allow Frigate to update.")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 1-second delay
                    
                    // Refresh the main events list
                    await fetchFrigateEvents()
                    
                    // Check if the finished events now appear in the main list
                    let mainEventIds = Set(events.map { $0.id })
                    let missingEvents = finishedEventIds.subtracting(mainEventIds)
                    
                    if !missingEvents.isEmpty {
                        print("⚠️ Some finished events not yet in main list: \(missingEvents). Retrying after another 1 second...")
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // Additional 1-second delay
                        await fetchFrigateEvents()
                        
                        // Final check
                        let finalMainEventIds = Set(events.map { $0.id })
                        let stillMissing = finishedEventIds.subtracting(finalMainEventIds)
                        if !stillMissing.isEmpty {
                            print("⚠️ Events still missing after retry: \(stillMissing)")
                        } else {
                            print("✅ All finished events now appear in main list")
                        }
                    } else {
                        print("✅ All finished events successfully moved to main list")
                    }
                }
            }
        } catch {
            // Don't show an error for a background poll, just log it.
            print("Error fetching in-progress events: \(error.localizedDescription)")
            
            // Still store error time for auto-retry, but don't show UI error
            UserDefaults.standard.set(Date(), forKey: "lastNetworkErrorTime")
        }
    }

    private func updateAvailableFilters(from events: [FrigateEvent]) {
        // Update labels
        let allLabels = Set(events.map { $0.label })
        let currentLabels = Set(settingsStore.availableLabels)
        let newLabels = allLabels.union(currentLabels)
        if newLabels.count > currentLabels.count {
            settingsStore.availableLabels = newLabels.sorted()
        }

        // Update zones
        let allZones = Set(events.flatMap { $0.zones })
        let currentZones = Set(settingsStore.availableZones)
        let newZones = allZones.union(currentZones)
        if newZones.count > currentZones.count {
            settingsStore.availableZones = newZones.sorted()
        }
    }

    private func fetchAvailableCameras() async {
        do {
            let cameras = try await apiClient.fetchCameras()
            updateAvailableCameras(from: cameras)
        } catch {
            // Don't show an error for a background poll, just log it.
            print("Error fetching available cameras: \(error.localizedDescription)")
        }
    }

    private func updateAvailableCameras(from cameras: [String]) {
        let currentCameras = Set(settingsStore.availableCameras)
        let newCameras = Set(cameras).union(currentCameras)
        if newCameras.count > currentCameras.count {
            settingsStore.availableCameras = newCameras.sorted()
        }
    }
    
    private func fetchReviewItems() async {
        print("📋📋📋 ============================================")
        print("📋 FETCH REVIEW ITEMS (ContentView) CALLED")
        print("📋📋📋 ============================================")
        
        do {
            // Fetch all review items (both reviewed and unreviewed)
            let items = try await apiClient.fetchReviewItems(reviewed: 0, limit: 1000)
            reviewItems = items
            
            print("✅ ContentView: Successfully fetched \(items.count) review items")
            
            // Log first few items for debugging
            for (index, item) in items.prefix(3).enumerated() {
                print("📋 Review Item \(index):")
                print("   - ID: \(item.id)")
                print("   - Camera: \(item.camera)")
                print("   - Has Been Reviewed: \(item.hasBeenReviewed)")
                print("   - Severity: \(item.severity)")
                if let objects = item.data?.objects {
                    print("   - Objects: \(objects.joined(separator: ", "))")
                }
                if let detections = item.data?.detections {
                    print("   - Detection IDs: \(detections.joined(separator: ", "))")
                }
            }
            
            print("📋📋📋 ============================================")
        } catch {
            print("❌ ContentView: Error fetching review items: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            // Don't show error to user, just log it
        }
    }
    
    private func fetchCrookedReviewStates() async {
        print("🔵🔵🔵 ============================================")
        print("🔵 FETCH CROOKED REVIEW STATES CALLED")
        print("🔵🔵🔵 ============================================")
        
        guard let client = reviewStateClient else {
            print("⚠️ CrookedReviewState client not initialized")
            return
        }
        
        do {
            let states = try await client.fetchReviewStates()
            
            // Convert array to dictionary for fast lookup
            var statesDict: [String: CrookedReviewState] = [:]
            for state in states {
                statesDict[state.eventId] = state
            }
            crookedReviewStates = statesDict
            
            print("✅ ContentView: Successfully fetched \(states.count) review states from CrookedReviewState API")
            
            // Log first few states for debugging
            for (index, state) in states.prefix(3).enumerated() {
                print("🔵 Review State \(index):")
                print("   - Event ID: \(state.eventId)")
                print("   - Reviewed: \(state.reviewed)")
                if let reviewedBy = state.reviewedBy {
                    print("   - Reviewed By: \(reviewedBy)")
                }
            }
            
            print("🔵🔵🔵 ============================================")
        } catch {
            print("❌ ContentView: Error fetching CrookedReviewStates: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            // Don't show error to user, just log it
        }
    }
    
    private func markEventAsReviewed(_ eventId: String) async {
        print("🔔🔔🔔 ============================================")
        print("🔔 MARK EVENT AS REVIEWED CALLED")
        print("🔔 Event ID: \(eventId)")
        print("🔔 Current review items count: \(reviewItems.count)")
        print("🔔🔔🔔 ============================================")
        // If we've already marked this locally, skip duplicate requests
        if viewedEventIds.contains(eventId) {
            print("⏭️ Skipping mark for \(eventId); already marked locally as viewed")
            return
        }
        
        do {
            // Optimistically update local state for instant UI feedback
            if let index = reviewItems.firstIndex(where: { $0.id == eventId }) {
                var updatedItem = reviewItems[index]
                // Create a new copy with hasBeenReviewed = true
                reviewItems[index] = FrigateReviewItem(
                    id: updatedItem.id,
                    camera: updatedItem.camera,
                    startTime: updatedItem.startTime,
                    endTime: updatedItem.endTime,
                    hasBeenReviewed: true,
                    severity: updatedItem.severity,
                    thumbPath: updatedItem.thumbPath,
                    data: updatedItem.data
                )
                print("🔄 Optimistically updated review item \(eventId) to reviewed=true")
            } else {
                print("⚠️ Event \(eventId) not found in reviewItems by direct ID match")
            }
            
            // Also check if any review item contains this event in its detections
            var foundInDetections = false
            for (index, reviewItem) in reviewItems.enumerated() {
                if let detections = reviewItem.data?.detections, detections.contains(eventId) {
                    reviewItems[index] = FrigateReviewItem(
                        id: reviewItem.id,
                        camera: reviewItem.camera,
                        startTime: reviewItem.startTime,
                        endTime: reviewItem.endTime,
                        hasBeenReviewed: true,
                        severity: reviewItem.severity,
                        thumbPath: reviewItem.thumbPath,
                        data: reviewItem.data
                    )
                    print("🔄 Found event \(eventId) in review item \(reviewItem.id), marking as reviewed")
                    foundInDetections = true
                    break
                }
            }
            
            // Always mark as viewed locally so UI updates immediately and we avoid duplicate POSTs
            if !viewedEventIds.contains(eventId) {
                viewedEventIds.insert(eventId)
                if let encoded = try? JSONEncoder().encode(Array(viewedEventIds)) {
                    UserDefaults.standard.set(encoded, forKey: viewedEventsKey)
                }
            }
            if !foundInDetections {
                print("⚠️ Event \(eventId) not found in any review item's detections")
                print("⚠️ Review items: \(reviewItems.map { $0.id })")
            }
            
            // Call API to mark as reviewed on server
            print("📡 Calling API to mark event \(eventId) as reviewed...")
            try await apiClient.markEventAsReviewed(eventId: eventId)
            
            print("✅ Event \(eventId) marked as reviewed via API")
            
            // Refresh review items from server to confirm
            await fetchReviewItems()
            
            print("✅ Review items refreshed after marking event as reviewed")
        } catch {
            print("❌ ContentView: Failed to mark event \(eventId) as reviewed: \(error)")
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SettingsStore())
    }
}
#endif
