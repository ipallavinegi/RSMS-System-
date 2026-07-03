import SwiftUI
import MapKit
import CoreLocation
import Combine
import UIKit


// MARK: - Location Manager (high-accuracy, worldwide)
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var hasLocation: Bool = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .other
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Only accept locations with reasonable accuracy (< 100m)
        if location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 100 {
            DispatchQueue.main.async {
                self.latitude = location.coordinate.latitude
                self.longitude = location.coordinate.longitude
                self.hasLocation = true
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

// MARK: - Map Pin Model
struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Image Picker (Gallery & Camera)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Helper to filter address to English-only characters
private func sanitizeToEnglish(_ text: String) -> String {
    let allowed = CharacterSet.alphanumerics
        .union(.whitespaces)
        .union(CharacterSet(charactersIn: ".,/-#'"))
    return String(text.unicodeScalars.filter { allowed.contains($0) })
}

// MARK: - Region-based Store ID Generator
class StoreIDGenerator: ObservableObject {
    // Persisted counters per region prefix using AppStorage pattern
    static let shared = StoreIDGenerator()
    
    private let counterKey = "storeIDCounters"
    
    private var counters: [String: Int] {
        get {
            UserDefaults.standard.dictionary(forKey: counterKey) as? [String: Int] ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: counterKey)
        }
    }
    
    /// Generates the next Store ID for a given country code
    func nextID(forRegion regionCode: String) -> String {
        let prefix = regionCode.uppercased()
        var current = counters
        let count = (current[prefix] ?? 0) + 1
        current[prefix] = count
        counters = current
        return String(format: "%@-%04d", prefix, count)
    }
    
    /// Peeks at what the next ID would be without incrementing
    func peekNextID(forRegion regionCode: String) -> String {
        let prefix = regionCode.uppercased()
        let count = (counters[prefix] ?? 0) + 1
        return String(format: "%@-%04d", prefix, count)
    }
}

// MARK: - Theme constants
enum FormTheme {
    static let navy = Color(red: 0.1, green: 0.2, blue: 0.4)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let fieldBackground = Color(uiColor: .systemGray6)
    static let cornerRadius: CGFloat = 16
    static let fieldCornerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
}

// MARK: - Reusable Section Card
struct FormSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FormTheme.navy)
                    .frame(width: 32, height: 32)
                    .background(FormTheme.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(FormTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FormTheme.cornerRadius, style: .continuous))
    }
}

// MARK: - Reusable Field Label
struct FieldLabel: View {
    let text: String
    
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
    }
}

// MARK: - Add Store View
struct AddStoreView: View {
    private let editingStore: AdminStore?
    var onDismiss: () -> Void
    var onSave: (AdminStore) -> Void
    
    @State private var storeName = ""
    @State private var generatedStoreID = ""
    @State private var detectedRegionCode = ""
    @State private var address = ""
    @State private var storeStatus: StoreStatus = .active
    
