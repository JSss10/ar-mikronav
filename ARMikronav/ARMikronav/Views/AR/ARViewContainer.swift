// ARViewContainer.swift
// ARMikronav
//
// SwiftUI-Wrapper für RealityKit's ARView. Startet die Session via
// ARSessionService. Barrieren werden bewusst NICHT im AR-Raum gerendert
// (sauberes Kamerabild, Wireframe 3.1) – sie melden sich ausschließlich über
// das Warn-Banner. Im POI-Modus (3.1b) projiziert der Coordinator die
// GPS-Positionen der POIs in den Bildschirmraum; die Karten selbst rendert
// das SwiftUI-Overlay in ARModeView.

import SwiftUI
import ARKit
import RealityKit
import CoreLocation

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var service: ARSessionService
    let origin: CLLocationCoordinate2D?
    var pois: [POI]
    let projector: ARPOIProjector

    func makeCoordinator() -> Coordinator {
        Coordinator(projector: projector)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )
        context.coordinator.arView = arView
        context.coordinator.startProjecting()
        Task { await service.run(on: arView.session, at: origin) }
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.origin = origin
        context.coordinator.pois = pois
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.stopProjecting()
        uiView.session.pause()
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator {
        weak var arView: ARView?
        var origin: CLLocationCoordinate2D?
        var pois: [POI] = []

        private let projector: ARPOIProjector
        private var projectionTask: Task<Void, Never>?

        init(projector: ARPOIProjector) {
            self.projector = projector
        }

        func startProjecting() {
            projectionTask = Task { [weak self] in
                while !Task.isCancelled {
                    self?.tick()
                    try? await Task.sleep(for: .milliseconds(120))
                }
            }
        }

        func stopProjecting() {
            projectionTask?.cancel()
            projectionTask = nil
        }

        private func tick() {
            guard let arView, let origin, !pois.isEmpty else {
                if !projector.projected.isEmpty {
                    projector.projected = []
                }
                return
            }

            let visibleBounds = arView.bounds.insetBy(dx: -80, dy: -80)
            var result: [ProjectedPOI] = []

            // Maximal 8 nächste POIs, damit das Bild nicht überladen wird.
            for poi in pois.prefix(8) {
                let coordinate = CLLocationCoordinate2D(
                    latitude: poi.latitude,
                    longitude: poi.longitude
                )
                let worldPosition = ARGeoMapper.arPosition(
                    of: coordinate,
                    relativeTo: origin,
                    height: 0
                )
                // project() liefert nil für Punkte hinter der Kamera.
                guard let screenPoint = arView.project(worldPosition) else { continue }
                guard visibleBounds.contains(screenPoint) else { continue }
                result.append(ProjectedPOI(poi: poi, point: screenPoint))
            }

            projector.projected = result
        }
    }
}
