// AROverlayView.swift
// ARMikronav
//
// SwiftUI-Overlay über der ARView ohne aktive Route: Kartenstreifen unten
// im gleichen Styling wie das Routen-Panel (ARRoutePanel), nah an den
// Standort gezoomt. Ein Tipp auf die Karte wechselt zurück zur
// Kartenansicht (ersetzt den früheren "Zur Karte"-Button).

import SwiftUI
import MapKit
import CoreLocation

struct AROverlayView: View {
    let barriers: [Barrier]
    let userCoordinate: CLLocationCoordinate2D?
    let onClose: () -> Void

    var body: some View {
        VStack {
            Spacer()
            miniMap
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Components

    private var miniMap: some View {
        Group {
            if let userCoordinate {
                Map(initialPosition: .region(region(around: userCoordinate))) {
                    UserAnnotation()
                    ForEach(barriers) { barrier in
                        Marker(
                            barrier.type.localizedLabel,
                            systemImage: barrier.type.symbolName,
                            coordinate: CLLocationCoordinate2D(
                                latitude: barrier.latitude,
                                longitude: barrier.longitude
                            )
                        )
                        .tint(barrier.type.tint)
                    }
                }
                .mapDisplayPreferences()
                .allowsHitTesting(false)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(height: 130)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture { onClose() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Zur Karte wechseln")
        .accessibilityAddTraits(.isButton)
    }

    // Enger Ausschnitt (~200 m), damit die unmittelbare Umgebung und eine
    // startende Route direkt erkennbar sind.
    private func region(around coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        )
    }
}