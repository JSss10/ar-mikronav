// ProfilePersonalizationTests.swift
// ARMikronavTests
//
// Tests für die v2.1-Personalisierung: Wetter-Toggle (Oberflächentoleranz),
// Energie-Toggle (kraftabhängige Limits) und Eurokey (WC-Bewertung) – inkl.
// rückwärtskompatiblem Decoding älterer Profile ohne die neuen Felder.

import Testing
import Foundation
@testable import ARMikronav

struct ProfilePersonalizationTests {

    // MARK: - Fixtures

    /// Basisprofil: manueller Rollstuhl, alleine unterwegs, keine Heute-Toggles.
    private func makeProfile(
        widthCm: Int = 65,
        maneuverBufferCm: Int = 0,
        maxIncline: Double = 6,
        maxCurbHeight: Double = 3,
        surfaceTolerance: SurfaceTolerance = .almostAll,
        companionStatus: CompanionStatus = .alwaysAlone,
        companionTodayOverride: Bool = false,
        wetConditionsToday: Bool = false,
        lowEnergyToday: Bool = false,
        hasEurokey: Bool = false
    ) -> UserProfile {
        UserProfile(
            id: UUID(),
            mobilityCategory: .wheelchair,
            wheelchairType: .manual,
            widthCm: widthCm,
            heightCm: 130,
            weightKg: 75,
            maneuverBufferCm: maneuverBufferCm,
            maxIncline: maxIncline,
            maxCurbHeight: maxCurbHeight,
            surfaceTolerance: surfaceTolerance,
            companionStatus: companionStatus,
            companionTodayOverride: companionTodayOverride,
            wetConditionsToday: wetConditionsToday,
            lowEnergyToday: lowEnergyToday,
            hasEurokey: hasEurokey,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makePOI(
        name: String,
        category: String?,
        wheelchairAccessible: String?
    ) -> POI {
        POI(
            id: UUID(),
            name: name,
            category: category,
            latitude: 47.37,
            longitude: 8.54,
            address: nil,
            wheelchairAccessible: wheelchairAccessible,
            accessibilityDetails: nil,
            source: "test",
            distanceM: 10
        )
    }

    // MARK: - Energie-Toggle

    @Test func lowEnergyReducesInclineAndCurbBy20Percent() {
        let profile = makeProfile(maxIncline: 6, maxCurbHeight: 5, lowEnergyToday: true)
        #expect(profile.effectiveMaxIncline == 6 * 0.8)
        #expect(profile.effectiveMaxCurb == 5 * 0.8)
    }

    @Test func lowEnergyOffKeepsBaseLimits() {
        let profile = makeProfile(maxIncline: 6, maxCurbHeight: 5, lowEnergyToday: false)
        #expect(profile.effectiveMaxIncline == 6)
        #expect(profile.effectiveMaxCurb == 5)
    }

    @Test func companionBoostAndLowEnergyStack() {
        // Begleitung hebt an (+3 / +4), Energie senkt die angehobene Basis um 20 %.
        let profile = makeProfile(
            maxIncline: 6,
            maxCurbHeight: 3,
            companionStatus: .usually,
            lowEnergyToday: true
        )
        #expect(profile.effectiveMaxIncline == (6 + 3) * 0.8)
        #expect(profile.effectiveMaxCurb == (3 + 4) * 0.8)
    }

    // MARK: - Wende-Puffer

    @Test func maneuverBufferAddsToNeededWidth() {
        // Basis: Breite + 10 cm fester Puffer.
        #expect(makeProfile(widthCm: 65, maneuverBufferCm: 0).effectiveWidthNeeded == 75)
        // Wende-Puffer kommt obendrauf.
        #expect(makeProfile(widthCm: 65, maneuverBufferCm: 15).effectiveWidthNeeded == 90)
    }

    @Test func maneuverBufferMakesTightSpotWarn() {
        // 82 cm Engstelle: ohne Puffer passierbar (braucht 75), mit 15 cm nicht (braucht 90).
        let narrow = Barrier(
            id: UUID(), type: .narrow, subtype: nil,
            value: 82, unit: "cm", latitude: 47.37, longitude: 8.54,
            valueSource: .measured, source: "test", sourceId: nil,
            isActive: true, lastVerified: nil
        )
        #expect(shouldWarn(barrier: narrow, profile:
            makeProfile(widthCm: 65, maneuverBufferCm: 0)) == false)
        #expect(shouldWarn(barrier: narrow, profile:
            makeProfile(widthCm: 65, maneuverBufferCm: 15)) == true)
    }

    // MARK: - Wetter-Toggle

    @Test func wetConditionsTightenSurfaceToleranceOneStep() {
        #expect(makeProfile(surfaceTolerance: .almostAll, wetConditionsToday: true)
            .effectiveSurfaceTolerance == .fineCobble)
        #expect(makeProfile(surfaceTolerance: .fineCobble, wetConditionsToday: true)
            .effectiveSurfaceTolerance == .smoothOnly)
        // smoothOnly ist bereits die strengste Stufe.
        #expect(makeProfile(surfaceTolerance: .smoothOnly, wetConditionsToday: true)
            .effectiveSurfaceTolerance == .smoothOnly)
    }

    @Test func wetConditionsOffKeepsBaseTolerance() {
        #expect(makeProfile(surfaceTolerance: .almostAll, wetConditionsToday: false)
            .effectiveSurfaceTolerance == .almostAll)
    }

    @Test func wetConditionsMakeBorderlineSurfaceWarn() {
        // Grobes Pflaster: bei "almostAll" trocken toleriert, bei Nässe (→ fineCobble)
        // nicht mehr.
        let surface = Barrier(
            id: UUID(), type: .surface, subtype: "cobblestone_coarse",
            value: nil, unit: nil, latitude: 47.37, longitude: 8.54,
            valueSource: .measured, source: "test", sourceId: nil,
            isActive: true, lastVerified: nil
        )
        #expect(shouldWarn(barrier: surface, profile:
            makeProfile(surfaceTolerance: .almostAll, wetConditionsToday: false)) == false)
        #expect(shouldWarn(barrier: surface, profile:
            makeProfile(surfaceTolerance: .almostAll, wetConditionsToday: true)) == true)
    }

    // MARK: - Eurokey

    @Test func eurokeyToiletIsDetected() {
        let poi = makePOI(name: "Eurokey-Toilette", category: "public_toilets",
                          wheelchairAccessible: "yes")
        #expect(poi.isEurokeyToilet)
    }

    @Test func regularToiletIsNotEurokey() {
        let poi = makePOI(name: "ZüriWC Rathauswache", category: "public_toilets",
                          wheelchairAccessible: "yes")
        #expect(!poi.isEurokeyToilet)
    }

    @Test func eurokeyToiletNotAccessibleWithoutKey() {
        let poi = makePOI(name: "Eurokey-Toilette", category: "public_toilets",
                          wheelchairAccessible: "yes")
        // Baulich "yes", aber abgeschlossen: ohne Schlüssel nicht nutzbar.
        #expect(poi.accessStatus == .accessible)
        #expect(poi.accessStatus(for: makeProfile(hasEurokey: false)) == .notAccessible)
    }

    @Test func eurokeyToiletAccessibleWithKey() {
        let poi = makePOI(name: "Eurokey-Toilette", category: "public_toilets",
                          wheelchairAccessible: "yes")
        #expect(poi.accessStatus(for: makeProfile(hasEurokey: true)) == .accessible)
    }

    @Test func eurokeyDoesNotAffectNonToilets() {
        let poi = makePOI(name: "Café Eurokey", category: "coffee",
                          wheelchairAccessible: "yes")
        #expect(!poi.isEurokeyToilet)
        #expect(poi.accessStatus(for: makeProfile(hasEurokey: false)) == .accessible)
    }

    // MARK: - Rückwärtskompatibles Decoding

    @Test func decodingLegacyProfileDefaultsNewFieldsToFalse() throws {
        // Profil-JSON aus der Zeit vor v2.1 – ohne die drei neuen Felder.
        let legacyJSON = """
        {
          "id": "\(UUID().uuidString)",
          "mobilityCategory": "wheelchair",
          "wheelchairType": "manual",
          "widthCm": 65,
          "heightCm": 130,
          "weightKg": 75,
          "maxIncline": 6,
          "maxCurbHeight": 3,
          "surfaceTolerance": "almostAll",
          "companionStatus": "alwaysAlone",
          "companionTodayOverride": false,
          "createdAt": "2026-01-01T00:00:00Z",
          "updatedAt": "2026-01-01T00:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profile = try decoder.decode(UserProfile.self, from: Data(legacyJSON.utf8))

        #expect(profile.wetConditionsToday == false)
        #expect(profile.lowEnergyToday == false)
        #expect(profile.hasEurokey == false)
        #expect(profile.maneuverBufferCm == 0)
        #expect(profile.effectiveMaxIncline == 6)
        #expect(profile.effectiveWidthNeeded == 75)
    }

    @Test func encodeThenDecodeRoundTripsNewFields() throws {
        let profile = makeProfile(
            maneuverBufferCm: 12,
            wetConditionsToday: true, lowEnergyToday: true, hasEurokey: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(profile)
        let restored = try decoder.decode(UserProfile.self, from: data)

        #expect(restored.wetConditionsToday)
        #expect(restored.lowEnergyToday)
        #expect(restored.hasEurokey)
        #expect(restored.maneuverBufferCm == 12)
    }
}
