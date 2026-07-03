import SwiftUI

struct ActivityCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header row ──
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)                  // HIG: .headline for card titles
                    .foregroundStyle(Color.primary)

                if let subtitle {
                    Spacer()
                    Text(subtitle)
                        .font(.caption.bold())
                        .foregroundStyle(Color.secondary)
                        .tracking(0.4)
                }
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }
}
