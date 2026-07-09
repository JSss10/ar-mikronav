// DeleteAccountView.swift
// ARMikronav
//
// Wireframe 4.11 – Konto endgültig löschen mit LOESCHEN-Tipp-Bestätigung.
// Lokal werden Profil und Einstellungen sofort entfernt und der User
// abgemeldet (→ Welcome). Die Server-Löschung des Auth-Accounts erfordert
// eine Admin-Aktion und wird wie in PrivacyView per Mail angefordert.

import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var confirmationText = ""
    @State private var isDeleting = false

    private var isConfirmed: Bool {
        confirmationText.trimmingCharacters(in: .whitespaces).uppercased() == "LOESCHEN"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label {
                        Text("Konto endgültig löschen?")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "exclamationmark.square")
                            .foregroundStyle(.red)
                    }
                }

                Section("Folgende Daten werden unwiderruflich gelöscht") {
                    bullet("Dein Profil und alle Einstellungen")
                    bullet("Deine gespeicherten Orte")
                    bullet("Dein Feedback-Verlauf")
                    bullet("Dein Account bei Supabase")
                }

                Section {
                    Text("Barrieren-Daten aus OSM und ginto bleiben bestehen, da diese nicht dir gehören.")
                        .font(.footnote)
                        .italic()
                        .foregroundStyle(.secondary)
                }

                Section {
                    TextField("LOESCHEN", text: $confirmationText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                } header: {
                    Text("Schreibe \u{201E}LOESCHEN\u{201C} um zu bestätigen")
                }

                Section {
                    Button(role: .destructive) {
                        deleteAccount()
                    } label: {
                        if isDeleting {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Konto löschen")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isConfirmed || isDeleting)
                } footer: {
                    Text("Die endgültige Löschung deines Supabase-Accounts wird nach der Abmeldung serverseitig veranlasst (innerhalb von 14 Tagen).")
                }
            }
            .navigationTitle("Konto löschen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .disabled(isDeleting)
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("·").bold()
            Text(text)
        }
        .font(.subheadline)
    }

    private func deleteAccount() {
        isDeleting = true

        // Lokale Daten vollständig entfernen
        ProfileService.shared.deleteLocalProfile()
        let defaults = UserDefaults.standard
        for key in [
            "armikronav.notificationSettings",
            "armikronav.recentSearches",
            "armikronav.consentGivenAt",
            "armikronav.tutorialSeen",
            "armikronav.notificationPermissionAsked",
            "armikronav.wifiOnlyUpdates",
            "armikronav.barrierCache"
        ] {
            defaults.removeObject(forKey: key)
        }

        Task {
            try? await authService.signOut()
            isDeleting = false
            // Nach signOut routet RootView automatisch auf Welcome (0.1).
        }
    }
}
