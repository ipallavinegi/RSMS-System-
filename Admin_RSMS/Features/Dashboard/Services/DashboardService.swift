import Foundation
import Supabase

struct DashboardData {
    let stores: [Store]
    let sales: [Sale]
    let saleItems: [SaleItem]
    let storeTargets: [StoreTarget]
    let shifts: [Shift]
    let attendance: [Attendance]
    let users: [User]
    let inventory: [InventoryItem]
    let products: [Product]
    let customers: [Customer]
    let appointments: [Appointment]
    let stockRequests: [StockRequest]
    let healthScores: [HealthScore]
    /// Human-readable reasons for any table that failed to fetch/decode.
    /// Empty means every table loaded cleanly. Surfaced in the UI so a
    /// partial failure is never silent again.
    let failureReasons: [String]
}

extension DashboardData {
    /// A genuinely empty dataset — used when the real fetch fails so the UI
    /// shows honest zero/empty states instead of fabricated demo numbers.
    static let empty = DashboardData(
        stores: [],
        sales: [],
        saleItems: [],
        storeTargets: [],
        shifts: [],
        attendance: [],
        users: [],
        inventory: [],
        products: [],
        customers: [],
        appointments: [],
        stockRequests: [],
        healthScores: [],
        failureReasons: []
    )
}

protocol DashboardServicing {
    func fetchDashboardData() async throws -> DashboardData
    func submitStockRequests(_ requests: [StockRequest]) async throws
}

final class SupabaseDashboardService: DashboardServicing {
    private let database = DatabaseService.shared

    func fetchDashboardData() async throws -> DashboardData {
        // Each table is fetched independently (and in parallel, via `async let`)
        // so a decoding failure in one table — e.g. a NULL sales.store_id that
        // Sale.storeId can't represent as a non-optional UUID — only empties
        // that one table instead of throwing away the whole dashboard. Any
        // failure reason is collected below instead of only being printed.
        // `stores` is decoded via AdminStore, not the SRS-canonical `Store`
        // struct: this codebase has two competing store models, and the real
        // Supabase table matches AdminStore's columns (name, address,
        // manager_name, is_archived, ...), not Store's (store_name, pin_code,
        // region, country, city). Decoding as `Store` failed on every
        // required field that doesn't exist in the real table.
        //
        // There is no `sales_targets`, `shift_assignments`, or `appointments`
        // table in the real schema (confirmed against the 27-table RSMS
        // schema doc). Targets live in `store_targets` (one row per store
        // per month); shift assignment is just `users.shift_id`, no join
        // table involved; appointments are `tasks` rows where
        // `task_type = 'Appointment'`.
        async let adminStores = database.fetchResilient(from: "stores", as: AdminStore.self)
        async let sales = database.fetchResilient(from: "sales", as: Sale.self)
        async let saleItems = database.fetchResilient(from: "sale_items", as: SaleItem.self)
        async let storeTargets = database.fetchResilient(from: "store_targets", as: StoreTarget.self)
        async let shifts = database.fetchResilient(from: "shifts", as: Shift.self)
        async let attendance = database.fetchResilient(from: "attendance", as: Attendance.self)
        async let users = database.fetchResilient(from: "users", as: User.self)
        async let inventory = database.fetchResilient(from: "inventory", as: InventoryItem.self)
        async let products = database.fetchResilient(from: "products", as: Product.self)
        async let customers = database.fetchResilient(from: "customers", as: Customer.self)
        async let tasks = database.fetchResilient(from: "tasks", as: TaskRecord.self)
        async let stockRequests = database.fetchResilient(from: "stock_requests", as: StockRequest.self)
        async let healthScores = database.fetchResilient(from: "health_scores", as: HealthScore.self)

        let results = await (
            adminStores: adminStores, sales: sales, saleItems: saleItems, storeTargets: storeTargets,
            shifts: shifts, attendance: attendance,
            users: users, inventory: inventory, products: products, customers: customers,
            tasks: tasks, stockRequests: stockRequests, healthScores: healthScores
        )

        let failureReasons = [
            results.adminStores.failureReason, results.sales.failureReason, results.saleItems.failureReason,
            results.storeTargets.failureReason, results.shifts.failureReason,
            results.attendance.failureReason, results.users.failureReason, results.inventory.failureReason,
            results.products.failureReason, results.customers.failureReason, results.tasks.failureReason,
            results.stockRequests.failureReason, results.healthScores.failureReason
        ].compactMap { $0 }

        // Adapt AdminStore (the real table shape) into the SRS Store shape
        // that DashboardViewModel/DashboardData already consume elsewhere.
        let stores = results.adminStores.values.map { admin in
            Store(
                id: admin.id,
                storeName: admin.name,
                pinCode: "",
                region: "",
                country: "",
                city: admin.address,
                status: admin.status.rawValue.lowercased(),
                managerId: nil,
                createdAt: Date()
            )
        }

        let appointments = results.tasks.values
            .filter { ($0.taskType ?? "").caseInsensitiveCompare("Appointment") == .orderedSame }
            .compactMap(\.asAppointment)

        return DashboardData(
            stores: stores,
            sales: results.sales.values,
            saleItems: results.saleItems.values,
            storeTargets: results.storeTargets.values,
            shifts: results.shifts.values,
            attendance: results.attendance.values,
            users: results.users.values,
            inventory: results.inventory.values,
            products: results.products.values,
            customers: results.customers.values,
            appointments: appointments,
            stockRequests: results.stockRequests.values,
            healthScores: results.healthScores.values,
            failureReasons: failureReasons
        )
    }

    func submitStockRequests(_ requests: [StockRequest]) async throws {
        for request in requests {
            try await database.insert(into: "stock_requests", value: request)
        }
    }
}
