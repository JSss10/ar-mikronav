// AppConfig.swift
// ARMikronav
//
// Öffentliche Konstanten der App – alles, was problemlos in Git stehen darf.
// Geheime Werte (Supabase-Keys, ginto-Bearer) liegen in Secrets.swift,
// das per .gitignore ausgeschlossen ist.

import Foundation

enum AppConfig {
    // MARK: - Testgebiet Altstadt Zürich
    static let testAreaMinLat = 47.369
    static let testAreaMaxLat = 47.375
    static let testAreaMinLng = 8.539
    static let testAreaMaxLng = 8.547

    // MARK: - Defaults
    static let defaultBarrierRadius: Double = 500
    static let approachWarningDistance: Double = 30

    // MARK: - ginto API (Endpoint ist öffentlich, der Bearer-Token nicht)
    static let gintoAPIEndpoint = "https://api.ginto.guide/graphql"

    // MARK: - ginto Rating Profile IDs (öffentlich, identifizieren nur Profile)
    static let gintoManualWheelchairID = "Z2lkOi8vcmFpbHMtYXBwL1JhdGluZ1Byb2ZpbGVzOjpSYXRpbmdQcm9maWxlLzc4"
    static let gintoPowerWheelchairID = "Z2lkOi8vcmFpbHMtYXBwL1JhdGluZ1Byb2ZpbGVzOjpSYXRpbmdQcm9maWxlLzc5"
    static let gintoScewoBroID = "Z2lkOi8vcmFpbHMtYXBwL1JhdGluZ1Byb2ZpbGVzOjpSYXRpbmdQcm9maWxlLzM5NTE"
    static let gintoPushchairID = "Z2lkOi8vcmFpbHMtYXBwL1JhdGluZ1Byb2ZpbGVzOjpSYXRpbmdQcm9maWxlLzgw"
}