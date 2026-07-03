//
//  Shipment.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Shipment: Codable, Identifiable {
    let id: UUID
    let shipmentNumber: String
    let shipmentType: String
    let source: String
    let destination: String
    let stockRequestId: UUID?
    let asnNumber: String?
    let trackingReference: String?
    let status: String
    let dispatchDate: Date?
    let receivedDate: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case shipmentNumber = "shipment_number"
        case shipmentType = "shipment_type"
        case source
        case destination
        case stockRequestId = "stock_request_id"
        case asnNumber = "asn_number"
        case trackingReference = "tracking_reference"
        case status
        case dispatchDate = "dispatch_date"
        case receivedDate = "received_date"
        case createdAt = "created_at"
    }
}
