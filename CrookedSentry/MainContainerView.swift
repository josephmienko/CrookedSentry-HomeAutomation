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
    @State private var securityInitialTab: SecurityTab? = nil
    
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
        ZStack(alignment: .leading) {
            // Main Content
            VStack(spacing: 0) {
                // Navigation Bar
                CustomNavigationBar(
                    title: selectedSection.title,
                    isDrawerOpen: $isDrawerOpen
                )
                
                // Content Area - completely free for scrolling
                contentView
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
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedSection {
        case .home:
            HomeView(
                events: events,
                inProgressEvents: inProgressEvents,
                onNavigateToSection: { section, tab in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedSection = section
                        isDrawerOpen = false
                        securityInitialTab = (section == .security) ? (tab ?? .events) : nil
                    }
                }
            )
                .environmentObject(settingsStore)
        case .security:
            SecurityView(
                events: events,
                inProgressEvents: inProgressEvents,
                errorMessage: errorMessage,
                isLoading: isLoading,
                eventsListView: eventsListView,
                onRefreshEvents: onRefreshEvents,
                initialTab: securityInitialTab
            )
            .environmentObject(settingsStore)
        case .media:
            MediaView()
                .environmentObject(settingsStore)
        case .climate:
            ClimateView()
                .environmentObject(settingsStore)
        case .uv:
            UVView()
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
    @State private var isHamburgerPressed = false
    @State private var isTitlePressed = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Material 3 Hamburger Button
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isDrawerOpen.toggle()
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.onSurface) // Use onSurface for icon at rest
                    .frame(width: 24, height: 24)
                    .padding(16) // Creates 56x56 total touch target
                    .background(
                        // State layer for hover/press (72px wide × 56px tall - horizontal pill)
                        RoundedRectangle(cornerRadius: 28) // Full radius for horizontal pill shape
                            .fill(Color.onSurface.opacity(isHamburgerPressed ? 0.1 : 0.0))
                            .frame(width: 72, height: 56)
                    )
                    // No base container at rest - just the icon
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isHamburgerPressed ? 0.95 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHamburgerPressed {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isHamburgerPressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isHamburgerPressed = false
                        }
                    }
            )
            
            // 32px spacing (8px margin + 24px for label's hover state)
            Spacer()
                .frame(width: 32)
            
            // Material 3 App Title Button - "Crooked Sentry"
            Button(action: {
                // Navigate to home page
                // This would typically be handled by the parent view
                print("Navigate to home page")
            }) {
                Text("Crooked Sentry")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        // State layer for hover/press with full radius (pill shape)
                        Capsule()
                            .fill(Color.onSurface.opacity(isTitlePressed ? 0.1 : 0.0))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isTitlePressed ? 0.98 : 1.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isTitlePressed {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isTitlePressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isTitlePressed = false
                        }
                    }
            )
            
            Spacer()
        }
        .padding(.horizontal, 8) // Overall 8px margin
        .frame(height: 72) // Height as specified
        .background(Color.surface)
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