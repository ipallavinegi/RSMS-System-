// Admin_RSMSApp.swift
// Admin_RSMS

import SwiftUI

@main
struct Admin_RSMSApp: App {
    // Instantiate the shared data manager once at app launch.
    // RSMSDataManager.init() kicks off fetching + realtime subscriptions.
    @StateObject private var dataManager = RSMSDataManager.shared
    @StateObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(dataManager)
            } else {
                LoginView()
            }
        }
    }
}
