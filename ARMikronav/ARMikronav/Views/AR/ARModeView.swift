// ARModeView.swift
// ARMikronav
//
// Vollbild-AR-Ansicht für den Wechsel von Karte zu AR.
// Kombiniert ARViewContainer (RealityKit) mit AROverlayView (SwiftUI-Overlay)
// und einem WarningBanner, der von ProximityWarningService bei Annäherung an
// eine warnpflichtige Barriere getriggert wird (Task A3).

import SwiftUI
import CoreLocation
import AVFoundation

struct ARModeView: View {
    let profile: UserProfile
    @ObservedObject var viewModel: MapViewModel
    let originCoordinate: CLLocationCoordinate2D?
    let onClose: () -> Void

    @StateObject private var arService = ARSessionService()
    @StateObject private var warningService = ProximityWarningService()
    @StateObject private var locationService = LocationService.shared
    @StateObject private var notificationStore = NotificationSettingsStore.shared
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        Group {
            if cameraStatus == .authorized {
                arContent
            } else {
                CameraPermissionView(status: $cameraStatus)
                    .overlay(alignment: .topLeading) { dismissButton }
            }
        }
    }

    private var dismissButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.title3.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: Circle())
        }
        .padding()
        .accessibilityLabel("Zurück zur Karte")
    }

    private var arContent: some View {
        ZStack(alignment: .top) {
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

            if notificationStore.settings.warningsEnabled,
               let warning = warningService.activeWarning {
                WarningBannerView(warning: warning) {
                    warningService.dismissCurrent()
                }
                .padding(.horizontal, 16)
                .padding(.top, 80)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: warningService.activeWarning?.barrier.id)
        .onReceive(locationService.$currentLocation) { _ in
            evaluateProximity()
        }
        .onChange(of: viewModel.filteredBarriers.map(\.id)) { _, _ in
            evaluateProximity()
        }
    }

    private func evaluateProximity() {
        warningService.evaluate(
            userLocation: locationService.currentLocation,
            barriers: viewModel.filteredBarriers,
            profile: profile
        )
    }
}