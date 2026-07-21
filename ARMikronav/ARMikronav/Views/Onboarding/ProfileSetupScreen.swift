// ProfileSetupScreen.swift
// ARMikronav – Onboarding Schritt 1/7: Name fürs Profil.
// Bei E-Mail-Registrierung vorbelegt aus user_metadata; Pflichtfeld bei
// Apple/Google Sign-in. Profilbild folgt später (Foto-Upload braucht Storage-Bucket).

import SwiftUI

struct Screen10_ProfileSetup: View {
    @Binding var draft: DraftProfile

    /// Feldtest: das Avatar-Bild des gewählten Testprofils anzeigen.
    private var testProfile: TestProfile? {
        guard let session = FieldTestService.shared.activeSession else { return nil }
        return TestProfile.byKey(session.profileKey)
    }

    var body: some View {
        VStack(spacing: 24) {
            if let testProfile {
                TestProfileAvatar(profile: testProfile, size: 120)
                    .padding(.top, 8)

                Text("Dein Testprofil: \(testProfile.displayName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                // Platzhalter für Profilbild (folgt später)
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 120, height: 120)
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                .accessibilityHidden(true)

                Text("Profilbild folgt in einer späteren Version")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Vorname")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Jessica", text: $draft.firstName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.givenName)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Nachname")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Muster", text: $draft.lastName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.familyName)
            }
        }
    }
}