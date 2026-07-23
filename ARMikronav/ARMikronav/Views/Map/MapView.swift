// MapView.swift
// ARMikronav
//
// Kartenansicht (iOS 17 Map API). Startregion: aktueller Standort bzw. als
// Fallback die Altstadt Zürich; POIs und Barrieren werden für die ganze
// Stadt Zürich geladen. Zeigt Userposition, profilrelevante Barrieren,
// POI-Marker mit Zugänglichkeits-Status, Suchleiste (inkl. Kategorie-Filter)
// und ein Annäherungs-Banner. Bei aktiver Route erscheinen nur die Barrieren
// direkt auf der Route. MapViewModel kommt vom HomeView, damit Filter-
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
    @State private var showingSavedPlaces = false
    /// Listenansicht der Barrieren entlang der aktiven Route.
    @State private var showingRouteBarriers = false
    /// In der Barrieren-Liste angetippte Barriere: wird nach dem Schliessen
    /// der Liste als Detail-Sheet geöffnet (zwei Sheets nicht gleichzeitig).
    @State private var pendingListBarrier: Barrier?
    /// Auf der Karte markierter gespeicherter Ort (aus dem Bookmark-Sheet).
    @State private var selectedSavedPlace: SavedPlace?

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

            // Aus dem Bookmark-Sheet gewählter gespeicherter Ort.
            if let place = selectedSavedPlace {
                Annotation(
                    place.displayName,
                    coordinate: CLLocationCoordinate2D(
                        latitude: place.latitude,
                        longitude: place.longitude
                    )
                ) {
                    SavedPlaceMarker()
                        .onTapGesture { selectedSavedPlace = nil }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
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
                    .padding(.trailing, 68) // Platz für den Home-Button (HomeView)

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
            // Bündig mit dem Home-Button (HomeView, .padding() = 16).
            .padding(.top, 16)
            .animation(.easeInOut(duration: 0.25), value: connectivity.isOnline)
            .animation(.spring(duration: 0.35), value: proximityService.activeWarning?.barrier.id)
        }
        // Persistenter Kompass (Blickrichtung des Geräts), unterhalb des
        // Home-Buttons (HomeView, rechts oben).
        .overlay(alignment: .topTrailing) {
            CompassView(heading: locationService.heading)
                .padding(.trailing, 16)
                .padding(.top, 72)
        }
        .overlay(alignment: .bottomLeading) {
            // Während der Navigation ersetzt das Routen-Panel Filter und Chips.
            if viewModel.activeRoute == nil {
                VStack(alignment: .leading, spacing: 10) {
                    mapStyleButton
                    savedPlacesButton
                    filterButton
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
                    barrierCount: routeBarrierCount,
                    criticalCount: criticalRouteBarrierCount,
                    onShowBarriers: { showingRouteBarriers = true },
                    onStop: { viewModel.stopNavigation() }
                )
                // Volle Breite während der Navigation: Der AR-FAB ist
                // ausgeblendet, die Abbiege-Anweisung bekommt so mehr Platz.
                .padding(.horizontal)
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
            BarrierDetailSheet(
                barrier: barrier,
                profile: profile,
                onFindAlternative: alternativeAction(for: barrier)
            )
            .trackScreen("barrier_detail", properties: [
                "barrier_id": barrier.id.uuidString,
                "type": barrier.type.rawValue
            ])
        }
        // Barrieren-Liste zur aktiven Route; Zeilen-Tap merkt die Barriere
        // vor und öffnet ihr Detail-Sheet, sobald die Liste geschlossen ist.
        .sheet(isPresented: $showingRouteBarriers, onDismiss: {
            if let barrier = pendingListBarrier {
                pendingListBarrier = nil
                selectedBarrier = barrier
            }
        }) {
            RouteBarrierListSheet(
                entries: viewModel.routeBarrierEntries,
                profile: profile,
                avoidedBarrierIds: viewModel.avoidedBarrierIds
            ) { barrier in
                pendingListBarrier = barrier
                showingRouteBarriers = false
            }
            .trackScreen("route_barrier_list")
        }
        .sheet(item: $selectedPOI) { poi in
            POIDetailSheet(
                poi: poi,
                profile: profile,
                onStartARRoute: onStartARRoute,
                onShowRoute: { poi in showRoute(to: poi) }
            )
            .trackScreen("poi_detail", properties: [
                "poi_id": poi.id.uuidString,
                "name": poi.name
            ])
        }
        .sheet(isPresented: $showingFilter) {
            FilterSheet(initial: viewModel.filterState) { newFilter in
                viewModel.applyFilter(newFilter)
            }
            .trackScreen("filter")
        }
        .sheet(isPresented: $showingSearch) {
            SearchSheet(viewModel: viewModel) { poi in
                focus(on: poi)
            }
            .trackScreen("search")
        }
        .sheet(isPresented: $showingSavedPlaces) {
            NavigationStack {
                SavedPlacesListView { place in
                    showingSavedPlaces = false
                    focus(on: place)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .trackScreen("saved_places")
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
            .padding(.horizontal, 12)
            // Gleiche Höhe wie der Home-Button (HomeView).
            .frame(height: 44)
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

    /// Öffnet die gespeicherten Orte als Sheet; Auswahl zentriert die Karte.
    private var savedPlacesButton: some View {
        Button {
            showingSavedPlaces = true
        } label: {
            Image(systemName: "bookmark.circle.fill")
                .font(.title)
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Gespeicherte Orte")
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

    /// Barrieren im Korridor der aktiven Route (für die Zähler-Zeile im
    /// Routen-Panel).
    private var routeBarrierCount: Int {
        viewModel.routeBarrierEntries.count
    }

    /// Davon fürs eigene Profil kritisch (shouldWarn).
    private var criticalRouteBarrierCount: Int {
        viewModel.routeBarrierEntries
            .filter { shouldWarn(barrier: $0.barrier, profile: profile) }
            .count
    }

    /// Alternativroute-Aktion fürs Barrieren-Detail – nur während einer
    /// aktiven Navigation, sonst nil (Sektion bleibt ausgeblendet).
    private func alternativeAction(for barrier: Barrier) -> AlternativeRouteAction? {
        guard viewModel.activeRoute != nil else { return nil }
        return AlternativeRouteAction { await findAlternativeRoute(avoiding: barrier) }
    }

    /// "Alternativroute anzeigen" aus dem Barrieren-Detail: Route neu
    /// berechnen, so dass sie die Barriere umgeht (Tagesform, z. B. Hitze),
    /// und bei Erfolg auf den neuen Routenverlauf zoomen.
    @MainActor
    private func findAlternativeRoute(avoiding barrier: Barrier) async -> Bool {
        let success = await viewModel.findAlternativeRoute(avoiding: barrier, profile: profile)
        if success, let route = viewModel.activeRoute {
            fitCamera(to: route)
        }
        return success
    }

    /// Gespeicherten Ort auf der Karte markieren und ansteuern.
    private func focus(on place: SavedPlace) {
        selectedSavedPlace = place
        withAnimation(.easeInOut) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                )
            )
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

/// Marker für einen gespeicherten Ort: Bookmark-Icon im Akzentkreis.
/// Tippen entfernt die Markierung wieder.
struct SavedPlaceMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 34, height: 34)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            Circle()
                .fill(Color.accentColor)
                .frame(width: 26, height: 26)
            Image(systemName: "bookmark.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Gespeicherter Ort, Markierung entfernen")
        .accessibilityAddTraits(.isButton)
    }
}

/// Kreisförmiger POI-Marker: weisser Ring, innerer Kreis in Violett 700
/// (eine Stufe heller als das Akzent-Violett) mit dem Kategorie-Icon
/// (Restaurant, Café, WC …). Der Zugänglichkeits-Status sitzt als kleines
/// Symbol-Icon (Häkchen/Warndreieck/Kreuz) oben rechts am Ring.
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

            POIStatusIcon(status: poi.accessStatus, diameter: 15)
                .offset(x: 3, y: -3)
        }
        .accessibilityLabel("\(poi.name), \(poi.accessStatus.shortLabel)")
    }
}