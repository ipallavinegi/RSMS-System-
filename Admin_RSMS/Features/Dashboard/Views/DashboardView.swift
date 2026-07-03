import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                
                // Top Section: Revenue Chart (Left) + 2x2 KPI Grid (Right)
                HStack(alignment: .top, spacing: 24) {
                    // Left: Revenue Chart Card
                    RevenueChartCard(salesSummary: viewModel.salesSummary, selectedPeriod: $viewModel.selectedRevenuePeriod)
                        .frame(maxWidth: .infinity)
                    
                    // Right: 2x2 Grid for Statistic Cards
                    DashboardGrid(spacing: 16) {
                        NavigationLink(destination: StoresView()) {
                            StatisticCard(
                                category: "Network", 
                                title: "Stores", 
                                value: "\(viewModel.networkStoresActive)", 
                                footnoteLeft: "Active", 
                                footnoteRight: "of \(viewModel.networkStoresTotal) total", 
                                iconName: "building.2.fill", 
                                iconColor: .blue, 
                                iconBackground: .blue.opacity(0.15)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: ProductsView()) {
                            StatisticCard(
                                category: "Inventory", 
                                title: "Products", 
                                value: "\(viewModel.inventoryProductsCount)", 
                                footnoteLeft: "Stocked", 
                                footnoteRight: "items", 
                                iconName: "shippingbox.fill", 
                                iconColor: .green, 
                                iconBackground: .green.opacity(0.15)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: ManagersView()) {
                            StatisticCard(
                                category: "Staffing", 
                                title: "Managers", 
                                value: "\(viewModel.staffingManagersCount)", 
                                footnoteLeft: "Allocated", 
                                footnoteRight: "of \(viewModel.staffingManagersTotal) slots", 
                                iconName: "person.2.fill", 
                                iconColor: .orange, 
                                iconBackground: .orange.opacity(0.15)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: ComingSoonView(title: "Promos")) {
                            StatisticCard(
                                category: "Marketing", 
                                title: "Promos", 
                                value: "\(viewModel.marketingPromosCount)", 
                                footnoteLeft: "Live", 
                                footnoteRight: "campaigns", 
                                iconName: "tag.fill", 
                                iconColor: .purple, 
                                iconBackground: .purple.opacity(0.15)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 480) // Fixed width for the grid side to let the chart stretch
                }
                
                // Bottom Section: 3 Columns
                HStack(alignment: .top, spacing: 24) {
                    
                    // 1. Retail Health Score
                    ActivityCard(
                        title: "Retail Health Score", 
                        subtitle: "NETWORK AVG"
                    ) {
                        VStack(spacing: 16) {
                            ForEach(viewModel.retailHealthScores) { health in
                                HStack(spacing: 12) {
                                    // Circular Score Indicator
                                    ZStack {
                                        Circle()
                                            .stroke(health.color.opacity(0.2), lineWidth: 4)
                                        Circle()
                                            .trim(from: 0, to: CGFloat(health.score) / 100)
                                            .stroke(health.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                        
                                        Text("\(health.score)%")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.primary)
                                    }
                                    .frame(width: 40, height: 40)
                                    
                                    Text(health.storeName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(health.statusText)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(health.color)
                                }
                                
                                if health.id != viewModel.retailHealthScores.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 2. Store Performance
                    ActivityCard(
                        title: "Store Performance",
                        subtitle: ""
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // Embedded picker for the custom card style
                            HStack {
                                Spacer()
                                HStack(spacing: 0) {
                                    ForEach(StorePerformanceFilter.allCases) { filter in
                                        Text(filter.rawValue)
                                            .font(.system(size: 12, weight: .semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(viewModel.selectedStorePerformanceFilter == filter ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                            .shadow(color: viewModel.selectedStorePerformanceFilter == filter ? Color.black.opacity(0.05) : Color.clear, radius: 2, y: 1)
                                            .foregroundColor(viewModel.selectedStorePerformanceFilter == filter ? .primary : .secondary)
                                            .onTapGesture {
                                                withAnimation {
                                                    viewModel.selectedStorePerformanceFilter = filter
                                                }
                                            }
                                    }
                                }
                                .padding(4)
                                .background(Color(uiColor: .systemGray6))
                                .clipShape(Capsule())
                            }
                            .padding(.top, -40) // pulls it up to the header area
                            
                            ForEach(viewModel.storePerformanceList) { store in
                                HStack(spacing: 12) {
                                    // Rank Circle
                                    Circle()
                                        .fill(Color(uiColor: .systemGray6))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text("\(store.rank)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.primary)
                                        )
                                    
                                    Text(store.storeName)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(store.revenueText)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                
                                if store.id != viewModel.storePerformanceList.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 3. Top Customers
                    ActivityCard(
                        title: "Top Customers",
                        subtitle: "BY SPEND"
                    ) {
                        VStack(spacing: 16) {
                            ForEach(viewModel.topCustomersList) { customer in
                                HStack(spacing: 12) {
                                    // Initials Avatar
                                    let initials = customer.customerName.components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
                                    
                                    Circle()
                                        .fill(Color.purple.opacity(0.5)) // fallback color, realistically would hash the name
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(initials)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text(customer.customerName)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(customer.spendText)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                
                                if customer.id != viewModel.topCustomersList.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                }
                
                // Add some padding at the bottom so the floating tab bar doesn't overlap content
                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Avatar
                Circle()
                    .fill(Color.orange)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("AM")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .statusBarHidden()
        .task {
            await viewModel.load()
        }
    }
}

#Preview {
    DashboardView()
}
