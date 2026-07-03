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
    
    // Binding variables for the sidebar map coordinates
    @State private var sidebarSelectedCoordinate = CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0)
    @State private var sidebarPinPlaced = false
    @State private var sidebarMapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )
    
    private let newPinId = UUID()
    
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
        var pins = dataManager.stores.compactMap { store -> MapStorePin? in
            guard let lat = store.latitude, let lon = store.longitude else { return nil }
            return MapStorePin(
                id: store.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                name: store.name,
                isNewPin: false,
                isArchived: store.isArchived
            )
        }
        
        if sidebarPinPlaced {
            pins.append(MapStorePin(
                id: newPinId,
                coordinate: sidebarSelectedCoordinate,
                name: "New Store Location",
                isNewPin: true
            ))
        }
        
        return pins
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
                    // Network Overview section
                    
                    
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
                        // Full Screen Map with Sidebar
                        HStack(spacing: 0) {
                            ZStack(alignment: .bottomTrailing) {
                                Map(coordinateRegion: $sidebarMapRegion, annotationItems: mapAnnotations) { pin in
                                    MapAnnotation(coordinate: pin.coordinate) {
                                        VStack(spacing: 0) {
                                            if pin.isNewPin {
                                                Image(systemName: "mappin.circle.fill")
                                                    .font(.system(size: 36))
                                                    .foregroundColor(.green)
                                                    .shadow(radius: 4)
                                            } else {
                                                Image(systemName: "mappin.circle.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(pin.isArchived ? .gray : .blue)
                                                    .shadow(radius: 4)
                                                    .opacity(pin.isArchived ? 0.6 : 1.0)
                                            }
                                            
                                            Text(pin.name)
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.white.opacity(0.9))
                                                .cornerRadius(4)
                                                .shadow(radius: 2)
                                                .offset(y: 4)
                                                .opacity(pin.isArchived ? 0.6 : 1.0)
                                        }
                                    }
                                }
                                .edgesIgnoringSafeArea(.bottom)
                                
                                // Zoom Controls
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation {
                                            sidebarMapRegion.span.latitudeDelta = max(sidebarMapRegion.span.latitudeDelta / 2, 0.01)
                                            sidebarMapRegion.span.longitudeDelta = max(sidebarMapRegion.span.longitudeDelta / 2, 0.01)
                                        }
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.title3.bold())
                                            .frame(width: 44, height: 44)
                                            .background(Color.white)
                                            .foregroundColor(.primary)
                                    }
                                    Divider()
                                    Button(action: {
                                        withAnimation {
                                            sidebarMapRegion.span.latitudeDelta = min(sidebarMapRegion.span.latitudeDelta * 2, 180)
                                            sidebarMapRegion.span.longitudeDelta = min(sidebarMapRegion.span.longitudeDelta * 2, 180)
                                        }
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.title3.bold())
                                            .frame(width: 44, height: 44)
                                            .background(Color.white)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .cornerRadius(8)
                                .shadow(radius: 4)
                                .padding(24)
                            }
                            
                            // Divider
                            Divider()
                            
                            // Right Sidebar for registering
                            AddStoreSidebarView(
                                mapRegion: $sidebarMapRegion,
                                selectedCoordinate: $sidebarSelectedCoordinate,
                                pinPlaced: $sidebarPinPlaced,
                                onSave: { newStore in
                                    dataManager.addStore(newStore)
                                }
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                NavigationView {
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
                    .navigationTitle("Add New Store")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddStore = false }
                        }
                    }
                }
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
    
    // Subviews to keep body clean
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
            Button(action: { withAnimation { viewMode = .grid } }) {
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
