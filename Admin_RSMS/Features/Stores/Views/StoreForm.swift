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

// MARK: - Add Store View
struct AddStoreView: View {
    private let editingStore: AdminStore?
    var onDismiss: () -> Void
    var onSave: (AdminStore) -> Void
    
    @State private var storeName = ""
    @State private var generatedStoreID = ""
    @State private var detectedRegionCode = ""
    @State private var address = ""
    @State private var storeType = "Flagship"
    @State private var storeStatus: StoreStatus = .active
    @State private var openingTime = Date()
    @State private var closingTime = Date()
    @State private var weekendOps = true
    
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
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var storeIDGenerator = StoreIDGenerator.shared
    
    // Default times
    private var defaultOpenTime: Date {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private var defaultCloseTime: Date {
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
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
        // Set default opening/closing times
        var openComps = DateComponents()
        openComps.hour = 9
        openComps.minute = 0
        _openingTime = State(initialValue: Calendar.current.date(from: openComps) ?? Date())
        
        var closeComps = DateComponents()
        closeComps.hour = 21
        closeComps.minute = 0
        _closingTime = State(initialValue: Calendar.current.date(from: closeComps) ?? Date())
        
        // Initialize coordinates if available
        if let lat = editingStore?.latitude, let lon = editingStore?.longitude {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            _selectedCoordinate = State(initialValue: coord)
            _mapRegion = State(initialValue: MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            _pinPlaced = State(initialValue: true)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar — native iOS chevron only, no "Back" text
            HStack(spacing: 16) {
                Button(action: { onDismiss() }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                }
                
                Spacer()
                
                Text(editingStore == nil ? "Add New Store" : "Edit Store")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                
                Spacer()
                
                // Invisible balancer
                Image(systemName: "chevron.backward")
                    .font(.system(size: 20, weight: .medium))
                    .opacity(0)
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    HStack(alignment: .top, spacing: 32) {
                        // Left Column: Basic Information
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Basic Information")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                HStack(spacing: 20) {
                                    // Store ID — first (left), auto-generated
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("STORE ID")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        HStack {
                                            Text(generatedStoreID.isEmpty ? "Auto-generated" : generatedStoreID)
                                                .foregroundColor(generatedStoreID.isEmpty ? .secondary.opacity(0.5) : .primary)
                                                .font(.system(size: 15))
                                            Spacer()
                                            if !generatedStoreID.isEmpty {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(Color(uiColor: .systemGray6).opacity(0.7))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                                        )
                                        if !detectedRegionCode.isEmpty {
                                            Text("Region: \(detectedRegionCode)")
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    // Store Name — second (right), user-editable
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("STORE NAME")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        TextField("e.g. London flagship", text: $storeName)
                                            .padding()
                                            .background(Color(uiColor: .systemGray6))
                                            .cornerRadius(10)
                                    }
                                }
                                
                                // Location/Address field — English text only
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("LOCATION/ADDRESS")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Image(systemName: "mappin.circle")
                                            .foregroundColor(.secondary)
                                        TextField("Search for address...", text: $address)
                                            .autocorrectionDisabled()
                                            .onChange(of: address) { _, newValue in
                                                let sanitized = sanitizeToEnglish(newValue)
                                                if sanitized != newValue {
                                                    address = sanitized
                                                }
                                            }
                                    }
                                    .padding()
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(10)
                                }
                                
                                // Interactive Map — worldwide
                                VStack(spacing: 0) {
                                    ZStack {
                                        Map(coordinateRegion: $mapRegion, interactionModes: .all, annotationItems: pinPlaced ? [MapPin(coordinate: selectedCoordinate)] : []) { pin in
                                            MapAnnotation(coordinate: pin.coordinate) {
                                                if pinPlaced {
                                                    Image(systemName: "mappin.circle.fill")
                                                        .font(.system(size: 30))
                                                        .foregroundColor(.red)
                                                        .shadow(radius: 4)
                                                }
                                            }
                                        }
                                        .frame(height: 260)
                                        .cornerRadius(16)
                                        
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
                                                    .frame(width: 36, height: 36)
                                                    .background(Color.white.opacity(0.9))
                                                    .foregroundColor(.primary)
                                            }
                                            Divider()
                                            Button(action: {
                                                withAnimation {
                                                    mapRegion.span.latitudeDelta = min(mapRegion.span.latitudeDelta * 2, 180)
                                                    mapRegion.span.longitudeDelta = min(mapRegion.span.longitudeDelta * 2, 180)
                                                }
                                            }) {
                                                Image(systemName: "minus")
                                                    .font(.title3.bold())
                                                    .frame(width: 36, height: 36)
                                                    .background(Color.white.opacity(0.9))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .cornerRadius(8)
                                        .shadow(radius: 4)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                        
                                        // Center crosshair when no pin is placed
                                        if !pinPlaced {
                                            Image(systemName: "plus")
                                                .font(.system(size: 20, weight: .light))
                                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.6))
                                        }
                                    }
                                    
                                    // Map action buttons
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            selectedCoordinate = mapRegion.center
                                            pinPlaced = true
                                            reverseGeocode(coordinate: selectedCoordinate)
                                            detectRegionAndGenerateID(coordinate: selectedCoordinate)
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "mappin.and.ellipse")
                                                    .font(.system(size: 12))
                                                Text("Drop Pin Here")
                                                    .font(.system(size: 12, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(red: 0.1, green: 0.2, blue: 0.4))
                                            .cornerRadius(8)
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
                                                Text("Use My Location")
                                                    .font(.system(size: 12, weight: .semibold))
                                            }
                                            .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(uiColor: .systemGray6))
                                            .cornerRadius(8)
                                        }
                                        .disabled(isLocating)
                                        
