// AppConfig.swift
// ARMikronav
//
// Öffentliche Konstanten der App – alles, was problemlos in Git stehen darf.
// Geheime Werte (Supabase-Keys, ginto-Bearer) liegen in Secrets.swift,
// das per .gitignore ausgeschlossen ist.

import Foundation
import CoreLocation

enum AppConfig {
    // MARK: - Feldtest Altstadt Zürich
    // Schaltet den Feldtest-Modus frei: Testpersonen wählen auf dem
    // Welcome-Screen ein vorgefertigtes Testprofil (statt Registrierung),
    // ihre Onboarding-Daten landen in `test_participants` und alle
    // Interaktionen in `test_events` (siehe migrations/field_test_tables.sql).
    // Nach den 3 Testtagen auf `false` stellen.
    static let fieldTestModeEnabled = true

    // MARK: - Feldtest Umfrage (Google Forms)
    // Nach "Test beenden" öffnet die App automatisch diese Umfrage in Safari,
    // mit dem Testprofil als vorausgefülltem Feld. Bleibt die URL leer, wird
    // der Schritt übersprungen.
    //
    // So kommst du an beide Werte:
    //   1. In Google Forms als erstes Feld eine Kurzantwort "Testprofil"
    //      anlegen.
    //   2. Drei-Punkte-Menü → "Link vorab ausfüllen" → im Feld Testprofil
    //      einen Platzhalter (z. B. MUSTER) eintragen → "Link abrufen".
    //   3. Der kopierte Link sieht so aus:
    //      https://docs.google.com/forms/d/e/<FORM_ID>/viewform?usp=pp_url&entry.1234567890=MUSTER
    //      → Teil bis "viewform" in `fieldTestSurveyURL`,
    //      → "entry.1234567890" in `fieldTestSurveyProfileEntryID`.
    static let fieldTestSurveyURL = ""
    static let fieldTestSurveyProfileEntryID = ""

    // MARK: - Testgebiet Altstadt Zürich
    static let testAreaMinLat = 47.369
    static let testAreaMaxLat = 47.375
    static let testAreaMinLng = 8.539
    static let testAreaMaxLng = 8.547

    // MARK: - Anzeigegebiet Kreis 1 Stadt Zürich
    // Barrieren werden immer für den ganzen Kreis 1 (Altstadt: Rathaus,
    // Hochschulen, Lindenhof, City) geladen, nicht nur um den Standort.
    // Der Radius um das Zentrum deckt die Quartiergrenzen inkl. Rand ab.
    static let kreis1Center = CLLocationCoordinate2D(latitude: 47.3710, longitude: 8.5400)
    static let kreis1RadiusM: Double = 1400

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