// BarrierLogic.swift
// ARMikronav – v2.0 | shouldWarn() Kernlogik

import Foundation
import Combine

struct Barrier: Codable, Identifiable {
    let id: UUID
    let type: BarrierType
    let subtype: String?
    let value: Double?
    let unit: String?
    let latitude: Double
    let longitude: Double
    let valueSource: ValueSource
    let source: String
    let sourceId: String?
    let isActive: Bool
    let lastVerified: Date?
}

enum BarrierType: String, Codable {
    case steps, curb, curbMissing = "curb_missing"
    case incline, surface, narrow, temporary
}

enum ValueSource: String, Codable {
    case measured, estimated, manual
}

struct BarrierWarning: Identifiable {
    let id = UUID()
    let barrier: Barrier
    let distance: Double
    let userLimit: String
    let barrierValue: String
    let alternative: Alternative?
}

struct Alternative {
    let description: String
    let direction: Double
    let distance: Double
}

// MARK: - shouldWarn (FA-23, FA-24)

func shouldWarn(barrier: Barrier, profile: UserProfile) -> Bool {
    switch barrier.type {
    case .curbMissing:
        return true // FA-26
        
    case .steps:
        return !profile.wheelchairType.canClimbStairs // FA-25, FA-47
        
    case .curb:
        guard let height = barrier.value else { return true } // NFA-15
        return height > profile.effectiveMaxCurb
        
    case .incline:
        guard let incline = barrier.value else { return true }
        if barrier.valueSource == .estimated {
            return incline >= profile.effectiveMaxIncline
        }
        return incline > profile.effectiveMaxIncline
        
    case .surface:
        guard let subtype = barrier.subtype else { return false }
        switch profile.surfaceTolerance {
        case .smoothOnly:
            return ["cobblestone_coarse", "cobblestone_fine", "sett",
                    "gravel", "sand", "unhewn_cobblestone"].contains(subtype)
        case .fineCobble:
            return ["cobblestone_coarse", "gravel", "sand",
                    "unhewn_cobblestone"].contains(subtype)
        case .almostAll:
            return ["sand", "gravel"].contains(subtype)
        }
        
    case .narrow:
        guard let width = barrier.value else { return true }
        return width < Double(profile.effectiveWidthNeeded)
        
    case .temporary:
        return true
    }
}

// MARK: - Warnung generieren

func generateWarning(barrier: Barrier, profile: UserProfile, distance: Double, alternative: Alternative? = nil) -> BarrierWarning? {
    guard shouldWarn(barrier: barrier, profile: profile) else { return nil }
    
    let (barrierValue, userLimit): (String, String) = {
        switch barrier.type {
        case .steps:
            let count = barrier.value.map { "\(Int($0))" } ?? "?"
            return ("Stufen: \(count)", "Nicht passierbar")
        case .curb, .curbMissing:
            let h = barrier.value.map { "\(Int($0))cm" } ?? "unbekannt"
            return ("Bordstein: \(h)", "Dein Limit: \(Int(profile.effectiveMaxCurb))cm")
        case .incline:
            let v = barrier.value.map { "\(Int($0))%" } ?? "unbekannt"
            return ("Steigung: \(v)", "Dein Limit: \(Int(profile.effectiveMaxIncline))%")
        case .surface:
            let name = barrier.subtype?.replacingOccurrences(of: "_", with: " ").capitalized ?? "unbekannt"
            return ("Oberfläche: \(name)", "Nicht in deiner Toleranz")
        case .narrow:
            let w = barrier.value.map { "\(Int($0))cm" } ?? "unbekannt"
            return ("Engstelle: \(w)", "Du brauchst: \(profile.effectiveWidthNeeded)cm")
        case .temporary:
            return ("Temporäres Hindernis", "Weg blockiert")
        }
    }()
    
    return BarrierWarning(barrier: barrier, distance: distance, userLimit: userLimit, barrierValue: barrierValue, alternative: alternative)
}
