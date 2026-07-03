import SwiftUI

struct PromotionsView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dismiss) private var dismiss
    
    @State private var promos: [Promotion] = PromotionSampleData.promos
    @State private var selectedFilter: PromotionStatus = .all
    @State private var searchText = ""

    private let cardWidth: CGFloat = 300

    private var filteredPromos: [Promotion] {
        let base = selectedFilter == .all ? promos : promos.filter { $0.status == selectedFilter.rawValue }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            filterBar

            Group {
                if filteredPromos.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No \(selectedFilter.rawValue.lowercased()) promotions" : "No results for \"\(searchText)\"",
                        systemImage: "tag"
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth, maximum: cardWidth), spacing: 20)], spacing: 20) {
                            ForEach(filteredPromos) { promotion in
                                PromoCard(promotion: promotion)
                                    .frame(width: cardWidth)
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
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .navigationTitle("Promotions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .statusBarHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search campaigns or keywords...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(Capsule())
        }
        .padding(.horizontal, sizeClass == .compact ? 16 : 32)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(PromotionStatus.allCases) { filter in
                filterPill(filter)
            }
            Spacer()
        }
        .padding(.horizontal, sizeClass == .compact ? 16 : 32)
        .padding(.bottom, 14)
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    @ViewBuilder
    private func filterPill(_ filter: PromotionStatus) -> some View {
        let isSelected = selectedFilter == filter
        
        // Compute count dynamically
        let count = filter == .all ? promos.count : promos.filter { $0.status == filter.rawValue }.count

        Button {
            withAnimation { selectedFilter = filter }
        } label: {
            Text("\(filter.rawValue) (\(count))")
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
