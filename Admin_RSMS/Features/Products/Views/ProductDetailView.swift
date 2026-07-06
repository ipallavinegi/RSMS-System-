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
        Form {
            Section {
                imageCarousel
                    .listRowInsets(EdgeInsets()) // Makes the image fit flush to the edges of the cell
                
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.identity(for: product.brand).gradient)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(initial)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.productName)
                            .font(.headline)
                        Text(product.brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ProductStatusBadge(status: status)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Product Details")) {
                ListRow(label: "SKU", value: product.sku)
                ListRow(label: "Brand", value: product.brand)

                if let onUpdatePrice {
                    EditablePriceField(price: product.price, onSave: onUpdatePrice)
                } else {
                    ListRow(label: "Price", value: product.price.asCurrency)
                }

                if let material = product.material, !material.isEmpty {
                    ListRow(label: "Material", value: material)
                }
                if let color = product.color, !color.isEmpty {
                    ListRow(label: "Color", value: color)
                }
                if let collection = product.collectionName, !collection.isEmpty {
                    ListRow(label: "Collection", value: collection)
                }
                if let barcode = product.barcode, !barcode.isEmpty {
                    ListRow(label: "Barcode", value: barcode)
                }
                if let cert = product.certificateNumber, !cert.isEmpty {
                    ListRow(label: "Certificate", value: cert)
                }
            }

            if let description = product.description, !description.isEmpty {
                Section(header: Text("Description")) {
                    Text(description)
                        .font(.body)
                        .padding(.vertical, 4)
                }
            }
        }
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
                .frame(height: 320)
        } else {
            TabView {
                ForEach(images) { productImage in
                    FitImageView(url: URL(string: productImage.imageURL), backdropColor: .rsmsSurface)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 320)
        }
    }
}

private struct ListRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer(minLength: 16)
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct ProductStatusBadge: View {
    let status: ApprovalStatus

    var body: some View {
        Label(status.rawValue, systemImage: status.icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
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
        HStack {
            Text("Price")
                .foregroundStyle(.primary)
            
            Spacer(minLength: 16)

            if isEditing {
                HStack(spacing: 8) {
                    TextField("Price", text: $draftText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .frame(maxWidth: 130)
                        .multilineTextAlignment(.trailing)
                        .onSubmit(commit)

                    Button(action: commit) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)

                    Button {
                        isEditing = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 8) {
                    Text(price.asCurrency)
                        .foregroundStyle(.secondary)

                    Button {
                        draftText = String(format: "%.0f", price)
                        isEditing = true
                        isFocused = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 20))
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
