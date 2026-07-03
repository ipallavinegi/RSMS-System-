//
//  Category.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Category: Identifiable, Codable {
    let id: UUID
    let categoryName: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case categoryName = "category_name"
        case createdAt = "created_at"
    }
}
