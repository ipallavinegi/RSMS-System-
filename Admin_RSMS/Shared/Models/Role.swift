//
//  Role.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//


import Foundation

struct Role: Identifiable, Codable {
    let id: UUID
    let roleName: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case roleName = "role_name"
        case createdAt = "created_at"
    }
}
