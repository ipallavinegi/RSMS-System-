//
//  ContentView.swift
//  Admin_RSMS
//

import SwiftUI

enum ActiveView {
    case dashboard
    case auditLogs
}

struct ContentView: View {
    @State private var activeView: ActiveView = .dashboard
    
    var body: some View {
        TabView(selection: $activeView) {
            NavigationStack {
                DashboardView()
                    .navigationTitle("Dashboard")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar { profileToolbarItem }
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            .tag(ActiveView.dashboard)
            
            NavigationStack {
                AuditLogsView()
                    .navigationTitle("Audit Logs")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar { profileToolbarItem }
            }
            .tabItem {
                Label("Audit Logs", systemImage: "list.clipboard")
            }
            .tag(ActiveView.auditLogs)
        }
        .tint(Color.brandGreenDark)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    @ToolbarContentBuilder
    private var profileToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                if let user = AuthManager.shared.currentUser {
                    Section {
                        Text("Signed in as:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(user.fullName)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section {
                        Text("Offline Admin Mode")
                            .font(.headline)
                    }
                }
                
                Divider()
                
                Button(role: .destructive, action: {
                    AuthManager.shared.signOut()
                }) {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("AM")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
