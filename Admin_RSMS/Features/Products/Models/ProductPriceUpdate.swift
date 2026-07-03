//
//  ProductPriceUpdate.swift
//  Admin_RSMS
//
//  Created by Yatharth Mishra on 02/07/26.
//


import Foundation

/// Partial update payload — only ever writes price, nothing else on the row.
struct ProductPriceUpdate: Encodable {
    let price: Double
}