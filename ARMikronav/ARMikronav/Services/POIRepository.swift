// POIRepository.swift
// ARMikronav
//
// Lädt POIs aus Supabase via RPC pois_within_radius
// (siehe migrations/pois_within_radius.sql). Freitext-Suche und
// Kategorie-Chips laufen über denselben search-Parameter.
//
// Params als [String: AnyJSON] statt nested Encodable-Struct – nested Typen
// erben die Default-MainActor-Isolation des Projekts und wären nicht Sendable
// (gleicher Fall wie bei BarrierRepository).

import Foundation
import CoreLocation
import Supabase

final class POIRepository: @unchecked Sendable {
    static let shared = POIRepository()

    private let client = SupabaseService.shared.client

    func fetchPOIs(
        near coordinate: CLLocationCoordinate2D,
        radius: Double,
        search: String? = nil
    ) async throws -> [POI] {
        var params: [String: AnyJSON] = [
            "lat": .double(coordinate.latitude),
            "lng": .double(coordinate.longitude),
            "radius_meters": .double(radius)
        ]
        if let search, !search.isEmpty {
            params["search"] = .string(search)
        }

        let pois: [POI] = try await client
            .rpc("pois_within_radius", params: params)
            .execute()
            .value

        return pois
    }
}
