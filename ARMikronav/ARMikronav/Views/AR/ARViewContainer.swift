// ARViewContainer.swift
// ARMikronav
//
// SwiftUI-Wrapper für RealityKit's ARView.
// In A1 startet er nur die Session via ARSessionService – Barrieren-Visualisierung
// folgt in A2.

import SwiftUI
import ARKit
import RealityKit
import CoreLocation

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var service: ARSessionService
    let coordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )
        Task { await service.run(on: arView.session, at: coordinate) }
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    static func dismantleUIView(_ uiView: ARView, coordinator: Void) {
        uiView.session.pause()
    }
}