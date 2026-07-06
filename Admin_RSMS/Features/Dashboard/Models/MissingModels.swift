import Foundation

struct Store: Codable, Identifiable {
    let id: UUID
    let storeName: String
    let pinCode: String
    let region: String
    let country: String
    let city: String
    let status: String
    let managerId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeName = "store_name"
        case pinCode = "pin_code"
        case region
        case country
        case city
        case status
        case managerId = "manager_id"
        case createdAt = "created_at"
    }
}

/// Matches the real `store_targets` table (see RSMS schema doc, table 27).
/// There is no `sales_targets` table and no `period_type`/`period_start`/
/// `period_end`/`target_amount` columns — targets are simply one row per
/// store per calendar month.
struct StoreTarget: Codable, Identifiable {
    let id: UUID
    let storeId: UUID?
    let targetMonth: Date
    let revenueTarget: Double
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case targetMonth = "target_month"
        case revenueTarget = "revenue_target"
        case createdAt = "created_at"
    }
}

/// There is no `shift_assignments` table in the schema. A user's shift is
/// assigned directly via `users.shift_id` (see RSMS schema doc, table 4),
/// so shift assignment is derived straight from `User` records instead of
/// a separate join table.

/// There is no dedicated `appointments` table in the schema. Appointments
/// are one flavor of the `tasks` table (see RSMS schema doc, table 12),
/// distinguished by `task_type = 'Appointment'`. `Tasks` only stores a
/// single `due_date` (DATE, no time) and has no `customer_id` column, so
/// `customerId` and `appointmentEnd` are necessarily unavailable until/
/// unless the schema is extended with real appointment columns.
struct Appointment: Codable, Identifiable {
    let id: UUID
    let storeId: UUID
    let customerId: UUID?
    let assignedUserId: UUID?
    let appointmentStart: Date
    let appointmentEnd: Date?
    let purpose: String?
    let priority: String
    let status: String
    let notes: String?
    let createdAt: Date
}

/// Matches the real `tasks` table. Rows with `taskType == "Appointment"`
/// are adapted into `Appointment` via `asAppointment`; every other
/// `task_type` (Reminder, VIP Event, Client Visit, Inventory Task,
/// Follow-Up, General Task) is out of scope for this dashboard.
struct TaskRecord: Codable, Identifiable {
    let id: UUID
    let storeId: UUID?
    let title: String
    let description: String?
    let priority: String?
    let status: String?
    let assignedTo: UUID?
    let dueDate: Date?
    let createdBy: UUID?
    let createdAt: Date?
    let completedAt: Date?
    let taskType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case title
        case description
        case priority
        case status
        case assignedTo = "assigned_to"
        case dueDate = "due_date"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case taskType = "task_type"
    }
}

extension TaskRecord {
    /// `Appointment` still requires storeId/priority/status since the rest
    /// of the dashboard treats those as load-bearing; rows missing them
    /// (or with `task_type` other than "Appointment") are filtered out in
    /// `DashboardService` before this is ever called.
    var asAppointment: Appointment? {
        guard let storeId else { return nil }
        return Appointment(
            id: id,
            storeId: storeId,
            customerId: nil,
            assignedUserId: assignedTo,
            appointmentStart: dueDate ?? createdAt ?? Date(),
            appointmentEnd: nil,
            purpose: title,
            priority: priority ?? "Medium",
            status: status ?? "Pending",
            notes: description,
            createdAt: createdAt ?? Date()
        )
    }
}
