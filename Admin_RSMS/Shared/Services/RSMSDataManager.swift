// RSMSDataManager.swift
// Admin_RSMS
//
// Central data manager — real-time Supabase reads, writes, and realtime
// subscriptions. Uses SupabaseManager.shared.client directly via the
// Services layer. Models: AdminStore (StoreModel.swift), Manager
// (ManagerModel.swift), Role (Models/Role.swift).
//

import Foundation
import SwiftUI
import Combine
import Supabase

// ─────────────────────────────────────────────────────────────────
// MARK: – AppUser payload (used when inserting a new user into `users` table)
// Matches the SRS `User` model columns subset required for creation.
// Full model is in Models/User.swift.
// ─────────────────────────────────────────────────────────────────
struct AppUser: Encodable {
    let id:         UUID
    let fullName:   String
    let username:   String
    let password:   String
    let email:      String
    let roleId:     UUID
    let storeId:    UUID?
    let designation: String?
    let createdBy:  UUID?
    let employeeStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName       = "full_name"
        case username
        case password
        case email
        case roleId         = "role_id"
        case storeId        = "store_id"
        case designation    = "designation"
        case createdBy      = "created_by"
        case employeeStatus = "employee_status"
    }
}

@MainActor
class RSMSDataManager: ObservableObject {

    static let shared = RSMSDataManager()

    // ── Published state ───────────────────────────────────────────
    @Published var stores:       [AdminStore]   = []
    @Published var managers: [Manager]  = []
    @Published var products: [Product]  = []
    @Published var isLoading:    Bool           = false
    @Published var errorMessage: String?        = nil

    // Supabase client — single source of truth via SupabaseManager
    private let client = SupabaseManager.shared.client

    // Private realtime channel references
    private var storeChannel: RealtimeChannelV2?
    private var managerChannel: RealtimeChannelV2?
    private var productChannel: RealtimeChannelV2?

