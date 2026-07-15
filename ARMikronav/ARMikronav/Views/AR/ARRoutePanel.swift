// ARRoutePanel.swift
// ARMikronav
//
// Bottom-Panel während der AR-Navigation: Kartenstreifen mit Routenverlauf
// (von Anfang an auf die komplette Route gezoomt, gleiches Styling wie die
// Navigations-Karte), darunter die geteilte RouteInfoBar mit Richtungspfeil,
// Zielname, Restzeit/-distanz und Stop-Button. Ein Tipp auf den Karten-
// streifen wechselt zurück zur Kartenansicht (ersetzt den früheren
// "Zur Karte"-Button).

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

    @State private var cameraPosition: MapCameraPosition

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
        _cameraPosition = State(initialValue: Self.fittedCamera(for: route))
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

    /// Kamera so, dass die komplette Route mit Rand sichtbar ist –
    /// gleicher Zoom wie die Kartenansicht nach "Route anzeigen".
    private static func fittedCamera(for route: ActiveRoute) -> MapCameraPosition {
        var rect = MKMapRect.null
        for coordinate in route.coordinates {
            let point = MKMapPoint(coordinate)
            rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
        guard !rect.isNull else { return .userLocation(fallback: .automatic) }

        let padding = max(rect.width, rect.height) * 0.3
        return .rect(rect.insetBy(dx: -padding, dy: -padding))
    }
}