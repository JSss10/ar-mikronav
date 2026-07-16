// MapViewModel.swift
// ARMikronav
//
// Verbindet LocationService und BarrierRepository für die Kartenansicht.
// Barrieren werden immer für das ganze Anzeigegebiet Kreis 1 Stadt Zürich
// geladen (AppConfig.kreis1Center/-RadiusM) und bei Bewegung des Users um
// mehr als `reloadThreshold` Meter aufgefrischt.

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

    private let locationService: LocationService
    private let repository: BarrierRepository
    private let poiRepository: POIRepository
    private let reloadThreshold: CLLocationDistance = 100
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
        // Der Radius wirkt nur noch auf die POI-Suche; Barrieren kommen
        // immer für den ganzen Kreis 1.
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
        if let route = activeRoute {
            routeProgress = RouteService.progress(of: route, at: location)
            nextManeuver = RouteService.nextManeuver(of: route, at: location)
        }
        if let last = lastLoadCenter, location.distance(from: last) < reloadThreshold {
            return
        }
        lastLoadCenter = location
        Task { await loadBarriers() }
    }

    /// Lädt alle Barrieren des Kreis 1 (fixes Gebiet, unabhängig vom
    /// Standort). Der Aufruf bei Bewegung dient nur der Datenauffrischung.
    func loadBarriers() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            barriers = try await repository.fetchBarriers(
                near: AppConfig.kreis1Center,
                radius: AppConfig.kreis1RadiusM
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
        guard let center = searchCenter else { return [] }
        recordRecentSearch(query)
        do {
            let results = try await poiRepository.fetchPOIs(
                near: center,
                radius: filterState.radius,
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
        guard let center = searchCenter else { return }
        do {
            pois = try await poiRepository.fetchPOIs(
                near: center,
                radius: filterState.radius,
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