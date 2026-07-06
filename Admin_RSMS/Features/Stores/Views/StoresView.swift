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
    @State private var selectedStoreForDetails: AdminStore? = nil
    @State private var activeSort: StoreSortOption = .nameAscending
    
    // UI Constants
    private let cardWidth: CGFloat = 300
    
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
        Group {
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
                .background(Color.pageBG)
            } else {
                VStack(spacing: 0) {
                    Picker("View Mode", selection: $viewMode) {
                        Text("Grid").tag(ViewMode.grid)
                        Text("Map").tag(ViewMode.map)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 250)
                    .padding(.vertical, 12)
                    
                    if viewMode == .grid {
                        // Grid of Stores
                        ScrollView {
                            let columns = sizeClass == .compact ? [GridItem(.flexible(), spacing: 20)] : [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)]
                            LazyVGrid(columns: columns, spacing: 20) {
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
                                    .frame(maxWidth: .infinity)
                                    .onTapGesture {
                                        selectedStoreForDetails = store
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, sizeClass == .compact ? 16 : 32)
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                        }
                    } else {
                        // Full Screen Map with optional details sidebar
                        mapViewContent
                    }
                }
                .searchable(text: $searchText, prompt: "Search stores or managers...")
                .background(Color.pageBG)
            }
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
        .sheet(item: $storeToEdit) { store in
            AddStoreView(
                onDismiss: { storeToEdit = nil },
                editingStore: store,
                onSave: { updatedStore in
                    dataManager.updateStore(updatedStore)
                    storeToEdit = nil
                }
            )
        }
        .sheet(item: $selectedStoreForDetails) { store in
            StoreDetailModalView(store: store, onDismiss: {
                selectedStoreForDetails = nil
            })
        }
        .navigationTitle("Stores")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                sortMenu
                
                Button(action: { showingAddStore = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
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
            // Scrollable Content
            ScrollView {
                VStack(spacing: 0) {
                    
                    // Edge-to-Edge Hero Image with Overlaid Close Button
                    ZStack(alignment: .topTrailing) {
                        storeImageView(for: store)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                selectedMapStore = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(16)
                    }
                    
                    // Content Body
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header block
                        VStack(alignment: .leading, spacing: 8) {
                            Text(store.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Text(store.storeID ?? "—")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Circle().fill(Color.gray.opacity(0.3)).frame(width: 4, height: 4)
                                
                                statusBadge(for: store.status)
                                
                                if store.isArchived {
                                    Text("ARCHIVED")
                                        .font(.system(size: 10, weight: .heavy))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.black.opacity(0.6))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Information Cards
                        VStack(spacing: 16) {
                            // Address Card
                            infoCard(title: "ADDRESS", icon: "mappin.circle.fill", content: AnyView(
                                Text(store.address)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            ))
                            
                            // Manager Card
                            infoCard(title: "STORE MANAGER", icon: "person.crop.circle.fill", content: AnyView(
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(uiColor: .systemGray4))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(store.managerInitials)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.primary)
                                        )
                                    Text(store.managerName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                 }
                            ))
                            
                            // Coordinates Card
                            if let lat = store.latitude, let lon = store.longitude {
                                infoCard(title: "COORDINATES", icon: "location.fill", content: AnyView(
                                    HStack(spacing: 24) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.and.down")
                                                .font(.system(size: 11))
                                                .foregroundStyle(.secondary)
                                            Text(String(format: "%.5f", lat))
                                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        }
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.left.and.right")
                                                .font(.system(size: 11))
                                                .foregroundStyle(.secondary)
                                            Text(String(format: "%.5f", lon))
                                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        }
                                    }
                                ))
                            }
                        }
                    }
                    .padding(24)
                }
            }
            
            // Bottom Action Bar
            VStack(spacing: 12) {
                Button(action: {
                    storeToEdit = store
                    selectedMapStore = nil
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .bold))
                        Text("Edit Store")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Color(red: 0.1, green: 0.2, blue: 0.4))
                    .clipShape(Capsule())
                }
                
                if store.isArchived {
                    Button(action: {
                        var restored = store
                        restored.isArchived = false
                        dataManager.updateStore(restored)
                        selectedMapStore = nil
                    }) {
                        Text("Restore Store")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(.green)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    }
                } else {
                    Button(action: {
                        dataManager.removeStore(store)
                        selectedMapStore = nil
                    }) {
                        Text("Remove Store")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(.red)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .background(.ultraThinMaterial)
            .overlay(Divider(), alignment: .top)
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 0)) // Handled by sidebar frame logic mostly
    }
    
    private func infoCard(title: String, icon: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(.secondary)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    @ViewBuilder
    private func statusBadge(for status: StoreStatus) -> some View {
        let isMaintenance = status == .maintenance
        let isInventory = status == .inventory
        
        let fgColor = isMaintenance ? Color.purple : (isInventory ? Color.orange : Color.teal)
        let bgColor = fgColor.opacity(0.15)
        
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(bgColor)
            .foregroundColor(fgColor)
            .clipShape(Capsule())
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
    
    // MARK: - Status Color Helper
    
    private func statusColor(for status: StoreStatus) -> Color {
        switch status {
        case .active: return .green
        case .maintenance: return .orange
        case .inventory: return .blue
        }
    }
    
    private var sortMenu: some View {
        Menu {
            Button("Name (A-Z)", action: { activeSort = .nameAscending })
            Button("Name (Z-A)", action: { activeSort = .nameDescending })
            Button("Store ID", action: { activeSort = .storeIDAscending })
            Button("Manager Name", action: { activeSort = .managerNameAscending })
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.accentColor)
        }
    }
}

#Preview {
    StoresView()
}
