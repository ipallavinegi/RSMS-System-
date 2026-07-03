//
//  AuditLog.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct AuditLog: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let module: String
    let action: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case module
        case action
        case createdAt = "created_at"
    }
}
