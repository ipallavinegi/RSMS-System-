//
//  Inventory.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct InventoryItem: Codable, Identifiable {
    let id: UUID
    let productId: UUID
    let storeId: UUID?
    let warehouseId: UUID?
    let locationType: String
    let quantity: Int
    let reorderLevel: Int
    let lastVerifiedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case storeId = "store_id"
        case warehouseId = "warehouse_id"
        case locationType = "location_type"
        case quantity
        case reorderLevel = "reorder_level"
        case lastVerifiedAt = "last_verified_at"
        case createdAt = "created_at"
    }
}
