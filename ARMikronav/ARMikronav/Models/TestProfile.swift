// TestProfile.swift
// ARMikronav – Vorgefertigte Profile für den Feldtest Altstadt Zürich.
//
// Testpersonen registrieren sich nicht, sondern wählen eines dieser Profile
// (Bild + Name) aus und durchlaufen danach nur noch das Onboarding mit ihren
// eigenen Angaben. Den Nachnamen tragen sie dort selbst ein.

import SwiftUI

struct TestProfile: Identifiable, Hashable {
    /// Stabiler Schlüssel, unter dem Teilnehmer- und Event-Daten in der
    /// Datenbank abgelegt werden (test_profile_key).
    let key: String
    let firstName: String
    let lastName: String
    /// Grundfarbton (0…1) des Avatars, damit jedes Profil visuell
    /// unterscheidbar ist.
    let hue: Double

    var id: String { key }

    var displayName: String {
        [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)"
    }

    var avatarTopColor: Color {
        Color(hue: hue, saturation: 0.50, brightness: 0.78)
    }

    var avatarBottomColor: Color {
        Color(hue: hue, saturation: 0.65, brightness: 0.55)
    }

    /// Die 6 Testpersonen der 3 Testtage, alphabetisch sortiert.
    /// Fehlt der Nachname, trägt ihn die Testperson im Onboarding selbst ein.
    static let all: [TestProfile] = [
        TestProfile(key: "tp01", firstName: "Alessio", lastName: "",         hue: 0.00),
        TestProfile(key: "tp02", firstName: "Annette", lastName: "Suter",    hue: 0.13),
        TestProfile(key: "tp03", firstName: "Edith",   lastName: "Schwitter", hue: 0.30),
        TestProfile(key: "tp04", firstName: "Livia",   lastName: "Künzler",  hue: 0.47),
        TestProfile(key: "tp05", firstName: "Taz",     lastName: "",         hue: 0.62),
        TestProfile(key: "tp06", firstName: "Ursula",  lastName: "Meier",    hue: 0.80)
    ]

    static func byKey(_ key: String) -> TestProfile? {
        all.first { $0.key == key }
    }
}

/// Rundes Avatar-Bild eines Testprofils: Farbverlauf + Initialen.
struct TestProfileAvatar: View {
    let profile: TestProfile
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [profile.avatarTopColor, profile.avatarBottomColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(profile.initials)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}