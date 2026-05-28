// ProximityWarningService.swift
// ARMikronav
//
// Überwacht Annäherung an warnpflichtige Barrieren im AR-Modus.
// Findet die nächstgelegene Barriere innerhalb `warningDistance`, die für das
// User-Profil `shouldWarn()` triggert, und publiziert ein BarrierWarning.
// Eine einmal dismissed Barriere wird unterdrückt, bis sie ausser Reichweite gerät
// und sich der User ihr erneut nähert.

import Foundation
import CoreLocation
import Combine

@MainActor
final class ProximityWarningService: ObservableObject {
    @Published private(set) var activeWarning: BarrierWarning?

    private let warningDistance: CLLocationDistance
    private var suppressedBarrierId: UUID?

    init() {
        self.warningDistance = AppConfig.approachWarningDistance
    }

    init(warningDistance: CLLocationDistance) {
        self.warningDistance = warningDistance
    }

    func evaluate(userLocation: CLLocation?, barriers: [Barrier], profile: UserProfile) {
        guard let userLocation else {
            activeWarning = nil
            return
        }

        let candidates: [(barrier: Barrier, distance: CLLocationDistance)] = barriers
            .compactMap { barrier in
                let location = CLLocation(latitude: barrier.latitude, longitude: barrier.longitude)
                let distance = userLocation.distance(from: location)
                guard distance <= warningDistance else { return nil }
                guard shouldWarn(barrier: barrier, profile: profile) else { return nil }
                return (barrier, distance)
            }

        let inRangeIds = Set(candidates.map { $0.barrier.id })
        if let id = suppressedBarrierId, !inRangeIds.contains(id) {
            suppressedBarrierId = nil
        }

        guard let nearest = candidates.min(by: { $0.distance < $1.distance }) else {
            activeWarning = nil
            return
        }

        if nearest.barrier.id == suppressedBarrierId {
            activeWarning = nil
            return
        }

        activeWarning = generateWarning(
            barrier: nearest.barrier,
            profile: profile,
            distance: nearest.distance
        )
    }

    func dismissCurrent() {
        suppressedBarrierId = activeWarning?.barrier.id
        activeWarning = nil
    }
}
