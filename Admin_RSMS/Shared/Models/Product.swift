//
//  Product.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Product: Codable, Identifiable {
    let id: UUID

    // Identification
    let sku: String
    let barcode: String?

    // Product Information
    let productName: String
    let brand: String
    let categoryId: UUID?

    let description: String?
    let shortDescription: String?

    // Pricing
    let price: Double

    // Catalogue Attributes
    let material: String?
    let color: String?
    let size: String?
    let weight: String?

    let collectionName: String?
    let modelNumber: String?

    // Product Authentication
    let serialNumber: String?
    let certificateNumber: String?

    // Selling Information
    let warrantyDuration: String?
    let status: String?
    let approvalStatus: String?

    // Marketing
    let isNewArrival: Bool?
    let isBestSeller: Bool?
    let isLimitedEdition: Bool?

    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id

        case sku
        case barcode

        case productName = "product_name"
        case brand
        case categoryId = "category_id"

        case description
        case shortDescription = "short_description"

        case price

        case material
        case color
        case size
        case weight

        case collectionName = "collection_name"
        case modelNumber = "model_number"

        case serialNumber = "serial_number"
        case certificateNumber = "certificate_number"

        case warrantyDuration = "warranty_duration"

        case status
        case approvalStatus = "approval_status"

        case isNewArrival = "is_new_arrival"
        case isBestSeller = "is_best_seller"
        case isLimitedEdition = "is_limited_edition"

        case createdAt = "created_at"
    }
}
