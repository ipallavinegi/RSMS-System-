import Foundation
import Combine

@MainActor
final class ProductApprovalViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var selectedProduct: Product?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// All images, grouped by product_id. Fetched once per load(), not per row.
    @Published private var imagesByProductId: [UUID: [ProductImage]] = [:]

    private let service = ProductService()

    /// "All" is the reviewed history — Approved + Rejected — and excludes
    /// Pending. "Pending" shows only pending items.
    func products(for filter: ProductFilter) -> [Product] {
        if filter == .all {
            return products.filter { $0.approvalStatus != ApprovalStatus.pending.rawValue }
        }
        guard let status = filter.matchingStatus else { return products }
        return products.filter { $0.approvalStatus == status.rawValue }
    }

    func count(for filter: ProductFilter) -> Int {
        products(for: filter).count
    }

    /// All images for a product, primary image first.
    func images(for product: Product) -> [ProductImage] {
        (imagesByProductId[product.id] ?? []).sorted { $0.isPrimary && !$1.isPrimary }
    }

    /// The single image to show in compact contexts like list rows.
    func primaryImageURL(for product: Product) -> URL? {
        let all = imagesByProductId[product.id] ?? []
        let chosen = all.first(where: \.isPrimary) ?? all.first
        return chosen.flatMap { URL(string: $0.imageURL) }
    }

    func load() async {
        isLoading = true
        do {
            async let fetchedProducts = service.fetchProducts()
            async let fetchedImages = service.fetchProductImages()
            let (productsResult, imagesResult) = try await (fetchedProducts, fetchedImages)

            products = productsResult
            imagesByProductId = Dictionary(grouping: imagesResult, by: \.productId)

            // Keep the open detail sheet (if any) showing fresh data after a reload.
            if let selectedId = selectedProduct?.id {
                selectedProduct = products.first(where: { $0.id == selectedId })
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func approve(_ product: Product) async {
        await setStatus(product, to: .approved)
    }

    /// Called only after the UI has already collected and validated a mandatory note.
    /// The note itself is never passed in here — nothing is written except approval_status.
    func reject(_ product: Product) async {
        await setStatus(product, to: .rejected)
    }

    /// Admin price correction. Writes only the price column, then reloads.
    func updatePrice(_ product: Product, to newPrice: Double) async {
        do {
            try await service.updatePrice(product, to: newPrice)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setStatus(_ product: Product, to status: ApprovalStatus) async {
        do {
            try await service.setApprovalStatus(product, to: status)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
