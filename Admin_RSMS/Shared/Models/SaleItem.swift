//
//  SaleItem.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct SaleItem: Codable, Identifiable {
    let id: UUID
    let saleId: UUID
    let productId: UUID
    let quantity: Int
    let unitPrice: Double
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case saleId = "sale_id"
        case productId = "product_id"
        case quantity
        case unitPrice = "unit_price"
        case createdAt = "created_at"
    }
}
