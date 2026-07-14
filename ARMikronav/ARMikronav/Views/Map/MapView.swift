// MapView.swift
// ARMikronav
//
// Kartenansicht (iOS 17 Map API). Default-Region: Altstadt Zürich.
// Zeigt Userposition, profilrelevante Barrieren, POI-Marker mit
// Zugänglichkeits-Status, Suchleiste, Kategorie-Chips und ein
// Annäherungs-Banner. MapViewModel kommt vom HomeView, damit Filter-
// und Barrieren-State mit dem AR-Modus geteilt werden.

import SwiftUI
import Combine
import MapKit
import CoreLocation

struct MapView: View {
    let profile: UserProfile
    @ObservedObject var viewModel: MapViewModel
    /// Startet die AR-Navigation zum POI (HomeView wechselt in den AR-Modus).
    var onStartARRoute: ((POI) -> Void)? = nil

    @StateObject private var locationService = LocationService.shared
    @StateObject private var connectivity = ConnectivityMonitor.shared
    @StateObject private var proximityService = ProximityWarningService()
    @StateObject private var barrierNotifications = BarrierNotificationService.shared
    @StateObject private var mapPreferences = MapPreferences.shared

    @State private var cameraPosition: MapCameraPosition = .region(MapView.defaultRegion)
    @State private var selectedBarrier: Barrier?
    @State private var selectedPOI: POI?
    @State private var showingFilter = false
    @State private var showingSearch = false

    private static let categoryChips = ["Café", "WC", "Restaurant", "Apotheke", "Haltestelle"]

