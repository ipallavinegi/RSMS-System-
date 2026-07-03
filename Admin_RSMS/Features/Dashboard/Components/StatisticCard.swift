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
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 52, height: 52)
                    Image(systemName: iconName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.uppercased())
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                        .tracking(1.0)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            Spacer(minLength: 4)

            // ── Value ───────────────────────────────────────────
            Text(value)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.primary)

            // ── Footnote ────────────────────────────────────────
            HStack(spacing: 3) {
                Text(footnoteLeft)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text(footnoteRight)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(24) // Reverted back to 24 for proper spacing and matching height
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
}
