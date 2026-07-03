//
//  Warehouse.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Warehouse: Identifiable, Codable {
    let id: UUID
    let warehouseName: String
    let city: String
    let status: String
    let createdAt: Date
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case warehouseName = "warehouse_name"
        case city
        case status
        case createdAt = "created_at"
    }
}
