// SavedPlacesService.swift
// ARMikronav
//
// CRUD für die Supabase-Tabelle saved_places (RLS: user-owned).
// Die geography-Spalte akzeptiert WKT-Text ('POINT(lng lat)') via PostgREST.
// Die Liste (4.4) kommt ohne Koordinaten aus – dekodiert werden nur die
// Anzeige-Felder.

import Foundation
import CoreLocation
import Supabase

enum SavedPlacesError: Error {
    case notAuthenticated
}

struct SavedPlace: Decodable, Identifiable {
    let id: UUID
    let name: String?
    let placeType: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case placeType = "place_type"
        case createdAt = "created_at"
    }
}

final class SavedPlacesService: @unchecked Sendable {
    static let shared = SavedPlacesService()

    private let client = SupabaseService.shared.client

    func save(poi: POI) async throws {
        try await insert(
            name: poi.name,
            coordinate: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude),
            placeType: "poi",
            referenceId: poi.id
        )
    }

    /// Eigener Ort über den Karten-Pin (Wireframe 4.4a).
    func saveCustomPlace(name: String, coordinate: CLLocationCoordinate2D) async throws {
        try await insert(name: name, coordinate: coordinate, placeType: "custom", referenceId: nil)
    }

    func list() async throws -> [SavedPlace] {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw SavedPlacesError.notAuthenticated
        }
        return try await client
            .from("saved_places")
            .select("id, name, place_type, created_at")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func delete(id: UUID) async throws {
        try await client
            .from("saved_places")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Insert

    private func insert(
        name: String,
        coordinate: CLLocationCoordinate2D,
        placeType: String,
        referenceId: UUID?
    ) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw SavedPlacesError.notAuthenticated
        }

        var payload: [String: AnyJSON] = [
            "user_id": .string(userId.uuidString),
            "name": .string(name),
            "location": .string("POINT(\(coordinate.longitude) \(coordinate.latitude))"),
            "place_type": .string(placeType)
        ]
        if let referenceId {
            payload["reference_id"] = .string(referenceId.uuidString)
        }

        try await client
            .from("saved_places")
            .insert(payload)
            .execute()
    }
}
