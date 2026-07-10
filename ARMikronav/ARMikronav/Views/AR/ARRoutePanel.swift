// ARRoutePanel.swift
// ARMikronav
//
// Bottom-Panel während der AR-Navigation: Kartenstreifen mit Routenverlauf
// (folgt dem Userstandort), darunter die RouteInfoBar (Zielname,
// Restzeit/-distanz, Stop-Button – geteilt mit dem MapRoutePanel).

import SwiftUI
import MapKit
import CoreLocation

struct ARRoutePanel: View {
    let route: ActiveRoute
    let progress: RouteProgress?
    let onStop: () -> Void

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        VStack(spacing: 0) {
            routeMap
                .frame(height: 130)

            RouteInfoBar(route: route, progress: progress, onStop: onStop)
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
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}