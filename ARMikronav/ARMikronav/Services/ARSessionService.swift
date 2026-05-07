// ARSessionService.swift
// ARMikronav
//
// Konfiguriert und überwacht eine ARKit-Session.
// Versucht zuerst ARGeoTracking (GPS-verankerte AR-Inhalte); fällt zurück auf
// ARWorldTracking, wenn das Gerät kein GeoTracking unterstützt oder die Position
// nicht von Apple's Geo-Map abgedeckt ist.
//
// Hinweis: Apple's GeoTracking-Coverage umfasst aktuell ausgewählte Städte in den
// USA, UK, Kanada, Australien, Japan, Singapur, Deutschland usw.
// Die Schweiz ist nicht abgedeckt – für das Testgebiet Altstadt Zürich greift
// daher praktisch immer der WorldTracking-Fallback.

import Foundation
import ARKit
import Combine
import CoreLocation

@MainActor
final class ARSessionService: NSObject, ObservableObject {
    enum SessionState: Equatable {
        case idle
        case starting
        case running(TrackingMode)
        case failed(String)
    }

    enum TrackingMode: Equatable {
        case geoTracking
        case worldTracking
    }

    @Published private(set) var sessionState: SessionState = .idle

    /// Startet die übergebene ARSession mit dem bestmöglichen Tracking-Modus.
    /// - Parameters:
    ///   - session: die Session, die der ARView gehört (siehe ARViewContainer).
    ///   - coordinate: aktueller Userstandort. Wenn vorhanden, wird GeoTracking
    ///     für genau diesen Punkt geprüft.
    func run(on session: ARSession, at coordinate: CLLocationCoordinate2D? = nil) async {
        sessionState = .starting
        session.delegate = self

        if let coordinate, ARGeoTrackingConfiguration.isSupported {
            let available = await Self.geoTrackingAvailable(at: coordinate)
            if available {
                let config = ARGeoTrackingConfiguration()
                config.planeDetection = [.horizontal]
                session.run(config)
                sessionState = .running(.geoTracking)
                return
            }
        }

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.worldAlignment = .gravityAndHeading
        session.run(config)
        sessionState = .running(.worldTracking)
    }

    func pause(_ session: ARSession) {
        session.pause()
        sessionState = .idle
    }

    private static func geoTrackingAvailable(at coordinate: CLLocationCoordinate2D) async -> Bool {
        await withCheckedContinuation { continuation in
            ARGeoTrackingConfiguration.checkAvailability(at: coordinate) { available, _ in
                continuation.resume(returning: available)
            }
        }
    }
}

// MARK: - ARSessionDelegate

extension ARSessionService: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            self.sessionState = .failed(error.localizedDescription)
        }
    }
}