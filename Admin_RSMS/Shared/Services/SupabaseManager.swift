//
//  SupabaseManager.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient
    /// Same decoder configured on the client's `db` options — exposed so
    /// `DatabaseService` can reuse the exact same date-parsing behavior when
    /// decoding rows one at a time (see `fetchResilient`).
    let decoder: JSONDecoder

    private init() {
        let decoder = SupabaseManager.makeDecoder()
        self.decoder = decoder

        client = SupabaseClient(
            supabaseURL: URL(string: Constants.supabaseURL)!,
            supabaseKey: Constants.supabaseKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    decoder: decoder
                )
            )
        )
    }

    /// Postgres/PostgREST is inconsistent about what a timestamp string
    /// looks like depending on the column type and driver defaults:
    ///   - `date`                      → "2026-01-30"
    ///   - `timestamp` (no tz)         → "2026-07-03T07:21:21.586"        (no Z, 3 fractional digits)
    ///                                   "2026-07-02T10:36:26.963922"     (no Z, 6 fractional digits)
    ///                                   "2026-07-02T10:00:00"            (no Z, no fractional digits)
    ///   - `timestamptz`               → "2026-07-03T18:55:05.514729Z"   (Z, 6 fractional digits)
    ///                                   "2026-07-03T10:23:10.335+05:30" (offset, 3 fractional digits)
    /// `ISO8601DateFormatter` only accepts one exact shape at a time (it
    /// requires a timezone designator, and only understands 3-digit
    /// fractional seconds), so previously any column without a trailing
    /// `Z`/offset — or with 6-digit microsecond precision — failed to
    /// decode. This normalizes the string into a shape `ISO8601DateFormatter`
    /// can always parse: pad/truncate fractional seconds to 3 digits, and
    /// assume UTC when no timezone designator is present (Postgres always
    /// stores/returns `timestamp without time zone` in UTC in this project).
    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        let isoWithFractionalSeconds = ISO8601DateFormatter()
        isoWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoWithoutFractionalSeconds = ISO8601DateFormatter()
        isoWithoutFractionalSeconds.formatOptions = [.withInternetDateTime]

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.calendar = Calendar(identifier: .iso8601)
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            if !raw.contains("T") {
                // Plain `date` column, e.g. "1985-11-26".
                if let date = dateOnlyFormatter.date(from: raw) {
                    return date
                }
            } else {
                let normalized = Self.normalizeTimestamp(raw)
                if normalized.contains(".") {
                    if let date = isoWithFractionalSeconds.date(from: normalized) {
                        return date
                    }
                } else if let date = isoWithoutFractionalSeconds.date(from: normalized) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(raw)"
            )
        }

        return decoder
    }

    /// Pads/truncates fractional seconds to exactly 3 digits and appends a
    /// `Z` if no timezone designator is present, so the result always
    /// matches a shape `ISO8601DateFormatter` understands.
    private static func normalizeTimestamp(_ raw: String) -> String {
        var result = raw

        if let dotIndex = result.firstIndex(of: ".") {
            var digitsEnd = result.index(after: dotIndex)
            while digitsEnd < result.endIndex, result[digitsEnd].isNumber {
                digitsEnd = result.index(after: digitsEnd)
            }
            let digits = result[result.index(after: dotIndex)..<digitsEnd]
            let normalizedDigits = String(digits.prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
            result.replaceSubrange(result.index(after: dotIndex)..<digitsEnd, with: normalizedDigits)
        }

        if let tIndex = result.firstIndex(of: "T") {
            let afterT = result[result.index(after: tIndex)...]
            let hasTimeZone = afterT.hasSuffix("Z") || afterT.contains("+") || afterT.contains("-")
            if !hasTimeZone {
                result += "Z"
            }
        }

        return result
    }
}
