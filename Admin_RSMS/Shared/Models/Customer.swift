
//
//  Customer.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Customer: Codable, Identifiable {
    let id: UUID

    // Basic Information
    let name: String
    let phone: String
    let email: String
    let gender: String?

    // Important Dates
    let dateOfBirth: Date?
    let anniversaryDate: Date?
    let lastVisitDate: Date?

    // Clienteling & Preferences
    let preferredBrand: String?
    let preferredCategory: String?
    let preferredContactMethod: String?
    let wishlist: String?
    let notes: String?

    // Relationship Management
    let assignedSalesAssociateId: UUID?
    let assignedStoreId: UUID?

    // Customer Classification
    let customerTier: String?
    let customerStatus: String?

    // Privacy & Loyalty
    let privacyConsent: Bool
    let loyaltyPoints: Int

    // Status Flags
    let isVip: Bool
    let isActive: Bool

    // Audit
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id

        case name
        case phone
        case email
        case gender

        case dateOfBirth = "date_of_birth"
        case anniversaryDate = "anniversary_date"
        case lastVisitDate = "last_visit_date"

        case preferredBrand = "preferred_brand"
        case preferredCategory = "preferred_category"
        case preferredContactMethod = "preferred_contact_method"

        case wishlist
        case notes

        case assignedSalesAssociateId = "assigned_sales_associate_id"
        case assignedStoreId = "assigned_store_id"

        case customerTier = "customer_tier"
        case customerStatus = "customer_status"

        case privacyConsent = "privacy_consent"
        case loyaltyPoints = "loyalty_points"

        case isVip = "is_vip"
        case isActive = "is_active"

        case createdAt = "created_at"
    }
}