    // Map state — starts at world view
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )
    @State private var selectedCoordinate = CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0)
    @State private var pinPlaced = false
    @State private var isLocating = false
    
    // Image picker state
    @State private var selectedImage: UIImage? = nil
    @State private var showingImageSourceSheet = false
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var storeIDGenerator = StoreIDGenerator.shared
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    // Default times

    
    init(onDismiss: @escaping () -> Void, editingStore: AdminStore? = nil, onSave: @escaping (AdminStore) -> Void = { _ in }) {
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.editingStore = editingStore
        _storeName = State(initialValue: editingStore?.name ?? "")
        _generatedStoreID = State(initialValue: editingStore?.storeID ?? "")
        _address = State(initialValue: editingStore?.address == "Address not set" ? "" : editingStore?.address ?? "")
        if let imageData = editingStore?.imageData {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
        _storeStatus = State(initialValue: editingStore?.status ?? .active)
        
        // Initialize coordinates if available
        if let lat = editingStore?.latitude, let lon = editingStore?.longitude {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            _selectedCoordinate = State(initialValue: coord)
            _mapRegion = State(initialValue: MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            _pinPlaced = State(initialValue: true)
        }
    }
    
    // Determine if we should use wide two-column layout
    private var useWideLayout: Bool {
        sizeClass == .regular
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if useWideLayout {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(editingStore == nil ? "Add Store" : "Edit Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveStore) {
                        Text(editingStore == nil ? "Create" : "Update")
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.startUpdating()
        }
        .onChange(of: locationManager.hasLocation) { _, newValue in
            if newValue, !pinPlaced {
                withAnimation(.easeInOut(duration: 0.6)) {
                    mapRegion = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: locationManager.latitude,
                            longitude: locationManager.longitude
                        ),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
        }

        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSourceType)
        }
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Missing Information"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // Bottom and Top bars removed in favor of Navigation Stack
    
    // MARK: - Wide Layout (iPad / Regular width)
    
    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            // Left Column
            VStack(spacing: 20) {
                locationMapSection
                basicInfoSection
            }
            .frame(maxWidth: .infinity)
            
            // Right Column
            VStack(spacing: 20) {
                storeMediaSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(28)
    }
    
    // MARK: - Compact Layout (iPhone / Compact width)
    
    private var compactLayout: some View {
        VStack(spacing: 20) {
            locationMapSection
            basicInfoSection
            storeMediaSection
        }
        .padding(20)
    }
    
    // MARK: - Section: Basic Information
    
    private var basicInfoSection: some View {
        FormSectionCard(title: "Basic Information", icon: "building.2") {
            VStack(spacing: 20) {
                // Store ID & Store Name — side by side
                HStack(alignment: .top, spacing: 16) {
                    // Store ID
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(text: "Store ID")
                        
                        HStack(spacing: 8) {
                            Image(systemName: "number")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            
                            Text(generatedStoreID.isEmpty ? "Auto-generated" : generatedStoreID)
                                .font(.system(size: 15, weight: generatedStoreID.isEmpty ? .regular : .semibold))
                                .foregroundColor(generatedStoreID.isEmpty ? .secondary.opacity(0.5) : .primary)
                            
                            Spacer()
                            
                            if !generatedStoreID.isEmpty {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(FormTheme.fieldBackground.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: FormTheme.fieldCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: FormTheme.fieldCornerRadius)
                                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                        )
                        
                        if !detectedRegionCode.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.system(size: 9))
                                Text("Region: \(detectedRegionCode)")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Store Name
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(text: "Store Name")
                        
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            
                            TextField("e.g. London Flagship", text: $storeName)
                                .font(.system(size: 15))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(FormTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: FormTheme.fieldCornerRadius))
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Store Status
                VStack(alignment: .leading, spacing: 10) {
                    FieldLabel(text: "Store Status")
                    
                    HStack(spacing: 0) {
                        ForEach([StoreStatus.active, StoreStatus.maintenance], id: \.self) { status in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) { storeStatus = status }
                            }) {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(statusColor(for: status))
                                        .frame(width: 6, height: 6)
                                    Text(status.rawValue.capitalized)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(storeStatus == status ? Color.white : Color.clear)
                                .foregroundColor(storeStatus == status ? .primary : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: storeStatus == status ? Color.black.opacity(0.06) : .clear, radius: 3, y: 1)
                            }
                            .buttonStyle(.plain)
                            .padding(3)
                        }
                    }
                    .background(FormTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Location / Address
                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "Location / Address")
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.red.opacity(0.7))
                        
                        TextField("Search for address or drop a pin below…", text: $address)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()
                            .onChange(of: address) { _, newValue in
                                let sanitized = sanitizeToEnglish(newValue)
                                if sanitized != newValue {
                                    address = sanitized
                                }
                            }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(FormTheme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: FormTheme.fieldCornerRadius))
                }
            }
        }
    }
    
    // MARK: - Section: Location Map
    
    private var locationMapSection: some View {
        FormSectionCard(title: "Pin Location", icon: "map") {
            VStack(spacing: 16) {
                // Map
                ZStack {
                    Map(coordinateRegion: $mapRegion, interactionModes: .all, annotationItems: pinPlaced ? [MapPin(coordinate: selectedCoordinate)] : []) { pin in
                        MapAnnotation(coordinate: pin.coordinate) {
                            if pinPlaced {
                                VStack(spacing: 0) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(.red)
                                        .shadow(color: .red.opacity(0.3), radius: 6, y: 2)
                                    
                                    Circle()
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 8, height: 8)
                                        .offset(y: -2)
                                }
                            }
                        }
                    }
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    // Zoom Controls
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation {
                                mapRegion.span.latitudeDelta = max(mapRegion.span.latitudeDelta / 2, 0.01)
                                mapRegion.span.longitudeDelta = max(mapRegion.span.longitudeDelta / 2, 0.01)
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial)
                                .foregroundColor(.primary)
                        }
                        Divider().frame(width: 36)
                        Button(action: {
                            withAnimation {
                                mapRegion.span.latitudeDelta = min(mapRegion.span.latitudeDelta * 2, 180)
                                mapRegion.span.longitudeDelta = min(mapRegion.span.longitudeDelta * 2, 180)
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial)
                                .foregroundColor(.primary)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    
                    // Center crosshair when no pin
                    if !pinPlaced {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(FormTheme.navy.opacity(0.5))
                    }
                }
                
                // Map Action Buttons
                HStack(spacing: 10) {
                    Button(action: {
                        selectedCoordinate = mapRegion.center
                        pinPlaced = true
                        reverseGeocode(coordinate: selectedCoordinate)
                        detectRegionAndGenerateID(coordinate: selectedCoordinate)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 12))
                            Text("Drop Pin")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(FormTheme.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button(action: {
                        fetchCurrentLocation()
                    }) {
                        HStack(spacing: 6) {
                            if isLocating {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                            }
                            Text("My Location")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(FormTheme.navy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(FormTheme.navy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isLocating)
                    
                    if pinPlaced {
                        Button(action: {
                            withAnimation {
                                pinPlaced = false
                                address = ""
                                generatedStoreID = ""
                                detectedRegionCode = ""
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 12))
                                Text("Clear")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    Spacer()
                }
                
                // Coordinates display
                if pinPlaced {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.and.down")
                                .font(.system(size: 10))
                            Text(String(format: "Lat: %.5f", selectedCoordinate.latitude))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.and.right")
                                .font(.system(size: 10))
                            Text(String(format: "Lon: %.5f", selectedCoordinate.longitude))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    

    
    // MARK: - Section: Store Media
    
    private var storeMediaSection: some View {
        FormSectionCard(title: "Store Media", icon: "photo.on.rectangle.angled") {
            if let image = selectedImage {
                // Image preview
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    // Overlay buttons
                    HStack(spacing: 8) {
                        Button(action: { showingImageSourceSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 10))
                                Text("Change")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial.opacity(0.9))
                            .background(Color.black.opacity(0.3))
                            .clipShape(Capsule())
                        }
                        
                        Button(action: {
                            withAnimation { selectedImage = nil }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 4)
                        }
                    }
                    .padding(12)
                }
            } else {
                // Upload placeholder
                Button(action: { showingImageSourceSheet = true }) {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(FormTheme.navy.opacity(0.06))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 24))
                                .foregroundColor(FormTheme.navy.opacity(0.7))
                        }
                        
                        VStack(spacing: 4) {
                            Text("Upload Store Image")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("PNG or JPG, up to 10 MB")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundStyle(Color.secondary.opacity(0.25))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        // Image source selection dialog attached here so the iPad popover points to this section
        .confirmationDialog("Select Image Source", isPresented: $showingImageSourceSheet, titleVisibility: .visible) {
            Button("Choose from Gallery") {
                imageSourceType = .photoLibrary
                showingImagePicker = true
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    imageSourceType = .camera
                    showingImagePicker = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Helpers
    
    private func statusColor(for status: StoreStatus) -> Color {
        switch status {
        case .active: return .green
        case .maintenance: return .orange
        case .inventory: return .blue
        }
    }
    
    // MARK: - Fetch current location, drop pin, and fill address
    private func fetchCurrentLocation() {
        isLocating = true
        locationManager.requestPermission()
        locationManager.startUpdating()
        
        // Wait longer for accurate GPS lock
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if locationManager.hasLocation {
                let loc = CLLocationCoordinate2D(
                    latitude: locationManager.latitude,
                    longitude: locationManager.longitude
                )
                withAnimation(.easeInOut(duration: 0.4)) {
                    mapRegion = MKCoordinateRegion(
                        center: loc,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                }
                selectedCoordinate = loc
                pinPlaced = true
                reverseGeocode(coordinate: loc)
                detectRegionAndGenerateID(coordinate: loc)
            }
            isLocating = false
        }
    }
    
    // MARK: - Reverse geocode to get English address text
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        Task {
            do {
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    self.address = String(format: "Lat: %.5f, Lon: %.5f", coordinate.latitude, coordinate.longitude)
                    return
                }
                request.preferredLocale = Locale(identifier: "en_US")
                let mapItems = try await request.mapItems
                if let placemark = mapItems.first?.placemark {
                    let components = [
                        placemark.subThoroughfare,
                        placemark.thoroughfare,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.postalCode,
                        placemark.country
                    ].compactMap { $0 }
                    let fullAddress = components.joined(separator: ", ")
                    self.address = sanitizeToEnglish(fullAddress)
                } else {
                    self.address = String(format: "Lat: %.5f, Lon: %.5f", coordinate.latitude, coordinate.longitude)
                }
            } catch {
                self.address = String(format: "Lat: %.5f, Lon: %.5f", coordinate.latitude, coordinate.longitude)
            }
        }
    }
    
    // MARK: - Detect region from coordinate and auto-generate Store ID
    private func detectRegionAndGenerateID(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        Task {
            do {
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    self.detectedRegionCode = "XX"
                    self.generatedStoreID = StoreIDGenerator.shared.nextID(forRegion: "XX")
                    return
                }
                request.preferredLocale = Locale(identifier: "en_US")
                let mapItems = try await request.mapItems
                if let isoCode = mapItems.first?.placemark.isoCountryCode {
                    self.detectedRegionCode = isoCode.uppercased()
                    self.generatedStoreID = StoreIDGenerator.shared.nextID(forRegion: isoCode)
                } else {
                    self.detectedRegionCode = "XX"
                    self.generatedStoreID = StoreIDGenerator.shared.nextID(forRegion: "XX")
                }
            } catch {
                self.detectedRegionCode = "XX"
                self.generatedStoreID = StoreIDGenerator.shared.nextID(forRegion: "XX")
            }
        }
    }
    
    private func saveStore() {
        let trimmedName = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            validationMessage = "Please enter the store name."
            showingValidationAlert = true
            return
        }
        
        if !pinPlaced {
            validationMessage = "Please set a location on the map."
            showingValidationAlert = true
            return
        }
        
        let storeID = generatedStoreID.isEmpty ? StoreIDGenerator.shared.nextID(forRegion: detectedRegionCode.isEmpty ? "XX" : detectedRegionCode) : generatedStoreID
        
        let store = AdminStore(
            id: editingStore?.id ?? UUID(),
            storeID: storeID,
            name: trimmedName,
            address: trimmedAddress.isEmpty ? "Address not set" : trimmedAddress,
            managerName: editingStore?.managerName ?? "Unassigned",
            managerInitials: editingStore?.managerInitials ?? "--",
            status: storeStatus,
            imageData: selectedImage?.jpegData(compressionQuality: 0.8),
            imageUrl: editingStore?.imageUrl,
            latitude: pinPlaced ? selectedCoordinate.latitude : nil,
            longitude: pinPlaced ? selectedCoordinate.longitude : nil
        )
        
        onSave(store)
        onDismiss()
    }
}

#Preview {
    AddStoreView(onDismiss: {}, onSave: { _ in })
}
