//
//  SupabaseManager.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {

        client = SupabaseClient(
            supabaseURL: URL(string: Constants.supabaseURL)!,
            supabaseKey: Constants.supabaseKey
        )
    }
}
