import Foundation
import Supabase

struct DashboardData {
    let stores: [Store]
    let sales: [Sale]
    let saleItems: [SaleItem]
    let salesTargets: [SalesTarget]
    let shifts: [Shift]
    let shiftAssignments: [ShiftAssignment]
    let attendance: [Attendance]
    let users: [User]
    let inventory: [InventoryItem]
    let products: [Product]
    let customers: [Customer]
    let appointments: [Appointment]
    let stockRequests: [StockRequest]
}

protocol DashboardServicing {
    func fetchDashboardData() async throws -> DashboardData
    func submitStockRequests(_ requests: [StockRequest]) async throws
}

final class SupabaseDashboardService: DashboardServicing {
    private let database = DatabaseService.shared

    func fetchDashboardData() async throws -> DashboardData {
        return try await DashboardData(
            stores: database.fetch(from: "stores", as: Store.self),
            sales: database.fetch(from: "sales", as: Sale.self),
            saleItems: database.fetch(from: "sale_items", as: SaleItem.self),
            salesTargets: database.fetch(from: "sales_targets", as: SalesTarget.self),
            shifts: database.fetch(from: "shifts", as: Shift.self),
            shiftAssignments: database.fetch(from: "shift_assignments", as: ShiftAssignment.self),
            attendance: database.fetch(from: "attendance", as: Attendance.self),
            users: database.fetch(from: "users", as: User.self),
            inventory: database.fetch(from: "inventory", as: InventoryItem.self),
            products: database.fetch(from: "products", as: Product.self),
            customers: database.fetch(from: "customers", as: Customer.self),
            appointments: database.fetch(from: "appointments", as: Appointment.self),
            stockRequests: database.fetch(from: "stock_requests", as: StockRequest.self)
        )
    }

    func submitStockRequests(_ requests: [StockRequest]) async throws {
        for request in requests {
            try await database.insert(into: "stock_requests", value: request)
        }
    }
}