    // Enger Zoom (~150 m Bildausschnitt), damit nur Barrieren in unmittelbarer
    // Nähe des aktuellen Standorts sichtbar sind.
    static let closeUpSpan = MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)

    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: (AppConfig.testAreaMinLat + AppConfig.testAreaMaxLat) / 2,
            longitude: (AppConfig.testAreaMinLng + AppConfig.testAreaMaxLng) / 2
        ),
        span: closeUpSpan
    )

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            // Aktive Navigations-Route (geteilt mit dem AR-Modus).
            if let route = viewModel.activeRoute {
                MapPolyline(coordinates: route.coordinates)
                    .stroke(
                        AppColor.accentPrimary,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )
                // Ziel-Pin nur als Fallback ohne Ziel-POI – sonst markiert der
                // POI-Marker (displayedPOIs) das Ziel.
                if viewModel.navigationTarget == nil {
                    Marker(
                        route.destinationName,
                        systemImage: "mappin",
                        coordinate: route.destinationCoordinate
                    )
                    .tint(AppColor.accentPrimary)
                }
            }

            ForEach(viewModel.displayedBarriers) { barrier in
                Annotation(
                    barrier.type.localizedLabel,
                    coordinate: CLLocationCoordinate2D(
                        latitude: barrier.latitude,
                        longitude: barrier.longitude
                    )
                ) {
                    BarrierAnnotation(barrier: barrier)
                        .onTapGesture { selectedBarrier = barrier }
                }
            }

            ForEach(viewModel.displayedPOIs) { poi in
                Annotation(
                    poi.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude: poi.latitude,
                        longitude: poi.longitude
                    )
                ) {
                    POIMarker(poi: poi)
                        .onTapGesture { selectedPOI = poi }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        // Direkt auf der Map, damit Hell-/Dunkel-Modus und Satellitenansicht
        // nur die Karte betreffen, nicht die Overlays.
        .mapDisplayPreferences(mapPreferences)
        .onAppear {
            viewModel.start()
        }
        .onReceive(locationService.$currentLocation.compactMap { $0 }.first()) { location in
            withAnimation(.easeInOut) {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: Self.closeUpSpan
                    )
                )
            }
        }
        .onReceive(locationService.$currentLocation) { _ in
            evaluateProximity()
        }
        .onReceive(barrierNotifications.$tappedBarrierId) { barrierId in
            guard let barrierId,
                  let barrier = viewModel.filteredBarriers.first(where: { $0.id == barrierId })
            else { return }
            barrierNotifications.tappedBarrierId = nil
            selectedBarrier = barrier
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                searchBar
                    .padding(.leading)
                    .padding(.trailing, 116) // Platz für Settings/Abmelden (HomeView)

                // Fallback-Banner nur ohne Mitteilungs-Berechtigung; sonst
                // kommt die Warnung als System-Mitteilung (UserNotifications).
                if !barrierNotifications.isAuthorized,
                   let warning = proximityService.activeWarning {
                    approachBanner(warning)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !connectivity.isOnline {
                    OfflineOverlay()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if viewModel.isLoading {
                    ProgressView()
                        .padding(8)
                        .background(.thinMaterial, in: Capsule())
                }
                if viewModel.isCalculatingRoute {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Route wird berechnet…")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                }
            }
            .padding(.top, 8)
            .animation(.easeInOut(duration: 0.25), value: connectivity.isOnline)
            .animation(.spring(duration: 0.35), value: proximityService.activeWarning?.barrier.id)
        }
        .overlay(alignment: .bottomLeading) {
            // Während der Navigation ersetzt das Routen-Panel Filter und Chips.
            if viewModel.activeRoute == nil {
                VStack(alignment: .leading, spacing: 10) {
                    mapStyleButton
                    filterButton
                    categoryChipRow
                }
                .padding(.leading)
                .padding(.bottom, 12)
            }
        }
        .overlay(alignment: .bottom) {
            if let route = viewModel.activeRoute {
                MapRoutePanel(
                    route: route,
                    progress: viewModel.routeProgress,
                    maneuver: viewModel.nextManeuver,
                    onStop: { viewModel.stopNavigation() }
                )
                .padding(.leading)
                .padding(.trailing, 96) // Platz für den AR-FAB (HomeView)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: viewModel.activeRoute)
        .overlay {
            if showEmptyState {
                EmptyStateView { showingFilter = true }
            }
        }
        .overlay(alignment: .bottom) {
            if let error = viewModel.loadError {
                Text(error)
                    .font(.footnote)
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
        .sheet(item: $selectedBarrier) { barrier in
            BarrierDetailSheet(barrier: barrier, profile: profile)
        }
        .sheet(item: $selectedPOI) { poi in
            POIDetailSheet(
                poi: poi,
                profile: profile,
                onStartARRoute: onStartARRoute,
                onShowRoute: { poi in showRoute(to: poi) }
            )
        }
        .sheet(isPresented: $showingFilter) {
            FilterSheet(initial: viewModel.filterState) { newFilter in
                viewModel.applyFilter(newFilter)
            }
        }
        .sheet(isPresented: $showingSearch) {
            SearchSheet(viewModel: viewModel) { poi in
                focus(on: poi)
            }
        }
    }

    // MARK: - Components

    private var searchBar: some View {
        Button {
            showingSearch = true
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Café suchen…")
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("Orte suchen")
    }

    /// Menü für Kartenansicht (Karte/Satellit) und Hell-/Dunkel-Modus.
    private var mapStyleButton: some View {
        Menu {
            Picker("Kartenansicht", selection: $mapPreferences.style) {
                ForEach(MapStyleChoice.allCases) { choice in
                    Text(choice.label).tag(choice)
                }
            }
            Picker("Kartendesign", selection: $mapPreferences.appearance) {
                ForEach(MapAppearance.allCases) { appearance in
                    Text(appearance.label).tag(appearance)
                }
            }
        } label: {
            Image(systemName: "square.3.layers.3d")
                .font(.title)
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Kartenstil wählen")
    }

    private var filterButton: some View {
        Button {
            showingFilter = true
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.title)
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Filter")
    }

    private var categoryChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Self.categoryChips, id: \.self) { chip in
                    let isActive = viewModel.activeCategory == chip
                    Button {
                        viewModel.toggleCategory(chip)
                    } label: {
                        Text(chip)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isActive ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.thinMaterial),
                                in: Capsule()
                            )
                            .foregroundStyle(isActive ? .white : .primary)
                    }
                    .accessibilityLabel("\(chip) anzeigen")
                    .accessibilityAddTraits(isActive ? .isSelected : [])
                }
            }
            .padding(.trailing, 96) // Platz für den AR-FAB (HomeView)
        }
    }

    // Banner ~30 m vor profilrelevanter Barriere.
    // Tap → Detail-Sheet, X → dismiss, auto-dismiss nach 10 s.
    private func approachBanner(_ warning: BarrierWarning) -> some View {
        Button {
            selectedBarrier = warning.barrier
            proximityService.dismissCurrent()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.square")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(warning.barrierValue) in \(Int(warning.distance)) m voraus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Tippen für Details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    proximityService.dismissCurrent()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
                .accessibilityLabel("Warnung ausblenden")
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .task(id: warning.barrier.id) {
            try? await Task.sleep(for: .seconds(10))
            proximityService.dismissCurrent()
        }
    }

    // MARK: - Helpers

    /// "Route anzeigen" aus dem POI-Detail: Route in-App berechnen und
    /// die Karte auf den gesamten Routenverlauf zoomen.
    private func showRoute(to poi: POI) {
        Task {
            guard await viewModel.startNavigation(to: poi, profile: profile),
                  let route = viewModel.activeRoute else { return }
            fitCamera(to: route)
        }
    }

    /// Zoomt die Kamera so, dass die komplette Route mit Rand sichtbar ist.
    private func fitCamera(to route: ActiveRoute) {
        var rect = MKMapRect.null
        for coordinate in route.coordinates {
            let point = MKMapPoint(coordinate)
            rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
        }
        guard !rect.isNull else { return }

        let padding = max(rect.width, rect.height) * 0.3
        withAnimation(.easeInOut) {
            cameraPosition = .rect(rect.insetBy(dx: -padding, dy: -padding))
        }
    }

    private func focus(on poi: POI) {
        withAnimation(.easeInOut) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                )
            )
        }
        selectedPOI = poi
    }

    private func evaluateProximity() {
        proximityService.evaluate(
            userLocation: locationService.currentLocation,
            barriers: viewModel.filteredBarriers,
            profile: profile
        )
    }

    private var showEmptyState: Bool {
        !viewModel.isLoading
            && viewModel.loadError == nil
            && viewModel.filteredBarriers.isEmpty
            && viewModel.pois.isEmpty
            && locationService.currentLocation != nil
    }
}

/// Kreisförmiger POI-Marker: weisser Ring, innerer Kreis in Violett 700
/// (eine Stufe heller als das Akzent-Violett) mit dem Kategorie-Icon
/// (Restaurant, Café, WC …). Der Zugänglichkeits-Status sitzt als kleiner
/// farbiger Punkt oben rechts am Ring.
struct POIMarker: View {
    let poi: POI

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 34, height: 34)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                Circle()
                    .fill(AppColor.Violet.v700)
                    .frame(width: 26, height: 26)
                Image(systemName: poi.categorySymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Circle()
                .fill(poi.accessStatus.tint)
                .frame(width: 11, height: 11)
                .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                .offset(x: 2, y: -2)
        }
        .accessibilityLabel("\(poi.name), \(poi.accessStatus.shortLabel)")
    }
}