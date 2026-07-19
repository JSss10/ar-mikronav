// TestProfile.swift
// ARMikronav – Vorgefertigte Profile für den Feldtest Altstadt Zürich.
//
// Testpersonen registrieren sich nicht, sondern wählen eines dieser Profile
// (Bild + Name) aus und durchlaufen danach nur noch das Onboarding mit ihren
// eigenen Angaben. Die Namen sind fiktiv; die Zuordnung Testperson → Profil
// notierst du dir am Testtag auf Papier.

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

    var displayName: String { "\(firstName) \(lastName)" }

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

    /// Die 12 vorbereiteten Profile für die 3 Testtage.
    static let all: [TestProfile] = [
        TestProfile(key: "tp01", firstName: "Luca",    lastName: "Brunner",  hue: 0.00),
        TestProfile(key: "tp02", firstName: "Mia",     lastName: "Keller",   hue: 0.08),
        TestProfile(key: "tp03", firstName: "Noah",    lastName: "Weber",    hue: 0.16),
        TestProfile(key: "tp04", firstName: "Emma",    lastName: "Huber",    hue: 0.30),
        TestProfile(key: "tp05", firstName: "Levin",   lastName: "Meier",    hue: 0.42),
        TestProfile(key: "tp06", firstName: "Sofia",   lastName: "Baumann",  hue: 0.50),
        TestProfile(key: "tp07", firstName: "Elias",   lastName: "Frei",     hue: 0.58),
        TestProfile(key: "tp08", firstName: "Lina",    lastName: "Steiner",  hue: 0.66),
        TestProfile(key: "tp09", firstName: "Jonas",   lastName: "Graf",     hue: 0.74),
        TestProfile(key: "tp10", firstName: "Alessia", lastName: "Moser",    hue: 0.82),
        TestProfile(key: "tp11", firstName: "David",   lastName: "Wyss",     hue: 0.90),
        TestProfile(key: "tp12", firstName: "Nora",    lastName: "Bachmann", hue: 0.96)
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
