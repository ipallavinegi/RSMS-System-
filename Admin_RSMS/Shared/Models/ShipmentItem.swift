//
//  ShipmentItem.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//
import Foundation

struct ShipmentItem: Codable, Identifiable {
    let id: UUID
    let shipmentId: UUID
    let productId: UUID
    let expectedQuantity: Int
    let receivedQuantity: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case shipmentId = "shipment_id"
        case productId = "product_id"
        case expectedQuantity = "expected_quantity"
        case receivedQuantity = "received_quantity"
        case status
    }
}
