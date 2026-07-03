//
//  Attendance.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Attendance: Codable, Identifiable {
    let id: UUID
    let employeeId: UUID
    let attendanceDate: Date
    let checkIn: Date?
    let checkOut: Date?
    let status: String
    let workingHours: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case employeeId = "employee_id"
        case attendanceDate = "attendance_date"
        case checkIn = "check_in"
        case checkOut = "check_out"
        case status
        case workingHours = "working_hours"
        case createdAt = "created_at"
    }
}
