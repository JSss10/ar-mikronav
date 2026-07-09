// NotificationSettingsView.swift
// ARMikronav
//
// Wireframe 4.5 – Push/Annäherung/Ton/Vibration, Warn-Radius (15–100 m)
// und der Opt-in für neue Barrieren-Daten im Testgebiet.

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var store = NotificationSettingsStore.shared

    var body: some View {
        Form {
            togglesSection
            radiusSection
            newDataSection
        }
        .navigationTitle("Benachrichtigungen")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var togglesSection: some View {
        Section {
            Toggle("Annäherungs-Warnungen", isOn: $store.settings.warningsEnabled)
            Toggle("Ton bei Warnung", isOn: $store.settings.soundEnabled)
                .disabled(!store.settings.warningsEnabled)
            Toggle("Vibration bei Warnung", isOn: $store.settings.vibrationEnabled)
                .disabled(!store.settings.warningsEnabled)
        } footer: {
            Text("Bei Annäherung an eine für dein Profil kritische Barriere erscheint ein Banner.")
        }
    }

    private var radiusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Warnungs-Radius")
                    Spacer()
                    Text("\(Int(store.settings.warningRadius)) m")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: $store.settings.warningRadius,
                    in: NotificationSettings.minRadius...NotificationSettings.maxRadius,
                    step: NotificationSettings.radiusStep
                )
                .disabled(!store.settings.warningsEnabled)
                .accessibilityValue("\(Int(store.settings.warningRadius)) Meter")
            }
        } footer: {
            Text("Bestimmt, ab welcher Distanz zur Barriere die Warnung ausgelöst wird.")
        }
    }

    private var newDataSection: some View {
        Section {
            Toggle("Neue Barrieren-Daten im Testgebiet", isOn: $store.settings.newDataAlerts)
        } footer: {
            Text("Stelle sicher, dass Benachrichtigungen in den iOS-Einstellungen erlaubt sind.")
        }
    }
}
