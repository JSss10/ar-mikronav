// RouteServiceTests.swift
// ARMikronavTests
//
// Tests für die Fortschritts-Berechnung entlang einer aktiven Route
// (RouteService.progress): Restdistanz, Restzeit und Ankunftserkennung.

import Testing
import CoreLocation
@testable import ARMikronav

struct RouteServiceTests {

    /// Gerade Route ~200 m Richtung Norden (Altstadt Zürich).
    private var straightRoute: ActiveRoute {
        let start = CLLocationCoordinate2D(latitude: 47.3700, longitude: 8.5400)
        let end = CLLocationCoordinate2D(latitude: 47.371797, longitude: 8.5400) // ~200 m nördlich
        return ActiveRoute(
            destinationName: "Test-Café",
            destinationCoordinate: end,
            coordinates: [start, end],
            totalDistanceM: 200,
            expectedTravelTimeS: 180
        )
    }

    @Test func progressAtStartIsFullDistance() {
        let route = straightRoute
        let location = CLLocation(latitude: 47.3700, longitude: 8.5400)

        let progress = RouteService.progress(of: route, at: location)

        #expect(abs(progress.remainingDistanceM - 200) < 5)
        #expect(abs(progress.remainingTimeS - 180) < 10)
        #expect(!progress.hasArrived)
    }

    @Test func progressHalfwayIsHalfDistance() {
        let route = straightRoute
        let location = CLLocation(latitude: 47.370899, longitude: 8.5400)

        let progress = RouteService.progress(of: route, at: location)

        #expect(abs(progress.remainingDistanceM - 100) < 5)
        #expect(abs(progress.remainingTimeS - 90) < 10)
        #expect(!progress.hasArrived)
    }

    @Test func progressNearDestinationDetectsArrival() {
        let route = straightRoute
        let location = CLLocation(latitude: 47.371790, longitude: 8.5400)

        let progress = RouteService.progress(of: route, at: location)

        #expect(progress.remainingDistanceM < 10)
        #expect(progress.hasArrived)
    }

    /// Abseits des Pfads: Restweg wird ab dem nächstgelegenen Punkt auf der
    /// Route gemessen, nicht ab der Luftlinie zum Ziel.
    @Test func progressOffPathSnapsToNearestSegment() {
        let route = straightRoute
        // ~20 m östlich des Streckenmittelpunkts.
        let location = CLLocation(latitude: 47.370899, longitude: 8.540265)

        let progress = RouteService.progress(of: route, at: location)

        #expect(abs(progress.remainingDistanceM - 100) < 5)
    }

    /// Korridor-Distanz: Punkte auf bzw. neben der Route liefern die
    /// senkrechte Distanz zum nächstgelegenen Segment.
    @Test func distanceToRouteMeasuresPerpendicularOffset() {
        let route = straightRoute

        let onPath = CLLocationCoordinate2D(latitude: 47.370899, longitude: 8.5400)
        #expect(RouteService.distance(from: onPath, to: route) < 2)

        // ~20 m östlich des Streckenmittelpunkts.
        let offPath = CLLocationCoordinate2D(latitude: 47.370899, longitude: 8.540265)
        let offDistance = RouteService.distance(from: offPath, to: route)
        #expect(abs(offDistance - 20) < 3)

        // ~100 m südlich des Starts: Distanz zum Startpunkt, nicht zur
        // Verlängerung des Segments.
        let behindStart = CLLocationCoordinate2D(latitude: 47.369101, longitude: 8.5400)
        let behindDistance = RouteService.distance(from: behindStart, to: route)
        #expect(abs(behindDistance - 100) < 5)
    }

    /// Route mit Knick: Restweg folgt beiden Segmenten.
    @Test func progressFollowsMultiSegmentRoute() {
        let corner = CLLocationCoordinate2D(latitude: 47.370899, longitude: 8.5400)
        let end = CLLocationCoordinate2D(latitude: 47.370899, longitude: 8.541327) // ~100 m östlich vom Knick
        let route = ActiveRoute(
            destinationName: "Test-WC",
            destinationCoordinate: end,
            coordinates: [
                CLLocationCoordinate2D(latitude: 47.3700, longitude: 8.5400),
                corner,
                end,
            ],
            totalDistanceM: 200,
            expectedTravelTimeS: 180
        )
        let start = CLLocation(latitude: 47.3700, longitude: 8.5400)

        let progress = RouteService.progress(of: route, at: start)

        #expect(abs(progress.remainingDistanceM - 200) < 8)
    }
}