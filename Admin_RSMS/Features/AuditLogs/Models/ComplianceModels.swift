//
//  ComplianceModels.swift
//  Admin_RSMS
//
//  All model types for the Audit & Compliance Center.
//  Philosophy: Dashboard = Performance.  Audit = Risk.
//

import Foundation
import SwiftUI

// MARK: - Raw rows (1:1 with the schema)

struct AHealthScore: Codable, Identifiable {
    let id: UUID
    let storeId: UUID
    let salesScore: Double
    let inventoryScore: Double
    let customerScore: Double
    let overallScore: Double
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case salesScore = "sales_score"
        case inventoryScore = "inventory_score"
        case customerScore = "customer_score"
        case overallScore = "overall_score"
        case generatedAt = "generated_at"
    }
}

struct AInventoryException: Codable, Identifiable {
    let id: UUID
    let shipmentId: UUID?
    let storeId: UUID?
    let productId: UUID?
    let exceptionType: String
    let priority: String
    let status: String
    let remarks: String?
    let reportedBy: UUID?
    let createdAt: Date
    let resolvedAt: Date?

    var isOpen: Bool { status == "Open" || status == "Investigating" }
    var isCriticalPriority: Bool { priority == "Critical" || priority == "High" }

    enum CodingKeys: String, CodingKey {
        case id
        case shipmentId = "shipment_id"
        case storeId = "store_id"
        case productId = "product_id"
        case exceptionType = "exception_type"
        case priority
        case status
        case remarks
        case reportedBy = "reported_by"
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
    }
}

struct ACycleCount: Identifiable, Decodable {
    let id: UUID
    let warehouseId: UUID
    let scheduledDate: Date
    let completedDate: Date?
    let status: String
    let createdBy: UUID?
    let remarks: String?
    let createdAt: Date
    let zone: String?

    func isDelayed(asOf now: Date = Date()) -> Bool {
        status != "Completed" && status != "Cancelled" && scheduledDate < now
    }

    enum CodingKeys: String, CodingKey {
        case id
        case warehouseId = "warehouse_id"
        case scheduledDate = "scheduled_date"
        case completedDate = "completed_date"
        case status
        case createdBy = "created_by"
        case remarks
        case createdAt = "created_at"
        case zone
    }

    // `scheduled_date` / `completed_date` are PostgreSQL DATE columns —
    // Supabase returns them as plain "YYYY-MM-DD" strings, not full
    // ISO8601 timestamps. The default Codable-synthesized Date decoding
    // expects a timestamp and throws ("data isn't in the correct
    // format") on a date-only string, which is what was crashing the
    // whole audit-data load. Decode those two fields manually here;
    // everything else still comes from the client's normal timestamp decoding.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        warehouseId = try c.decode(UUID.self, forKey: .warehouseId)
        scheduledDate = try Self.decodeDateOnly(c, .scheduledDate) ?? .distantPast
        completedDate = try Self.decodeDateOnly(c, .completedDate)
        status = try c.decode(String.self, forKey: .status)
        createdBy = try c.decodeIfPresent(UUID.self, forKey: .createdBy)
        remarks = try c.decodeIfPresent(String.self, forKey: .remarks)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        zone = try c.decodeIfPresent(String.self, forKey: .zone)
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static func decodeDateOnly(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) throws -> Date? {
        guard let raw = try c.decodeIfPresent(String.self, forKey: key) else { return nil }
        return dateOnlyFormatter.date(from: raw)
    }
}


// MARK: - Additional raw rows (Audit Health Score inputs)

/// Minimal projection of `stock_requests` — only what's needed to penalize
/// the Audit Health Score for stale/unfulfilled replenishment requests.
struct AStockRequest: Codable, Identifiable {
    let id: UUID
    let storeId: UUID?
    let productId: UUID?
    let priority: String
    let status: String
    let createdAt: Date

    var isOpen: Bool { status == "Pending" || status == "Approved" }
    var isUrgent: Bool { priority == "Critical" || priority == "High" }

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case productId = "product_id"
        case priority
        case status
        case createdAt = "created_at"
    }
}

