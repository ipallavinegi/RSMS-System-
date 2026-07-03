//
//  HealthScore.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct HealthScore: Codable, Identifiable {
    let id: UUID
    let storeId: UUID
    let salesScore: Double
    let inventoryScore: Double
    let customerScore: Double
    let overallScore: Double
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case salesScore = "sales_score"
        case inventoryScore = "inventory_score"
        case customerScore = "customer_score"
        case overallScore = "overall_score"
        case generatedAt = "generated_at"
    }
}
