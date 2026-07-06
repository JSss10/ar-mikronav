// DraftProfile.swift
// ARMikronav – Temporärer Profil-Draft während des Onboardings.
// Wird am Ende (Screen 1.6) in ein UserProfile umgewandelt und in Supabase gespeichert.

import Foundation

struct DraftProfile {
    // Profil-Setup – Screen 1.0. Vorbelegt aus Auth-user_metadata (Registrierung),
    // Pflicht bei Apple/Google Sign-in, wo kein Name miterfasst wird.
    var firstName: String = ""
    var lastName: String = ""

    var mobilityCategory: MobilityCategory?
    var wheelchairSubtype: WheelchairSubtype?

    // Masse – werden in Screen 1.3 mit Defaults aus wheelchairSubtype vorbelegt
    var widthCm: Int = 65
    var heightCm: Int = 130
    var weightKg: Int = 80

    // Fähigkeiten – werden in Screen 1.4 mit Defaults aus wheelchairSubtype vorbelegt
    var maxIncline: Double = 6.0
    var maxCurbHeight: Double = 3.0
    var surfaceTolerance: SurfaceTolerance = .fineCobble

    // Unterstützung – Screen 1.5
    var companionStatus: CompanionStatus = .alwaysAlone

    /// Gibt den internen Rollstuhltyp (5 Kategorien) für die Barrierenlogik zurück.
    var wheelchairType: WheelchairType? {
        wheelchairSubtype?.internalType
    }

    /// Übernimmt die Defaults eines Rollstuhl-Subtyps in die Masse- und Fähigkeiten-Felder.
    /// Wird aufgerufen, wenn in Screen 1.2 ein Subtyp ausgewählt wird.
    mutating func applyDefaults(for subtype: WheelchairSubtype) {
        let type = subtype.internalType
        widthCm = type.defaultWidth
        maxIncline = type.defaultMaxIncline
        maxCurbHeight = type.defaultMaxCurb
    }

    /// Validiert, ob der Draft vollständig genug ist, um ein UserProfile zu bauen.
    var isComplete: Bool {
        mobilityCategory != nil && wheelchairSubtype != nil
    }

    /// Wandelt den Draft in ein finales UserProfile um. Gibt nil zurück, wenn unvollständig.
    func buildUserProfile(userId: UUID) -> UserProfile? {
        guard let category = mobilityCategory,
              let type = wheelchairType else { return nil }

        let now = Date()
        return UserProfile(
            id: userId,
            mobilityCategory: category,
            wheelchairType: type,
            widthCm: widthCm,
            heightCm: heightCm,
            weightKg: weightKg,
            maxIncline: maxIncline,
            maxCurbHeight: maxCurbHeight,
            surfaceTolerance: surfaceTolerance,
            companionStatus: companionStatus,
            companionTodayOverride: false,
            createdAt: now,
            updatedAt: now
        )
    }
}
