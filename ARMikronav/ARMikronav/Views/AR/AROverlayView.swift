// AROverlayView.swift
// ARMikronav
//
// SwiftUI-Overlay über der ARView: runde Mini-Karte unten
// links, "Zur Karte"-Pill unten rechts.

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
            HStack(alignment: .bottom) {
                miniMap
                Spacer()
                backToMapButton
            }
        }
        .padding()
    }

    // MARK: - Components

    private var backToMapButton: some View {
        Button(action: onClose) {
            Text("Zur Karte")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
        }
        .accessibilityLabel("Zurück zur Karte")
    }

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
                .disabled(true)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.6), lineWidth: 2))
        .shadow(radius: 4)
        .accessibilityHidden(true)
    }

    private func region(around coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )
    }
}