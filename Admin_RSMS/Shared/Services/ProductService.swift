//
//  ProductService.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class ProductService {

    private let client = SupabaseManager.shared.client

    func fetchProducts() async throws -> [Product] {
        try await client
            .from("products")
            .select()
            .execute()
            .value
    }

    func fetchProductImages() async throws -> [ProductImage] {
        try await client
            .from("product_images")
            .select()
            .execute()
            .value
    }

    func setApprovalStatus(_ product: Product, to status: ApprovalStatus) async throws {
        let update = ProductStatusUpdate(approval_status: status.rawValue)
        try await client
            .from("products")
            .update(update)
            .eq("id", value: product.id.uuidString)
            .execute()
    }

    /// Admin-only price correction. Only ever writes the `price` column.
    func updatePrice(_ product: Product, to price: Double) async throws {
        let update = ProductPriceUpdate(price: price)
        try await client
            .from("products")
            .update(update)
            .eq("id", value: product.id.uuidString)
            .execute()
    }
}
