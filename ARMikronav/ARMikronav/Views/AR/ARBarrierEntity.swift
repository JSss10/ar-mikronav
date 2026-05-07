// ARBarrierEntity.swift
// ARMikronav
//
// Factory für die RealityKit-Entities, die Barrieren im AR-Raum darstellen.
// MVP: Eingefärbte Kugel pro Typ – Kugeln sind aus jeder Blickrichtung gleich,
// also kein Billboard-Constraint nötig. Sphärische Form erleichtert Wiedererkennung
// und stört Identifikation auf Distanz nicht.

import Foundation
import RealityKit
import UIKit
import SwiftUI

enum ARBarrierEntity {
    private static let radius: Float = 0.4
    private static let displayHeight: Float = 1.0

    /// Erzeugt einen AnchorEntity an der gegebenen Welt-Position mit einer eingefärbten Kugel.
    static func makeAnchor(for barrier: Barrier, position: SIMD3<Float>) -> AnchorEntity {
        var elevatedPosition = position
        elevatedPosition.y = displayHeight

        let anchor = AnchorEntity(world: elevatedPosition)
        anchor.name = "barrier-\(barrier.id.uuidString)"

        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(
            color: UIColor(barrier.type.tint),
            roughness: 0.3,
            isMetallic: false
        )
        let model = ModelEntity(mesh: mesh, materials: [material])
        anchor.addChild(model)

        return anchor
    }
}