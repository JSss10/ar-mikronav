// UserProfile.swift
// ARMikronav – v2.0

import Foundation

struct UserProfile: Codable {
    let id: UUID
    var mobilityCategory: MobilityCategory
    var wheelchairType: WheelchairType
    var widthCm: Int
    var heightCm: Int
    var weightKg: Int
    var maxIncline: Double
    var maxCurbHeight: Double
    var surfaceTolerance: SurfaceTolerance
    var companionStatus: CompanionStatus
    var companionTodayOverride: Bool
    var createdAt: Date
    var updatedAt: Date
    
    var effectiveWidthNeeded: Int { widthCm + 10 }
    
    var effectiveMaxIncline: Double {
        let hasCompanion = companionTodayOverride || companionStatus == .usually
        return hasCompanion ? maxIncline + 3.0 : maxIncline
    }
    
    var effectiveMaxCurb: Double {
        let hasCompanion = companionTodayOverride || companionStatus == .usually
        return hasCompanion ? maxCurbHeight + 4.0 : maxCurbHeight
    }
}

enum MobilityCategory: String, Codable, CaseIterable {
    case none, wheelchair, visualImpairment, blind
    case hearingImpairment, deaf, walkingDisability
    case stroller, rollator, elderly
}

enum WheelchairType: String, Codable, CaseIterable {
    case manual, emotion, joystick, electric, stairClimbing
    
    var canClimbStairs: Bool { self == .stairClimbing }
    
    var defaultWidth: Int {
        switch self {
        case .manual, .emotion: return 65
        case .joystick: return 70
        case .electric, .stairClimbing: return 80
        }
    }
    
    var defaultMaxIncline: Double {
        switch self {
        case .manual: return 6.0
        case .emotion: return 9.0
        case .joystick, .electric, .stairClimbing: return 12.0
        }
    }
    
    var defaultMaxCurb: Double {
        switch self {
        case .manual: return 3.0
        case .emotion, .joystick: return 6.0
        case .electric, .stairClimbing: return 3.0
        }
    }
    
    /// ginto Rating Profile ID für diesen Rollstuhltyp
    var gintoRatingProfileID: String {
        switch self {
        case .manual, .emotion, .joystick:
            return AppConfig.gintoManualWheelchairID
        case .electric:
            return AppConfig.gintoPowerWheelchairID
        case .stairClimbing:
            return AppConfig.gintoScewoBroID
        }
    }

    /// ginto-Profil-Schlüssel in accessibility_details (manual/power/scewo)
    /// für diesen Rollstuhltyp.
    var gintoRatingProfileKey: String {
        switch self {
        case .manual, .emotion, .joystick: return "manual"
        case .electric:                    return "power"
        case .stairClimbing:               return "scewo"
        }
    }
}

enum SurfaceTolerance: String, Codable, CaseIterable {
    case smoothOnly, fineCobble, almostAll
}

enum CompanionStatus: String, Codable, CaseIterable {
    case alwaysAlone, sometimes, usually
}