// Screen10_ProfileSetup.swift
// ARMikronav – Onboarding Schritt 1/7: Name fürs Profil.
// Bei E-Mail-Registrierung vorbelegt aus user_metadata; Pflichtfeld bei
// Apple/Google Sign-in. Profilbild ist im Wireframe optional und folgt
// in einer späteren Version (Foto-Upload braucht Storage-Bucket).

import SwiftUI

struct Screen10_ProfileSetup: View {
    @Binding var draft: DraftProfile

    var body: some View {
        VStack(spacing: 24) {
            // Platzhalter für optionales Profilbild (folgt später)
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
