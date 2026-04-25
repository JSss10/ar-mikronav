// BarrierRepository.swift
// ARMikronav
//
// Lädt Barrieren aus Supabase via RPC `barriers_within_radius` (siehe migrations/barriers_within_radius.sql).
// ginto-Anbindung folgt in einem späteren Task – diese Schicht ist der einzige Aufruf-Punkt aus dem MapViewModel.

import Foundation
import CoreLocation
import Supabase

final class BarrierRepository: @unchecked Sendable {
    static let shared = BarrierRepository()

    private let client = SupabaseService.shared.client

    private struct RadiusParams: Encodable {
        let lat: Double
        let lng: Double
        let radius_meters: Double
    }

    func fetchBarriers(near coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Barrier] {
        let params = RadiusParams(
            lat: coordinate.latitude,
            lng: coordinate.longitude,
            radius_meters: radius
        )

        let barriers: [Barrier] = try await client
            .rpc("barriers_within_radius", params: params)
            .execute()
            .value

        return barriers
    }
}