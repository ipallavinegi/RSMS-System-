//
//  Task.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct RSMSTask: Codable, Identifiable {
    let id: UUID
    let storeId: UUID
    let title: String
    let description: String?
    let priority: String
    let status: String
    let assignedTo: UUID?
    let dueDate: Date?
    let createdBy: UUID
    let createdAt: Date

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
    }
}
