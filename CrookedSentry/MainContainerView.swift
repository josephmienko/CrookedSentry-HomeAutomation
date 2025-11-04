//
//  MainContainerView.swift
//  Crooked Sentry
//
//  Created by Assistant on 2025
//

import SwiftUI

struct MainContainerView: View {
    // Events data passed from ContentView
    let events: [FrigateEvent]
    let inProgressEvents: [FrigateEvent]
    let errorMessage: String?
    let isLoading: Bool
    let eventsListView: AnyView
    let onRefreshEvents: (Bool) async -> Void
    
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var selectedSection: AppSection = .home
    @State private var isDrawerOpen = false
    
    // Convert eventsListView to AnyView in init
    init(events: [FrigateEvent], 
         inProgressEvents: [FrigateEvent], 
         errorMessage: String?, 
         isLoading: Bool, 
         eventsListView: some View, 
         onRefreshEvents: @escaping (Bool) async -> Void) {
        self.events = events
        self.inProgressEvents = inProgressEvents
        self.errorMessage = errorMessage
        self.isLoading = isLoading
        self.eventsListView = AnyView(eventsListView)
        self.onRefreshEvents = onRefreshEvents
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Main Content
                VStack(spacing: 0) {
                    // Navigation Bar
                    CustomNavigationBar(
                        title: selectedSection.title,
                        isDrawerOpen: $isDrawerOpen
                    )
                    
                    // Content Area
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        contentView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .offset(x: isDrawerOpen ? 280 : 0)
                .scaleEffect(isDrawerOpen ? 0.9 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isDrawerOpen)
                
                // Navigation Drawer
                if isDrawerOpen {
                    NavigationDrawer(
                        selectedSection: $selectedSection,
                        isDrawerOpen: $isDrawerOpen
                    )
                    .transition(.move(edge: .leading))
                }
                
                // Overlay to close drawer
                if isDrawerOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .offset(x: 280)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isDrawerOpen = false
                            }
                        }
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 100 && abs(gesture.translation.height) < 50 {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isDrawerOpen = true
                        }
                    } else if gesture.translation.width < -100 && abs(gesture.translation.height) < 50 {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isDrawerOpen = false
                        }
                    }
                }
        )
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedSection {
        case .home:
            HomeView()
                .environmentObject(settingsStore)
        case .security:
            SecurityView(
                events: events,
                inProgressEvents: inProgressEvents,
                errorMessage: errorMessage,
                isLoading: isLoading,
                eventsListView: eventsListView,
                onRefreshEvents: onRefreshEvents
            )
            .environmentObject(settingsStore)
        case .media:
            MediaView()
                .environmentObject(settingsStore)
        case .climate:
            ClimateView()
                .environmentObject(settingsStore)
        case .settings:
            SettingsView()
                .environmentObject(settingsStore)
        }
    }
}

struct CustomNavigationBar: View {
    let title: String
    @Binding var isDrawerOpen: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isDrawerOpen.toggle()
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            Spacer()
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Placeholder for potential action buttons
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
}

// Preview
struct MainContainerView_Previews: PreviewProvider {
    static var previews: some View {
        MainContainerView(
            events: [],
            inProgressEvents: [],
            errorMessage: nil,
            isLoading: false,
            eventsListView: EmptyView(),
            onRefreshEvents: { _ in }
        )
        .environmentObject(SettingsStore())
    }
}