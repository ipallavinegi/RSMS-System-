import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case stores = "Stores"
    case manager = "Manager"
    case reports = "Reports"
    case settings = "Settings"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .stores: return "storefront"
        case .manager: return "person.2"
        case .reports: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}
