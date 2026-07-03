//
//  DatabaseService.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class DatabaseService {

    static let shared = DatabaseService()

    private let client = SupabaseManager.shared.client

    private init() {}
}

// MARK: - Generic Fetch

extension DatabaseService {

    func fetch<T: Decodable>(
        from table: String,
        as type: T.Type
    ) async throws -> [T] {

        try await client
            .from(table)
            .select()
            .execute()
            .value
    }
}

// MARK: - Generic Insert

extension DatabaseService {

    func insert<T: Encodable>(
        into table: String,
        value: T
    ) async throws {

        try await client
            .from(table)
            .insert(value)
            .execute()
    }
}

// MARK: - Generic Update

extension DatabaseService {

    func update<T: Encodable>(
        table: String,
        value: T,
        column: String,
        equals id: String
    ) async throws {

        try await client
            .from(table)
            .update(value)
            .eq(column, value: id)
            .execute()
    }
}

// MARK: - Generic Delete

extension DatabaseService {

    func delete(
        from table: String,
        column: String,
        equals id: String
    ) async throws {

        try await client
            .from(table)
            .delete()
            .eq(column, value: id)
            .execute()
    }
}
