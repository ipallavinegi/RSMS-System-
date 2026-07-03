import SwiftUI
import MapKit
import CoreLocation

struct AddStoreSidebarView: View {
    @Binding var mapRegion: MKCoordinateRegion
    @Binding var selectedCoordinate: CLLocationCoordinate2D
    @Binding var pinPlaced: Bool
    
    var onSave: (AdminStore) -> Void
    
    @State private var storeName = ""
    @State private var generatedStoreID = ""
    @State private var detectedRegionCode = ""
    @State private var address = ""
    @State private var storeType = "Flagship"
    @State private var storeStatus: StoreStatus = .active
    @State private var openingTime: Date = {
        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var closingTime: Date = {
        var comps = DateComponents()
        comps.hour = 21
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var weekendOps = true
    
    // Image picker state
    @State private var selectedImage: UIImage? = nil
    @State private var showingImageSourceSheet = false
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @StateObject private var locationManager = LocationManager()
    @State private var isLocating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Sidebar Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Register New Store")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                Text("Add a location to the global network.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)
            
            // Scrollable Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Store Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("STORE NAME")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            TextField("e.g. London Flagship", text: $storeName)
                                .padding(12)
                                .background(Color(uiColor: .systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Store ID
                        VStack(alignment: .leading, spacing: 6) {
                            Text("STORE ID")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            HStack {
                                Text(generatedStoreID.isEmpty ? "Auto-generated" : generatedStoreID)
                                    .foregroundColor(generatedStoreID.isEmpty ? .secondary.opacity(0.5) : .primary)
                                    .font(.system(size: 14))
                                Spacer()
                                if !generatedStoreID.isEmpty {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(12)
                            .background(Color(uiColor: .systemGray6).opacity(0.7))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                            if !detectedRegionCode.isEmpty {
                                Text("Region: \(detectedRegionCode)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Location Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Location Details")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Address/Search Input
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ADDRESS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(.secondary)
                                TextField("Enter address or drop pin...", text: $address)
                                    .autocorrectionDisabled()
                                    .onChange(of: address) { _, newValue in
                                        let sanitized = sanitizeToEnglish(newValue)
                                        if sanitized != newValue {
                                            address = sanitized
                                        }
                                    }
                            }
                            .padding(12)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Pin Placed Indicator
                        HStack {
                            Circle()
                                .fill(pinPlaced ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(pinPlaced ? "Location Pin Placed" : "No Location Selected")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        // Map controls
                        VStack(spacing: 10) {
                            Button(action: {
                                selectedCoordinate = mapRegion.center
                                pinPlaced = true
                                reverseGeocode(coordinate: selectedCoordinate)
                                detectRegionAndGenerateID(coordinate: selectedCoordinate)
                            }) {
                                Label("Drop Pin at Map Center", systemImage: "mappin.and.ellipse")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor(.white)
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
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
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
                                    Label("Clear Pin", systemImage: "xmark.circle")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .foregroundColor(.red)
                                        .background(Color.red.opacity(0.08))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Operational & Image Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Operations & Media")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Store Type
                        VStack(alignment: .leading, spacing: 6) {
                            Text("STORE TYPE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            HStack(spacing: 0) {
                                ForEach(["Flagship", "Warehouse", "Boutique"], id: \.self) { type in
                                    Button(action: { storeType = type }) {
                                        Text(type)
                                            .font(.system(size: 11, weight: .semibold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(storeType == type ? Color.white : Color.clear)
                                            .foregroundColor(storeType == type ? .primary : .secondary)
                                            .cornerRadius(6)
                                            .padding(2)
                                    }
                                    .buttonStyle(.plain)
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
                        
                        // Hours
                        VStack(alignment: .leading, spacing: 6) {
                            Text("OPENING HOURS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            HStack(spacing: 12) {
                                DatePicker("Opens", selection: $openingTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                Text("TO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                DatePicker("Closes", selection: $closingTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                        }
                        
                        // Weekend operations
                        Toggle(isOn: $weekendOps) {
                            Text("Weekend Operations")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        // Store Image
                        VStack(alignment: .leading, spacing: 6) {
                            Text("STORE IMAGE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Button(action: { showingImageSourceSheet = true }) {
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                        .cornerRadius(8)
                                        .clipped()
                                } else {
                                    VStack(spacing: 6) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.title3)
                                        Text("Upload Image")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 100)
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Save Button
                    Button(action: { saveStore() }) {
                        Text("Save Store Registry")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.1, green: 0.2, blue: 0.4))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .frame(width: 400)
        .background(Color(uiColor: .secondarySystemBackground))
        .confirmationDialog("Select Image Source", isPresented: $showingImageSourceSheet) {
            Button("Camera") {
                imageSourceType = .camera
                showingImagePicker = true
            }
            Button("Photo Library") {
                imageSourceType = .photoLibrary
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSourceType)
        }
        .onChange(of: locationManager.hasLocation) { _, hasLoc in
            if hasLoc && isLocating {
                // Done loading location
            }
        }
    }
    
    // MARK: - Location Helpers
    private func fetchCurrentLocation() {
        isLocating = true
        locationManager.requestPermission()
        locationManager.startUpdating()
        
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
                    self.address = self.sanitizeToEnglish(fullAddress)
                } else {
                    self.address = String(format: "Lat: %.5f, Lon: %.5f", coordinate.latitude, coordinate.longitude)
                }
            } catch {
                self.address = String(format: "Lat: %.5f, Lon: %.5f", coordinate.latitude, coordinate.longitude)
            }
        }
    }
    
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
            id: UUID(),
            storeID: storeID,
            name: trimmedName.isEmpty ? "New Store" : trimmedName,
            address: trimmedAddress.isEmpty ? "Address not set" : trimmedAddress,
            managerName: "Unassigned",
            managerInitials: "--",
            status: storeStatus,
            imageData: selectedImage?.jpegData(compressionQuality: 0.8),
            latitude: pinPlaced ? selectedCoordinate.latitude : nil,
            longitude: pinPlaced ? selectedCoordinate.longitude : nil
        )
        
        onSave(store)
        
        // Reset form
        storeName = ""
        address = ""
        generatedStoreID = ""
        detectedRegionCode = ""
        selectedImage = nil
        pinPlaced = false
    }
    
    private func sanitizeToEnglish(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: ".,/-#'"))
        return String(text.unicodeScalars.filter { allowed.contains($0) })
    }
}
