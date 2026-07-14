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

    // MARK: - Nächstes Manöver (Richtungspfeile)

    /// Route mit 90°-Knick nach Osten: vom Start aus ist das nächste
    /// Manöver "rechts abbiegen" in ~100 m.
    @Test func maneuverDetectsRightTurnAhead() {
        let route = cornerRoute
        let start = CLLocation(latitude: 47.3700, longitude: 8.5400)

        let maneuver = RouteService.nextManeuver(of: route, at: start)

        #expect(maneuver?.direction == .right)
        if let maneuver {
            #expect(abs(maneuver.distanceM - 100) < 8)
        }
    }

    /// Nach dem Knick (auf dem Ost-Segment) gibt es keinen weiteren Knick:
    /// geradeaus bis zum Ziel.
    @Test func maneuverAfterTurnIsStraight() {
        let route = cornerRoute
        // ~30 m östlich des Knicks, auf dem letzten Segment.
        let afterCorner = CLLocation(latitude: 47.370899, longitude: 8.540398)

        let maneuver = RouteService.nextManeuver(of: route, at: afterCorner)

        #expect(maneuver?.direction == .straight)
    }

    /// Gerade Route ohne Knick: durchgehend geradeaus, Distanz = Restweg.
    @Test func maneuverOnStraightRouteIsStraight() {
        let route = straightRoute
        let start = CLLocation(latitude: 47.3700, longitude: 8.5400)

        let maneuver = RouteService.nextManeuver(of: route, at: start)

        #expect(maneuver?.direction == .straight)
        if let maneuver {
            #expect(abs(maneuver.distanceM - 200) < 8)
        }
    }

    /// Spiegelbild des Ost-Knicks: Abbiegen nach Westen ist links.
    @Test func maneuverDetectsLeftTurnAhead() {
        let corner = CLLocationCoordinate2D(latitude: 47.370899, longitude: 8.5400)
        let end = CLLocationCoordinate2D(latitude: 47.370899, longitude: 8.538673) // ~130 m westlich
        let route = ActiveRoute(
            destinationName: "Test-Apotheke",
            destinationCoordinate: end,
            coordinates: [
                CLLocationCoordinate2D(latitude: 47.3700, longitude: 8.5400),
                corner,
                end,
            ],
            totalDistanceM: 230,
            expectedTravelTimeS: 200
        )
        let start = CLLocation(latitude: 47.3700, longitude: 8.5400)

        let maneuver = RouteService.nextManeuver(of: route, at: start)

        #expect(maneuver?.direction == .left)
    }

    /// Route ~100 m Norden, dann 90° nach Osten (~100 m).
    private var cornerRoute: ActiveRoute {
        let corner = CLLocationCoordinate2D(latitude: 47.370899, longitude: 8.5400)
        let end = CLLocationCoordinate2D(latitude: 47.370899, longitude: 8.541327)
        return ActiveRoute(
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
    }
}