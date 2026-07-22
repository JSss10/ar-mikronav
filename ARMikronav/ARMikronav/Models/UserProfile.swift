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
    /// Zusätzlicher Wende-/Rangier-Puffer in cm (Wendekreis, Länge), der zur
    /// benötigten Durchfahrtsbreite addiert wird. 0 = kein zusätzlicher Puffer.
    var maneuverBufferCm: Int = 0
    var maxIncline: Double
    var maxCurbHeight: Double
    var surfaceTolerance: SurfaceTolerance
    var companionStatus: CompanionStatus
    var companionTodayOverride: Bool

    // MARK: - Tagesform & Bedingungen (v2.1)

    /// Nasse/rutschige Bedingungen heute (Regen, Laub, Schnee). Verschärft die
    /// Oberflächentoleranz um eine Stufe – nasses Pflaster ist glatter als
    /// trockenes. Transienter Tages-Zustand, analog zu `companionTodayOverride`.
    var wetConditionsToday: Bool = false

    /// Weniger Kraft/Energie heute (langer Tag, Erschöpfung). Senkt die
    /// kraftabhängigen Limits (Steigung, Bordstein) um 20 %.
    var lowEnergyToday: Bool = false

    /// Besitzt einen Schweizer Eurokey (Euroschlüssel). Persistentes Merkmal:
    /// öffnet abgeschlossene barrierefreie WCs (Eurokey-Toiletten), die ohne
    /// Schlüssel faktisch nicht nutzbar sind.
    var hasEurokey: Bool = false

    var createdAt: Date
    var updatedAt: Date

    /// Ob effektiv eine Begleitperson dabei ist (Standardprofil oder Heute-Toggle).
    private var hasCompanion: Bool {
        companionTodayOverride || companionStatus == .usually
    }

    /// Reduktionsfaktor für kraftabhängige Limits bei „heute weniger Energie".
    private var energyFactor: Double {
        lowEnergyToday ? 0.8 : 1.0
    }

    var effectiveWidthNeeded: Int { widthCm + 10 + maneuverBufferCm }

    var effectiveMaxIncline: Double {
        let base = hasCompanion ? maxIncline + 3.0 : maxIncline
        return base * energyFactor
    }

    var effectiveMaxCurb: Double {
        let base = hasCompanion ? maxCurbHeight + 4.0 : maxCurbHeight
        return base * energyFactor
    }

    /// Oberflächentoleranz nach Tagesbedingungen: bei Nässe eine Stufe strenger.
    var effectiveSurfaceTolerance: SurfaceTolerance {
        wetConditionsToday ? surfaceTolerance.oneStepStricter : surfaceTolerance
    }
}

extension UserProfile {
    /// Explizite Schlüssel (Raw-Wert = Property-Name), damit bestehende JSON-
    /// Profile weiterhin passen und der eigene Decoder eindeutig auflöst.
    enum CodingKeys: String, CodingKey {
        case id, mobilityCategory, wheelchairType, widthCm, heightCm, weightKg
        case maneuverBufferCm, maxIncline, maxCurbHeight, surfaceTolerance
        case companionStatus, companionTodayOverride, wetConditionsToday
        case lowEnergyToday, hasEurokey, createdAt, updatedAt
    }

    /// Rückwärtskompatibles Decoding: die v2.1-Felder fehlen in Profilen, die
    /// vor dem Update in UserDefaults / user_metadata gespeichert wurden. Sie
    /// werden dann auf `false` gesetzt statt das Decoding scheitern zu lassen.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        mobilityCategory = try c.decode(MobilityCategory.self, forKey: .mobilityCategory)
        wheelchairType = try c.decode(WheelchairType.self, forKey: .wheelchairType)
        widthCm = try c.decode(Int.self, forKey: .widthCm)
        heightCm = try c.decode(Int.self, forKey: .heightCm)
        weightKg = try c.decode(Int.self, forKey: .weightKg)
        maneuverBufferCm = try c.decodeIfPresent(Int.self, forKey: .maneuverBufferCm) ?? 0
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

    /// Eine Stufe strenger – für nasse/rutschige Bedingungen. `smoothOnly` ist
    /// bereits die strengste Stufe und bleibt unverändert.
    var oneStepStricter: SurfaceTolerance {
        switch self {
        case .almostAll:  return .fineCobble
        case .fineCobble: return .smoothOnly
        case .smoothOnly: return .smoothOnly
        }
    }
}

enum CompanionStatus: String, Codable, CaseIterable {
    case alwaysAlone, sometimes, usually
}