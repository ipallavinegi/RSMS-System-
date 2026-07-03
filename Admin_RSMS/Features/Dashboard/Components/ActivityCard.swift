import SwiftUI

struct ActivityCard<Content: View, TrailingContent: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: Content
    let trailingContent: TrailingContent

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) where TrailingContent == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.trailingContent = EmptyView()
    }

    init(title: String, subtitle: String? = nil, @ViewBuilder trailingContent: () -> TrailingContent, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header row ──
            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold)) // HIG: .headline for card titles
                    .foregroundStyle(Color.primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.4)
                }

                Spacer()

                trailingContent
            }

            content
            Spacer(minLength: 0) // push content to top if card gets stretched
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }
}
