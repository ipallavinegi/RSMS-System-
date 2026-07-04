//
//  AuditLogsViewModel.swift
//  Admin_RSMS
//
//  Drives the Audit & Compliance Center: what's broken, where risk is
//  concentrated, and whether controls are improving.
//  Philosophy:  Dashboard = Performance.  Audit = Risk.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AuditLogsViewModel: ObservableObject {

    // MARK: Loading state

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var lastRefreshed: Date = Date()
    @Published var isLiveStreamActive = true

    // MARK: Compliance Center controls

    @Published var complianceStoreId: UUID? = nil {
        didSet { rebuildCompliance(); rebuildFilteredLogs() }
    }
    @Published var complianceDateFilter: AuditDateFilter = .last30Days {
        didSet { rebuildCompliance(); rebuildFilteredLogs() }
    }
    @Published private(set) var complianceSummary: ComplianceSummary = .empty
    @Published var inspectorContent: InspectorContent?

    // MARK: Export

    @Published var exportedFileURL: URL?
    @Published var isExporting = false
    @Published private(set) var filteredLogs: [AuditLogDisplayItem] = []

    // MARK: Private state

    private let service: AuditLogsServicing
    private var data: AuditLogsData?
    private var allDisplayLogs: [AuditLogDisplayItem] = []
    private var refreshTimer: AnyCancellable?
    private let calendar = Calendar.current
    /// Health scores scoped to the current store filter (ignores the date
    /// filter) — cached each rebuild so the chart's own range control can
    /// resample independently of the global Time Range filter.
    private var scopedHealthScoresCache: [AHealthScore] = []

    var stores: [AdminStore] { RSMSDataManager.shared.stores }

    init(service: AuditLogsServicing = SupabaseAuditLogsService()) {
        self.service = service
        startAutoRefresh()
    }

    // MARK: Loading

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await service.fetchAuditLogsData()
            data = fetched
            let usersById = Dictionary(uniqueKeysWithValues: fetched.users.map { ($0.id, $0) })
            allDisplayLogs = fetched.auditLogs
                .map { AuditLogDisplayItem.make(from: $0, user: usersById[$0.userId]) }
                .sorted { $0.date > $1.date }
            lastRefreshed = Date()
        } catch {
            errorMessage = "Couldn't load audit data: \(error.localizedDescription)"
        }
        isLoading = false
        rebuildFilteredLogs()
        rebuildCompliance()
    }

    func refresh() async {
        await load()
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.publish(every: 5 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isLiveStreamActive else { return }
                Task { await self.refresh() }
            }
    }

    // MARK: Audit trail

    private func rebuildFilteredLogs() {
        var logs = allDisplayLogs
        if let interval = complianceDateFilter.interval(calendar: calendar) {
            logs = logs.filter { interval.contains($0.date) }
        }
        if let complianceStoreId {
            logs = logs.filter { $0.userStoreId == complianceStoreId }
        }
        filteredLogs = logs
    }

    // MARK: Compliance Center — core rebuild

    private func rebuildCompliance() {
        guard let data else { complianceSummary = .empty; scopedHealthScoresCache = []; return }

        let now = Date()
        let currentInterval = complianceDateFilter.interval(calendar: calendar, now: now)
            ?? DateInterval(start: .distantPast, end: now)
        let periodLength     = currentInterval.duration
        let previousInterval = DateInterval(
            start: currentInterval.start.addingTimeInterval(-periodLength),
            end:   currentInterval.start
        )

        // Weekly windows for delta calculation
        let currentWeekStart = calendar.date(from: calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) ?? now

        let storesById = Dictionary(uniqueKeysWithValues: stores.map { ($0.id, $0) })

        func scoped<T>(_ items: [T], storeId: (T) -> UUID?) -> [T] {
            guard let complianceStoreId else { return items }
            return items.filter { storeId($0) == complianceStoreId }
        }

        let scopedHealthScores = scoped(data.healthScores)        { $0.storeId }
        let scopedExceptions   = scoped(data.inventoryExceptions) { $0.storeId }

        let currentHealthScores  = scopedHealthScores.filter { currentInterval.contains($0.generatedAt) }
        let previousHealthScores = scopedHealthScores.filter { previousInterval.contains($0.generatedAt) }
        let currentExceptions    = scopedExceptions.filter   { currentInterval.contains($0.createdAt) }

        // Latest snapshot per store (for risk hotspots)
        let latestScoreByStore: [UUID: AHealthScore] = Dictionary(
            grouping: scopedHealthScores, by: \.storeId
        ).compactMapValues { $0.max(by: { $0.generatedAt < $1.generatedAt }) }

        // Build per-store health summaries
        let allActivity = buildActivity(from: data, exceptions: currentExceptions)
        let storeSummaries: [StoreHealthSummary] = latestScoreByStore.compactMap { storeId, score in
            guard let store = storesById[storeId] else { return nil }
            let openIssuesForStore = data.inventoryExceptions
                .filter { $0.storeId == storeId && $0.isOpen }
                .sorted { $0.createdAt > $1.createdAt }
                .map { ex in
                    OpenIssue(
                        id: ex.id,
                        label: ex.exceptionType,
                        category: ExceptionCategory.category(forExceptionType: ex.exceptionType),
                        priority: ex.priority,
                        createdAt: ex.createdAt
                    )
                }
            let storeActivity = allActivity.filter { $0.storeId == storeId }
            return StoreHealthSummary(
                id: storeId,
                storeName: store.name,
                overallScore: score.overallScore,
                salesScore: score.salesScore,
                inventoryScore: score.inventoryScore,
                customerScore: score.customerScore,
                openIssues: openIssuesForStore,
                recentActivity: Array(storeActivity.prefix(5))
            )
        }

        // MARK: KPI 1 — Compliance score + delta
        let currentAvgScore  = average(currentHealthScores.isEmpty ? Array(latestScoreByStore.values) : currentHealthScores, \.overallScore)
        let previousAvgScore = average(previousHealthScores, \.overallScore)
        let deltaPct: Double = previousAvgScore > 0 ? ((currentAvgScore - previousAvgScore) / previousAvgScore) * 100 : 0

        // MARK: KPI 2 — Stores at risk
        let atRiskSummaries = storeSummaries.filter { $0.overallScore < complianceAttentionThreshold }

        // MARK: KPI 3 — Critical exceptions
        let criticalIssues = currentExceptions.filter { $0.isOpen && $0.isCriticalPriority }

        // MARK: KPI 4 — Inventory accuracy (shown in the exported report)
        let inventoryAccuracy = average(
            currentHealthScores.isEmpty ? Array(latestScoreByStore.values) : currentHealthScores,
            \.inventoryScore
        )

        // MARK: Section 2 — Dual-line operational trend
        let operationalTrend = operationalTrendPoints(currentHealthScores, in: currentInterval)

        // MARK: Section 3 — Stores at risk (surfaced inside the Compliance Score inspector)
        let riskHotspots: [RiskHotspot] = atRiskSummaries
            .sorted { $0.overallScore < $1.overallScore }
            .map { summary in
                RiskHotspot(
                    id: summary.id,
                    storeName: summary.storeName,
                    overallScore: summary.overallScore,
                    openIssuesTotal: summary.openIssues.count,
                    healthSummary: summary
                )
            }

        // MARK: Section 4 — Exception type counts with trend delta + severity

        func countOpen(_ type: String)     -> Int { currentExceptions.filter { $0.exceptionType == type && $0.isOpen }.count }
        func thisWeek(_ type: String)      -> Int { currentExceptions.filter { $0.exceptionType == type && $0.createdAt >= currentWeekStart }.count }
        func lastWeekCount(_ type: String) -> Int { currentExceptions.filter { $0.exceptionType == type && $0.createdAt >= lastWeekStart && $0.createdAt < currentWeekStart }.count }
        func delta(_ type: String)         -> Int { thisWeek(type) - lastWeekCount(type) }

        let exceptionCounts: [ExceptionTypeCount] = [
            makeException("Missing Item",      count: countOpen("Missing Item"),      delta: delta("Missing Item"),      category: .inventory,  icon: "shippingbox",                    exceptionType: "Missing Item"),
            makeException("Extra Item",        count: countOpen("Extra Item"),        delta: delta("Extra Item"),        category: .inventory,  icon: "plus.square.on.square",          exceptionType: "Extra Item"),
            makeException("Wrong Quantity",    count: countOpen("Wrong Quantity"),    delta: delta("Wrong Quantity"),    category: .inventory,  icon: "number",                         exceptionType: "Wrong Quantity"),
            makeException("Damaged Product",   count: countOpen("Damaged Product"),   delta: delta("Damaged Product"),   category: .inventory,  icon: "exclamationmark.triangle",       exceptionType: "Damaged Product"),
            makeException("Shipment Mismatch", count: countOpen("Shipment Mismatch"), delta: delta("Shipment Mismatch"), category: .shipment,   icon: "shippingbox.and.arrow.backward", exceptionType: "Shipment Mismatch"),
            makeException("Store Mismatch",    count: countOpen("Store Mismatch"),    delta: delta("Store Mismatch"),    category: .compliance, icon: "building.2",                     exceptionType: "Store Mismatch"),
        ]

        // MARK: Risk Distribution — open exceptions grouped by their own severity column
        let openExceptionsForSeverity = currentExceptions.filter { $0.isOpen }
        let severityDistribution: [RiskSeverityBucket] = ["Critical", "High", "Medium", "Low"].map { sev in
            let count = openExceptionsForSeverity.filter { $0.priority == sev }.count
            return RiskSeverityBucket(severity: sev, count: count, tint: RiskSeverityBucket.palette(for: sev))
        }

        // MARK: Audit Health Score — derived operational risk metric
        let scopedStockRequests = scoped(data.stockRequests) { $0.storeId }
        let scopedShipments     = data.shipments // shipments have no direct store_id column
        let openExceptionsAll   = scopedExceptions.filter { $0.isOpen }

        func auditHealthScore(exceptions: [AInventoryException], asOf refDate: Date) -> Int {
            let criticalCount = exceptions.filter { $0.isOpen && $0.priority == "Critical" }.count
            let highCount     = exceptions.filter { $0.isOpen && $0.priority == "High" }.count
            let mediumCount   = exceptions.filter { $0.isOpen && $0.priority == "Medium" }.count
            let pendingUrgentRequests = scopedStockRequests.filter { $0.isOpen && $0.isUrgent && $0.createdAt <= refDate }.count
            let atRiskShipments       = scopedShipments.filter { $0.createdAt <= refDate && $0.isAtRisk(asOf: refDate) }.count
            let delayedCounts         = data.cycleCounts.filter { $0.isDelayed(asOf: refDate) }.count

            let penalty = Double(criticalCount) * 8
                + Double(highCount) * 4
                + Double(mediumCount) * 1.5
                + Double(pendingUrgentRequests) * 2.5
                + Double(atRiskShipments) * 3
                + Double(delayedCounts) * 3
            return Int(max(0, min(100, 100 - penalty)).rounded())
        }

        let currentAuditHealthScore  = auditHealthScore(exceptions: openExceptionsAll, asOf: now)
        let previousRefDate          = currentInterval.start
        let previousAuditHealthScore = auditHealthScore(
            exceptions: scopedExceptions.filter { $0.createdAt <= previousRefDate && ($0.resolvedAt == nil || $0.resolvedAt! > previousRefDate) },
            asOf: previousRefDate
        )
        let auditHealthDeltaPct: Double = previousAuditHealthScore > 0
            ? (Double(currentAuditHealthScore - previousAuditHealthScore) / Double(previousAuditHealthScore)) * 100
            : 0

        complianceSummary = ComplianceSummary(
            complianceScore: Int(currentAvgScore.rounded()),
            complianceRating: ComplianceRating.rating(for: currentAvgScore),
            complianceScoreDeltaPct: deltaPct,
            storesAtRiskCount: atRiskSummaries.count,
            criticalExceptionsCount: criticalIssues.count,
            inventoryAccuracy: inventoryAccuracy,
            auditHealthScore: currentAuditHealthScore,
            auditHealthDeltaPct: auditHealthDeltaPct,
            riskHotspots: riskHotspots,
            operationalTrend: operationalTrend,
            exceptionCounts: exceptionCounts,
            recentActivity: Array(allActivity.prefix(10)),
            severityDistribution: severityDistribution
        )

        scopedHealthScoresCache = scopedHealthScores
    }

    // MARK: Inspector helpers

    func exceptionRecords(for group: ExceptionTypeCount) -> [AInventoryException] {
        guard let data, let type = group.exceptionType else { return [] }
        let scoped = complianceStoreId.map { id in data.inventoryExceptions.filter { $0.storeId == id } } ?? data.inventoryExceptions
        return scoped.filter { $0.exceptionType == type && $0.isOpen }.sorted { $0.createdAt > $1.createdAt }
    }

    func storeName(forExceptionStoreId id: UUID?) -> String {
        guard let id, let store = stores.first(where: { $0.id == id }) else { return "Unknown Store" }
        return store.name
    }

    /// Every open exception at a given severity — used by the Risk
    /// Distribution bar chart's tap-to-drill-down.
    func exceptionRecords(forSeverity severity: String) -> [AInventoryException] {
        guard let data else { return [] }
        let scoped = complianceStoreId.map { id in data.inventoryExceptions.filter { $0.storeId == id } } ?? data.inventoryExceptions
        return scoped.filter { $0.priority == severity && $0.isOpen }.sorted { $0.createdAt > $1.createdAt }
    }

    /// Recomputes the Operational Health Trend independent of the global
    /// Time Range filter, for the chart's own embedded segmented control
    /// (7 Days / 30 Days / Quarter / Year).
    func trendPoints(forDays days: Int) -> [OperationalTrendPoint] {
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) ?? end
        return operationalTrendPoints(scopedHealthScoresCache, in: DateInterval(start: start, end: end))
    }

    // MARK: Export

    func exportPDF() {
        isExporting = true
        defer { isExporting = false }
        exportedFileURL = AuditLogExporter.makePDF(
            summary: complianceSummary,
            storeFilterName: storeName(for: complianceStoreId),
            dateRangeText: complianceDateFilter.rawValue
        )
    }

    func exportExceptionsCSV() {
        guard let data else { return }
        isExporting = true
        defer { isExporting = false }
        
        let storesById = Dictionary(uniqueKeysWithValues: stores.map { ($0.id, $0) })
        exportedFileURL = AuditLogExporter.makeExceptionsCSV(
            exceptions: data.inventoryExceptions,
            stores: storesById
        )
    }

    func exportComplianceCSV() {
        guard let data else { return }
        isExporting = true
        defer { isExporting = false }
        
        let storesById = Dictionary(uniqueKeysWithValues: stores.map { ($0.id, $0) })
        exportedFileURL = AuditLogExporter.makeComplianceCSV(
            scores: data.healthScores,
            stores: storesById
        )
    }

    private func storeName(for id: UUID?) -> String {
        guard let id, let store = stores.first(where: { $0.id == id }) else { return "All Stores" }
        return store.name
    }

    // MARK: Activity building

    private func buildActivity(from data: AuditLogsData, exceptions: [AInventoryException]) -> [ActivityItem] {
        var items: [ActivityItem] = []

        for exception in exceptions {
            let store = storeName(forExceptionStoreId: exception.storeId)
            if let resolvedAt = exception.resolvedAt {
                items.append(ActivityItem(
                    id: exception.id, date: resolvedAt,
                    title: "\(exception.exceptionType) Resolved",
                    subtitle: store,
                    icon: "checkmark.circle.fill", tint: .green,
                    storeId: exception.storeId
                ))
            } else {
                items.append(ActivityItem(
                    id: exception.id, date: exception.createdAt,
                    title: "\(exception.exceptionType) Detected",
                    subtitle: store,
                    icon: "exclamationmark.triangle.fill",
                    tint: exception.isCriticalPriority ? Color(red: 0.95, green: 0.15, blue: 0.15) : Color(red: 1.0, green: 0.55, blue: 0.0),
                    storeId: exception.storeId
                ))
            }
        }

        for count in data.cycleCounts where count.status == "Completed" {
            let date = count.completedDate ?? count.createdAt
            guard complianceDateFilter.interval(calendar: calendar)?.contains(date) ?? true else { continue }
            items.append(ActivityItem(
                id: count.id, date: date,
                title: "Cycle Count Completed",
                subtitle: count.zone ?? "Warehouse Audit",
                icon: "checkmark.seal.fill", tint: .rsmsBlue,
                storeId: nil
            ))
        }

        return items.sorted { $0.date > $1.date }
    }

    // MARK: Numeric helpers

    private func average<T>(_ items: [T], _ keyPath: KeyPath<T, Double>) -> Double {
        guard !items.isEmpty else { return 0 }
        return items.reduce(0) { $0 + $1[keyPath: keyPath] } / Double(items.count)
    }

    /// Builds the dual-line (compliance + inventory) trend series.
    private func operationalTrendPoints(_ items: [AHealthScore], in interval: DateInterval) -> [OperationalTrendPoint] {
        let end = calendar.startOfDay(for: min(interval.end, Date()))
        // Guard only against unbounded ("All time") intervals — cap those
        // to a year back so the chart stays readable. Explicit ranges
        // (7D/30D/Quarter/Year) pass through untouched.
        let flooredStart = interval.start > .distantPast
            ? interval.start
            : (calendar.date(byAdding: .year, value: -1, to: end) ?? end)
        let start = calendar.startOfDay(for: min(flooredStart, end))
        let days  = calendar.generateDays(from: start, to: end)
        
        let scoresByStore = Dictionary(grouping: items, by: \.storeId)
        let allStoreIds = Array(scoresByStore.keys)
        
        guard !allStoreIds.isEmpty else { return [] }
        
        return days.map { day in
            var dayOverallScores: [Double] = []
            var dayInventoryScores: [Double] = []
            
            for storeId in allStoreIds {
                if let storeScores = scoresByStore[storeId] {
                    let activeScore = storeScores
                        .filter { calendar.startOfDay(for: $0.generatedAt) <= day }
                        .max(by: { $0.generatedAt < $1.generatedAt })
                    
                    if let score = activeScore {
                        dayOverallScores.append(score.overallScore)
                        dayInventoryScores.append(score.inventoryScore)
                    }
                }
            }
            
            let avgCompliance = dayOverallScores.isEmpty ? 0 : (dayOverallScores.reduce(0, +) / Double(dayOverallScores.count))
            let avgInventory  = dayInventoryScores.isEmpty ? 0 : (dayInventoryScores.reduce(0, +) / Double(dayInventoryScores.count))
            
            return OperationalTrendPoint(
                day: day,
                complianceScore: avgCompliance,
                inventoryAccuracy: avgInventory
            )
        }
    }

    private func makeException(
        _ title: String, count: Int, delta: Int,
        category: ExceptionCategory, icon: String, exceptionType: String?
    ) -> ExceptionTypeCount {
        ExceptionTypeCount(
            title: title, count: count, weeklyDelta: delta,
            severity: ExceptionSeverity.severity(count: count, delta: max(0, delta)),
            category: category, icon: icon, exceptionType: exceptionType
        )
    }

}

// MARK: - Calendar extension

private extension Calendar {
    func generateDays(from start: Date, to end: Date) -> [Date] {
        var days: [Date] = []
        var cursor = startOfDay(for: start)
        let last   = startOfDay(for: end)
        while cursor <= last {
            days.append(cursor)
            guard let next = date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }
}
