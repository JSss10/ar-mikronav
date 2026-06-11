// ConnectivityMonitor.swift
// ARMikronav
//
// Beobachtet die Netzwerkverfügbarkeit über NWPathMonitor und publiziert ein
// einfaches isOnline-Flag. Wird vom OfflineOverlay konsumiert.

import Foundation
import Network
import Combine

@MainActor
final class ConnectivityMonitor: ObservableObject {
    static let shared = ConnectivityMonitor()

    @Published private(set) var isOnline: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "armikronav.connectivity", qos: .utility)

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                self?.isOnline = online
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
