import SwiftUI

struct ProductCard: View {
    let product: Product
    let primaryImageURL: URL?
    let showActions: Bool
    let onSelect: () -> Void
    let onApprove: () -> Void
    let onReject: () -> Void

    private var status: ApprovalStatus {
        ApprovalStatus(rawValue: product.approvalStatus ?? "") ?? .pending
    }

    private var initial: String {
        String(product.brand.prefix(1)).uppercased()
    }

    private let imageHeight: CGFloat = 160

    var body: some View {
        // The whole card is itself a Button (tap anywhere opens detail), and the
        // Approve/Reject buttons below are nested with `.buttonStyle(.borderless)`.
        // This is the pattern that lets inner buttons work correctly — an
        // `.onTapGesture` on the outer card would fire *alongside* inner Button
        // taps instead of yielding to them, which is why Approve/Reject looked
        // broken before.
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                imageSection
                infoSection
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    /// Image always fills the same box edge-to-edge (aspect-fill + clip).
    /// Portrait and landscape source photos both end up looking intentional —
    /// no letterboxing, no backdrop-color filler behind the image.
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { proxy in
                Group {
                    if let primaryImageURL {
                        AsyncImage(url: primaryImageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.identity(for: product.brand).opacity(0.10))
                            default:
                                placeholder
                            }
                        }
                    } else {
                        placeholder
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }

            Text(status.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold))
                .kerning(0.4)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.tint, in: Capsule())
                .foregroundColor(.white)
                .padding(8)
        }
        .frame(height: imageHeight)
        .frame(maxWidth: .infinity)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.productName)
                        .font(.system(size: 16, weight: .bold)) // Sightly bolder/larger for native feel
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        // Removed hardcoded nameHeight frame natively

                    Text(product.brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(product.price.asCurrency)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.rsmsBlue)
            }

            if showActions {
                VStack(spacing: 12) {
                    Divider()
                    HStack(spacing: 12) {
                        Button(action: onReject) {
                            Text("Reject")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.borderless)

                        Button(action: onApprove) {
                            Text("Approve")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.green, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 16)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color.identity(for: product.brand).gradient)
            .overlay(
                Text(initial)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}
