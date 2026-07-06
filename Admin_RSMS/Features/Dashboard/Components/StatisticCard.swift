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
            ViewThatFits(in: .horizontal) {
                // Wide layout
                HStack(alignment: .center, spacing: 16) {
                    iconView
                    textLabels
                    Spacer(minLength: 4)
                    chevronView
                }
                
                // Narrow layout
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        iconView
                        Spacer()
                        chevronView
                    }
                    textLabels
                }
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
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        .cardShadow()
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(iconBackground)
                .frame(width: 44, height: 44) // slightly smaller for better fit
            Image(systemName: iconName)
                .font(.title3.weight(.bold))
                .foregroundStyle(iconColor)
        }
    }
    
    @ViewBuilder
    private var textLabels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(category.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .tracking(1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
    
    @ViewBuilder
    private var chevronView: some View {
        Image(systemName: "chevron.right")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(.tertiaryLabel))
    }
}
