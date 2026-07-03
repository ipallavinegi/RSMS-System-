//
//  ProductImage.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct ProductImage: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let imageURL: String
    let isPrimary: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case imageURL = "image_url"
        case isPrimary = "is_primary"
        case createdAt = "created_at"
    }
}
