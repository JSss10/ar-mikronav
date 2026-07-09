// RouteService.swift
// ARMikronav
//
// Berechnet Fussgänger-Routen via MapKit (MKDirections) und liefert den
// Fortschritt (Restdistanz/Restzeit) entlang einer aktiven Route.
// Die Route wird als Wegpunkt-Liste gehalten, damit Karte (MapPolyline)
// und AR-Rendering (ARRouteRenderer) dieselbe Geometrie verwenden.

import Foundation
import MapKit
import CoreLocation
import simd

/// Eine berechnete Fussgänger-Route zu einem Ziel (POI).
struct ActiveRoute: Identifiable, Equatable {
    let id: UUID
    let destinationName: String
    let destinationCoordinate: CLLocationCoordinate2D
    /// Wegpunkte aus dem MKRoute-Polyline (Start → Ziel).
    let coordinates: [CLLocationCoordinate2D]
    let totalDistanceM: CLLocationDistance
    let expectedTravelTimeS: TimeInterval

    init(
        id: UUID = UUID(),
        destinationName: String,
        destinationCoordinate: CLLocationCoordinate2D,
        coordinates: [CLLocationCoordinate2D],
        totalDistanceM: CLLocationDistance,
        expectedTravelTimeS: TimeInterval
    ) {
        self.id = id
        self.destinationName = destinationName
        self.destinationCoordinate = destinationCoordinate
        self.coordinates = coordinates
        self.totalDistanceM = totalDistanceM
        self.expectedTravelTimeS = expectedTravelTimeS
    }

    static func == (lhs: ActiveRoute, rhs: ActiveRoute) -> Bool {
        lhs.id == rhs.id
    }
}

/// Verbleibende Distanz und Zeit auf der aktiven Route.
struct RouteProgress: Equatable {
    let remainingDistanceM: CLLocationDistance
    let remainingTimeS: TimeInterval

    /// Ankunft, sobald weniger als 10 m Restweg übrig sind.
    var hasArrived: Bool { remainingDistanceM < 10 }
}

enum RouteService {
    enum RouteError: LocalizedError {
        case noRoute

        var errorDescription: String? {
            "Keine Fussgänger-Route gefunden."
        }
    }

    /// Berechnet eine Fussgänger-Route vom Start zum Ziel.
    static func walkingRoute(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        destinationName: String
    ) async throws -> ActiveRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking

        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else { throw RouteError.noRoute }

        return ActiveRoute(
            destinationName: destinationName,
            destinationCoordinate: destination,
            coordinates: route.polyline.coordinateList(),
            totalDistanceM: route.distance,
            expectedTravelTimeS: route.expectedTravelTime
        )
    }

    /// Projiziert den Standort auf das nächstgelegene Routensegment und
    /// summiert die verbleibenden Segmentlängen. Restzeit anteilig zur
    /// erwarteten Gesamtzeit.
    static func progress(of route: ActiveRoute, at location: CLLocation) -> RouteProgress {
        let coords = route.coordinates
        guard coords.count >= 2 else {
            let destination = CLLocation(
                latitude: route.destinationCoordinate.latitude,
                longitude: route.destinationCoordinate.longitude
            )
            let remaining = location.distance(from: destination)
            return RouteProgress(
                remainingDistanceM: remaining,
                remainingTimeS: remainingTime(for: remaining, on: route)
            )
        }

        // Lokales Ost/Nord-Meter-Koordinatensystem um den aktuellen Standort:
        // der Standort selbst liegt im Ursprung (0,0).
        let points = coords.map { metersEastNorth(of: $0, relativeTo: location.coordinate) }

        // suffix[i] = Weglänge von Punkt i bis zum Ziel.
        var suffix = [Double](repeating: 0, count: points.count)
        for i in stride(from: points.count - 2, through: 0, by: -1) {
            suffix[i] = suffix[i + 1] + simd_distance(points[i], points[i + 1])
        }

        var bestDistanceToPath = Double.greatestFiniteMagnitude
        var bestRemaining = suffix[0]

        for i in 0..<(points.count - 1) {
            let a = points[i]
            let b = points[i + 1]
            let ab = b - a
            let lengthSquared = simd_length_squared(ab)
            let t = lengthSquared > 0 ? min(1, max(0, simd_dot(-a, ab) / lengthSquared)) : 0
            let projected = a + t * ab
            let distanceToPath = simd_length(projected)
            if distanceToPath < bestDistanceToPath {
                bestDistanceToPath = distanceToPath
                bestRemaining = simd_distance(projected, b) + suffix[i + 1]
            }
        }

        return RouteProgress(
            remainingDistanceM: bestRemaining,
            remainingTimeS: remainingTime(for: bestRemaining, on: route)
        )
    }

    // MARK: - Helpers

    private static func remainingTime(for remainingDistance: Double, on route: ActiveRoute) -> TimeInterval {
        guard route.totalDistanceM > 0 else { return 0 }
        return route.expectedTravelTimeS * min(1, remainingDistance / route.totalDistanceM)
    }

    /// Flach-Erde-Näherung wie in ARGeoMapper: x = Ost-Meter, y = Nord-Meter.
    private static func metersEastNorth(
        of target: CLLocationCoordinate2D,
        relativeTo origin: CLLocationCoordinate2D
    ) -> SIMD2<Double> {
        let metersPerDegreeLatitude = 111_320.0
        let metersPerDegreeLongitude = metersPerDegreeLatitude * cos(origin.latitude * .pi / 180)
        return SIMD2(
            (target.longitude - origin.longitude) * metersPerDegreeLongitude,
            (target.latitude - origin.latitude) * metersPerDegreeLatitude
        )
    }
}

extension MKPolyline {
    /// Alle Koordinaten des Polylines als Array.
    func coordinateList() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: pointCount
        )
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
