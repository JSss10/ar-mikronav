// ARViewContainer.swift
// ARMikronav
//
// SwiftUI-Wrapper für RealityKit's ARView. Startet die Session via
// ARSessionService und platziert eine Kugel pro Barriere im Welt-Koordinatensystem.
// Geo-zu-AR-Konvertierung läuft über ARGeoMapper (siehe Services/).
// Bei Änderungen an der Barrieren-Liste werden die Anchors neu aufgebaut.

import SwiftUI
import ARKit
import RealityKit
import CoreLocation

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var service: ARSessionService
    let origin: CLLocationCoordinate2D?
    let barriers: [Barrier]

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )
        Task { await service.run(on: arView.session, at: origin) }
        rebuildBarrierAnchors(in: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        rebuildBarrierAnchors(in: uiView)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Void) {
        uiView.session.pause()
    }

    // MARK: - Anchors

    private func rebuildBarrierAnchors(in arView: ARView) {
        guard let origin else { return }

        let existing = arView.scene.anchors
            .compactMap { $0 as? AnchorEntity }
            .filter { $0.name.hasPrefix("barrier-") }
        for anchor in existing {
            arView.scene.removeAnchor(anchor)
        }

        for barrier in barriers {
            let coordinate = CLLocationCoordinate2D(
                latitude: barrier.latitude,
                longitude: barrier.longitude
            )
            let position = ARGeoMapper.arPosition(of: coordinate, relativeTo: origin)
            let anchor = ARBarrierEntity.makeAnchor(for: barrier, position: position)
            arView.scene.addAnchor(anchor)
        }
    }
}