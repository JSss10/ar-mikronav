// ARRoutePanel.swift
// ARMikronav
//
// Bottom-Panel während der AR-Navigation: Kartenstreifen mit Routenverlauf
// (eng an den aktuellen Standort gezoomt und diesem folgend, gleiches
// Styling wie die Navigations-Karte), darunter die geteilte RouteInfoBar
// mit Richtungspfeil, Zielname, Restzeit/-distanz und Stop-Button. Ein Tipp
// auf den Kartenstreifen wechselt zurück zur Kartenansicht (ersetzt den
// früheren "Zur Karte"-Button).

import SwiftUI
import MapKit
import CoreLocation

struct ARRoutePanel: View {
    let route: ActiveRoute
    let progress: RouteProgress?
    var maneuver: RouteManeuver? = nil
    let onStop: () -> Void
    /// Tipp auf den Kartenstreifen → zurück zur Kartenansicht.
    var onMapTap: (() -> Void)? = nil

    @StateObject private var locationService = LocationService.shared
    @State private var cameraPosition: MapCameraPosition

    // Enger Ausschnitt (~100 m), damit die unmittelbare Umgebung entlang
    // der Route gut erkennbar ist; die Kamera folgt dem Standort.
    private static let closeUpSpan = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)

    init(
        route: ActiveRoute,
        progress: RouteProgress?,
        maneuver: RouteManeuver? = nil,
        onStop: @escaping () -> Void,
        onMapTap: (() -> Void)? = nil
    ) {
        self.route = route
        self.progress = progress
        self.maneuver = maneuver
        self.onStop = onStop
        self.onMapTap = onMapTap
        _cameraPosition = State(initialValue: Self.closeUpCamera(for: route))
    }

    var body: some View {
        VStack(spacing: 0) {
            routeMap
                .frame(height: 130)

            RouteInfoBar(route: route, progress: progress, maneuver: maneuver, onStop: onStop)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 6)
        .padding(.horizontal, 12)
    }

    // MARK: - Karte

    private var routeMap: some View {
        Map(position: $cameraPosition) {
            MapPolyline(coordinates: route.coordinates)
                .stroke(
                    AppColor.accentPrimary,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
            UserAnnotation()
            Marker(
                route.destinationName,
                systemImage: "mappin",
                coordinate: route.destinationCoordinate
            )
            .tint(AppColor.accentPrimary)
        }
        .mapDisplayPreferences()
        .allowsHitTesting(false)
        // Kamera folgt dem aktuellen Standort im engen Ausschnitt.
        .onReceive(locationService.$currentLocation.compactMap { $0 }) { location in
            withAnimation(.easeInOut) {
                cameraPosition = .region(
                    MKCoordinateRegion(center: location.coordinate, span: Self.closeUpSpan)
                )
            }
        }
        // Tap-Fläche über der (nicht interaktiven) Karte: wechselt zur Karte.
        .overlay {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onMapTap?() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Zur Karte wechseln")
        .accessibilityAddTraits(.isButton)
    }

    /// Start-Kamera eng am Routenanfang (= Standort bei Routenberechnung);
    /// danach folgt die Kamera dem Live-Standort.
    private static func closeUpCamera(for route: ActiveRoute) -> MapCameraPosition {
        guard let start = route.coordinates.first else {
            return .userLocation(fallback: .automatic)
        }
        return .region(MKCoordinateRegion(center: start, span: closeUpSpan))
    }
}