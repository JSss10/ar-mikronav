// FieldTestService.swift
// ARMikronav – Steuert den Feldtest-Modus (Altstadt Zürich, 3 Testtage).
//
// Ablauf pro Testperson:
//   1. Auf dem Welcome-Screen "Feldtest starten" → Testprofil (Bild + Name)
//      auswählen. Es wird ein anonymer Supabase-User erstellt (kein
//      Registrieren nötig) und eine Zeile in `test_participants` angelegt.
//   2. Die Testperson füllt das normale Onboarding mit ihren Daten aus;
//      das Ergebnis wird zusätzlich als JSON in `test_participants.profile`
//      gespeichert (separat von den regulären App-Daten).
//   3. Während des Tests schreibt TestAnalyticsService alle Interaktionen
//      in `test_events`.
//   4. Nach dem Test: "Test beenden" (Home, oben rechts) lädt offene Events
//      hoch und setzt das Gerät für die nächste Testperson zurück.
//
// Voraussetzung in Supabase: migrations/field_test_tables.sql ausführen und
// "Allow anonymous sign-ins" aktivieren (Authentication → Sign In / Providers).

import Foundation
import Combine
import UIKit
import Supabase

/// Aktiver Testlauf einer Testperson. Wird in den UserDefaults persistiert,
/// damit ein App-Neustart den Testlauf nicht beendet.
struct FieldTestSession: Codable {
    let profileKey: String
    let firstName: String
    let lastName: String
    /// Pro Testlauf konstante ID, um Events eines Durchgangs zu gruppieren.
    let sessionId: UUID
    let startedAt: Date

    var displayName: String {
        [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

enum FieldTestError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Kein Test-User angemeldet. Bitte Testprofil erneut auswählen."
        }
    }
}

@MainActor
final class FieldTestService: ObservableObject {
    static let shared = FieldTestService()

    @Published private(set) var activeSession: FieldTestSession?

    private let client = SupabaseService.shared.client
    private static let sessionKey = "armikronav.fieldTest.session"

    private init() {
        activeSession = Self.loadPersistedSession()
    }

    /// Feldtest läuft: Feature-Flag an UND eine Testperson hat ein Profil gewählt.
    var isActive: Bool {
        AppConfig.fieldTestModeEnabled && activeSession != nil
    }

    // MARK: - Testlauf starten (Profil-Auswahl)

    /// Meldet einen anonymen Supabase-User an und startet den Testlauf für
    /// das gewählte Testprofil.
    func startTest(with profile: TestProfile) async throws {
        try await AuthService.shared.signInAnonymously()

        let session = FieldTestSession(
            profileKey: profile.key,
            firstName: profile.firstName,
            lastName: profile.lastName,
            sessionId: UUID(),
            startedAt: Date()
        )
        activeSession = session
        persist(session)

        // Teilnehmer-Zeile anlegen. Best effort: schlägt das fehl (z. B. kurz
        // offline), wird sie beim Speichern des Onboardings per Upsert
        // nachgeholt.
        try? await upsertParticipant(profile: nil)

        TestAnalyticsService.shared.track(
            "test_started",
            properties: ["test_profile": profile.key, "name": profile.displayName]
        )
    }

    // MARK: - Onboarding-Daten separat speichern

    /// Schreibt die Onboarding-Antworten der Testperson als JSON in
    /// `test_participants.profile`.
    func saveOnboardingProfile(_ profile: UserProfile) async throws {
        try await upsertParticipant(profile: profile)
    }

    private func upsertParticipant(profile: UserProfile?) async throws {
        guard let session = activeSession else { return }
        guard let userId = AuthService.shared.currentUser?.id else {
            throw FieldTestError.notAuthenticated
        }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")

        let appVersion = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        let row = ParticipantRow(
            userId: userId,
            testProfileKey: session.profileKey,
            displayName: session.displayName,
            testDay: dayFormatter.string(from: session.startedAt),
            profile: profile,
            deviceModel: "\(UIDevice.current.model) (iOS \(UIDevice.current.systemVersion))",
            appVersion: appVersion,
            updatedAt: Date()
        )

        try await client
            .from("test_participants")
            .upsert(row, onConflict: "user_id")
            .execute()
    }

    // MARK: - Umfrage nach dem Test

    /// Baut den Google-Forms-Link mit dem Testprofil als vorausgefülltem
    /// Feld (siehe AppConfig.fieldTestSurveyURL). nil, wenn keine Umfrage
    /// konfiguriert oder kein Testlauf aktiv ist.
    func surveyURL() -> URL? {
        guard let session = activeSession,
              !AppConfig.fieldTestSurveyURL.isEmpty,
              var components = URLComponents(string: AppConfig.fieldTestSurveyURL) else {
            return nil
        }

        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "usp", value: "pp_url"))
        if !AppConfig.fieldTestSurveyNameEntryID.isEmpty {
            items.append(URLQueryItem(
                name: AppConfig.fieldTestSurveyNameEntryID,
                value: session.displayName
            ))
        }
        // Optionaler stabiler Profil-Schlüssel (tp01–tp06) für die eindeutige
        // Verknüpfung mit test_events / test_participants.
        if !AppConfig.fieldTestSurveyKeyEntryID.isEmpty {
            items.append(URLQueryItem(
                name: AppConfig.fieldTestSurveyKeyEntryID,
                value: session.profileKey
            ))
        }
        components.queryItems = items
        return components.url
    }

    // MARK: - Testlauf beenden (Gerät für nächste Testperson zurücksetzen)

    /// Lädt offene Events hoch, meldet den anonymen User ab und löscht alle
    /// lokalen Zustände (Consent, Profil-Cache, Notification-Flag), damit die
    /// nächste Testperson wieder ganz vorne startet. Ist eine Umfrage
    /// konfiguriert, öffnet sich danach automatisch der Google-Forms-Link
    /// mit dem Testprofil als vorausgefülltem Feld.
    func endTest() async {
        // URL vor dem Zurücksetzen bauen – danach ist die Session weg.
        let survey = surveyURL()

        if survey != nil {
            TestAnalyticsService.shared.track("survey_opened")
        }
        TestAnalyticsService.shared.track("test_ended")
        await TestAnalyticsService.shared.flushNow()

        activeSession = nil
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)

        ProfileService.shared.deleteLocalProfile()
        ConsentStore.reset()
        NotificationPermissionStore.reset()

        try? await AuthService.shared.signOut()

        if let survey {
            await UIApplication.shared.open(survey)
        }
    }

    // MARK: - Persistenz

    private func persist(_ session: FieldTestSession) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(session) {
            UserDefaults.standard.set(data, forKey: Self.sessionKey)
        }
    }

    private static func loadPersistedSession() -> FieldTestSession? {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(FieldTestSession.self, from: data)
    }
}

/// Eine Zeile in `test_participants`.
private struct ParticipantRow: Encodable {
    let userId: UUID
    let testProfileKey: String
    let displayName: String
    let testDay: String
    let profile: UserProfile?
    let deviceModel: String?
    let appVersion: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case testProfileKey = "test_profile_key"
        case displayName = "display_name"
        case testDay = "test_day"
        case profile
        case deviceModel = "device_model"
        case appVersion = "app_version"
        case updatedAt = "updated_at"
    }
}