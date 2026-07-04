//
//  AuditLogsService.swift
//  Admin_RSMS
//
//  Service layer for the Audit & Compliance Center.
//  Contains:
//    • AuditLogsData       — the raw bundle returned by the service
//    • AuditDateFilter     — the time-range enum used by filters
//    • AuditLogDisplayItem — a display-ready projection of AuditLog + User
//    • AuditLogsServicing  — the testable protocol
//    • SupabaseAuditLogsService — the live Supabase implementation
//

import Foundation
import Supabase

// MARK: - AuditLogsData

/// All raw rows fetched in a single call — handed directly to the ViewModel.
struct AuditLogsData {
    let auditLogs:           [AuditLog]
    let users:               [User]
    let healthScores:        [AHealthScore]
    let inventoryExceptions: [AInventoryException]
    let stockRequests:       [AStockRequest]
    let shipments:           [AShipment]
    let cycleCounts:         [ACycleCount]
}

// MARK: - AuditDateFilter

enum AuditDateFilter: String, CaseIterable, Identifiable {
    case last7Days   = "Last 7 Days"
    case last30Days  = "Last 30 Days"
    case lastQuarter = "Last Quarter"
    case lastYear    = "Last Year"
    case allTime     = "All Time"

    var id: String { rawValue }

    /// Returns the date interval for this filter, or nil for "All Time".
    func interval(calendar: Calendar, now: Date = Date()) -> DateInterval? {
        let end = now
        switch self {
        case .last7Days:
            guard let start = calendar.date(byAdding: .day, value: -7, to: end) else { return nil }
            return DateInterval(start: start, end: end)
        case .last30Days:
            guard let start = calendar.date(byAdding: .day, value: -30, to: end) else { return nil }
            return DateInterval(start: start, end: end)
        case .lastQuarter:
            guard let start = calendar.date(byAdding: .month, value: -3, to: end) else { return nil }
            return DateInterval(start: start, end: end)
        case .lastYear:
            guard let start = calendar.date(byAdding: .year, value: -1, to: end) else { return nil }
            return DateInterval(start: start, end: end)
        case .allTime:
            return nil
        }
    }
}

// MARK: - AuditLogDisplayItem

/// A display-ready projection of an AuditLog row enriched with user info.
struct AuditLogDisplayItem: Identifiable {
    let id: UUID
    let date: Date
    let module: String
    let action: String
    let userName: String
    let userEmail: String
    /// The store the acting user belonged to at the time of the log.
    let userStoreId: UUID?

    static func make(from log: AuditLog, user: User?) -> AuditLogDisplayItem {
        AuditLogDisplayItem(
            id: log.id,
            date: log.createdAt,
            module: log.module,
            action: log.action,
            userName: user?.fullName ?? "Unknown",
            userEmail: user?.email ?? "",
            userStoreId: user?.storeId
        )
    }
}

// MARK: - AuditLogsServicing

protocol AuditLogsServicing {
    func fetchAuditLogsData() async throws -> AuditLogsData
}

// MARK: - SupabaseAuditLogsService

final class SupabaseAuditLogsService: AuditLogsServicing {
    private let client = SupabaseManager.shared.client

    func fetchAuditLogsData() async throws -> AuditLogsData {
        async let auditLogs:           [AuditLog]            = client.from("audit_logs").select().execute().value
        async let users:               [User]                = client.from("users").select().execute().value
        async let healthScores:        [AHealthScore]        = client.from("health_scores").select().execute().value
        async let inventoryExceptions: [AInventoryException] = client.from("inventory_exceptions").select().execute().value
        async let stockRequests:       [AStockRequest]       = client.from("stock_requests").select("id, store_id, product_id, priority, status, created_at").execute().value
        async let shipments:           [AShipment]           = client.from("shipments").select("id, status, dispatch_date, received_date, verified_at, created_at").execute().value
        async let cycleCounts:         [ACycleCount]         = client.from("cycle_counts").select().execute().value

        return try await AuditLogsData(
            auditLogs:           auditLogs,
            users:               users,
            healthScores:        healthScores,
            inventoryExceptions: inventoryExceptions,
            stockRequests:       stockRequests,
            shipments:           shipments,
            cycleCounts:         cycleCounts
        )
    }
}
