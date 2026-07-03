//
//  InventoryService.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class InventoryService {

    private let client = SupabaseManager.shared.client

    func fetchInventory() async throws -> [InventoryItem] {

        try await client
            .from("inventory")
            .select()
            .execute()
            .value
    }
}
