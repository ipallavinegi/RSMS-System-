import Foundation
import Combine

enum SalesPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        }
    }
}

struct SalesSummary {
    let actual: Double
    let target: Double
    let transactionCount: Int
    let unitsSold: Int
    let averageTransactionValue: Double
    let unitsPerTransaction: Double
    let estimatedGrossMargin: Double
    let trend: [DailySalesPoint]

    var variance: Double { actual - target }
    var variancePercent: Double { target == 0 ? 0 : variance / target }
    var progress: Double { target == 0 ? 0 : min(actual / target, 1.4) }
}

struct DailySalesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct ShiftSummary {
    let currentShift: Shift?
    let nextShift: Shift?
    let scheduledUsers: [User]
    let presentUsers: [User]
    let attendanceRows: [Attendance]
}

struct StockAlertItem: Identifiable {
    let id: UUID
    let product: Product
    let inventory: InventoryItem
    let soldUnits: Int

    var isOutOfStock: Bool { inventory.quantity <= 0 }
    var shortage: Int { max(inventory.reorderLevel - inventory.quantity, 0) }
    var urgencyTitle: String { isOutOfStock ? "Out of stock" : "Low stock" }
}

struct ReplenishmentCartItem: Identifiable {
    let id = UUID()
    let product: Product
    let storeId: UUID
    var quantity: Int
    var priority: String
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedPeriod: SalesPeriod = .day {
        didSet { rebuild() }
    }
    @Published var selectedShiftDate = Date() {
        didSet { rebuild() }
    }
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var usingSampleData = false
    @Published private(set) var salesSummary = SalesSummary.empty
    @Published private(set) var shiftSummary = ShiftSummary.empty
    @Published private(set) var stockAlerts: [StockAlertItem] = []
    @Published private(set) var priorityAppointments: [Appointment] = []
    @Published private(set) var allAppointments: [Appointment] = []
    @Published private(set) var customersById: [UUID: Customer] = [:]
    @Published private(set) var usersById: [UUID: User] = [:]
    @Published var replenishmentCart: [ReplenishmentCartItem] = []

    // High fidelity dashboard configurations & states
    @Published var activeTab: Int = 0
    @Published var selectedDateRange: String = "Jun 1 – Jun 10, 2024"
    @Published var notificationCount: Int = 2
    @Published var selectedRevenuePeriod: RevenuePeriod = .month {
        didSet { rebuild() }
    }
    @Published var selectedStorePerformanceFilter: StorePerformanceFilter = .highest {
        didSet { rebuild() }
    }
    
    // Core KPIs
    @Published var networkStoresActive: Int = 47
    @Published var networkStoresTotal: Int = 50
    @Published var inventoryProductsCount: Int = 0
    @Published var inventoryProductsTotal: Int = 0
    @Published var staffingManagersCount: Int = 0
    @Published var staffingManagersTotal: Int = 0
    @Published var marketingPromosCount: Int = 0

    // Detailed metrics
    @Published var retailHealthScores: [StoreHealthScore] = []
    @Published var storePerformanceList: [StorePerformanceItem] = []
    @Published var topCustomersList: [TopCustomerItem] = []

    private let service: DashboardServicing
    private var data: DashboardData?
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()

    init(service: DashboardServicing? = nil) {
        self.service = service ?? SupabaseDashboardService()
        setupRealtimeSync()
    }
    
    private func setupRealtimeSync() {
        let dm = RSMSDataManager.shared
        
        dm.$stores
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stores in
                guard !stores.isEmpty else { return }
                self?.networkStoresTotal = stores.count
                self?.networkStoresActive = stores.filter { $0.status == .active }.count
            }
            .store(in: &cancellables)
            
