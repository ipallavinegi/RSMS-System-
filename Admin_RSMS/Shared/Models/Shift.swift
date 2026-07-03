//
//  Shift.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Shift: Codable, Identifiable {
    let id: UUID
    let storeId: UUID
    let shiftName: String
    let startTime: String
    let endTime: String
    let status: String
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case shiftName = "shift_name"
        case startTime = "start_time"
        case endTime = "end_time"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}
