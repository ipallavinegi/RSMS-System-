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

struct SalesTarget: Codable, Identifiable {
    let id: UUID
    let storeId: UUID
    let periodType: String
    let periodStart: Date
    let periodEnd: Date
    let targetAmount: Double
    let createdBy: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case periodType = "period_type"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case targetAmount = "target_amount"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

struct ShiftAssignment: Codable, Identifiable {
    let id: UUID
    let shiftId: UUID
    let userId: UUID
    let assignmentDate: Date
    let status: String
    let createdBy: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case shiftId = "shift_id"
        case userId = "user_id"
        case assignmentDate = "assignment_date"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

struct Appointment: Codable, Identifiable {
    let id: UUID
    let storeId: UUID
    let customerId: UUID
    let assignedUserId: UUID?
    let appointmentStart: Date
    let appointmentEnd: Date
    let purpose: String?
    let priority: String
    let status: String
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case customerId = "customer_id"
        case assignedUserId = "assigned_user_id"
        case appointmentStart = "appointment_start"
        case appointmentEnd = "appointment_end"
        case purpose
        case priority
        case status
        case notes
        case createdAt = "created_at"
    }
}
