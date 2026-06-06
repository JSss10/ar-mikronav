// NotificationSettingsView.swift
// ARMikronav
//
// Konfiguriert Warn-Radius und Banner-Verhalten der Proximity-Warnung im AR-Modus.

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var store = NotificationSettingsStore.shared

    var body: some View {
        Form {
            warningsSection
            radiusSection
            soundSection
        }
        .navigationTitle("Benachrichtigungen")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var warningsSection: some View {
        Section {
            Toggle("Warnungen anzeigen", isOn: $store.settings.warningsEnabled)
        } footer: {
            Text("Bei Annäherung an eine für dein Profil kritische Barriere erscheint ein Banner.")
        }
    }

    private var radiusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Warn-Radius")
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

    private var soundSection: some View {
        Section {
            Toggle("Sound", isOn: $store.settings.soundEnabled)
                .disabled(!store.settings.warningsEnabled)
        }
    }
}