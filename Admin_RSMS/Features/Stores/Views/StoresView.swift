import SwiftUI
import MapKit

enum StoreSortOption {
    case nameAscending
    case nameDescending
    case storeIDAscending
    case managerNameAscending
}

enum ViewMode {
    case grid
    case map
}

struct MapStorePin: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let name: String
    let isNewPin: Bool
    var isArchived: Bool = false
}

struct StoresView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = RSMSDataManager.shared
    @State private var searchText = ""
    @State private var showingAddStore = false
    @State private var storeToEdit: AdminStore? = nil
    @State private var activeSort: StoreSortOption = .nameAscending
    
    @State private var viewMode: ViewMode = .grid
    
    // Map state
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )
    
    // Selected store on map
    @State private var selectedMapStore: AdminStore? = nil
    
    var filteredStores: [AdminStore] {
        let stores = dataManager.stores
        let searchedStores: [AdminStore]
        if searchText.isEmpty {
            searchedStores = stores
        } else {
            searchedStores = stores.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.managerName.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch activeSort {
        case .nameAscending:
            return searchedStores.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return searchedStores.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .storeIDAscending:
            return searchedStores.sorted { ($0.storeID ?? "").localizedCaseInsensitiveCompare($1.storeID ?? "") == .orderedAscending }
        case .managerNameAscending:
            return searchedStores.sorted { $0.managerName.localizedCaseInsensitiveCompare($1.managerName) == .orderedAscending }
        }
    }
    
    var mapAnnotations: [MapStorePin] {
        dataManager.stores.compactMap { store -> MapStorePin? in
            guard let lat = store.latitude, let lon = store.longitude else { return nil }
            return MapStorePin(
                id: store.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                name: store.name,
                isNewPin: false,
                isArchived: store.isArchived
            )
        }
    }
    
    var body: some View {
        if dataManager.isLoading && dataManager.stores.isEmpty {
            // Full-screen loading on first launch
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                Text("Loading stores…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
        } else if storeToEdit != nil {
            AddStoreView(
                onDismiss: { 
                    storeToEdit = nil
                },
                editingStore: storeToEdit,
                onSave: { store in
                    dataManager.updateStore(store)
                    storeToEdit = nil
                }
            )
        } else {
            VStack(spacing: 0) {
                // Header Area
                headerView
                
                VStack(alignment: .leading, spacing: 20) {
                    if viewMode == .grid {
                        // Grid of Stores
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 20)], spacing: 20) {
                                ForEach(filteredStores) { store in
                                    StoreCard(store: store, onEdit: {
                                        storeToEdit = store
                                    }, onDelete: {
                                        dataManager.removeStore(store)
                                    }, onRestore: {
                                        var restored = store
                                        restored.isArchived = false
                                        dataManager.updateStore(restored)
                                    })
                                    .frame(height: 250)
                                }
                            }
                            .padding(.horizontal, sizeClass == .compact ? 16 : 32)
                            .padding(.top, 32)
                            .padding(.bottom, 100)
                        }
                    } else {
                        // Full Screen Map with optional details sidebar
                        mapViewContent
                    }
                }
                .padding(.bottom, 0)
                
                Spacer()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .overlay(alignment: .bottom) {
                statusBar
            }
            .alert("Error", isPresented: Binding(
                get: { dataManager.errorMessage != nil },
                set: { if !$0 { dataManager.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { dataManager.errorMessage = nil }
            } message: {
                Text(dataManager.errorMessage ?? "")
            }
            .onAppear {
                Task { await dataManager.fetchStores() }
            }
            .refreshable {
                await dataManager.fetchAll()
            }
            .sheet(isPresented: $showingAddStore) {
                AddStoreView(
                    onDismiss: {
                        showingAddStore = false
                    },
                    editingStore: nil,
                    onSave: { store in
                        dataManager.addStore(store)
                        showingAddStore = false
                    }
                )
            }
            .navigationTitle("Stores")
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
    }
    
    // MARK: - Map View Content
    
    private var mapViewContent: some View {
        HStack(spacing: 0) {
            // Map (takes full width or shares with sidebar)
            ZStack(alignment: .bottomTrailing) {
                Map(coordinateRegion: $mapRegion, annotationItems: mapAnnotations) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        Button(action: {
                            // Find the matching store and select it
                            if let store = dataManager.stores.first(where: { $0.id == pin.id }) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedMapStore = store
                                    // Zoom into the selected store
                                    mapRegion = MKCoordinateRegion(
                                        center: pin.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                    )
                                }
                            }
                        }) {
                            VStack(spacing: 2) {
                                ZStack {
                                    // Outer glow for selected state
                                    if selectedMapStore?.id == pin.id {
                                        Circle()
                                            .fill(Color.blue.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                    }
                                    
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: selectedMapStore?.id == pin.id ? 36 : 28))
                                        .foregroundColor(pin.isArchived ? .gray : (selectedMapStore?.id == pin.id ? Color(red: 0.1, green: 0.2, blue: 0.4) : .blue))
                                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                                        .opacity(pin.isArchived ? 0.6 : 1.0)
                                        .scaleEffect(selectedMapStore?.id == pin.id ? 1.15 : 1.0)
                                }
                                
                                Text(pin.name)
                                    .font(.system(size: selectedMapStore?.id == pin.id ? 11 : 9, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(selectedMapStore?.id == pin.id ? Color.white : Color.white.opacity(0.9))
                                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    )
                                    .opacity(pin.isArchived ? 0.6 : 1.0)
                            }
                            .animation(.easeInOut(duration: 0.2), value: selectedMapStore?.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
                
                // Zoom Controls
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            mapRegion.span.latitudeDelta = max(mapRegion.span.latitudeDelta / 2, 0.01)
                            mapRegion.span.longitudeDelta = max(mapRegion.span.longitudeDelta / 2, 0.01)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.title3.bold())
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.primary)
                    }
                    Divider().frame(width: 44)
                    Button(action: {
                        withAnimation {
                            mapRegion.span.latitudeDelta = min(mapRegion.span.latitudeDelta * 2, 180)
                            mapRegion.span.longitudeDelta = min(mapRegion.span.longitudeDelta * 2, 180)
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.title3.bold())
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.primary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                .padding(24)
            }
            
            // Store Details Sidebar (slides in when a pin is selected)
            if let store = selectedMapStore {
                Divider()
                
                storeDetailsSidebar(for: store)
                    .frame(width: 360)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Store Details Sidebar
    
    private func storeDetailsSidebar(for store: AdminStore) -> some View {
        VStack(spacing: 0) {
            // Sidebar Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Store Details")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                    Text(store.storeID ?? "—")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selectedMapStore = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Store Image
                    storeImageView(for: store)
                    
                    // Store Name & Status
                    VStack(alignment: .leading, spacing: 10) {
                        Text(store.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor(for: store.status))
                                .frame(width: 8, height: 8)
                            Text(store.status.rawValue.capitalized)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(statusColor(for: store.status))
                            
                            if store.isArchived {
                                Text("• Archived")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Address
                    detailRow(icon: "mappin.circle.fill", iconColor: .red, label: "ADDRESS", value: store.address)
                    
                    // Manager
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.1))
                                .frame(width: 40, height: 40)
                            Text(store.managerInitials)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MANAGER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            Text(store.managerName)
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .systemGray6).opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Coordinates
                    if let lat = store.latitude, let lon = store.longitude {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COORDINATES")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.and.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.5f", lat))
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.left.and.right")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.5f", lon))
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .systemGray6).opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Divider()
                    
                    // Action Buttons
                    VStack(spacing: 10) {
                        Button(action: {
                            storeToEdit = store
                            selectedMapStore = nil
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 16))
                                Text("Edit Store")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundColor(.white)
                            .background(Color(red: 0.1, green: 0.2, blue: 0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        if store.isArchived {
                            Button(action: {
                                var restored = store
                                restored.isArchived = false
                                dataManager.updateStore(restored)
                                selectedMapStore = nil
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Restore Store")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .foregroundColor(.green)
                                .background(Color.green.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            Button(action: {
                                dataManager.removeStore(store)
                                selectedMapStore = nil
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Remove Store")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .foregroundColor(.red)
                                .background(Color.red.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
    
    // MARK: - Store Image View (sidebar)
    
    @ViewBuilder
    private func storeImageView(for store: AdminStore) -> some View {
        Group {
            if let imageUrlString = store.imageUrl, let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        imagePlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipped()
                    case .failure:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else if let imageData = store.imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
            } else {
                imagePlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.08), Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "building.2")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.2))
                Text("No Image")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
    
    // MARK: - Detail Row Helper
    
    private func detailRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
                .frame(width: 20)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Status Color Helper
    
    private func statusColor(for status: StoreStatus) -> Color {
        switch status {
        case .active: return .green
        case .maintenance: return .orange
        case .inventory: return .blue
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if sizeClass == .compact {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        searchBar
                        createButton
                    }
                    HStack {
                        gridMapToggle
                        Spacer()
                        sortMenu
                    }
                }
            } else {
                HStack(spacing: 12) {
                    searchBar
                    createButton
                    Spacer()
                    gridMapToggle
                    sortMenu
                }
            }
        }
        .padding(.horizontal, sizeClass == .compact ? 16 : 32)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search stores or managers...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }
    
    private var createButton: some View {
        Button(action: { showingAddStore = true }) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Create")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .clipShape(Capsule())
        }
    }
    
    private var gridMapToggle: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    viewMode = .grid
                    selectedMapStore = nil
                }
            }) {
                Label("Grid", systemImage: "square.grid.2x2")
                    .font(.system(size: 13, weight: viewMode == .grid ? .bold : .medium))
                    .foregroundColor(viewMode == .grid ? .blue : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            Divider().frame(height: 16)
            Button(action: { withAnimation { viewMode = .map } }) {
                Label("Map", systemImage: "map")
                    .font(.system(size: 13, weight: viewMode == .map ? .bold : .medium))
                    .foregroundColor(viewMode == .map ? .blue : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    private var sortMenu: some View {
        Menu {
            Button("Name (A-Z)", action: { activeSort = .nameAscending })
            Button("Name (Z-A)", action: { activeSort = .nameDescending })
            Button("Store ID", action: { activeSort = .storeIDAscending })
            Button("Manager Name", action: { activeSort = .managerNameAscending })
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(8)
        }
    }
    
    private var statusBar: some View {
        HStack(spacing: 24) {
            HStack(spacing: 8) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("\(dataManager.stores.filter { $0.status == .active }.count) STORES ONLINE")
                    .font(.system(size: 9, weight: .bold))
            }
            
            HStack(spacing: 8) {
                Circle().fill(Color.orange).frame(width: 6, height: 6)
                Text("\(dataManager.stores.filter { $0.status == .inventory }.count) IN MAINTENANCE")
                    .font(.system(size: 9, weight: .bold))
            }
            
            Spacer()
            
            Text("SYNC STATUS: REAL-TIME • TODAY 09:42 AM")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }
}


#Preview {
    StoresView()
}
