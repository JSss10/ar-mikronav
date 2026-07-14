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
    @StateObject private var barrierNotifications = BarrierNotificationService.shared
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

                // Fallback-Banner nur ohne Mitteilungs-Berechtigung; sonst
                // kommt die Warnung als System-Mitteilung (UserNotifications).
                if notificationStore.settings.warningsEnabled,
                   !barrierNotifications.isAuthorized,
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
        .onReceive(barrierNotifications.$tappedBarrierId) { barrierId in
            guard let barrierId,
                  let barrier = viewModel.filteredBarriers.first(where: { $0.id == barrierId })
            else { return }
            barrierNotifications.tappedBarrierId = nil
            selectedBarrier = barrier
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
                POIARMarker(poi: item.poi)
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

// MARK: - POI-Marker im AR-Raum

/// Kreis-Badge mit Kategorie-Icon, das über einem gepunkteten Strich am
/// projizierten POI-Punkt "schwebt" (Ankerpunkt unten). Der innere Kreis
/// trägt die Zugänglichkeits-Statusfarbe, das Icon die Kategorie.
struct POIARMarker: View {
    let poi: POI

    private static let badgeSize: CGFloat = 52
    private static let stemHeight: CGFloat = 44
    private static let anchorSize: CGFloat = 7

    var body: some View {
        VStack(spacing: 2) {
            badge

            DashedVerticalLine()
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 6]))
                .foregroundStyle(.white)
                .frame(width: 2, height: Self.stemHeight)
                .shadow(color: .black.opacity(0.35), radius: 1)

            Circle()
                .fill(.white)
                .frame(width: Self.anchorSize, height: Self.anchorSize)
                .shadow(color: .black.opacity(0.35), radius: 1)
        }
        // .position() zentriert die View am projizierten Punkt; nach oben
        // verschieben, damit der Ankerpunkt (unten) auf dem Punkt liegt.
        .offset(y: -(Self.badgeSize + Self.stemHeight) / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(poi.name), \(poi.accessStatus.shortLabel), \(Int(poi.distanceM)) Meter")
        .accessibilityAddTraits(.isButton)
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: Self.badgeSize, height: Self.badgeSize)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            Circle()
                .fill(poi.accessStatus.tint)
                .frame(width: Self.badgeSize - 12, height: Self.badgeSize - 12)
            Image(systemName: poi.categorySymbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

/// Vertikale Linie für den gepunkteten Marker-Strich.
struct DashedVerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}