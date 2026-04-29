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

    private let locationService: LocationService
    private let repository: BarrierRepository
    private let reloadThreshold: CLLocationDistance = 100

    private var lastLoadCenter: CLLocation?
    private var cancellables = Set<AnyCancellable>()

    var filteredBarriers: [Barrier] {
        barriers.filter { filterState.enabledTypes.contains($0.type) }
    }

    init() {
        self.locationService = .shared
        self.repository = .shared
    }

    init(locationService: LocationService, repository: BarrierRepository) {
        self.locationService = locationService
        self.repository = repository
    }

    func applyFilter(_ newFilter: BarrierFilterState) {
        let radiusChanged = newFilter.radius != filterState.radius
        filterState = newFilter

        guard radiusChanged, let center = lastLoadCenter else { return }
        Task { await loadBarriers(around: center.coordinate) }
    }

    func start() {
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
}