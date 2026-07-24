// LocationService.swift
// ARMikronav
//
// Wrapper um CLLocationManager – publiziert aktuellen Standort und Autorisierungsstatus.
// Aktualisiert nur, wenn sich die Position um mindestens `distanceFilter` Meter geändert hat,
// damit der MapViewModel nicht bei jedem GPS-Tick neu lädt.

import Foundation
import Combine
import CoreLocation
import CoreMotion

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    /// Aktuelle Blickrichtung des Geräts in Grad (0 = Norden, im Uhrzeigersinn).
    /// Bevorzugt der (bereits deklinationskorrigierte) wahre Kurs; fällt auf
    /// den magnetischen zurück. `nil`, solange noch kein Kurs vorliegt.
    /// Basiert auf `CLHeading` (Oberkante des Geräts) – für den Kompass korrekt,
    /// aber bei aufrecht gehaltenem iPhone NICHT die Kamera-Blickrichtung.
    @Published private(set) var heading: CLLocationDirection?

    /// Richtung, in die die Rückkamera des iPhones zeigt (0 = Norden, im
    /// Uhrzeigersinn) – aus der Gerätelage (CoreMotion) berechnet, damit sie
    /// auch bei AUFRECHT gehaltenem Gerät stimmt (dort steht `heading`/Kompass
    /// ~90° daneben, weil er die Oberkante misst). `nil`, solange keine
    /// verlässliche Lage vorliegt (z. B. Gerät flach nach oben/unten).
    @Published private(set) var lookDirection: CLLocationDirection?

    /// Blickrichtung für den Standort-Kegel: bevorzugt die Kamera-Blickrichtung
    /// (funktioniert aufrecht), fällt auf den Magnetkompass zurück.
    var viewingDirection: CLLocationDirection? {
        lookDirection ?? heading
    }

    private let manager: CLLocationManager
    private let motionManager = CMMotionManager()

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
        stopCameraDirectionUpdates()
    }

    /// Startet die Kompass-Updates (für Karten- und AR-Kompass) und die
    /// Kamera-Blickrichtung (für den Standort-Kegel).
    func startUpdatingHeading() {
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
        startCameraDirectionUpdates()
    }

    func stopUpdatingHeading() {
        manager.stopUpdatingHeading()
        stopCameraDirectionUpdates()
    }

    // MARK: - Kamera-Blickrichtung (CoreMotion)

    /// Liefert die Blickrichtung der Rückkamera aus der Gerätelage, echt-Nord-
    /// referenziert. Funktioniert unabhängig davon, ob das iPhone flach oder
    /// aufrecht gehalten wird.
    private func startCameraDirectionUpdates() {
        guard motionManager.isDeviceMotionAvailable,
              !motionManager.isDeviceMotionActive
        else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 20.0
        motionManager.showsDeviceMovementDisplay = true
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        motionManager.startDeviceMotionUpdates(
            using: .xTrueNorthZVertical,
            to: queue
        ) { [weak self] motion, _ in
            guard let motion,
                  let bearing = Self.cameraBearing(from: motion.attitude.rotationMatrix)
            else { return }
            Task { @MainActor in self?.lookDirection = bearing }
        }
    }

    private func stopCameraDirectionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    /// Konvention für Apples `CMAttitude.rotationMatrix`. Auf dem echten Gerät
    /// verifiziert: Die transponierte Ableitung (`false`, Referenz → Gerät,
    /// nutzt m31/m32) liefert die korrekte Kamera-Blickrichtung. Nur umstellen,
    /// falls der Kegel je gespiegelt/verdreht erscheinen sollte.
    private static let usesDeviceToReferenceMatrix = false

    /// Bearing (0 = Norden, im Uhrzeigersinn) der Kamera-Blickrichtung
    /// (Geräte-(−Z)-Achse) im Referenzrahmen `.xTrueNorthZVertical`
    /// (x = Nord, y = West, z = oben). Die (−Z)-Achse in Referenzkoordinaten ist
    /// die negierte dritte Spalte der Matrix: Nord = −m13, West = −m23 ⇒
    /// Ost = m23. Bei fast senkrecht gehaltenem Gerät (Kamera nach oben/unten)
    /// ist die horizontale Projektion zu klein/verrauscht → `nil`.
    private static func cameraBearing(from r: CMRotationMatrix) -> CLLocationDirection? {
        let north: Double
        let east: Double
        if usesDeviceToReferenceMatrix {
            north = -r.m13
            east = r.m23
        } else {
            // Transponierte Konvention (Referenz → Gerät).
            north = -r.m31
            east = r.m32
        }
        let magnitude = (north * north + east * east).squareRoot()
        guard magnitude > 0.2 else { return nil }
        var degrees = atan2(east, north) * 180 / .pi
        if degrees < 0 { degrees += 360 }
        return degrees
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