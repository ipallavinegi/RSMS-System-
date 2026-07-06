import SwiftUI

struct ProductsView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProductApprovalViewModel()
    @State private var selectedFilter: ProductFilter = .all
    @State private var searchText = ""

    @State private var productPendingRejection: Product?
    @State private var rejectionNote: String = ""

    // Uniform grid cells: fixed column width so every ProductCard renders at
    // an identical size instead of stretching to fill leftover row space.
    private let cardWidth: CGFloat = 300

    private var filteredProducts: [Product] {
        let base = viewModel.products(for: selectedFilter)
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.productName.localizedCaseInsensitiveContains(searchText) ||
            $0.brand.localizedCaseInsensitiveContains(searchText) ||
            $0.sku.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            Group {
                if filteredProducts.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No \(selectedFilter.rawValue.lowercased()) products" : "No results for \"\(searchText)\"",
                        systemImage: "shippingbox"
                    )
                } else {
                    ScrollView {
                        let columns = sizeClass == .compact ? [GridItem(.flexible(), spacing: 20, alignment: .top)] : [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20, alignment: .top)]
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredProducts) { product in
                                ProductCard(
                                    product: product,
                                    primaryImageURL: viewModel.primaryImageURL(for: product),
                                    showActions: product.approvalStatus == ApprovalStatus.pending.rawValue,
                                    onSelect: { viewModel.selectedProduct = product },
                                    onApprove: { Task { await viewModel.approve(product) } },
                                    onReject: { productPendingRejection = product }
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, sizeClass == .compact ? 16 : 32)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBG)
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $viewModel.selectedProduct) { product in
            NavigationView {
                ProductDetailView(
                    product: product,
                    images: viewModel.images(for: product),
                    onUpdatePrice: { newPrice in
                        Task { await viewModel.updatePrice(product, to: newPrice) }
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { viewModel.selectedProduct = nil }
                    }
                }
            }
        }
        .alert(
            "Reason for rejecting \(productPendingRejection?.productName ?? "")",
            isPresented: Binding(
                get: { productPendingRejection != nil },
                set: { if !$0 { productPendingRejection = nil; rejectionNote = "" } }
            )
        ) {
            TextField("Enter a reason", text: $rejectionNote)
            Button("Reject", role: .destructive) {
                if let product = productPendingRejection {
                    Task { await viewModel.reject(product) }
                    if viewModel.selectedProduct?.id == product.id {
                        viewModel.selectedProduct = nil
                    }
                }
                rejectionNote = ""
                productPendingRejection = nil
            }
            .disabled(rejectionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Cancel", role: .cancel) {
                rejectionNote = ""
                productPendingRejection = nil
            }
        } message: {
            Text("A reason is required to reject, but it isn't saved anywhere.")
        }
        .navigationTitle("Products")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search products by name, brand or SKU...")
    }

    /// Horizontal filter bar — just All and Pending, each labelled with a
    /// live count. Tapping a pill selects it directly (no dropdown).
    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(ProductFilter.allCases) { filter in
                filterPill(filter)
            }
            Spacer()
        }
        .padding(.horizontal, sizeClass == .compact ? 16 : 32)
        .padding(.bottom, 14)
        .background(Color.pageBG)
        .overlay(Divider(), alignment: .bottom)
    }

    @ViewBuilder
    private func filterPill(_ filter: ProductFilter) -> some View {
        let isSelected = selectedFilter == filter

        Button {
            withAnimation { selectedFilter = filter }
        } label: {
            Text("\(filter.rawValue) (\(viewModel.count(for: filter)))")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}
