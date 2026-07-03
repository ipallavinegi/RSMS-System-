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
        
        guard !searchText.isEmpty else {
            return service.promotions
        }
        
        return service.promotions.filter {
            $0.promotionName.localizedCaseInsensitiveContains(searchText)
            ||
            ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            headerView
            
            Group {
                
                if service.isLoading {
                    
                    ProgressView("Loading Promotions...")
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity)
                    
                } else if filteredPromotions.isEmpty {
                    
                    ContentUnavailableView(
                        "No Promotions Yet",
                        systemImage: "tag",
                        description: Text(
                            "Create your first promotional campaign."
                        )
                    )
                    
                } else {
                    
                    ScrollView {
                        
                        LazyVGrid(
                            columns: [
                                GridItem(
                                    .adaptive(
                                        minimum: cardWidth,
                                        maximum: cardWidth
                                    ),
                                    spacing: 20,
                                    alignment: .top
                                )
                            ],
                            alignment: .leading,
                            spacing: 20
                        ) {
                            
                            ForEach(filteredPromotions) { promotion in
                                
                                PromoCard(
                                    promotion: promotion,
                                    onTap: {
                                        editingPromotion = promotion
                                    }
                                )
                                .frame(width: cardWidth)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(
                            .horizontal,
                            sizeClass == .compact ? 16 : 32
                        )
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background(
                Color(uiColor: .systemGroupedBackground)
            )
        }
        .navigationTitle("Promotions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .statusBarHidden()
        .task {
            await service.fetchPromotions()
        }
        .toolbar {
            
            ToolbarItem(
                placement: .navigationBarLeading
            ) {
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(
            isPresented: $showingAddPromotion
        ) {
            
            AddPromotionView(
                onDismiss: {
                    showingAddPromotion = false
                },
                onSaved: { _ in
                    
                    Task {
                        await service.fetchPromotions()
                    }
                }
            )
        }
        .sheet(
            item: $editingPromotion
        ) { promotion in
            
            AddPromotionView(
                editingPromotion: promotion,
                onDismiss: {
                    editingPromotion = nil
                },
                onSaved: { _ in
                    
                    Task {
                        await service.fetchPromotions()
                    }
                }
            )
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        
        HStack(spacing: 12) {
            
            HStack(spacing: 12) {
                
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(
                    "Search promotions...",
                    text: $searchText
                )
                .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    
                    Button {
                        searchText = ""
                    } label: {
                        Image(
                            systemName: "xmark.circle.fill"
                        )
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(
                    uiColor:
                        .secondarySystemGroupedBackground
                )
            )
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
            
            Button {
                showingAddPromotion = true
            } label: {
                
                HStack(spacing: 8) {
                    
                    Image(systemName: "plus.circle.fill")
                    
                    Text("Create")
                }
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Color.blue,
                    in: Capsule()
                )
            }
        }
        .padding(
            .horizontal,
            sizeClass == .compact ? 16 : 32
        )
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(
            Color(uiColor: .systemGroupedBackground)
        )
    }
}
