// LocationService.swift
// ARMikronav
//
// Wrapper um CLLocationManager – publiziert aktuellen Standort und Autorisierungsstatus.
// Aktualisiert nur, wenn sich die Position um mindestens `distanceFilter` Meter geändert hat,
// damit der MapViewModel nicht bei jedem GPS-Tick neu lädt.

import Foundation
import Combine
import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    /// Aktuelle Blickrichtung des Geräts in Grad (0 = Norden, im Uhrzeigersinn).
    /// Bevorzugt der (bereits deklinationskorrigierte) wahre Kurs; fällt auf
    /// den magnetischen zurück. `nil`, solange noch kein Kurs vorliegt.
    @Published private(set) var heading: CLLocationDirection?

    private let manager: CLLocationManager

    override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.headingFilter = 2
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            startUpdatingHeading()
        default:
            break
        }
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    /// Startet die Kompass-Updates (für Karten- und AR-Kompass).
    func startUpdatingHeading() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        manager.stopUpdatingHeading()
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
                if CLLocationManager.headingAvailable() {
                    manager.startUpdatingHeading()
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = latest
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Ungültige Kurse (negative Genauigkeit) verwerfen; sonst wahren
        // Kurs bevorzugen, magnetischen als Fallback.
        guard newHeading.headingAccuracy >= 0 else { return }
        let direction = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.heading = direction
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Stille Fehlerbehandlung – UI reagiert über fehlende currentLocation.
    }
}