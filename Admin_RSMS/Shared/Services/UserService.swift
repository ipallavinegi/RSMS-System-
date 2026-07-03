//
//  UserService.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class UserService {

    private let client = SupabaseManager.shared.client

    func fetchUsers() async throws -> [User] {
        try await client
            .from("users")
            .select()
            .execute()
            .value
    }

    func fetchUsersByStore(storeId: UUID) async throws -> [User] {
        try await client
            .from("users")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .execute()
            .value
    }

    func fetchEmployeesByDesignation(
        designation: String
    ) async throws -> [User] {

        try await client
            .from("users")
            .select()
            .eq("designation", value: designation)
            .execute()
            .value
    }

    func fetchSalesAssociates(
        storeId: UUID
    ) async throws -> [User] {

        try await client
            .from("users")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .eq("designation", value: "Sales Associate")
            .execute()
            .value
    }
    func fetchUserByEmail(email: String) async throws -> User? {
        let results: [User] = try await client
            .from("users")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        return results.first
    }
}
