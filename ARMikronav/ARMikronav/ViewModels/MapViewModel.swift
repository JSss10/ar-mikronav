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

    private let locationService: LocationService
    private let repository: BarrierRepository
    private let radius: Double
    private let reloadThreshold: CLLocationDistance = 100

    private var lastLoadCenter: CLLocation?
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.locationService = .shared
        self.repository = .shared
        self.radius = AppConfig.defaultBarrierRadius
    }

    init(locationService: LocationService, repository: BarrierRepository, radius: Double) {
        self.locationService = locationService
        self.repository = repository
        self.radius = radius
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
            barriers = try await repository.fetchBarriers(near: coordinate, radius: radius)
        } catch {
            loadError = error.localizedDescription
        }
    }
}