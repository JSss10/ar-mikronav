// SavedPlacesService.swift
// ARMikronav
//
// Speichert POIs in der Supabase-Tabelle saved_places (RLS: user-owned).
// Die geography-Spalte akzeptiert WKT-Text ('POINT(lng lat)') via PostgREST.

import Foundation
import Supabase

enum SavedPlacesError: Error {
    case notAuthenticated
}

final class SavedPlacesService: @unchecked Sendable {
    static let shared = SavedPlacesService()

    private let client = SupabaseService.shared.client

    func save(poi: POI) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw SavedPlacesError.notAuthenticated
        }

        let payload: [String: AnyJSON] = [
            "user_id": .string(userId.uuidString),
            "name": .string(poi.name),
            "location": .string("POINT(\(poi.longitude) \(poi.latitude))"),
            "place_type": .string("poi"),
            "reference_id": .string(poi.id.uuidString)
        ]

        try await client
            .from("saved_places")
            .insert(payload)
            .execute()
    }
}
