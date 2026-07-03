//
//  Report.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Report: Identifiable, Codable {
    let id: UUID
    let reportType: String
    let generatedBy: UUID
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case reportType = "report_type"
        case generatedBy = "generated_by"
        case generatedAt = "generated_at"
    }
}