        dm.$managers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] managers in
                guard !managers.isEmpty, let self else { return }
                // Only count staff_members whose role is actually a manager-type
                // role — otherwise this card silently counted every staff member,
                // not just managers.
                let managerRoleMembers = managers.filter { self.isManagerRole($0.role) }
                self.staffingManagersTotal = managerRoleMembers.count
                self.staffingManagersCount = managerRoleMembers.filter { !$0.isArchived }.count
            }
            .store(in: &cancellables)
            
        dm.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                guard !products.isEmpty else { return }
                self?.inventoryProductsTotal = products.count
                self?.inventoryProductsCount = products.filter { $0.approvalStatus == ApprovalStatus.approved.rawValue }.count
            }
            .store(in: &cancellables)
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            data = try await service.fetchDashboardData()
            usingSampleData = false
            if let data, !data.failureReasons.isEmpty {
                // Individual tables failed to fetch/decode but the dashboard
                // still loaded with whatever succeeded — surface this instead
                // of letting it look like a silent zero/empty state.
                errorMessage = "Some data couldn't be loaded: \(data.failureReasons.joined(separator: "; "))"
            }
        } catch {
            // No mock/demo fallback: surface the real failure and keep the
            // dashboard empty rather than showing fabricated numbers.
            data = DashboardData.empty
            usingSampleData = false
            errorMessage = "Couldn't load dashboard data: \(error.localizedDescription)"
        }

        // Live count of currently-running promotions, from the same
        // service the Promotions screen uses (no more hardcoded mock value).
        await PromotionService.shared.fetchPromotions()

        rebuild()
        isLoading = false
    }

    func addToCart(_ alert: StockAlertItem) {
        let suggestedQuantity = max(alert.shortage, alert.inventory.reorderLevel, 1)

        if let index = replenishmentCart.firstIndex(where: { $0.product.id == alert.product.id }) {
            replenishmentCart[index].quantity += suggestedQuantity
        } else {
            replenishmentCart.append(
                ReplenishmentCartItem(
                    product: alert.product,
                    storeId: alert.inventory.storeId ?? currentStoreId,
                    quantity: suggestedQuantity,
                    priority: alert.isOutOfStock ? "high" : "medium"
                )
            )
        }
    }

    func removeCartItem(_ item: ReplenishmentCartItem) {
        replenishmentCart.removeAll { $0.id == item.id }
    }

    func submitReplenishmentCart() async {
        guard !replenishmentCart.isEmpty else { return }

        let requester = data?.users.first?.id ?? UUID()
        let now = Date()
        let requests = replenishmentCart.map {
            StockRequest(
                id: UUID(),
                storeId: $0.storeId,
                productId: $0.product.id,
                requestedBy: requester,
                requestedQuantity: $0.quantity,
                priority: $0.priority,
                status: "draft_submitted",
                remarks: "Created from manager dashboard replenishment cart",
                createdAt: now,
                updatedAt: now
            )
        }

        do {
            try await service.submitStockRequests(requests)
            replenishmentCart.removeAll()
        } catch {
            errorMessage = "Could not submit stock requests. Keep the draft cart and try again."
        }
    }

    private func rebuild() {
        guard let data else { return }

        let storeId = data.stores.first?.id ?? data.sales.first?.storeId ?? data.inventory.compactMap(\.storeId).first ?? UUID()
        customersById = Dictionary(uniqueKeysWithValues: data.customers.map { ($0.id, $0) })
        usersById = Dictionary(uniqueKeysWithValues: data.users.map { ($0.id, $0) })
        salesSummary = makeSalesSummary(data: data)
        shiftSummary = makeShiftSummary(data: data, storeId: storeId)
        stockAlerts = makeStockAlerts(data: data, storeId: storeId)
        allAppointments = data.appointments
            .filter { $0.storeId == storeId }
            .sorted { $0.appointmentStart < $1.appointmentStart }
        priorityAppointments = allAppointments
            .filter { calendar.isDateInToday($0.appointmentStart) && $0.status.lowercased() != "cancelled" }
            .sorted { appointmentRank($0) < appointmentRank($1) }
            .prefix(4)
            .map { $0 }
            
        // Populate core KPIs strictly from live data. RSMSDataManager publishes
        // real-time counts once loaded; until then, fall back to the counts
        // from this fetch — never to fabricated numbers.
        if RSMSDataManager.shared.stores.isEmpty {
            networkStoresActive = data.stores.filter { $0.status.lowercased() == "active" }.count
            networkStoresTotal = data.stores.count
        }

        if RSMSDataManager.shared.products.isEmpty {
            inventoryProductsTotal = data.products.count
            inventoryProductsCount = data.products.filter { $0.approvalStatus == ApprovalStatus.approved.rawValue }.count
        }

        if RSMSDataManager.shared.managers.isEmpty {
            // Same manager-role filter as the live staff_members stream,
            // applied to the closest available signal (designation) since
            // DashboardData doesn't fetch staff_members/roles directly.
            let managerRoleUsers = data.users.filter { isManagerRole($0.designation ?? "") }
            staffingManagersTotal = managerRoleUsers.count
            staffingManagersCount = managerRoleUsers.count
        }

        // Live campaigns = promotions whose schedule currently overlaps today,
        // pulled straight from PromotionService (same source as the Promotions screen).
        marketingPromosCount = PromotionService.shared.promotions
            .filter { $0.promotionState == .active }
            .count

        // Retail Health Score — from the `health_scores` table, joined to store names.
        let storeNamesById = Dictionary(uniqueKeysWithValues: data.stores.map { ($0.id, $0.storeName) })
        retailHealthScores = data.healthScores
            .sorted { $0.overallScore > $1.overallScore }
            .compactMap { health -> StoreHealthScore? in
                guard let storeName = storeNamesById[health.storeId] else { return nil }
                let score = Int(health.overallScore.rounded())
                let (statusText, colorHex) = healthBand(for: score)
                return StoreHealthScore(storeName: storeName, score: score, statusText: statusText, colorHex: colorHex)
            }

        // Top Customers — real spend aggregated from completed sales.
        let completedSales = data.sales.filter { $0.saleStatus.lowercased() != "cancelled" }
        let spendByCustomer = Dictionary(grouping: completedSales, by: \.customerId)
            .mapValues { $0.reduce(0) { $0 + $1.totalAmount } }
        let rankedCustomers = spendByCustomer
            .sorted { $0.value > $1.value }
            .prefix(4)
        let maxSpend = rankedCustomers.first?.value ?? 0
        topCustomersList = rankedCustomers.compactMap { customerId, spend -> TopCustomerItem? in
            guard let customer = customersById[customerId] else { return nil }
            return TopCustomerItem(customerName: customer.name, spend: spend, maxSpend: maxSpend)
        }

        // Store Performance — real revenue aggregated from completed sales, per store.
        let revenueByStore = Dictionary(grouping: completedSales, by: \.storeId)
            .mapValues { $0.reduce(0) { $0 + $1.totalAmount } }
        let sortedStoreRevenue = selectedStorePerformanceFilter == .highest
            ? revenueByStore.sorted { $0.value > $1.value }
            : revenueByStore.sorted { $0.value < $1.value }
        storePerformanceList = sortedStoreRevenue.prefix(4).enumerated().compactMap { index, entry -> StorePerformanceItem? in
            guard let storeName = storeNamesById[entry.key] else { return nil }
            return StorePerformanceItem(rank: index + 1, storeName: storeName, revenue: entry.value)
        }
    }

    private func healthBand(for score: Int) -> (statusText: String, colorHex: String) {
        switch score {
        case 80...: return ("Optimal Health", "34C759")
        case 60..<80: return ("Monitoring Required", "FF9500")
        case 40..<60: return ("Action Needed", "FF3B30")
        default: return ("Critical Threshold", "FF2D55")
        }
    }

    /// Mirrors RSMSDataManager.isManagerRole — kept in sync manually since
    /// that helper is private to RSMSDataManager. Treats any role/designation
    /// containing "manager", "admin", or "lead" as a manager-type role.
    private func isManagerRole(_ role: String) -> Bool {
        let lower = role.lowercased()
        return lower.contains("manager") || lower.contains("admin") || lower.contains("lead")
    }

    private var currentStoreId: UUID {
        data?.stores.first?.id ?? data?.inventory.compactMap(\.storeId).first ?? UUID()
    }

    private func makeSalesSummary(data: DashboardData) -> SalesSummary {
        let interval: DateInterval
        switch selectedRevenuePeriod {
        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: Date()) ?? DateInterval(start: Date(), duration: 604_800)
        case .month:
            interval = calendar.dateInterval(of: .month, for: Date()) ?? DateInterval(start: Date(), duration: 2_592_000)
        case .year:
            interval = calendar.dateInterval(of: .year, for: Date()) ?? DateInterval(start: Date(), duration: 31_536_000)
        }

        // Network-wide: this is the corporate "Total Revenue" card, so it
        // aggregates sales across every store rather than one arbitrarily
        // chosen store.
        let periodSales = data.sales.filter {
            $0.saleStatus.lowercased() != "cancelled" &&
            interval.contains($0.saleDate)
        }
        let saleIds = Set(periodSales.map(\.id))
        let periodItems = data.saleItems.filter { saleIds.contains($0.saleId) }
        let actual = periodSales.reduce(0) { $0 + $1.totalAmount }
        let target = matchingTarget(in: data.storeTargets, interval: interval)
        let transactionCount = periodSales.count
        let unitsSold = periodItems.reduce(0) { $0 + $1.quantity }
        let averageTransactionValue = transactionCount == 0 ? 0 : actual / Double(transactionCount)
        let unitsPerTransaction = transactionCount == 0 ? 0 : Double(unitsSold) / Double(transactionCount)

        return SalesSummary(
            actual: actual,
            target: target,
            transactionCount: transactionCount,
            unitsSold: unitsSold,
            averageTransactionValue: averageTransactionValue,
            unitsPerTransaction: unitsPerTransaction,
            estimatedGrossMargin: actual * 0.42,
            trend: makeTrend(from: data.sales)
        )
    }

    private func matchingTarget(in targets: [StoreTarget], interval: DateInterval) -> Double {
        // `store_targets` has one row per store per calendar month — there's
        // no period_type/period_start to match against directly, so the
        // network-wide target for the selected period is derived from
        // whichever month(s) the interval falls in.
        switch selectedRevenuePeriod {
        case .month:
            let matching = targets.filter { calendar.isDate($0.targetMonth, equalTo: interval.start, toGranularity: .month) }
            return matching.reduce(0) { $0 + $1.revenueTarget }
        case .week:
            // Prorate that month's total target down to a 7-day share.
            let matching = targets.filter { calendar.isDate($0.targetMonth, equalTo: interval.start, toGranularity: .month) }
            let monthlyTotal = matching.reduce(0) { $0 + $1.revenueTarget }
            let daysInMonth = calendar.range(of: .day, in: .month, for: interval.start)?.count ?? 30
            return monthlyTotal / Double(daysInMonth) * 7
        case .year:
            let matching = targets.filter { calendar.isDate($0.targetMonth, equalTo: interval.start, toGranularity: .year) }
            return matching.reduce(0) { $0 + $1.revenueTarget }
        }
    }

    private func makeTrend(from sales: [Sale]) -> [DailySalesPoint] {
        switch selectedRevenuePeriod {
        case .week:
            let todayStart = calendar.startOfDay(for: Date())
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: todayStart) }.reversed()
            return days.map { day in
                let amount = sales
                    .filter { calendar.isDate($0.saleDate, inSameDayAs: day) }
                    .reduce(0) { $0 + $1.totalAmount }
                return DailySalesPoint(date: day, amount: amount)
            }
        case .month:
            let todayStart = calendar.startOfDay(for: Date())
            let days = (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: todayStart) }.reversed()
            return days.map { day in
                let amount = sales
                    .filter { calendar.isDate($0.saleDate, inSameDayAs: day) }
                    .reduce(0) { $0 + $1.totalAmount }
                return DailySalesPoint(date: day, amount: amount)
            }
        case .year:
            let todayStart = calendar.startOfDay(for: Date())
            let months = (0..<12).compactMap { calendar.date(byAdding: .month, value: -$0, to: todayStart) }.reversed()
            return months.map { month in
                let amount = sales
                    .filter { sale in
                        guard let saleMonth = calendar.dateComponents([.year, .month], from: sale.saleDate).month,
                              let currentMonth = calendar.dateComponents([.year, .month], from: month).month
                        else { return false }
                        return saleMonth == currentMonth
                    }
                    .reduce(0) { $0 + $1.totalAmount }
                return DailySalesPoint(date: month, amount: amount)
            }
        }
    }

    private func makeShiftSummary(data: DashboardData, storeId: UUID) -> ShiftSummary {
        let shifts = data.shifts.filter { $0.storeId == storeId && $0.status.lowercased() == "active" }
        let current = shifts.first { $0.contains(Date(), calendar: calendar) } ?? shifts.first
        let next = shifts
            .filter { shift in
                guard let start = shift.startDate(on: Date(), calendar: calendar) else { return false }
                return start > Date()
            }
            .sorted { ($0.startDate(on: Date(), calendar: calendar) ?? Date()) < ($1.startDate(on: Date(), calendar: calendar) ?? Date()) }
            .first

        // There is no `shift_assignments` join table in the real schema —
        // a user's shift is assigned directly via `users.shift_id`
        // (RSMS schema doc, table 4), so scheduling is read straight off
        // the User records for the current shift and store.
        let scheduled = data.users.filter { user in
            user.storeId == storeId && user.shiftId == current?.id
        }
        let attendance = data.attendance.filter { calendar.isDate($0.attendanceDate, inSameDayAs: selectedShiftDate) }
        let presentIds = Set(attendance.filter { $0.checkIn != nil && $0.status.lowercased() != "absent" }.map(\.employeeId))
        let present = scheduled.filter { presentIds.contains($0.id) }

        return ShiftSummary(
            currentShift: current,
            nextShift: next,
            scheduledUsers: scheduled,
            presentUsers: present,
            attendanceRows: attendance
        )
    }

    private func makeStockAlerts(data: DashboardData, storeId: UUID) -> [StockAlertItem] {
        let productsById = Dictionary(uniqueKeysWithValues: data.products.map { ($0.id, $0) })
        let soldUnitsByProduct = Dictionary(grouping: data.saleItems, by: \.productId)
            .mapValues { $0.reduce(0) { $0 + $1.quantity } }

        return data.inventory
            .filter { $0.storeId == storeId && $0.quantity <= $0.reorderLevel }
            .compactMap { inventory in
                guard let product = productsById[inventory.productId] else { return nil }
                return StockAlertItem(
                    id: inventory.id,
                    product: product,
                    inventory: inventory,
                    soldUnits: soldUnitsByProduct[inventory.productId] ?? 0
                )
            }
            .sorted {
                if $0.isOutOfStock != $1.isOutOfStock { return $0.isOutOfStock }
                return $0.soldUnits > $1.soldUnits
            }
    }

    private func appointmentRank(_ appointment: Appointment) -> Int {
        switch appointment.priority.lowercased() {
        case "high", "vip": return 0
        case "medium": return 1
        default: return 2
        }
    }
}

