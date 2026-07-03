import SwiftUI

// MARK: - Store Health Score

struct StoreHealthScore: Identifiable {
    let id = UUID()
    let storeName: String
    let score: Int       // 0...100
    let statusText: String
    let colorHex: String

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}

// MARK: - Store Performance

enum StorePerformanceFilter: String, CaseIterable, Identifiable {
    case highest = "Highest"
    case lowest = "Lowest"

    var id: String { rawValue }
}

struct StorePerformanceItem: Identifiable {
    let id = UUID()
    let rank: Int
    let storeName: String
    let revenue: Double

    var revenueText: String {
        let formatted = Int(revenue)
        return "₹\(formatted.formattedIndian)"
    }
    
    var initials: String {
        storeName.components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
    }
}

// MARK: - Top Customers

struct TopCustomerItem: Identifiable {
    let id = UUID()
    let customerName: String
    let spend: Double
    let maxSpend: Double   // used to normalize progress bar width

    var spendText: String { "₹\(Int(spend).formattedIndian)" }
    var progress: Double { maxSpend > 0 ? spend / maxSpend : 0 }
    
    var initials: String {
        customerName.components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined().uppercased()
    }
}

// MARK: - Revenue Period

enum RevenuePeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var id: String { rawValue }
}

// MARK: - Color from hex helper

extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard hex.count == 6, let intVal = UInt64(hex, radix: 16) else { return nil }
        let r = Double((intVal >> 16) & 0xFF) / 255.0
        let g = Double((intVal >> 8)  & 0xFF) / 255.0
        let b = Double(intVal         & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Indian number formatter

extension Int {
    var formattedIndian: String {
        if self >= 1_00_000 {
            let lakhs = self / 1_00_000
            let thousands = (self % 1_00_000) / 1_000
            let hundreds = self % 1_000
            if thousands == 0 && hundreds == 0 {
                return "\(lakhs),00,000"
            } else if hundreds == 0 {
                return "\(lakhs),\(String(format: "%02d", thousands)),000"
            } else {
                return "\(lakhs),\(String(format: "%02d", thousands)),\(String(format: "%03d", hundreds))"
            }
        } else if self >= 1_000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale(identifier: "en_IN")
            return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        } else {
            return "\(self)"
        }
    }
}
