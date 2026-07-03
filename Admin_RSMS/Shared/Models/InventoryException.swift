//
//  InventoryException.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct InventoryException: Identifiable, Codable {
    let id: UUID
    let shipmentId: UUID?
    let storeId: UUID
    let productId: UUID
    let exceptionType: String
    let priority: String
    let status: String
    let remarks: String?
    let reportedBy: UUID
    let createdAt: Date
    let resolvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case shipmentId = "shipment_id"
        case storeId = "store_id"
        case productId = "product_id"
        case exceptionType = "exception_type"
        case priority
        case status
        case remarks
        case reportedBy = "reported_by"
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
    }
}
