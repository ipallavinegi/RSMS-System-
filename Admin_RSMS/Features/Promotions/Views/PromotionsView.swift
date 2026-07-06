import SwiftUI

struct PromotionsView: View {
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var service = PromotionService.shared
    
    @State private var searchText = ""
    @State private var showingAddPromotion = false
    @State private var editingPromotion: AdminPromotion?
    
    private let cardWidth: CGFloat = 320
    
    private var filteredPromotions: [AdminPromotion] {
        guard !searchText.isEmpty else { return service.promotions }
        return service.promotions.filter {
            $0.promotionName.localizedCaseInsensitiveContains(searchText) || ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if service.isLoading {
                    ProgressView("Loading Promotions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredPromotions.isEmpty {
                    ContentUnavailableView(
                        "No Promotions Yet",
                        systemImage: "tag",
                        description: Text("Create your first promotional campaign.")
                    )
                } else {
                    ScrollView {
                        let columns = sizeClass == .compact ? [GridItem(.flexible(), spacing: 20)] : [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)]
                        LazyVGrid(
                            columns: columns,
                            alignment: .leading,
                            spacing: 20
                        ) {
                            ForEach(filteredPromotions) { promotion in
                                PromoCard(
                                    promotion: promotion,
                                    onTap: { editingPromotion = promotion }
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, sizeClass == .compact ? 16 : 32)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.pageBG)
        }
        .navigationTitle("Promotions")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search promotions...")
        .task { await service.fetchPromotions() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddPromotion = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingAddPromotion) {
            AddPromotionView(
                onDismiss: { showingAddPromotion = false },
                onSaved: { _ in Task { await service.fetchPromotions() } }
            )
        }
        .sheet(item: $editingPromotion) { promotion in
            AddPromotionView(
                editingPromotion: promotion,
                onDismiss: { editingPromotion = nil },
                onSaved: { _ in Task { await service.fetchPromotions() } }
            )
        }
    }
}
