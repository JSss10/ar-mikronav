// BarrierAnnotation.swift
// ARMikronav
//
// SwiftUI-Annotation-Inhalt je Barrierentyp – wird von MapView in MapKit `Annotation`-Items
// platziert. SF Symbols + Systemfarben gemäß Konventionen.

import SwiftUI

extension BarrierType {
    var symbolName: String {
        switch self {
        case .steps:        return "stairs"
        case .curb:         return "square.stack.3d.up"
        case .curbMissing:  return "square.stack.3d.up.slash"
        case .incline:      return "triangle"
        case .surface:      return "circle.grid.cross"
        case .narrow:       return "arrow.left.and.right"
        case .temporary:    return "exclamationmark.triangle"
        }
    }

    var tint: Color {
        switch self {
        case .steps, .curbMissing, .temporary: return .red
        case .curb, .incline:                   return .orange
        case .narrow, .surface:                 return .yellow
        }
    }

    var localizedLabel: String {
        switch self {
        case .steps:        return "Stufen"
        case .curb:         return "Bordstein"
        case .curbMissing:  return "Bordstein-Absenkung fehlt"
        case .incline:      return "Steigung"
        case .surface:      return "Oberfläche"
        case .narrow:       return "Engstelle"
        case .temporary:    return "Temporäres Hindernis"
        }
    }
}

struct BarrierAnnotation: View {
    let barrier: Barrier

    var body: some View {
        ZStack {
            Circle()
                .fill(barrier.type.tint)
                .frame(width: 32, height: 32)
                .shadow(radius: 2)
            Image(systemName: barrier.type.symbolName)
                .foregroundStyle(.white)
                .font(.system(size: 16, weight: .semibold))
        }
        .accessibilityLabel(barrier.type.localizedLabel)
    }
}