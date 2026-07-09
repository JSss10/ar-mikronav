// SettingsView.swift
// ARMikronav
//
// Wireframe 4.1 – Account-Übersicht: Profilkopf mit Name/E-Mail/Rollstuhl,
// Schwellen-Zeile, "Heute mit Begleitperson"-Toggle und das Menü zu allen
// Unterseiten (Profildaten 4.2, Passwort 4.3, Orte 4.4, Benachrichtigungen
// 4.5, Einstellungen 4.6, Tutorial 4.7, Über 4.8, Datenschutz 4.9).

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @Binding var profile: UserProfile

    @State private var showingSignOutConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                profileHeader
                companionSection
                menuSection
                signOutSection
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .bold()
                }
            }
        }
    }

    // MARK: - Profilkopf (4.1)

    private var profileHeader: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.headline)
                    if let email = authService.currentUser?.email {
                        Text(email)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text(profile.wheelchairType.displayName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            Text(thresholdSummary.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var displayName: String {
        guard let metadata = authService.currentUser?.userMetadata else { return "Profil" }
        var parts: [String] = []
        if case .string(let first) = metadata["first_name"] { parts.append(first) }
        if case .string(let last) = metadata["last_name"] { parts.append(last) }
        return parts.isEmpty ? "Profil" : parts.joined(separator: " ")
    }

    private var thresholdSummary: String {
        "Steigung max \(Int(profile.effectiveMaxIncline))% · Bordstein max \(Int(profile.effectiveMaxCurb))cm · Breite min \(profile.effectiveWidthNeeded)cm"
    }

    // MARK: - Begleitung

    private var companionSection: some View {
        Section {
            Toggle("Heute mit Begleitperson", isOn: $profile.companionTodayOverride)
        } footer: {
            Text(profile.companionTodayOverride
                 ? "Deine Limits sind heute leicht erhöht (mehr Steigung und Bordsteinhöhe erlaubt)."
                 : "Verschiebt deine Schwellenwerte temporär, wenn dich heute jemand begleitet.")
        }
    }

    // MARK: - Menü (4.1)

    private var menuSection: some View {
        Section {
            NavigationLink {
                ProfileEditView(profile: $profile)
            } label: {
                Label("Profildaten anpassen", systemImage: "person.text.rectangle")
            }

            NavigationLink {
                ChangePasswordView()
            } label: {
                Label("Passwort ändern", systemImage: "key")
            }

            NavigationLink {
                SavedPlacesView()
            } label: {
                Label("Gespeicherte Orte", systemImage: "bookmark")
            }

            NavigationLink {
                NotificationSettingsView()
            } label: {
                Label("Benachrichtigungen", systemImage: "bell")
            }

            NavigationLink {
                AppSettingsView()
            } label: {
                Label("Einstellungen", systemImage: "gearshape")
            }

            NavigationLink {
                TutorialFromSettings()
            } label: {
                Label("Tutorial", systemImage: "questionmark.circle")
            }

            NavigationLink {
                AboutView()
            } label: {
                Label("Impressum / Über die App", systemImage: "info.circle")
            }

            NavigationLink {
                PrivacyView()
            } label: {
                Label("Datenschutz", systemImage: "lock")
            }
        }
    }

    // MARK: - Abmelden (4.1a)

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                showingSignOutConfirm = true
            } label: {
                Text("Abmelden")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .confirmationDialog(
                "Du kannst dich jederzeit wieder anmelden. Dein Profil bleibt gespeichert.",
                isPresented: $showingSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Abmelden", role: .destructive) {
                    Task { try? await authService.signOut() }
                }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }
}

/// Wireframe 4.7: Tutorial-Wiedereinstieg aus den Einstellungen –
/// "Los geht's"/"Überspringen" führen zurück zur Einstellungs-Ebene.
private struct TutorialFromSettings: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TutorialView {
            dismiss()
        }
        .navigationBarBackButtonHidden(false)
    }
}
