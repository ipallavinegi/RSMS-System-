//
//  CycleCount.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct CycleCount: Identifiable, Codable {
    let id: UUID
    let warehouseId: UUID
    let scheduledDate: Date
    let completedDate: Date?
    let status: String
    let createdBy: UUID
    let remarks: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case warehouseId = "warehouse_id"
        case scheduledDate = "scheduled_date"
        case completedDate = "completed_date"
        case status
        case createdBy = "created_by"
        case remarks
        case createdAt = "created_at"
    }
}
