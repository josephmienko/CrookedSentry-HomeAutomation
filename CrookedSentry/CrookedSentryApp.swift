import SwiftUI
import UserNotifications

extension Notification.Name {
    static let autoRetryConnection = Notification.Name("autoRetryConnection")
    static let refreshFromMenu = Notification.Name("refreshFromMenu")
}

@main
struct CrookedSentryApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @State private var showSettingsOnLaunch = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .onAppear {
                    if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
                        showSettingsOnLaunch = true
                        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                    }
                }
                .sheet(isPresented: $showSettingsOnLaunch) {
                    SettingsView()
                        .environmentObject(settingsStore)
                }
        }
    }
}
