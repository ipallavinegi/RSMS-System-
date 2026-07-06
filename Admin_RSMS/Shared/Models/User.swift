//
//  User.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

public struct User: Codable, Identifiable {
    public let id: UUID

    // Basic Information
    public let fullName: String
    public let username: String
    public let email: String

    // Authentication
    public let isVerified: Bool?
    public let lastLogin: Date?

    // Organization
    public let roleId: UUID
    public let storeId: UUID?
    public let shiftId: UUID?

    // Employee Information
    public let employeeCode: String?
    public let designation: String?

    public let phone: String?
    public let gender: String?

    public let dateOfBirth: String?      // PostgreSQL DATE type — stored as "YYYY-MM-DD"
    public let address: String?

    public let joiningDate: String?      // PostgreSQL DATE type — stored as "YYYY-MM-DD"
    public let employeeStatus: String?

    public let profileImageURL: String?

    // Audit
    public let createdBy: UUID?
    public let createdAt: Date

    public enum CodingKeys: String, CodingKey {
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

    public init(
        id: UUID,
        fullName: String,
        username: String,
        email: String,
        isVerified: Bool? = nil,
        lastLogin: Date? = nil,
        roleId: UUID,
        storeId: UUID? = nil,
        shiftId: UUID? = nil,
        employeeCode: String? = nil,
        designation: String? = nil,
        phone: String? = nil,
        gender: String? = nil,
        dateOfBirth: String? = nil,
        address: String? = nil,
        joiningDate: String? = nil,
        employeeStatus: String? = nil,
        profileImageURL: String? = nil,
        createdBy: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fullName = fullName
        self.username = username
        self.email = email
        self.isVerified = isVerified
        self.lastLogin = lastLogin
        self.roleId = roleId
        self.storeId = storeId
        self.shiftId = shiftId
        self.employeeCode = employeeCode
        self.designation = designation
        self.phone = phone
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.address = address
        self.joiningDate = joiningDate
        self.employeeStatus = employeeStatus
        self.profileImageURL = profileImageURL
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}
