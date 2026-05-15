// ARModeView.swift
// ARMikronav
//
// Vollbild-AR-Ansicht für den Wechsel von Karte zu AR.
// Kombiniert ARViewContainer (RealityKit) mit AROverlayView (SwiftUI-Overlay).
// Eigene ARSessionService-Instanz pro Aufruf, damit Session sauber geschlossen
// wird, sobald der User die AR-Ansicht verlässt.

import SwiftUI
import CoreLocation

struct ARModeView: View {
    let profile: UserProfile
    @ObservedObject var viewModel: MapViewModel
    let originCoordinate: CLLocationCoordinate2D?
    let onClose: () -> Void

    @StateObject private var arService = ARSessionService()

    var body: some View {
        ZStack {
            ARViewContainer(
                service: arService,
                origin: originCoordinate,
                barriers: viewModel.filteredBarriers
            )
            .ignoresSafeArea()

            AROverlayView(
                barriers: viewModel.filteredBarriers,
                userCoordinate: originCoordinate,
                onClose: onClose
            )
        }
    }
}