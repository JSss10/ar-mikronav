// Config.swift
// ARMikronav
//
// ⚠️ NICHT in Git einchecken! Kopiere Config.example.swift → Config.swift
// und trage deine Supabase-Credentials ein.

import Foundation

enum AppConfig {
    // MARK: - Supabase
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = "YOUR_ANON_KEY"
    
    // MARK: - Testgebiet Altstadt Zürich
    static let testAreaMinLat = 47.369
    static let testAreaMaxLat = 47.375
    static let testAreaMinLng = 8.539
    static let testAreaMaxLng = 8.547
    
    // MARK: - Defaults
    static let defaultBarrierRadius: Double = 500
    static let approachWarningDistance: Double = 30
    
    // MARK: - ginto API
    static let gintoAPIEndpoint = "https://api.ginto.guide/graphql"
    static let gintoAPIKey = "YOUR_GINTO_BEARER_TOKEN"
    
    // MARK: - ginto Rating Profile IDs
    static let gintoManualWheelchairID = "Z2lkOi8vcmFpbHMtYXBwL1JhdGluZ1Byb2ZpbGVzOjpSYXRpbmdQcm9maWxlLzc4"
    static let gintoPowerWheelchairID = "Z2lkOi8vcmFpbHMtYXBwL1JhdGluZ1Byb2ZpbGVzOjpSYXRpbmdQcm9maWxlLzc5"
    static let gintoScewoBroID = "Z2lkOi8vcmFpbHMtYXBwL1JhdGluZ1Byb2ZpbGVzOjpSYXRpbmdQcm9maWxlLzM5NTE"
    static let gintoPushchairID = "Z2lkOi8vcmFpbHMtYXBwL1JhdGluZ1Byb2ZpbGVzOjpSYXRpbmdQcm9maWxlLzgw"
}
