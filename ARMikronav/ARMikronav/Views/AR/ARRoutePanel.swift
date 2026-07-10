// ARRoutePanel.swift
// ARMikronav
//
// Bottom-Panel während der AR-Navigation: Kartenstreifen mit Routenverlauf
// (folgt dem Userstandort), darunter Zielname, Restzeit/-distanz und
// Stop-Button. Bei Ankunft (< 10 m Restweg) wechselt die Infozeile in den
// "Ziel erreicht"-Zustand mit Fertig-Button.

import SwiftUI
import MapKit
import CoreLocation

struct ARRoutePanel: View {
    let route: ActiveRoute
    let progress: RouteProgress?
    let onStop: () -> Void

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    private var hasArrived: Bool {
        progress?.hasArrived ?? false
    }

    var body: some View {
        VStack(spacing: 0) {
            routeMap
                .frame(height: 130)

            infoBar
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

    // MARK: - Infozeile

    private var infoBar: some View {
        HStack(spacing: 12) {
            Image(systemName: hasArrived ? "checkmark.circle.fill" : "arrow.up")
                .font(.title3.weight(.semibold))
                .foregroundStyle(hasArrived ? AppColor.Status.openIcon : AppColor.textPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(hasArrived ? "Ziel erreicht" : route.destinationName)
                    .font(.headline)
                    .lineLimit(1)
                Text(hasArrived ? route.destinationName : progressText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 8)

            Button(action: onStop) {
                Text(hasArrived ? "Fertig" : "Stop")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.onAccent)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(AppColor.accentPrimary, in: Capsule())
            }
            .accessibilityLabel(hasArrived ? "Navigation abschliessen" : "Navigation beenden")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Formatierung

    private var progressText: String {
        let distance = progress?.remainingDistanceM ?? route.totalDistanceM
        let time = progress?.remainingTimeS ?? route.expectedTravelTimeS
        return "\(minutesText(time)) · \(distanceText(distance))"
    }

    private func minutesText(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int((seconds / 60).rounded(.up)))
        return "\(minutes) min"
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(max(0, Int(meters.rounded()))) m"
    }

    private var accessibilitySummary: String {
        if hasArrived {
            return "Ziel erreicht: \(route.destinationName)"
        }
        return "Navigation zu \(route.destinationName), noch \(progressText)"
    }
}