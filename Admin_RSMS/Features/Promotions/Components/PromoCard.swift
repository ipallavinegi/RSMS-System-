import SwiftUI

struct PromoCard: View {

    let promotion: AdminPromotion
    var onTap: () -> Void = {}

    private let imageHeight: CGFloat = 180

    var body: some View {

        Button(action: onTap) {

            VStack(spacing: 0) {

                bannerSection

                contentSection
            }
            .background(Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
            .cardShadow()
        }
        .buttonStyle(PromoCardButtonStyle())
    }

    // MARK: - Banner

    private var bannerSection: some View {

        Group {

            if let urlString = promotion.bannerImageUrl,
               let url = URL(string: urlString) {

                AsyncImage(url: url) { phase in

                    switch phase {

                    case .success(let image):

                        image
                            .resizable()
                            .scaledToFill()

                    default:

                        placeholderBanner
                    }
                }

            } else {

                placeholderBanner
            }
        }
        .frame(height: imageHeight)
        .clipped()
    }

    private var placeholderBanner: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Content

    private var contentSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(promotion.promotionName)
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(promotion.promotionType)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)

            Divider()

            infoRow(
                icon: "calendar",
                title: formattedDateRange
            )

            infoRow(
                icon: "storefront",
                title: storeText
            )
        }
        .padding(18)
        // Anchors text to the leading edge so the whole card
        // area (not just the text) is tappable and hit-tests correctly.
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoRow(
        icon: String,
        title: String
    ) -> some View {

        HStack(spacing: 8) {

            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var formattedDateRange: String {

        "\(promotion.startDate) – \(promotion.endDate)"
    }

    private var storeText: String {

        promotion.appliesToAllStores
        ? "All Stores"
        : "Selected Store"
    }
}

// MARK: - Press animation for the whole card

private struct PromoCardButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {

        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(
                .easeOut(duration: 0.15),
                value: configuration.isPressed
            )
    }
}
