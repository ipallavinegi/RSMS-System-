//
//  User.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID

    // Basic Information
    let fullName: String
    let username: String
    let email: String

    // Authentication
    let isVerified: Bool?
    let lastLogin: Date?

    // Organization
    let roleId: UUID
    let storeId: UUID?
    let shiftId: UUID?

    // Employee Information
    let employeeCode: String?
    let designation: String?

    let phone: String?
    let gender: String?

    let dateOfBirth: String?      // PostgreSQL DATE type — stored as "YYYY-MM-DD"
    let address: String?

    let joiningDate: String?      // PostgreSQL DATE type — stored as "YYYY-MM-DD"
    let employeeStatus: String?

    let profileImageURL: String?

    // Audit
    let createdBy: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id

        case fullName = "full_name"
        case username
        case email

        case isVerified = "is_verified"
        case lastLogin = "last_login"

        case roleId = "role_id"
        case storeId = "store_id"
        case shiftId = "shift_id"

        case employeeCode = "employee_code"
        case designation

        case phone
        case gender

        case dateOfBirth = "date_of_birth"
        case address

        case joiningDate = "joining_date"
        case employeeStatus = "employee_status"

        case profileImageURL = "profile_image_url"

        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}
