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
        NavigationStack {
            Group {
                switch activeView {
                case .dashboard:
                    DashboardView()
                case .auditLogs:
                    ComingSoonView(title: "Audit Logs")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(activeView == .dashboard ? "Dashboard" : "Audit Logs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View", selection: $activeView) {
                        Text("Dashboard").tag(ActiveView.dashboard)
                        Text("Audit Logs").tag(ActiveView.auditLogs)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    ContentView()
}