    // ─────────────────────────────────────────────────────────────
    // MARK: – Init: load data & start realtime
    // ─────────────────────────────────────────────────────────────
    private init() {
        Task {
            await fetchAll()
            await subscribeToRealtime()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Fetch everything on launch
    // ─────────────────────────────────────────────────────────────
    func fetchAll() async {
        isLoading = true
        errorMessage = nil
        async let s = fetchStores()
        async let m = fetchManager()
        async let p = fetchProducts()
        _ = await (s, m, p)
        isLoading = false
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORES: Fetch
    // ─────────────────────────────────────────────────────────────
    @discardableResult
    func fetchStores() async -> [AdminStore] {
        do {
            let result: [AdminStore] = try await client
                .from("stores")
                .select()
                .order("name")
                .execute()
                .value
            stores = result
            return result
        } catch {
            errorMessage = "Failed to load stores: \(error.localizedDescription)"
            print("[RSMS] fetchStores error: \(error)")
            return []
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – PRODUCTS: Fetch
    // ─────────────────────────────────────────────────────────────
    @discardableResult
    func fetchProducts() async -> [Product] {
        do {
            let result: [Product] = try await client
                .from("products")
                .select()
                .order("product_name")
                .execute()
                .value
            products = result
            return result
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("[RSMS] fetchProducts error: \(error)")
            return []
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORES: Add
    // ─────────────────────────────────────────────────────────────
    func addStore(_ store: AdminStore) {
        Task {
            do {
                var finalStore = store
                // Upload image if present
                if let data = store.imageData {
                    if let url = try? await uploadStoreImage(data: data, storeId: store.id.uuidString) {
                        finalStore.imageUrl = url
                    }
                }
                
                let payload = AdminStorePayload(from: finalStore)
                let inserted: [AdminStore] = try await client
                    .from("stores")
                    .insert(payload)
                    .select()
                    .execute()
                    .value
                if let newStore = inserted.first {
                    stores.append(newStore)
                    assignManagerIfNeeded(for: newStore)
                }
            } catch {
                errorMessage = "Failed to add store: \(error.localizedDescription)"
                print("[RSMS] addStore error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORES: Update
    // ─────────────────────────────────────────────────────────────
    func updateStore(_ store: AdminStore) {
        Task {
            do {
                var finalStore = store
                if let data = store.imageData {
                    if let url = try? await uploadStoreImage(data: data, storeId: store.id.uuidString) {
                        finalStore.imageUrl = url
                    }
                }
                
                let payload = AdminStorePayload(from: finalStore)
                let updated: [AdminStore] = try await client
                    .from("stores")
                    .update(payload)
                    .eq("id", value: store.id.uuidString)
                    .select()
                    .execute()
                    .value
                if let updatedStore = updated.first,
                   let idx = stores.firstIndex(where: { $0.id == store.id }) {
                    stores[idx] = updatedStore
                }
            } catch {
                errorMessage = "Failed to update store: \(error.localizedDescription)"
                print("[RSMS] updateStore error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORES: Soft-delete (archive)
    // ─────────────────────────────────────────────────────────────
    func removeStore(_ store: AdminStore) {
        Task {
            do {
                var archived = store
                archived.isArchived = true
                let payload = AdminStorePayload(from: archived)
                let updated: [AdminStore] = try await client
                    .from("stores")
                    .update(payload)
                    .eq("id", value: store.id.uuidString)
                    .select()
                    .execute()
                    .value
                if let updatedStore = updated.first,
                   let idx = stores.firstIndex(where: { $0.id == store.id }) {
                    stores[idx] = updatedStore
                }
            } catch {
                errorMessage = "Failed to archive store: \(error.localizedDescription)"
                print("[RSMS] removeStore error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORAGE: Upload Image
    // ─────────────────────────────────────────────────────────────
    private func uploadStoreImage(data: Data, storeId: String) async throws -> String? {
        let fileName = "\(storeId).jpg"
        let bucket = "store-images"
        
        do {
            _ = try await client.storage
                .from(bucket)
                .upload(
                    fileName,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )
            
            let publicUrl = try client.storage.from(bucket).getPublicURL(path: fileName)
            return publicUrl.absoluteString
        } catch {
            print("[RSMS] Image upload failed: \(error)")
            throw error
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STAFF: Fetch
    // ─────────────────────────────────────────────────────────────
    @discardableResult
    func fetchManager() async -> [Manager] {
        do {
            let result: [Manager] = try await client
                .from("staff_members")
                .select()
                .order("name")
                .execute()
                .value
            managers = result
            return result
        } catch {
            errorMessage = "Failed to load manager: \(error.localizedDescription)"
            print("[RSMS] fetchManager error: \(error)")
            return []
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STAFF: Add
    // Uses Role from Models/Role.swift for the role lookup.
    // ─────────────────────────────────────────────────────────────
    func addManager(_ member: Manager) {
        Task {
            do {
                if isManagerRole(member.role) {
                    // 1. Fetch matching role using Models/Role.swift (role_name column)
                    let roles: [Role] = try await client
                        .from("roles")
                        .select()
                        .ilike("role_name", value: "%\(member.role)%")
                        .execute()
                        .value
                    
                    if let role = roles.first {
                        // 2. Generate random 8-character secure password
                        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
                        let randomPassword = String((0..<8).map { _ in letters.randomElement()! })
                        
                        // 3. Find the store to get store_id
                        let store = self.stores.first(where: { $0.name == member.location })
                        
                        let generatedUsername = member.email.split(separator: "@").first.map(String.init)?.lowercased() ?? String(member.name.prefix(6)).lowercased()
                        
                        // 4. Insert into users table using AppUser payload
                        let newUser = AppUser(
                            id: UUID(),
                            fullName: member.name,
                            username: generatedUsername.replacingOccurrences(of: ".", with: ""),
                            password: randomPassword,
                            email: member.email,
                            roleId: role.id,
                            storeId: store?.id,
                            designation: "Manager",
                            createdBy: AuthManager.shared.currentUser?.id,
                            employeeStatus: "Active"
                        )
                        
                        _ = try await client
                            .from("users")
                            .insert(newUser)
                            .execute()
                            
                        // 4. Trigger send-credentials edge function
                        let emailParams = [
                            "userEmail": member.email,
                            "userName": member.name,
                            "username": newUser.username,
                            "password": randomPassword,
                            "role": member.role
                        ]
                        
                        do {
                            _ = try await client.functions.invoke(
                                "send-credentials",
                                options: FunctionInvokeOptions(body: emailParams)
                            )
                        } catch {
                            print("[RSMS] Warning: Failed to call edge function: \(error)")
                            print("[RSMS] DEBUG: Generated Password for \(member.email) is \(randomPassword)")
                        }
                    } else {
                        print("[RSMS] Warning: Could not find role_id for role: \(member.role)")
                    }
                }
                
                let payload = ManagerPayload(from: member)
                let inserted: [Manager] = try await client
                    .from("staff_members")
                    .insert(payload)
                    .select()
                    .execute()
                    .value
                if let newMember = inserted.first {
                    managers.append(newMember)
                    await syncManagerToStore(member: newMember)
                }
            } catch {
                errorMessage = "Failed to add manager member: \(error.localizedDescription)"
                print("[RSMS] addManager error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STAFF: Update
    // ─────────────────────────────────────────────────────────────
    func updateManager(_ member: Manager) {
        Task {
            do {
                let oldMember = managers.first(where: { $0.id == member.id })
                let payload = ManagerPayload(from: member)
                let updated: [Manager] = try await client
                    .from("staff_members")
                    .update(payload)
                    .eq("id", value: member.id.uuidString)
                    .select()
                    .execute()
                    .value
                if let updatedMember = updated.first,
                   let idx = managers.firstIndex(where: { $0.id == member.id }) {
                    managers[idx] = updatedMember

                    if let old = oldMember,
                       old.location != member.location,
                       isManagerRole(old.role) {
                        await unassignManagerFromStore(location: old.location, managerName: old.name)
                    }
                    await syncManagerToStore(member: updatedMember)
                }
            } catch {
                errorMessage = "Failed to update manager member: \(error.localizedDescription)"
                print("[RSMS] updateManager error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STAFF: Soft-delete (archive)
    // ─────────────────────────────────────────────────────────────
    func removeManager(_ member: Manager) {
        Task {
            do {
                var archived = member
                archived.isArchived = true
                let payload = ManagerPayload(from: archived)
                let updated: [Manager] = try await client
                    .from("staff_members")
                    .update(payload)
                    .eq("id", value: member.id.uuidString)
                    .select()
                    .execute()
                    .value
                if let updatedMember = updated.first,
                   let idx = managers.firstIndex(where: { $0.id == member.id }) {
                    managers[idx] = updatedMember
                    if isManagerRole(member.role) {
                        await unassignManagerFromStore(location: member.location, managerName: member.name)
                    }
                }
                
                // Update employee status to Inactive in the users table
                struct UserStatusUpdate: Encodable {
                    let employeeStatus: String
                    enum CodingKeys: String, CodingKey {
                        case employeeStatus = "employee_status"
                    }
                }
                _ = try? await client
                    .from("users")
                    .update(UserStatusUpdate(employeeStatus: "Inactive"))
                    .eq("email", value: member.email)
                    .execute()
            } catch {
                errorMessage = "Failed to archive manager member: \(error.localizedDescription)"
                print("[RSMS] removeManager error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Manager ↔ Store sync helpers
    // ─────────────────────────────────────────────────────────────
    private func isManagerRole(_ role: String) -> Bool {
        let lower = role.lowercased()
        return lower.contains("manager") || lower.contains("admin") || lower.contains("lead")
    }

    private func assignManagerIfNeeded(for store: AdminStore) {
        // Called after a store is added; no-op here since manager is set on save
    }

    private func syncManagerToStore(member: Manager) async {
        guard isManagerRole(member.role) else { return }
        guard let storeIdx = stores.firstIndex(where: {
            $0.name.localizedCaseInsensitiveCompare(member.location) == .orderedSame
        }) else { return }

        var updatedStore = stores[storeIdx]
        updatedStore.managerName     = member.name
        updatedStore.managerInitials = member.initials

        do {
            let payload = AdminStorePayload(from: updatedStore)
            let result: [AdminStore] = try await client
                .from("stores")
                .update(payload)
                .eq("id", value: updatedStore.id.uuidString)
                .select()
                .execute()
                .value
            if let s = result.first {
                stores[storeIdx] = s
            }
        } catch {
            print("[RSMS] syncManagerToStore error: \(error)")
        }
    }

    private func unassignManagerFromStore(location: String, managerName: String) async {
        guard let storeIdx = stores.firstIndex(where: {
            $0.name.localizedCaseInsensitiveCompare(location) == .orderedSame &&
            $0.managerName == managerName
        }) else { return }

        var updatedStore = stores[storeIdx]
        updatedStore.managerName     = "Unassigned"
        updatedStore.managerInitials = "--"

        do {
            let payload = AdminStorePayload(from: updatedStore)
            let result: [AdminStore] = try await client
                .from("stores")
                .update(payload)
                .eq("id", value: updatedStore.id.uuidString)
                .select()
                .execute()
                .value
            if let s = result.first {
                stores[storeIdx] = s
            }
        } catch {
            print("[RSMS] unassignManagerFromStore error: \(error)")
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Realtime subscriptions (live updates across devices)
    // ─────────────────────────────────────────────────────────────
    private func subscribeToRealtime() async {
        // ── Stores channel ────────────────────────────────────────
        let storesCh = await client.realtimeV2.channel("stores-changes")
        let storesChanges = await storesCh.postgresChange(
            AnyAction.self,
            schema: "public",
            table:  "stores"
        )
        await storesCh.subscribe()
        storeChannel = storesCh

        Task {
            for await _ in storesChanges {
                await fetchStores()
            }
        }

        // ── Manager channel ─────────────────────────────────────────
        let managerCh = await client.realtimeV2.channel("staff-changes")
        let managerChanges = await managerCh.postgresChange(
            AnyAction.self,
            schema: "public",
            table:  "staff_members"
        )
        await managerCh.subscribe()
        managerChannel = managerCh

        Task {
            for await _ in managerChanges {
                await fetchManager()
            }
        }
        
        // ── Products channel ────────────────────────────────────────
        let productCh = await client.realtimeV2.channel("products-changes")
        let productChanges = await productCh.postgresChange(
            AnyAction.self,
            schema: "public",
            table:  "products"
        )
        await productCh.subscribe()
        productChannel = productCh

        Task {
            for await _ in productChanges {
                await fetchProducts()
            }
        }
    }
}
