// SettingsView.swift
// ARMikronav
//
// Einstellungs-Hauptseite. Zeigt Profil-Übersicht und den "Heute mit Begleitung"-
// Toggle, der direkt auf das gebundene UserProfile schreibt. Weitere Settings
// (Benachrichtigungen, Datenschutz, Konto) folgen in S2/S3.

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: UserProfile

    // Daten-Präferenzen. Der WLAN-Toggle wird vom künftigen
    // Offline-Caching ausgewertet; der Cache-Key ist dort definiert.
    @AppStorage("armikronav.wifiOnlyUpdates") private var wifiOnlyUpdates = false
    @State private var showingCacheDeleteConfirm = false

    // Geteilte Karten-Präferenzen (auch über das Ebenen-Menü auf der
    // Karte änderbar).
    @StateObject private var mapPreferences = MapPreferences.shared

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                companionSection
                editSection
                notificationsSection
                mapSection
                generalSection
                privacyAndAboutSection
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .trackScreen("settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .bold()
                }
            }
            .alert("Barrieren-Daten löschen?", isPresented: $showingCacheDeleteConfirm) {
                Button("Löschen", role: .destructive) {
                    deleteBarrierCache()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Gecachte Daten werden entfernt und beim nächsten Start neu geladen. Offline sind dann keine Barrieren verfügbar.")
            }
        }
    }

    // MARK: - Benachrichtigungen

    private var notificationsSection: some View {
        Section {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                Label("Benachrichtigungen", systemImage: "bell")
            }
        }
    }

    // MARK: - Karte

    private var mapSection: some View {
        Section("Karte") {
            Picker(selection: $mapPreferences.style) {
                ForEach(MapStyleChoice.allCases) { choice in
                    Text(choice.label).tag(choice)
                }
            } label: {
                Label("Kartenansicht", systemImage: "map")
            }

            Picker(selection: $mapPreferences.appearance) {
                ForEach(MapAppearance.allCases) { appearance in
                    Text(appearance.label).tag(appearance)
                }
            } label: {
                Label("Kartendesign", systemImage: "circle.lefthalf.filled")
            }
        }
    }

    // MARK: - Allgemein (Sprache, Daten)

    private var generalSection: some View {
        Section("Allgemein") {
            NavigationLink {
                LanguageSettingsView()
            } label: {
                Label("Sprache", systemImage: "globe")
            }

            Toggle(isOn: $wifiOnlyUpdates) {
                Label("Nur über WLAN aktualisieren", systemImage: "wifi")
            }

            Button(role: .destructive) {
                showingCacheDeleteConfirm = true
            } label: {
                Label("Barrieren-Daten löschen", systemImage: "trash")
            }
        }
    }

    private func deleteBarrierCache() {
        // Cache-Key des kommenden Offline-Cachings; heute noch leer.
        UserDefaults.standard.removeObject(forKey: "armikronav.barrierCache")
    }

    // MARK: - Profil

    private var profileSection: some View {
        Section("Mein Profil") {
            row("Rollstuhltyp", profile.wheelchairType.displayName)
            row("Mobilitätskategorie", profile.mobilityCategory.displayName)
            row("Breite", "\(profile.widthCm) cm  (effektiv \(profile.effectiveWidthNeeded) cm)")
            row("Gesamthöhe (sitzend)", "\(profile.heightCm) cm")
            row("Sitzhöhe", "\(profile.seatHeightCm) cm")
            row("Länge", "\(profile.lengthCm) cm")
            row("Gewicht", "\(profile.weightKg) kg")
            row("Max. Steigung", "\(Int(profile.effectiveMaxIncline)) %")
            row("Max. Bordstein", "\(Int(profile.effectiveMaxCurb)) cm")
            row("Oberflächentoleranz", profile.surfaceTolerance.displayName)
        }
    }

    // MARK: - Heute (Tages-Zustände: Begleitung, Nässe, Energie)

    private var companionSection: some View {
        Section {
            Toggle("Heute mit Begleitperson", isOn: $profile.companionTodayOverride)
            Toggle("Nasse Bedingungen", isOn: $profile.wetConditionsToday)
            Toggle("Heute weniger Energie", isOn: $profile.lowEnergyToday)
        } header: {
            Text("Heute")
        } footer: {
            Text(todayFooter)
        }
    }

    private var todayFooter: String {
        var parts: [String] = []
        if profile.companionTodayOverride {
            parts.append("Begleitung: Limits erhöht (+\(Int(profile.companionInclineBonus)) % Steigung, +\(Int(profile.companionCurbBonus)) cm Bordstein).")
        }
        if profile.wetConditionsToday {
            parts.append("Nässe: Oberflächen-Toleranz eine Stufe strenger.")
        }
        if profile.lowEnergyToday {
            parts.append("Weniger Energie: Grund-Limits um 20 % gesenkt.")
        }
        if parts.isEmpty {
            return "Tages-Zustände passen deine Warn-Schwellen temporär an – dein Profil bleibt unverändert."
        }
        return parts.joined(separator: " ")
    }

    // MARK: - Edit-Link + Gespeicherte Orte

    private var editSection: some View {
        Section {
            NavigationLink {
                ProfileEditView(profile: $profile)
            } label: {
                Label("Profil bearbeiten", systemImage: "pencil")
            }

            NavigationLink {
                SavedPlacesListView()
            } label: {
                Label("Gespeicherte Orte", systemImage: "bookmark")
            }
        }
    }

    // MARK: - Datenschutz + About

    private var privacyAndAboutSection: some View {
        Section {
            NavigationLink {
                PrivacyView()
            } label: {
                Label("Datenschutz", systemImage: "lock")
            }
            NavigationLink {
                AboutView()
            } label: {
                Label("Über die App", systemImage: "info.circle")
            }
        }
    }

    // MARK: - Helpers

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}