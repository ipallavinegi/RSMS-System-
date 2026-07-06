//
//  AuthManager.swift
//  Admin_RSMS
//
//  Handles login against the `users` table using the SRS-aligned
//  User model (Models/User.swift). Uses SupabaseManager.shared.client
//  via the Services layer.
//
//  Authentication flow:
//  - Query users table by username + password
//  - Check role_id matches admin role UUID
//  - OTP currently bypassed after successful credential check
//

import Foundation
import Supabase
import SwiftUI
import Combine

@MainActor
public class AuthManager: ObservableObject {
    public static let shared = AuthManager()

    // ⚠️ TEMPORARY — flip to false to re-enable the login screen.
    // While true, the app skips authentication entirely on launch.
    private let authDisabledForTesting = false

    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?

    // Kept for future use if the OTP step is re-enabled.
    var pendingUser: User?
    private var currentOTP: String?

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Uses the canonical SupabaseManager from Services/SupabaseManager.swift
    private let client = SupabaseManager.shared.client

    // Table name matches SRS schema (lowercase `users`)
    private let table = "users"

    // Admin role UUID from the Roles table.
    // TODO: replace with a real query (e.g. fetch role where role_name = 'Admin')
    // once the roles table is seeded, so this doesn't silently break if the role
    // is ever recreated.
    private let adminRoleID = UUID(uuidString: "196203f9-3fe8-41f8-81c9-c665e004148b")

    private init() {
        self.isAuthenticated = authDisabledForTesting
    }

    // MARK: - Sign In

    func signIn(username: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            print("[AuthManager] Querying users table for username: \(username)")

            let users: [User] = try await client
                .from(table)
                .select()
                .eq("username", value: username)
                .eq("password", value: password)
                .execute()
                .value

            print("[AuthManager] Query returned \(users.count) user(s)")
            isLoading = false

            guard let matchedUser = users.first else {
                print("[AuthManager] No user matched username='\(username)' — wrong credentials or user doesn't exist")
                errorMessage = "Invalid username or password."
                return false
            }

            print("[AuthManager] Matched user: \(matchedUser.fullName), roleId: \(matchedUser.roleId)")

            guard matchedUser.roleId == adminRoleID else {
                print("[AuthManager] Role mismatch — user roleId \(matchedUser.roleId) != adminRoleID \(adminRoleID?.uuidString ?? "nil")")
                errorMessage = "Access Denied: You must be an Admin."
                return false
            }

            // ── Generate 6-digit OTP ──────────────────────────────
            let otp = String(format: "%06d", Int.random(in: 0...999999))
            self.currentOTP = otp
            self.pendingUser = matchedUser

            // ── Send via existing send-otp-email edge function ────
            let emailParams: [String: String] = [
                "email": matchedUser.email,
                "otp":   otp,
                "name":  matchedUser.fullName
            ]

            do {
                _ = try await client.functions.invoke(
                    "send-otp-email",
                    options: FunctionInvokeOptions(body: emailParams)
                )
                print("[AuthManager] OTP sent to \(matchedUser.email)")
            } catch {
                // Email failed — still allow login attempt; OTP visible in console for dev
                print("[AuthManager] ⚠️ send-otp-email failed: \(error)")
                print("[AuthManager] 🔑 DEBUG OTP for \(matchedUser.email): \(otp)")
            }

            // Return true → LoginView will show OTP screen.
            // isAuthenticated stays false until verifyCustomOTP() confirms the code.
            return true

        } catch {
            isLoading = false
            print("[AuthManager] ❌ Sign In Error (full): \(error)")
            print("[AuthManager] ❌ Localized: \(error.localizedDescription)")
            errorMessage = "Database error: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Verify OTP (currently unused — signIn bypasses this)

    func verifyCustomOTP(code: String) async -> Bool {
        guard let pending = pendingUser, let actualOTP = currentOTP else {
            errorMessage = "Session expired. Please sign in again."
            return false
        }

        isLoading = true
        errorMessage = nil

        if code == actualOTP {
            self.currentUser = pending
            self.pendingUser = nil
            self.currentOTP = nil
            self.isAuthenticated = true
            isLoading = false
            return true
        } else {
            isLoading = false
            errorMessage = "Invalid verification code."
            return false
        }
    }

    // MARK: - Sign Out

    func signOut() {
        currentUser = nil
        pendingUser = nil
        currentOTP = nil
        isAuthenticated = false
    }
}
