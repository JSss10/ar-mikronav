// AppConfig.swift
// ARMikronav
//
// Öffentliche Konstanten der App – alles, was problemlos in Git stehen darf.
// Geheime Werte (Supabase-Keys, ginto-Bearer) liegen in Secrets.swift,
// das per .gitignore ausgeschlossen ist.

import Foundation
import CoreLocation

enum AppConfig {
    // MARK: - Testgebiet Altstadt Zürich
    static let testAreaMinLat = 47.369
    static let testAreaMaxLat = 47.375
    static let testAreaMinLng = 8.539
    static let testAreaMaxLng = 8.547

    // MARK: - Feldtest-Gebiet Kreis 1 Stadt Zürich
    // Bezugspunkt für den Feldtest (Altstadt: Rathaus, Hochschulen,
    // Lindenhof, City) und Wetter-Fallback ohne GPS-Fix.
    static let kreis1Center = CLLocationCoordinate2D(latitude: 47.3710, longitude: 8.5400)
    static let kreis1RadiusM: Double = 1400

    // MARK: - Abdeckung ganze Schweiz
    // Karte (Barrieren) und Homescreen laden schweizweit; der Radius um den
    // geografischen Mittelpunkt (Älggi-Alp) deckt das ganze Land ab. POIs
    // (ginto) werden ebenfalls schweizweit gesucht.
    static let schweizCenter = CLLocationCoordinate2D(latitude: 46.8011, longitude: 8.2266)
    static let schweizRadiusM: Double = 250_000

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

    // MARK: - Auth
    // Länge des E-Mail-Einmalcodes (Bestätigung + Code-Login). Muss mit der
    // OTP-Länge im Supabase-Dashboard übereinstimmen (Authentication → Emails).
    static let emailOTPCodeLength = 8

    // MARK: - Rechtliches
    // Die App verwendet Apples Standard-Lizenzvertrag für lizenzierte
    // Apps (Standard-EULA) statt eigener Nutzungsbedingungen.
    static let appleStandardEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // MARK: - Feldtest
    static let fieldTestModeEnabled = true
    static let fieldTestSurveyURL = "https://docs.google.com/forms/d/e/1FAIpQLSfqUaSbVZUignM6xjY4NhPtxaKBANLNqPMaOnp23Rj7nHWL0A/viewform"
    static let fieldTestSurveyNameEntryID = "entry.274175680"
    static let fieldTestSurveyKeyEntryID = "entry.2040937465"
}