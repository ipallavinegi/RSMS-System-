// ManagerModel.swift
// Admin_RSMS

import Foundation

// ─────────────────────────────────────────────────────────────────
// MARK: – Manager  (maps 1-to-1 with `staff_members` table)
// ─────────────────────────────────────────────────────────────────
struct Manager: Identifiable, Codable, Equatable {
    var id:         UUID
    var name:       String
    var email:      String
    var role:       String
    var location:   String
    var shift:      String
    var imageName:  String?
    var initials:   String
    var isArchived: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case role
        case location
        case shift
        case imageName  = "image_name"
        case initials
        case isArchived = "is_archived"
    }

    init(
        id:         UUID    = UUID(),
        name:       String,
        email:      String  = "",
        role:       String,
        location:   String,
        shift:      String,
        imageName:  String? = nil,
        initials:   String,
        isArchived: Bool    = false
    ) {
        self.id         = id
        self.name       = name
        self.email      = email
        self.role       = role
        self.location   = location
        self.shift      = shift
        self.imageName  = imageName
        self.initials   = initials
        self.isArchived = isArchived
    }

    init(from decoder: Decoder) throws {
        let c       = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,             forKey: .id)
        name        = try c.decode(String.self,           forKey: .name)
        email       = (try? c.decode(String.self,         forKey: .email))  ?? ""
        role        = try c.decode(String.self,           forKey: .role)
        location    = (try? c.decode(String.self,         forKey: .location)) ?? ""
        shift       = (try? c.decode(String.self,         forKey: .shift))    ?? ""
        imageName   = try c.decodeIfPresent(String.self,  forKey: .imageName)
        initials    = (try? c.decode(String.self,         forKey: .initials)) ?? "??"
        isArchived  = (try? c.decode(Bool.self,           forKey: .isArchived)) ?? false
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: – Payload for insert / update operations
// ─────────────────────────────────────────────────────────────────
struct ManagerPayload: Encodable {
    let name:       String
    let email:      String
    let role:       String
    let location:   String
    let shift:      String
    let imageName:  String?
    let initials:   String
    let isArchived: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case email
        case role
        case location
        case shift
        case imageName  = "image_name"
        case initials
        case isArchived = "is_archived"
    }

    init(from member: Manager) {
        name       = member.name
        email      = member.email
        role       = member.role
        location   = member.location
        shift      = member.shift
        imageName  = member.imageName
        initials   = member.initials
        isArchived = member.isArchived
    }
}
