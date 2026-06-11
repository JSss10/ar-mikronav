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
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)

        monitor.pathUpdateHandler = { path in
            continuation.yield(path.status == .satisfied)
        }
        monitor.start(queue: queue)

        Task { @MainActor [weak self] in
            for await online in stream {
                self?.isOnline = online
            }
        }
    }

    deinit {
        monitor.cancel()
    }
}