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
    @Namespace private var tabNamespace
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Tab Switcher: Centered below navigation title ──
                HStack(spacing: 6) {
                    TabBarButton(
                        icon: "square.grid.2x2.fill", 
                        title: "Dashboard", 
                        view: .dashboard, 
                        activeView: $activeView, 
                        namespace: tabNamespace
                    )
                    
                    TabBarButton(
                        icon: "magnifyingglass.circle.fill", 
                        title: "Audit Logs", 
                        view: .auditLogs, 
                        activeView: $activeView, 
                        namespace: tabNamespace
                    )
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                .padding(.top, 4)
                .padding(.bottom, 16)
                
                // ── Main Content ──
                Group {
                    switch activeView {
                    case .dashboard:
                        DashboardView()
                    case .auditLogs:
                        ComingSoonView(title: "Audit Logs")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(activeView == .dashboard ? "Dashboard" : "Audit Logs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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

struct TabBarButton: View {
    let icon: String
    let title: String
    let view: ActiveView
    @Binding var activeView: ActiveView
    let namespace: Namespace.ID
    
    var isSelected: Bool { activeView == view }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                activeView = view
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.blue.opacity(0.12))
                            .matchedGeometryEffect(id: "TabBackground", in: namespace)
                    }
                }
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
