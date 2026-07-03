import SwiftUI

struct StatisticCard: View {
    let category: String
    let title: String
    let value: String
    let footnoteLeft: String
    let footnoteRight: String
    let iconName: String
    let iconColor: Color
    let iconBackground: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ── Top Row: Icon + Labels + Chevron ────────────────
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 44, height: 44)
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                        .tracking(0.8)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            Spacer(minLength: 4)

            // ── Value ───────────────────────────────────────────
            Text(value)
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            // ── Footnote ────────────────────────────────────────
            HStack(spacing: 3) {
                Text(footnoteLeft)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.primary)
                Text(footnoteRight)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(24) // Added more padding to make it breathable
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // Ensures full stretch!
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
}
