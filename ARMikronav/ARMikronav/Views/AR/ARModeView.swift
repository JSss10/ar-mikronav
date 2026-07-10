// ARModeView.swift
// ARMikronav
//
// Vollbild-AR-Ansicht.
// Barrieren-Modus: sauberes Kamerabild, Barrieren melden sich NUR über das
// Warn-Banner (keine 3D-Objekte). POI-Modus: Chips oben aktivieren eine
// Kategorie; die POIs erscheinen als projizierte Karten im Kamerabild.
// Beim Start läuft ein Coaching-Overlay (Lokalisierung); nach Timeout oder
// Session-Fehler erscheint der Fehler-State mit Rückweg zur Karte.

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
    @StateObject private var projector = ARPOIProjector()

    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var localizationTimedOut = false
    @State private var selectedBarrier: Barrier?
    @State private var selectedPOI: POI?

    private static let poiChips = ["Café", "WC", "Restaurant"]

    var body: some View {
        Group {
            if cameraStatus != .authorized {
                CameraPermissionView(status: $cameraStatus)
                    .overlay(alignment: .topLeading) { dismissButton }
            } else if originCoordinate == nil {
                ARUnavailableView(
                    reason: "GPS-Signal zu schwach.\nGehe ins Freie für besseren Empfang.",
                    onBack: onClose
                )
            } else if case .failed(let message) = arService.sessionState {
                ARUnavailableView(
                    reason: message,
                    onBack: onClose
                )
            } else if localizationTimedOut {
                ARUnavailableView(
                    reason: "Die Umgebung konnte nicht lokalisiert werden.\nVersuche es an einem anderen Ort erneut.",
                    onBack: onClose
                )
            } else {
                arContent
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(20))
            if case .starting = arService.sessionState {
                localizationTimedOut = true
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

    // MARK: - AR Content

    private var arContent: some View {
        ZStack(alignment: .top) {
            ARViewContainer(
                service: arService,
                origin: originCoordinate,
                pois: viewModel.pois,
                route: viewModel.activeRoute,
                projector: projector
            )
            .ignoresSafeArea()

            // Projizierte POI-Karten
            poiCards

            // Bei aktiver Navigation ersetzt das Routen-Panel (Karte + Ziel-
            // Infos + Stop) die Standard-Overlays unten.
            if let route = viewModel.activeRoute {
                VStack(spacing: 10) {
                    Spacer()

                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Text("Zur Karte")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(.regularMaterial, in: Capsule())
                        }
                        .accessibilityLabel("Zurück zur Karte, Navigation läuft weiter")
                    }
                    .padding(.horizontal, 16)

                    ARRoutePanel(
                        route: route,
                        progress: viewModel.routeProgress,
                        onStop: { viewModel.stopNavigation() }
                    )
                    .padding(.bottom, 12)
                }
            } else {
                AROverlayView(
                    barriers: viewModel.filteredBarriers,
                    userCoordinate: originCoordinate,
                    onClose: onClose
                )
            }

            VStack(spacing: 10) {
                poiChipRow

                if notificationStore.settings.warningsEnabled,
                   let warning = warningService.activeWarning {
                    WarningBannerView(warning: warning) {
                        warningService.dismissCurrent()
                    }
                    .onTapGesture { selectedBarrier = warning.barrier }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 8)

            // Coaching-Overlay, solange die Session startet
            if case .starting = arService.sessionState {
                coachingOverlay
            }
        }
        .animation(.spring(duration: 0.35), value: warningService.activeWarning?.barrier.id)
        .animation(.spring(duration: 0.35), value: viewModel.activeRoute?.id)
        .onReceive(locationService.$currentLocation) { _ in
            evaluateProximity()
        }
        .onChange(of: viewModel.filteredBarriers.map(\.id)) { _, _ in
            evaluateProximity()
        }
        .sheet(item: $selectedBarrier) { barrier in
            BarrierDetailSheet(barrier: barrier, profile: profile)
        }
        .sheet(item: $selectedPOI) { poi in
            POIDetailSheet(poi: poi, onStartARRoute: { poi in
                Task { await viewModel.startNavigation(to: poi, profile: profile) }
            })
        }
    }

    // MARK: - POI-Modus

    private var poiChipRow: some View {
        HStack(spacing: 8) {
            ForEach(Self.poiChips, id: \.self) { chip in
                let isActive = viewModel.activeCategory == chip
                Button {
                    viewModel.toggleCategory(chip)
                } label: {
                    Text(chip)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isActive ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.regularMaterial),
                            in: Capsule()
                        )
                        .foregroundStyle(isActive ? .white : .primary)
                }
                .accessibilityLabel("\(chip) im Kamerabild anzeigen")
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var poiCards: some View {
        GeometryReader { _ in
            ForEach(projector.projected) { item in
                POIARCard(poi: item.poi)
                    .position(item.point)
                    .onTapGesture { selectedPOI = item.poi }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Coaching

    private var coachingOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text("Richte die Kamera auf Gebäude")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Bewege dein iPhone langsam")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Text("Lokalisierung…".uppercased())
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Helpers

    private func evaluateProximity() {
        warningService.evaluate(
            userLocation: locationService.currentLocation,
            barriers: viewModel.filteredBarriers,
            profile: profile
        )
    }
}

// MARK: - POI-Karte im AR-Raum

struct POIARCard: View {
    let poi: POI

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(poi.accessStatus.tint)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(poi.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(poi.accessStatus.shortLabel) · \(Int(poi.distanceM)) m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(poi.accessStatus.tint, lineWidth: 2)
        )
        .shadow(radius: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(poi.name), \(poi.accessStatus.shortLabel), \(Int(poi.distanceM)) Meter")
    }
}