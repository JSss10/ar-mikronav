// MapViewModel.swift
// ARMikronav
//
// Verbindet LocationService und BarrierRepository für die Kartenansicht.
// Barrieren werden schweizweit geladen (AppConfig.schweizCenter/-RadiusM),
// unabhängig vom Standort – ein einmaliger Ladevorgang deckt das ganze Land
// ab. POIs (ginto) werden ebenfalls schweizweit gesucht (nächste Treffer zur
// Position).

import Foundation
import Combine
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var barriers: [Barrier] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var loadError: String?
    @Published private(set) var filterState: BarrierFilterState = .default

    // POIs (Wireframe 2.1/2.1a): sichtbar wenn ein Kategorie-Chip aktiv ist
    // oder eine Suche lief.
    @Published private(set) var pois: [POI] = []
    @Published var activeCategory: String?
    @Published private(set) var recentSearches: [String] = []

    // Navigation: aktive rollstuhlgerechte Route zu einem POI plus
    // fortlaufend aktualisierter Fortschritt (Restdistanz/Restzeit).
    @Published private(set) var activeRoute: ActiveRoute?
    @Published private(set) var routeProgress: RouteProgress?
    /// Nächstes Abbiege-Manöver (Pfeil-Anweisung) auf der aktiven Route.
    @Published private(set) var nextManeuver: RouteManeuver?
    @Published private(set) var isCalculatingRoute = false
    /// Ziel-POI der aktiven Navigation (nil, wenn keine Route läuft).
    @Published private(set) var navigationTarget: POI?
    /// Barrieren, die der User für heute als "nicht machbar" markiert hat
    /// (Tagesform, z. B. Hitze) – die Route wird um sie herum berechnet.
    @Published private(set) var avoidedBarrierIds: Set<UUID> = []

    private let locationService: LocationService
    private let repository: BarrierRepository
    private let poiRepository: POIRepository
    private let recentSearchesKey = "armikronav.recentSearches"

    private var lastLoadCenter: CLLocation?
    private var cancellables = Set<AnyCancellable>()
    private var hasStarted = false

    var filteredBarriers: [Barrier] {
        barriers.filter { filterState.enabledTypes.contains($0.type) }
    }

    /// Halbe Korridor-Breite: Barrieren weiter als 30 m neben dem Routen-
    /// Polyline gelten als "nicht auf der Route" und bleiben ausgeblendet.
    private let routeCorridorM: CLLocationDistance = 30

    /// Barrieren, die auf der Karte/AR angezeigt werden:
    /// – aktive Route → nur Barrieren im Korridor entlang der Route
    /// – POIs eingeblendet (Kategorie-Chip oder Suche) → keine Barrieren
    /// – sonst → alle profilrelevanten Barrieren
    var displayedBarriers: [Barrier] {
        if let route = activeRoute {
            return filteredBarriers.filter { barrier in
                RouteService.distance(
                    from: CLLocationCoordinate2D(
                        latitude: barrier.latitude,
                        longitude: barrier.longitude
                    ),
                    to: route
                ) <= routeCorridorM
            }
        }
        if activeCategory != nil || !pois.isEmpty {
            return []
        }
        return filteredBarriers
    }

    /// Eine Barriere entlang der aktiven Route für die Listenansicht:
    /// Position auf der Route (ab Start) und Restweg ab aktuellem Standort.
    struct RouteBarrierEntry: Identifiable {
        let barrier: Barrier
        /// Weglänge vom Routen-Start bis zur Barriere.
        let distanceFromStartM: CLLocationDistance
        /// Weglänge vom aktuellen Standort bis zur Barriere
        /// (negativ = bereits passiert, nil = Standort unbekannt).
        let distanceAheadM: CLLocationDistance?

        var id: UUID { barrier.id }
    }

    /// Barrieren im Korridor der aktiven Route, sortiert in Laufrichtung –
    /// die Datenbasis der "Barrieren auf der Route"-Liste.
    var routeBarrierEntries: [RouteBarrierEntry] {
        guard let route = activeRoute else { return [] }
        let alongUser = locationService.currentLocation.map {
            RouteService.distanceAlongRoute(to: $0.coordinate, on: route)
        }
        return displayedBarriers
            .map { barrier in
                let along = RouteService.distanceAlongRoute(
                    to: CLLocationCoordinate2D(
                        latitude: barrier.latitude,
                        longitude: barrier.longitude
                    ),
                    on: route
                )
                return RouteBarrierEntry(
                    barrier: barrier,
                    distanceFromStartM: along,
                    distanceAheadM: alongUser.map { along - $0 }
                )
            }
            .sorted { $0.distanceFromStartM < $1.distanceFromStartM }
    }

    /// POIs, die auf der Karte/AR angezeigt werden: während einer aktiven
    /// Navigation nur noch das Ziel, sonst alle geladenen POIs.
    var displayedPOIs: [POI] {
        guard activeRoute != nil else { return pois }
        return navigationTarget.map { [$0] } ?? []
    }

    var searchCenter: CLLocationCoordinate2D? {
        lastLoadCenter?.coordinate ?? locationService.currentLocation?.coordinate
    }

    init() {
        self.locationService = .shared
        self.repository = .shared
        self.poiRepository = .shared
        loadRecentSearches()
    }

    init(locationService: LocationService, repository: BarrierRepository, poiRepository: POIRepository) {
        self.locationService = locationService
        self.repository = repository
        self.poiRepository = poiRepository
        loadRecentSearches()
    }

    func applyFilter(_ newFilter: BarrierFilterState) {
        // Nur die aktiven Barrierentypen sind relevant; Barrieren und POIs
        // decken beide die ganze Schweiz ab.
        filterState = newFilter
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        Task { await loadBarriers() }

        locationService.startUpdating()

        locationService.$currentLocation
            .compactMap { $0 }
            .removeDuplicates { lhs, rhs in
                lhs.distance(from: rhs) < 1
            }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        // Barrieren sind schweizweit und standortunabhängig geladen – hier nur
        // die Position für die POI-Suche merken und den Routenfortschritt
        // aktualisieren.
        lastLoadCenter = location
        if let route = activeRoute {
            routeProgress = RouteService.progress(of: route, at: location)
            nextManeuver = RouteService.nextManeuver(of: route, at: location)
        }
    }

    /// Lädt die Barrieren der ganzen Schweiz (fixes Gebiet, unabhängig vom
    /// Standort – der Radius um den Landesmittelpunkt deckt das ganze Land ab).
    func loadBarriers() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            barriers = try await repository.fetchBarriers(
                near: AppConfig.schweizCenter,
                radius: AppConfig.schweizRadiusM
            )
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - AR-Navigation

    /// Berechnet die rollstuhlgerechte Route zum POI (mit den Limits aus
    /// dem Profil) und startet die Navigation. Fällt auf die MapKit-
    /// Fussgängerroute zurück, wenn keine Rollstuhl-Route verfügbar ist.
    /// - Returns: `true`, wenn eine Route gefunden wurde.
    @discardableResult
    func startNavigation(to poi: POI, profile: UserProfile) async -> Bool {
        guard let start = locationService.currentLocation?.coordinate else {
            loadError = "Standort unbekannt – Navigation nicht möglich."
            return false
        }
        isCalculatingRoute = true
        defer { isCalculatingRoute = false }

        do {
            let route = try await RouteService.route(
                from: start,
                to: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude),
                destinationName: poi.name,
                profile: profile
            )
            activeRoute = route
            navigationTarget = poi
            routeProgress = RouteProgress(
                remainingDistanceM: route.totalDistanceM,
                remainingTimeS: route.expectedTravelTimeS
            )
            if let location = locationService.currentLocation {
                nextManeuver = RouteService.nextManeuver(of: route, at: location)
            }
            // Ziel für die "Letzte Ziele"-Liste auf dem Homescreen merken.
            RecentDestinationsStore.shared.record(
                name: poi.name,
                latitude: poi.latitude,
                longitude: poi.longitude
            )
            return true
        } catch {
            loadError = error.localizedDescription
            return false
        }
    }

    func stopNavigation() {
        activeRoute = nil
        navigationTarget = nil
        routeProgress = nil
        nextManeuver = nil
        avoidedBarrierIds = []
    }

    /// Markiert die Barriere für heute als "nicht machbar" (Tagesform,
    /// z. B. Hitze) und berechnet die Route zum aktuellen Ziel neu, so dass
    /// sie diese – und alle zuvor markierten – Barrieren umgeht. Bewusst
    /// ohne Fussgänger-Fallback: der würde die Barriere nicht umgehen.
    /// - Returns: `true`, wenn eine Alternativroute gefunden wurde.
    @discardableResult
    func findAlternativeRoute(avoiding barrier: Barrier, profile: UserProfile) async -> Bool {
        guard let route = activeRoute else { return false }
        guard let start = locationService.currentLocation?.coordinate else {
            loadError = "Standort unbekannt – Alternativroute nicht möglich."
            return false
        }

        let previouslyAvoided = avoidedBarrierIds
        avoidedBarrierIds.insert(barrier.id)
        let avoidCoordinates = barriers
            .filter { avoidedBarrierIds.contains($0.id) }
            .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

        isCalculatingRoute = true
        defer { isCalculatingRoute = false }

        do {
            let newRoute = try await RouteService.wheelchairRoute(
                from: start,
                to: route.destinationCoordinate,
                destinationName: route.destinationName,
                profile: profile,
                avoiding: avoidCoordinates
            )
            activeRoute = newRoute
            routeProgress = RouteProgress(
                remainingDistanceM: newRoute.totalDistanceM,
                remainingTimeS: newRoute.expectedTravelTimeS
            )
            if let location = locationService.currentLocation {
                nextManeuver = RouteService.nextManeuver(of: newRoute, at: location)
            }
            return true
        } catch {
            avoidedBarrierIds = previouslyAvoided
            return false
        }
    }

    /// Kategorie-Chip getippt: lädt POIs zur Kategorie, nochmaliges Tippen
    /// deaktiviert. Das deutsche Chip-Label wird auf den englischen
    /// DB-Kategorie-Suchbegriff gemappt (sonst findet die RPC nichts).
    func toggleCategory(_ category: String) {
        if activeCategory == category {
            activeCategory = nil
            pois = []
            return
        }
        activeCategory = category
        Task { await loadPOIs(search: POICategory.searchTerm(forChip: category)) }
    }

    /// Freitext-Suche aus dem SearchSheet. Ergebnis wird zurückgegeben UND als
    /// Karten-Marker übernommen.
    func searchPOIs(query: String) async -> [POI] {
        // Ohne GPS-Fix vom Landesmittelpunkt aus suchen, damit die Suche auch
        // vor dem ersten Standort-Update schweizweit Treffer liefert.
        let center = searchCenter ?? AppConfig.schweizCenter
        recordRecentSearch(query)
        do {
            let results = try await poiRepository.fetchPOIs(
                near: center,
                radius: AppConfig.schweizRadiusM,
                search: POICategory.searchTerm(forChip: query)
            )
            pois = results
            activeCategory = nil
            return results
        } catch {
            loadError = error.localizedDescription
            return []
        }
    }

    private func loadPOIs(search: String?) async {
        let center = searchCenter ?? AppConfig.schweizCenter
        do {
            pois = try await poiRepository.fetchPOIs(
                near: center,
                radius: AppConfig.schweizRadiusM,
                search: search
            )
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Letzte Suchen (max. 5, UserDefaults)

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    private func recordRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var searches = recentSearches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        searches.insert(trimmed, at: 0)
        recentSearches = Array(searches.prefix(5))
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
}