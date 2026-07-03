import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let images: [ProductImage]
    /// Admin price correction. Passing nil hides the edit affordance entirely.
    var onUpdatePrice: ((Double) -> Void)? = nil

    private var status: ApprovalStatus {
        ApprovalStatus(rawValue: product.approvalStatus ?? "") ?? .pending
    }

    private var initial: String {
        String(product.brand.prefix(1)).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                imageCarousel

                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.identity(for: product.brand).gradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(initial)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.productName)
                            .font(.title2.weight(.semibold))
                        Text(product.brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadge(status: status)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    detailField("SKU", product.sku)
                    detailField("Brand", product.brand)

                    if let onUpdatePrice {
                        EditablePriceField(price: product.price, onSave: onUpdatePrice)
                    } else {
                        detailField("Price", product.price.asCurrency)
                    }

                    detailField("Material", product.material)
                    detailField("Color", product.color)
                    detailField("Collection", product.collectionName)
                    detailField("Barcode", product.barcode)
                    detailField("Certificate", product.certificateNumber)
                }

                if let description = product.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(description)
                            .font(.body)
                    }
                }
            }
            .padding(LayoutConstants.cardPadding)
            .frame(maxWidth: LayoutConstants.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color.rsmsBackground)
        .navigationTitle(product.productName)
        // Approve/Reject intentionally live only on the card in the grid.
        // The detail sheet's toolbar is just "Close" (added by the presenting view).
    }

    /// Swipeable page carousel of every image for this product, primary first.
    /// Every image is shown in full (`.scaledToFit`, no cropping) regardless of
    /// whether the source photo is portrait or landscape.
    @ViewBuilder
    private var imageCarousel: some View {
        if images.isEmpty {
            FitImageView(url: nil, backdropColor: .rsmsSurface)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            TabView {
                ForEach(images) { productImage in
                    FitImageView(url: URL(string: productImage.imageURL), backdropColor: .rsmsSurface)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func detailField(_ label: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value?.isEmpty == false ? value! : "—")
                .font(.body)
        }
    }
}

private struct StatusBadge: View {
    let status: ApprovalStatus

    var body: some View {
        Label(status.rawValue, systemImage: status.icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(status.tint.opacity(0.15), in: Capsule())
            .foregroundStyle(status.tint)
    }
}

/// Tap the pencil to edit price inline; checkmark saves, X cancels.
private struct EditablePriceField: View {
    let price: Double
    let onSave: (Double) -> Void

    @State private var isEditing = false
    @State private var draftText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Price")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isEditing {
                HStack(spacing: 8) {
                    TextField("Price", text: $draftText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .frame(maxWidth: 130)
                        .onSubmit(commit)

                    Button(action: commit) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)

                    Button {
                        isEditing = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 6) {
                    Text(price.asCurrency)
                        .font(.body)

                    Button {
                        draftText = String(format: "%.0f", price)
                        isEditing = true
                        isFocused = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func commit() {
        if let value = Double(draftText), value > 0 {
            onSave(value)
        }
        isEditing = false
    }
}
