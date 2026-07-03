//
//  PromotionType.swift
//  Admin_RSMS
//
//  Created by Yatharth Mishra on 03/07/26.
//

import Foundation

// MARK: - Promotion Type

enum PromotionType: String, CaseIterable, Codable, Identifiable {

    case seasonalCampaign = "Seasonal Campaign"
    case newCollection = "New Collection Launch"
    case vipEvent = "VIP Client Event"
    case privateSale = "Private Sale"

    var id: String { rawValue }
}

// MARK: - Calculated Promotion State

enum PromotionState: String, CaseIterable, Identifiable {

    case upcoming = "Upcoming"
    case active = "Active"
    case ended = "Ended"

    var id: String { rawValue }
}

// MARK: - AdminPromotion

struct AdminPromotion: Identifiable, Codable, Hashable {

    var id: UUID

    var promotionName: String
    var promotionType: String

    var categoryId: UUID?
    var description: String?

    var startDate: String
    var endDate: String

    var appliesToAllStores: Bool
    var storeId: UUID?

    var bannerImageUrl: String?

    // Keeping because it exists in DB
    var status: String

    var createdBy: UUID?
    var createdAt: Date?
    var updatedAt: Date?

    // MARK: Coding Keys

    enum CodingKeys: String, CodingKey {

        case id

        case promotionName = "promotion_name"
        case promotionType = "promotion_type"

        case categoryId = "category_id"
        case description

        case startDate = "start_date"
        case endDate = "end_date"

        case appliesToAllStores = "applies_to_all_stores"
        case storeId = "store_id"

        case bannerImageUrl = "banner_image_url"

        case status

        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: Init

    init(
        id: UUID = UUID(),
        promotionName: String,
        promotionType: String,
        categoryId: UUID? = nil,
        description: String? = nil,
        startDate: String,
        endDate: String,
        appliesToAllStores: Bool = true,
        storeId: UUID? = nil,
        bannerImageUrl: String? = nil,
        status: String = "",
        createdBy: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {

        self.id = id
        self.promotionName = promotionName
        self.promotionType = promotionType

        self.categoryId = categoryId
        self.description = description

        self.startDate = startDate
        self.endDate = endDate

        self.appliesToAllStores = appliesToAllStores
        self.storeId = storeId

        self.bannerImageUrl = bannerImageUrl

        self.status = status

        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: Calculated State

    var promotionState: PromotionState {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard
            let start = formatter.date(from: startDate),
            let end = formatter.date(from: endDate)
        else {
            return .upcoming
        }

        let today = Date()

        if today < start {
            return .upcoming
        }

        if today > end {
            return .ended
        }

        return .active
    }
}

// MARK: - Payload

struct AdminPromotionPayload: Encodable {

    let promotionName: String
    let promotionType: String

    let categoryId: UUID?
    let description: String?

    let startDate: String
    let endDate: String

    let appliesToAllStores: Bool
    let storeId: UUID?

    let bannerImageUrl: String?

    let createdBy: UUID?

    enum CodingKeys: String, CodingKey {

        case promotionName = "promotion_name"
        case promotionType = "promotion_type"

        case categoryId = "category_id"
        case description

        case startDate = "start_date"
        case endDate = "end_date"

        case appliesToAllStores = "applies_to_all_stores"
        case storeId = "store_id"

        case bannerImageUrl = "banner_image_url"

        case createdBy = "created_by"
    }

    init(from promotion: AdminPromotion) {

        self.promotionName = promotion.promotionName
        self.promotionType = promotion.promotionType

        self.categoryId = promotion.categoryId
        self.description = promotion.description

        self.startDate = promotion.startDate
        self.endDate = promotion.endDate

        self.appliesToAllStores = promotion.appliesToAllStores

        self.storeId = promotion.appliesToAllStores
            ? nil
            : promotion.storeId

        self.bannerImageUrl = promotion.bannerImageUrl

        self.createdBy = promotion.createdBy
    }
}
