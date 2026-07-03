import SwiftUI

extension Color {
    /// Primary brand blue. Used for the accent/tint color across the app.
    static let rsmsBlue = Color.blue

    /// Soft blue used for selected-state fills and subtle highlights.
    static let rsmsBlueTint = Color.blue.opacity(0.12)

    /// Page and card background — resolves to white in Light Mode.
    static let rsmsBackground = Color(uiColor: .systemGroupedBackground)

    /// Secondary surface, e.g. thumbnails, placeholders.
    static let rsmsSurface = Color(uiColor: .secondarySystemGroupedBackground)

    /// A small curated set of identification colors (Contacts/Reminders-style).
    /// Deterministic per input string, so the same brand always gets the same
    /// color without needing to store it anywhere.
    private static let identityPalette: [Color] = [
        .blue, .indigo, .purple, .pink, .orange, .teal, .mint, .cyan
    ]

    static func identity(for text: String) -> Color {
        let hash = text.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return identityPalette[hash % identityPalette.count]
    }
}

/// Semantic colors + icons for approval states.
extension ApprovalStatus {
    var tint: Color {
        switch self {
        case .pending: return .rsmsBlue
        case .approved: return .green
        case .rejected: return .red
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .approved: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        }
    }
}

/// Icon used for each tab in the filter bar.
extension ProductFilter {
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .pending: return "clock.fill"
        }
    }
}

enum LayoutConstants {
    static let cornerRadius: CGFloat = 10
    static let avatarSize: CGFloat = 44
    static let cardPadding: CGFloat = 16
    /// Caps line length for readable text on large iPad displays.
    static let readableContentWidth: CGFloat = 680
}

extension Double {
    /// Locale-correct currency string with no decimal places, e.g. "₹1,18,000".
    var asCurrency: String {
        self.formatted(.currency(code: "INR").precision(.fractionLength(0)))
    }
}
