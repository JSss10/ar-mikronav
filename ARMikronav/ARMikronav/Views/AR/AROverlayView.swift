// AROverlayView.swift
// ARMikronav
//
// SwiftUI-Overlay über der ARView: Zurück-Button (links oben) und runde
// Mini-Karte (rechts oben). Wird von der finalen AR-Mode-View (Task A5) zusammen
// mit ARViewContainer in einem ZStack gerendert.

import SwiftUI
import MapKit
import CoreLocation

struct AROverlayView: View {
    let barriers: [Barrier]
    let userCoordinate: CLLocationCoordinate2D?
    let onClose: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                closeButton
                Spacer()
                miniMap
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Components

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(12)
                .background(.thinMaterial, in: Circle())
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
        .frame(width: 140, height: 140)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 2))
        .shadow(radius: 4)
    }

    private func region(around coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )
    }
}