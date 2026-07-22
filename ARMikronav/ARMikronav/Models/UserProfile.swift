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

    // Tages-Zustände + Ausstattung (Quick Wins aus der Persona-Analyse)
    var wetConditionsToday: Bool = false
    var lowEnergyToday: Bool = false
    var hasEurokey: Bool = false

    var createdAt: Date
    var updatedAt: Date

    var effectiveWidthNeeded: Int { widthCm + 10 }

    /// Reihenfolge: Companion-Boost additiv, dann Energie-Malus multiplikativ.
    var effectiveMaxIncline: Double {
        let hasCompanion = companionTodayOverride || companionStatus == .usually
        let base = hasCompanion ? maxIncline + 3.0 : maxIncline
        return lowEnergyToday ? base * 0.8 : base
    }

    var effectiveMaxCurb: Double {
        let hasCompanion = companionTodayOverride || companionStatus == .usually
        let base = hasCompanion ? maxCurbHeight + 4.0 : maxCurbHeight
        return lowEnergyToday ? base * 0.8 : base
    }

    /// Nässe verschiebt die Oberflächen-Toleranz eine Stufe Richtung "nur glatt".
    var effectiveSurfaceTolerance: SurfaceTolerance {
        guard wetConditionsToday else { return surfaceTolerance }
        switch surfaceTolerance {
        case .almostAll:  return .fineCobble
        case .fineCobble: return .smoothOnly
        case .smoothOnly: return .smoothOnly
        }
    }

    // Custom Decodable: ältere gespeicherte Profile (UserDefaults,
    // user_metadata) kennen die neuen Felder noch nicht.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        mobilityCategory = try c.decode(MobilityCategory.self, forKey: .mobilityCategory)
        wheelchairType = try c.decode(WheelchairType.self, forKey: .wheelchairType)
        widthCm = try c.decode(Int.self, forKey: .widthCm)
        heightCm = try c.decode(Int.self, forKey: .heightCm)
        weightKg = try c.decode(Int.self, forKey: .weightKg)
        maxIncline = try c.decode(Double.self, forKey: .maxIncline)
        maxCurbHeight = try c.decode(Double.self, forKey: .maxCurbHeight)
        surfaceTolerance = try c.decode(SurfaceTolerance.self, forKey: .surfaceTolerance)
        companionStatus = try c.decode(CompanionStatus.self, forKey: .companionStatus)
        companionTodayOverride = try c.decode(Bool.self, forKey: .companionTodayOverride)
        wetConditionsToday = try c.decodeIfPresent(Bool.self, forKey: .wetConditionsToday) ?? false
        lowEnergyToday = try c.decodeIfPresent(Bool.self, forKey: .lowEnergyToday) ?? false
        hasEurokey = try c.decodeIfPresent(Bool.self, forKey: .hasEurokey) ?? false
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    init(
        id: UUID,
        mobilityCategory: MobilityCategory,
        wheelchairType: WheelchairType,
        widthCm: Int,
        heightCm: Int,
        weightKg: Int,
        maxIncline: Double,
        maxCurbHeight: Double,
        surfaceTolerance: SurfaceTolerance,
        companionStatus: CompanionStatus,
        companionTodayOverride: Bool,
        wetConditionsToday: Bool = false,
        lowEnergyToday: Bool = false,
        hasEurokey: Bool = false,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.mobilityCategory = mobilityCategory
        self.wheelchairType = wheelchairType
        self.widthCm = widthCm
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.maxIncline = maxIncline
        self.maxCurbHeight = maxCurbHeight
        self.surfaceTolerance = surfaceTolerance
        self.companionStatus = companionStatus
        self.companionTodayOverride = companionTodayOverride
        self.wetConditionsToday = wetConditionsToday
        self.lowEnergyToday = lowEnergyToday
        self.hasEurokey = hasEurokey
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
}

enum SurfaceTolerance: String, Codable, CaseIterable {
    case smoothOnly, fineCobble, almostAll
}

enum CompanionStatus: String, Codable, CaseIterable {
    case alwaysAlone, sometimes, usually
}
