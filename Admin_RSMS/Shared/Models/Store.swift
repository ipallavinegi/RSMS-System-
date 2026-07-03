// StoreModel.swift
// Admin_RSMS
//
// AdminStore maps 1-to-1 with the `stores` Supabase table (the working
// admin UI table). The SRS-canonical `Store` type lives in Models/Store.swift.

import Foundation

// ─────────────────────────────────────────────────────────────────
// MARK: – AdminStore  (maps 1-to-1 with the `stores` Supabase table)
// ─────────────────────────────────────────────────────────────────
struct AdminStore: Identifiable, Codable {
    var id:               UUID
    var storeID:          String?
    var name:             String
    var address:          String
    var managerName:      String
    var managerInitials:  String
    var status:           StoreStatus
    var imageData:        Data?      // local-only; not persisted to Supabase
    var imageUrl:         String?
    var latitude:         Double?
    var longitude:        Double?
    var isArchived:       Bool

    // ── Coding keys: snake_case ↔ camelCase ──────────────────────
    enum CodingKeys: String, CodingKey {
        case id
        case storeID          = "store_id"
        case name
        case address
        case managerName      = "manager_name"
        case managerInitials  = "manager_initials"
        case status
        case imageUrl         = "image_url"
        case latitude
        case longitude
        case isArchived       = "is_archived"
        // imageData is intentionally excluded — stored locally only
    }

    // ── Custom init so imageData survives even though it's not in CodingKeys ──
    init(
        id:              UUID     = UUID(),
        storeID:         String?  = nil,
        name:            String,
        address:         String,
        managerName:     String,
        managerInitials: String,
        status:          StoreStatus,
        imageData:       Data?    = nil,
        imageUrl:        String?  = nil,
        latitude:        Double?  = nil,
        longitude:       Double?  = nil,
        isArchived:      Bool     = false
    ) {
        self.id              = id
        self.storeID         = storeID
        self.name            = name
        self.address         = address
        self.managerName     = managerName
        self.managerInitials = managerInitials
        self.status          = status
        self.imageData       = imageData
        self.imageUrl        = imageUrl
        self.latitude        = latitude
        self.longitude       = longitude
        self.isArchived      = isArchived
    }

    // ── Decode (from Supabase JSON) ──────────────────────────────
    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self,        forKey: .id)
        storeID         = try c.decodeIfPresent(String.self, forKey: .storeID)
        name            = try c.decode(String.self,      forKey: .name)
        address         = try c.decode(String.self,      forKey: .address)
        managerName     = try c.decode(String.self,      forKey: .managerName)
        managerInitials = try c.decode(String.self,      forKey: .managerInitials)
        let rawStatus   = try c.decode(String.self,      forKey: .status)
        status          = StoreStatus(rawValue: rawStatus) ?? .active
        imageUrl        = try c.decodeIfPresent(String.self,  forKey: .imageUrl)
        latitude        = try c.decodeIfPresent(Double.self,  forKey: .latitude)
        longitude       = try c.decodeIfPresent(Double.self,  forKey: .longitude)
        isArchived      = try c.decode(Bool.self,        forKey: .isArchived)
        imageData       = nil   // never comes from Supabase
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: – Payload used when inserting / updating to Supabase
// (excludes id, created_at, updated_at so Supabase generates them)
// ─────────────────────────────────────────────────────────────────
struct AdminStorePayload: Encodable {
    let storeID:         String?
    let name:            String
    let address:         String
    let managerName:     String
    let managerInitials: String
    let status:          String
    let imageUrl:        String?
    let latitude:        Double?
    let longitude:       Double?
    let isArchived:      Bool

    enum CodingKeys: String, CodingKey {
        case storeID         = "store_id"
        case name
        case address
        case managerName     = "manager_name"
        case managerInitials = "manager_initials"
        case status
        case imageUrl        = "image_url"
        case latitude
        case longitude
        case isArchived      = "is_archived"
    }

    init(from store: AdminStore) {
        storeID         = store.storeID
        name            = store.name
        address         = store.address
        managerName     = store.managerName
        managerInitials = store.managerInitials
        status          = store.status.rawValue
        imageUrl        = store.imageUrl
        latitude        = store.latitude
        longitude       = store.longitude
        isArchived      = store.isArchived
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: – StoreStatus
// ─────────────────────────────────────────────────────────────────
enum StoreStatus: String, Codable, CaseIterable {
    case active      = "ACTIVE"
    case maintenance = "MAINTENANCE"
    case inventory   = "INVENTORY"
}