                                        if pinPlaced {
                                            Button(action: {
                                                pinPlaced = false
                                                address = ""
                                                generatedStoreID = ""
                                                detectedRegionCode = ""
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "xmark.circle")
                                                        .font(.system(size: 12))
                                                    Text("Clear Pin")
                                                        .font(.system(size: 12, weight: .semibold))
                                                }
                                                .foregroundColor(.red)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.red.opacity(0.08))
                                                .cornerRadius(8)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.top, 12)
                                }
                            }
                            .padding(24)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Column
                        VStack(alignment: .leading, spacing: 24) {
                            // Operational Details
                            VStack(alignment: .leading, spacing: 24) {
                                Text("Operational Details")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                // Store Type
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("STORE TYPE")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 0) {
                                        ForEach(["Flagship", "Warehouse", "Boutique"], id: \.self) { type in
                                            Button(action: { storeType = type }) {
                                                Text(type)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 10)
                                                    .background(storeType == type ? Color.white : Color.clear)
                                                    .foregroundColor(storeType == type ? .primary : .secondary)
                                                    .cornerRadius(6)
                                                    .padding(2)
                                            }
                                        }
                                    }
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                // Store Status
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("STORE STATUS")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 0) {
                                        ForEach(StoreStatus.allCases, id: \.self) { status in
                                            Button(action: { storeStatus = status }) {
                                                Text(status.rawValue.capitalized)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                                    .background(storeStatus == status ? Color.white : Color.clear)
                                                    .foregroundColor(storeStatus == status ? .primary : .secondary)
                                                    .cornerRadius(6)
                                                    .padding(2)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                // Opening Hours — no curved rectangle boxes around DatePickers
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("OPENING HOURS")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    VStack(spacing: 16) {
                                        HStack(spacing: 16) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Opens at")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                DatePicker("", selection: $openingTime, displayedComponents: .hourAndMinute)
                                                    .datePickerStyle(.compact)
                                                    .labelsHidden()
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            
                                            Text("TO")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.secondary)
                                                .padding(.top, 20)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Closes at")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                DatePicker("", selection: $closingTime, displayedComponents: .hourAndMinute)
                                                    .datePickerStyle(.compact)
                                                    .labelsHidden()
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                    }
                                }
                                
                                // Weekend Operations — full text, no subtitle
                                HStack {
                                    Text("Weekend Operations")
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                    Toggle("", isOn: $weekendOps)
                                        .labelsHidden()
                                }
                                .padding()
                                .background(Color(uiColor: .systemGray6).opacity(0.5))
                                .cornerRadius(12)
                            }
                            .padding(24)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            
                            // Store Media — Upload Image with Gallery/Camera
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Store Media")
                                    .font(.headline)
                                
                                if let image = selectedImage {
                                    // Show selected image preview
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                        
                                        // Remove / Change buttons
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                showingImageSourceSheet = true
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "arrow.triangle.2.circlepath")
                                                        .font(.system(size: 10))
                                                    Text("Change")
                                                        .font(.system(size: 10, weight: .semibold))
                                                }
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.black.opacity(0.6))
                                                .cornerRadius(8)
                                            }
                                            
                                            Button(action: {
                                                withAnimation {
                                                    selectedImage = nil
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(.white)
                                                    .shadow(radius: 4)
                                            }
                                        }
                                        .padding(10)
                                    }
                                } else {
                                    // Upload placeholder
                                    Button(action: {
                                        showingImageSourceSheet = true
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 28))
                                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                                                .padding(14)
                                                .background(Color(uiColor: .systemGray6))
                                                .cornerRadius(12)
                                            
                                            VStack(spacing: 4) {
                                                Text("Upload Image")
                                                    .font(.system(size: 14, weight: .bold))
                                                Text("PNG/JPG up to 10MB")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 32)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                                .foregroundColor(.secondary.opacity(0.3))
                                        )
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                            .padding(24)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .frame(width: 340)
                    }
                }
                .padding(32)
            }
            .background(Color(uiColor: .systemGroupedBackground).opacity(0.5))
            
            // Bottom Bar — only Cancel and Save buttons
            HStack {
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                    
                    Button(action: { saveStore() }) {
                        Text(editingStore == nil ? "Save Store Registry" : "Update Registry")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.1, green: 0.2, blue: 0.4))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(Divider(), alignment: .top)
        }
        .navigationBarHidden(true)
        .onAppear {
            locationManager.requestPermission()
            locationManager.startUpdating()
        }
        .onChange(of: locationManager.hasLocation) { _, newValue in
            if newValue, !pinPlaced {
                // Center map on user's real-time location when first acquired
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
        // Image source selection dialog
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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSourceType)
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
        let storeID = generatedStoreID.isEmpty ? StoreIDGenerator.shared.nextID(forRegion: detectedRegionCode.isEmpty ? "XX" : detectedRegionCode) : generatedStoreID
        
        let store = AdminStore(
            id: editingStore?.id ?? UUID(),
            storeID: storeID,
            name: trimmedName.isEmpty ? "New Store" : trimmedName,
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