/// Minimal projection of `shipments` — only what's needed to penalize the
/// Audit Health Score for shipments stuck in transit or awaiting verification.
struct AShipment: Codable, Identifiable {
    let id: UUID
    let status: String
    let dispatchDate: Date?
    let receivedDate: Date?
    let verifiedAt: Date?
    let createdAt: Date

    /// A shipment is "at risk" if it's been dispatched/in-transit for more
    /// than 5 days without being verified, or delivered but never verified.
    func isAtRisk(asOf now: Date = Date()) -> Bool {
        switch status {
        case "Delivered":
            return verifiedAt == nil
        case "Dispatched", "In Transit":
            guard let dispatchDate else { return false }
            return now.timeIntervalSince(dispatchDate) > 5 * 24 * 3600
        default:
            return false
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case dispatchDate = "dispatch_date"
        case receivedDate = "received_date"
        case verifiedAt = "verified_at"
        case createdAt = "created_at"
    }
}

// MARK: - Risk Distribution (Section 3 — horizontal severity bar chart)

/// One severity bucket in the Risk Distribution bar chart — counts every
/// open inventory exception by its own `priority` column (Critical/High/
/// Medium/Low), independent of the type-based Operational Exception cards.
struct RiskSeverityBucket: Identifiable {
    var id: String { severity }
    let severity: String   // "Critical" | "High" | "Medium" | "Low"
    let count: Int
    let tint: Color

    static func palette(for severity: String) -> Color {
        switch severity {
        case "Critical": return Color(red: 0.95, green: 0.15, blue: 0.15)
        case "High":     return Color(red: 1.0,  green: 0.55, blue: 0.0)
        case "Medium":   return Color(red: 0.95, green: 0.75, blue: 0.10)
        default:         return Color(red: 0.2,  green: 0.78, blue: 0.35)
        }
    }
}

// MARK: - Exception categorisation

enum ExceptionCategory: String, CaseIterable, Identifiable {
    case inventory  = "Inventory"
    case shipment   = "Shipment"
    case compliance = "Compliance"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .inventory:  return .orange
        case .shipment:   return .purple
        case .compliance: return .red
        }
    }

    static func category(forExceptionType type: String) -> ExceptionCategory {
        switch type {
        case "Shipment Mismatch":                  return .shipment
        case "Store Mismatch":                     return .compliance
        default:                                   return .inventory
        }
    }
}

// MARK: - Exception severity

/// Derived severity for each exception type card in the Operational Exceptions grid.
enum ExceptionSeverity: String {
    case critical = "Critical"
    case high     = "High"
    case medium   = "Medium"
    case low      = "Low"

    var tint: Color {
        switch self {
        case .critical: return Color(red: 0.95, green: 0.15, blue: 0.15)
        case .high:     return Color(red: 1.0,  green: 0.55, blue: 0.0)
        case .medium:   return Color(red: 0.95, green: 0.75, blue: 0.10)
        case .low:      return Color(red: 0.2,  green: 0.78, blue: 0.35)
        }
    }

    var labelColor: Color {
        switch self {
        case .critical, .high: return .white
        case .medium, .low:    return .primary
        }
    }

    /// Derive severity from open count and weekly change delta.
    static func severity(count: Int, delta: Int) -> ExceptionSeverity {
        if count >= 10 || delta >= 5 { return .critical }
        if count >= 5  || delta >= 3 { return .high }
        if count >= 1  || delta >= 1 { return .medium }
        return .low
    }
}

// MARK: - Compliance score interpretation

enum ComplianceRating: String {
    case excellent      = "Excellent"
    case good           = "Good"
    case needsAttention = "Needs Attention"
    case critical       = "Critical"

    var tint: Color {
        switch self {
        case .excellent:      return Color(red: 0.18, green: 0.76, blue: 0.38)
        case .good:           return .rsmsBlue
        case .needsAttention: return Color(red: 1.0,  green: 0.55, blue: 0.0)
        case .critical:       return Color(red: 0.95, green: 0.15, blue: 0.15)
        }
    }

