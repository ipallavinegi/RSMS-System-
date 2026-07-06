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

    /// Same as `fetch`, but never throws, and never lets one bad row take
    /// down the whole table. Every table so far that's failed has failed
    /// because of exactly one or two rows (a NULL in a column the schema
    /// says is nullable but the model didn't, a stray bad date) — decoding
    /// the response as a single `[T]` means Swift's Codable throws away
    /// the *entire* array the moment any one element fails. Decoding row
    /// by row instead means 39 good rows still load even if row 40 is bad,
    /// and the failure reason names exactly which row and why.
    func fetchResilient<T: Decodable>(
        from table: String,
        as type: T.Type
    ) async -> (values: [T], failureReason: String?) {
        do {
            let response = try await client
                .from(table)
                .select()
                .execute()
            return Self.decodeRowByRow(response.data, as: T.self, table: table)
        } catch {
            let reason = "\(table): \(Self.describe(error))"
            print("[DatabaseService] '\(table)' fetch failed, returning empty: \(error)")
            return ([], reason)
        }
    }

    private static func decodeRowByRow<T: Decodable>(
        _ data: Data,
        as type: T.Type,
        table: String
    ) -> (values: [T], failureReason: String?) {
        let decoder = SupabaseManager.shared.decoder

        guard let rawArray = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            // Not a JSON array — decode as a single blob so whatever error
            // Postgrest/PostgREST actually returned still surfaces.
            do {
                return (try decoder.decode([T].self, from: data), nil)
            } catch {
                return ([], "\(table): \(describe(error))")
            }
        }

        var values: [T] = []
        values.reserveCapacity(rawArray.count)
        var firstFailure: String?
        var failureCount = 0

        for (index, element) in rawArray.enumerated() {
            guard let elementData = try? JSONSerialization.data(withJSONObject: element) else { continue }
            do {
                values.append(try decoder.decode(T.self, from: elementData))
            } catch {
                failureCount += 1
                if firstFailure == nil {
                    firstFailure = "row \(index) \(describe(error))"
                }
            }
        }

        guard failureCount > 0 else { return (values, nil) }
        let reason = "\(table): \(failureCount) row(s) skipped — \(firstFailure ?? "decode error") (\(values.count) row(s) loaded)"
        return (values, reason)
    }

    /// Pulls the exact key path out of a DecodingError instead of the vague
    /// generic message Swift's localizedDescription gives ("couldn't be read
    /// because it is missing"), so a schema mismatch is diagnosable from the
    /// error text alone.
    private static func describe(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else {
            return error.localizedDescription
        }

        func path(_ context: DecodingError.Context) -> String {
            context.codingPath.map(\.stringValue).joined(separator: ".")
        }

        switch decodingError {
        case .keyNotFound(let key, let context):
            let fullPath = (context.codingPath.map(\.stringValue) + [key.stringValue]).joined(separator: ".")
            return "missing required field '\(fullPath)'"
        case .valueNotFound(_, let context):
            return "field '\(path(context))' is null but is required"
        case .typeMismatch(let expectedType, let context):
            return "field '\(path(context))' expected \(expectedType) but got a different type"
        case .dataCorrupted(let context):
            return "field '\(path(context))' malformed: \(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
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
