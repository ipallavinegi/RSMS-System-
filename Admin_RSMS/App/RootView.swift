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
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch activeView {
                case .dashboard:
                    NavigationStack {
                        DashboardView()
                    }
                case .auditLogs:
                    ComingSoonView(title: "Audit Logs")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Glassmorphic Bottom Tab Bar matching reference image
            HStack(spacing: 8) {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.bottom, 24)
            .zIndex(1)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color(uiColor: .systemGroupedBackground))
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .medium : .regular))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
            }
            .foregroundColor(isSelected ? .blue : .primary)
            .frame(width: 80, height: 60)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                            .matchedGeometryEffect(id: "TabBackground", in: namespace)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