    static func rating(for score: Double) -> ComplianceRating {
        switch score {
        case 90...:      return .excellent
        case 75..<90:    return .good
        case 60..<75:    return .needsAttention
        default:         return .critical
        }
    }
}

/// Stores below this overall-score threshold appear in the Risk Hotspots carousel.
let complianceAttentionThreshold: Double = 75

// MARK: - Derived / display models

struct OpenIssue: Identifiable, Hashable {
    let id: UUID
    let label: String
    let category: ExceptionCategory
    let priority: String
    let createdAt: Date

    static func == (lhs: OpenIssue, rhs: OpenIssue) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A timeline entry shown in the Recent Compliance Events section.
struct ActivityItem: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let storeId: UUID?

    static func == (lhs: ActivityItem, rhs: ActivityItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Full health detail for a store — used by the inspector when a hotspot is tapped.
struct StoreHealthSummary: Identifiable, Hashable {
    let id: UUID
    let storeName: String
    let overallScore: Double
    let salesScore: Double
    let inventoryScore: Double
    let customerScore: Double
    let openIssues: [OpenIssue]
    let recentActivity: [ActivityItem]

    var rating: ComplianceRating { ComplianceRating.rating(for: overallScore) }

    static func == (lhs: StoreHealthSummary, rhs: StoreHealthSummary) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Operational Risk Trend (Section 2 — dual-line chart)

/// One data point for the dual-line Operational Risk Trend chart.
struct OperationalTrendPoint: Identifiable {
    let id = UUID()
    let day: Date
    let complianceScore: Double    // blue line
    let inventoryAccuracy: Double  // green line
}

// MARK: - Risk Hotspot (Section 3 — carousel)

/// A store that is below the compliance threshold.
/// Surfaced in the Compliance Score inspector's "Stores At Risk" list.
struct RiskHotspot: Identifiable, Hashable {
    let id: UUID               // storeId
    let storeName: String
    let overallScore: Double
    let openIssuesTotal: Int
    /// Full detail — passed to the store inspector when this row is tapped.
    let healthSummary: StoreHealthSummary

    var rating: ComplianceRating { ComplianceRating.rating(for: overallScore) }

    static func == (lhs: RiskHotspot, rhs: RiskHotspot) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Operational Exception card (Section 4)

/// One card in the Operational Exceptions grid.
struct ExceptionTypeCount: Identifiable {
    let id = UUID()
    let title: String
    let count: Int
    let weeklyDelta: Int           // positive = more issues vs last week
    let severity: ExceptionSeverity
    let category: ExceptionCategory
    let icon: String
    let exceptionType: String?     // nil for cycle-count-delays
}

// MARK: - Top-level summary fed to every section

struct ComplianceSummary {
    // KPI cards
    let complianceScore: Int
    let complianceRating: ComplianceRating
    let complianceScoreDeltaPct: Double
    let storesAtRiskCount: Int
    let criticalExceptionsCount: Int
    let inventoryAccuracy: Double
    /// Derived operational risk metric (0-100) blending unresolved
    /// exceptions, pending stock requests, at-risk shipments, and delayed
    /// cycle counts into one number. See `ComplianceRating` for banding.
    let auditHealthScore: Int
    let auditHealthDeltaPct: Double

    // Section data
    let riskHotspots: [RiskHotspot]               // Section 3
    let operationalTrend: [OperationalTrendPoint]  // Section 2
    let exceptionCounts: [ExceptionTypeCount]      // Section 4
    let recentActivity: [ActivityItem]             // Section 5
    let severityDistribution: [RiskSeverityBucket] // Risk Distribution bar chart

    var auditHealthRating: ComplianceRating { ComplianceRating.rating(for: Double(auditHealthScore)) }

    // MARK: Derived convenience

    /// Total open exceptions across every category — the single headline
    /// number shown on the report card. Category breakdown is one tap away.
    var totalOpenExceptions: Int { exceptionCounts.reduce(0) { $0 + $1.count } }

    static let empty = ComplianceSummary(
        complianceScore: 0,
        complianceRating: .critical,
        complianceScoreDeltaPct: 0,
        storesAtRiskCount: 0,
        criticalExceptionsCount: 0,
        inventoryAccuracy: 0,
        auditHealthScore: 0,
        auditHealthDeltaPct: 0,
        riskHotspots: [],
        operationalTrend: [],
        exceptionCounts: defaultExceptionCounts,
        recentActivity: [],
        severityDistribution: ["Critical", "High", "Medium", "Low"].map {
            RiskSeverityBucket(severity: $0, count: 0, tint: RiskSeverityBucket.palette(for: $0))
        }
    )

    /// Five zero-count cards shown before data loads (and when all is healthy).
    /// These map 1:1 to the real `inventory_exceptions.exception_type`
    /// values in the schema — no invented categories.
    static let defaultExceptionCounts: [ExceptionTypeCount] = [
        ExceptionTypeCount(title: "Missing Item",      count: 0, weeklyDelta: 0, severity: .low,
                           category: .inventory,  icon: "shippingbox",                         exceptionType: "Missing Item"),
        ExceptionTypeCount(title: "Extra Item",        count: 0, weeklyDelta: 0, severity: .low,
                           category: .inventory,  icon: "plus.square.on.square",                exceptionType: "Extra Item"),
        ExceptionTypeCount(title: "Wrong Quantity",    count: 0, weeklyDelta: 0, severity: .low,
                           category: .inventory,  icon: "number",                               exceptionType: "Wrong Quantity"),
        ExceptionTypeCount(title: "Damaged Product",   count: 0, weeklyDelta: 0, severity: .low,
                           category: .inventory,  icon: "exclamationmark.triangle",             exceptionType: "Damaged Product"),
        ExceptionTypeCount(title: "Shipment Mismatch", count: 0, weeklyDelta: 0, severity: .low,
                           category: .shipment,   icon: "shippingbox.and.arrow.backward",       exceptionType: "Shipment Mismatch"),
        ExceptionTypeCount(title: "Store Mismatch",    count: 0, weeklyDelta: 0, severity: .low,
                           category: .compliance, icon: "building.2",                           exceptionType: "Store Mismatch"),
    ]
}

// MARK: - Inspector content

/// What the bottom sheet is currently showing.
enum InspectorContent: Identifiable {
    /// Full health detail for one store — reached from the Compliance
    /// Score inspector's "Stores At Risk" list.
    case store(StoreHealthSummary)
    /// Records behind a single exception type — reached from the "Open
    /// Exceptions" breakdown list.
    case exceptionGroup(ExceptionTypeCount, [AInventoryException])
    /// Compliance Score stat tap — score ring, trend context, and the
    /// list of stores currently below threshold.
    case complianceScore(ComplianceSummary)
    /// Open Exceptions stat tap — breakdown by type, each row drills
    /// into `.exceptionGroup`.
    case allExceptions(ComplianceSummary)
    /// Audit Health Score stat tap — calculation breakdown and the
    /// factors currently dragging the score down.
    case auditHealthScore(ComplianceSummary)
    /// A bar in the Risk Distribution chart — every open exception at
    /// that severity, regardless of type.
    case severityGroup(String, [AInventoryException])
    /// An entry in the Recent Activity timeline.
    case activityDetail(ActivityItem)

    var id: String {
        switch self {
        case .store(let s):              return "store-\(s.id)"
        case .exceptionGroup(let g, _): return "group-\(g.id)"
        case .complianceScore:          return "compliance-score"
        case .allExceptions:            return "all-exceptions"
        case .auditHealthScore:         return "audit-health-score"
        case .severityGroup(let sev, _): return "severity-\(sev)"
        case .activityDetail(let a):     return "activity-\(a.id)"
        }
    }
}
