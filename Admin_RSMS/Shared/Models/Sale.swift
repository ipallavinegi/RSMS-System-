//
//  Sale.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//


import Foundation

struct Sale: Codable, Identifiable {
    let id: UUID
    let customerId: UUID
    let userId: UUID?
    let storeId: UUID
    let totalAmount: Double
    let paymentMethod: String
    let saleStatus: String
    let saleDate: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case userId = "user_id"
        case storeId = "store_id"
        case totalAmount = "total_amount"
        case paymentMethod = "payment_method"
        case saleStatus = "sale_status"
        case saleDate = "sale_date"
        case createdAt = "created_at"
    }
}
