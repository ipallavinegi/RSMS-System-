//
//  Transfer.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Transfer: Codable, Identifiable {
    let id: UUID
    let stockRequestId: UUID
    let sourceStoreId: UUID
    let destinationStoreId: UUID
    let approvedBy: UUID?
    let status: String
    let transferDate: Date
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case stockRequestId = "stock_request_id"
        case sourceStoreId = "source_store_id"
        case destinationStoreId = "destination_store_id"
        case approvedBy = "approved_by"
        case status
        case transferDate = "transfer_date"
        case completedAt = "completed_at"
    }
}
