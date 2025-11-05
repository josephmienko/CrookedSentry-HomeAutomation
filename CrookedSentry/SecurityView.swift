import SwiftUI

struct SecurityView: View {
    let events: [FrigateEvent]
    let inProgressEvents: [FrigateEvent] 
    let errorMessage: String?
    let isLoading: Bool
    let eventsListView: AnyView
    let onRefreshEvents: (Bool) async -> Void
    
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("Events").tag(0)
                Text("Live").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                // Events can be shown without VPN (historical data)
                ScrollView { eventsListView }
            } else {
                // Live feeds require VPN for security
                SecurityGate(isSecureContentRequired: VPNFeatureFlags.vpnRequiredForLiveFeeds) {
                    LiveFeedView().environmentObject(settingsStore)
                }
            }
        }
        .background(Color.background)
        .onAppear {
            // Update VPN manager with current Frigate URL for local network detection
            VPNManager.shared.updateFrigateURL(settingsStore.frigateBaseURL)
            // Check current security state
            VPNManager.shared.checkCurrentSecurityState()
        }
    }
}
