//
//  AuthService.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class AuthService {

    private let client = SupabaseManager.shared.client

    func sendOTP(email: String) async throws {

        try await client.auth.signInWithOTP(
            email: email
        )
    }
    
    func verifyOTP(
        email: String,
        token: String
    ) async throws {

        try await client.auth.verifyOTP(
            email: email,
            token: token,
            type: .email
        )
    }
}