private extension SalesSummary {
    static let empty = SalesSummary(
        actual: 0,
        target: 0,
        transactionCount: 0,
        unitsSold: 0,
        averageTransactionValue: 0,
        unitsPerTransaction: 0,
        estimatedGrossMargin: 0,
        trend: []
    )
}

private extension ShiftSummary {
    static let empty = ShiftSummary(
        currentShift: nil,
        nextShift: nil,
        scheduledUsers: [],
        presentUsers: [],
        attendanceRows: []
    )
}

private extension SalesPeriod {
    func dateInterval(containing date: Date, calendar: Calendar) -> DateInterval {
        switch self {
        case .day:
            return calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 86_400)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 604_800)
        case .month:
            return calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 2_592_000)
        }
    }
}

private extension Shift {
    func contains(_ date: Date, calendar: Calendar) -> Bool {
        guard let start = startDate(on: date, calendar: calendar),
              let end = endDate(on: date, calendar: calendar)
        else { return false }

        if end < start {
            return date >= start || date <= end
        }

        return date >= start && date <= end
    }

    func startDate(on date: Date, calendar: Calendar) -> Date? {
        dateFromTime(startTime, on: date, calendar: calendar)
    }

    func endDate(on date: Date, calendar: Calendar) -> Date? {
        dateFromTime(endTime, on: date, calendar: calendar)
    }

    private func dateFromTime(_ time: String, on date: Date, calendar: Calendar) -> Date? {
        let pieces = time.split(separator: ":").compactMap { Int($0) }
        guard pieces.count >= 2 else { return nil }
        return calendar.date(
            bySettingHour: pieces[0],
            minute: pieces[1],
            second: 0,
            of: date
        )
    }
}
