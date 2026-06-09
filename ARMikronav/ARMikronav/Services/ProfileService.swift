// ProfileService.swift
// ARMikronav – Service zum Speichern des UserProfile.
//
// Aktueller Stand: Profil wird lokal in UserDefaults persistiert.
// TODO: Sobald der Supabase-Client (aus dem Auth-Flow) referenziert werden kann,
//       in saveProfile() einen Sync auf user_metadata ergänzen.

import Foundation
import Auth

protocol ProfileServiceProtocol: Sendable {
    var currentUserId: UUID? { get }
    func saveProfile(_ profile: UserProfile) async throws
    func loadProfile() async throws -> UserProfile?
}

final class ProfileService: ProfileServiceProtocol, @unchecked Sendable {
    /// Singleton. Thread-safe durch `@unchecked Sendable` auf der Klasse.
    static let shared = ProfileService()

    private init() {}

    /// Liefert die aktuell eingeloggte User-ID aus dem AuthService.
    var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    func saveProfile(_ profile: UserProfile) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)

        // 1. Lokal cachen (offline-first)
        UserDefaults.standard.set(data, forKey: UserDefaultsKey.userProfile)

        // 2. TODO: Sync auf Supabase user_metadata
        // try await SupabaseClient.shared.auth.update(
        //     user: UserAttributes(data: profile.asJSON())
        // )
    }

    func loadProfile() async throws -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKey.userProfile) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserProfile.self, from: data)
    }

    /// Löscht das lokal gecachte Profil aus den UserDefaults. Server-Account-
    /// Löschung erfordert Admin-Aktion (siehe PrivacyView, S3).
    func deleteLocalProfile() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.userProfile)
    }
}

enum ProfileServiceError: Error {
    case encodingFailed
    case notAuthenticated
}

private enum UserDefaultsKey {
    static let userProfile = "armikronav.userProfile"
}
