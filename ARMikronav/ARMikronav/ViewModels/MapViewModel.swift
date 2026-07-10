// MapViewModel.swift
// ARMikronav
//
// Verbindet LocationService und BarrierRepository für die Kartenansicht.
// Lädt Barrieren neu, sobald sich der Nutzerstandort um mehr als `reloadThreshold` Meter
// gegenüber dem letzten Lade-Punkt verschoben hat.

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

    // AR-Navigation: aktive Fussgänger-Route zu einem POI plus
    // fortlaufend aktualisierter Fortschritt (Restdistanz/Restzeit).
    @Published private(set) var activeRoute: ActiveRoute?
    @Published private(set) var routeProgress: RouteProgress?
    @Published private(set) var isCalculatingRoute = false

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
        let radiusChanged = newFilter.radius != filterState.radius
        filterState = newFilter

        guard radiusChanged, let center = lastLoadCenter else { return }
        Task { await loadBarriers(around: center.coordinate) }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

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
        }
        if let last = lastLoadCenter, location.distance(from: last) < reloadThreshold {
            return
        }
        lastLoadCenter = location
        Task { await loadBarriers(around: location.coordinate) }
    }

    func loadBarriers(around coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            barriers = try await repository.fetchBarriers(near: coordinate, radius: filterState.radius)
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - AR-Navigation

    /// Berechnet die Fussgänger-Route zum POI und startet die Navigation.
    /// - Returns: `true`, wenn eine Route gefunden wurde.
    @discardableResult
    func startNavigation(to poi: POI) async -> Bool {
        guard let start = locationService.currentLocation?.coordinate else {
            loadError = "Standort unbekannt – Navigation nicht möglich."
            return false
        }
        isCalculatingRoute = true
        defer { isCalculatingRoute = false }

        do {
            let route = try await RouteService.walkingRoute(
                from: start,
                to: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude),
                destinationName: poi.name
            )
            activeRoute = route
            routeProgress = RouteProgress(
                remainingDistanceM: route.totalDistanceM,
                remainingTimeS: route.expectedTravelTimeS
            )
            return true
        } catch {
            loadError = error.localizedDescription
            return false
        }
    }

    func stopNavigation() {
        activeRoute = nil
        routeProgress = nil
    }

    /// Kategorie-Chip getippt: lädt POIs zur Kategorie, nochmaliges Tippen deaktiviert.
    func toggleCategory(_ category: String) {
        if activeCategory == category {
            activeCategory = nil
            pois = []
            return
        }
        activeCategory = category
        Task { await loadPOIs(search: category) }
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
                search: query
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