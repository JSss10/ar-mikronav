// AppSettingsView.swift
// ARMikronav
//
// Wireframe 4.6 – App-Einstellungen: Sprache, Kartentyp, Einheiten,
// Daten-Präferenzen und der Einstieg in die Konto-Löschung (4.11).
// Schriftgrösse/Kontrast/Bewegung respektiert die App über die
// iOS-Systemeinstellungen (Dynamic Type, Reduce Motion) – der Footer
// verweist dorthin, statt wirkungslose App-Toggles anzubieten.

import SwiftUI

struct AppSettingsView: View {
    @AppStorage("armikronav.mapStyle") private var mapStyle = "standard"
    @AppStorage("armikronav.wifiOnlyUpdates") private var wifiOnlyUpdates = false

    @State private var showingCacheDeleteConfirm = false
    @State private var showingDeleteAccount = false

    var body: some View {
        Form {
            generalSection
            dataSection
            accessibilitySection
            deleteAccountSection
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Barrieren-Daten löschen?", isPresented: $showingCacheDeleteConfirm) {
            Button("Löschen", role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "armikronav.barrierCache")
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Gecachte Daten werden entfernt und beim nächsten Start neu geladen. Offline sind dann keine Barrieren verfügbar.")
        }
        .sheet(isPresented: $showingDeleteAccount) {
            DeleteAccountView()
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        Section {
            NavigationLink {
                LanguageSettingsView()
            } label: {
                HStack {
                    Text("Sprache")
                    Spacer()
                    Text("Deutsch")
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Kartentyp", selection: $mapStyle) {
                Text("Standard").tag("standard")
                Text("Satellit").tag("hybrid")
            }

            HStack {
                Text("Einheiten")
                Spacer()
                Text("Metrisch (cm/m)")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var dataSection: some View {
        Section("Daten") {
            Toggle("Nur über WLAN aktualisieren", isOn: $wifiOnlyUpdates)

            Button(role: .destructive) {
                showingCacheDeleteConfirm = true
            } label: {
                HStack {
                    Text("Barrieren-Daten löschen")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var accessibilitySection: some View {
        Section {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Schriftgrösse & Kontrast anpassen", systemImage: "textformat.size")
            }
        } header: {
            Text("Barrierefreiheit der App")
        } footer: {
            Text("ARMikronav folgt den iOS-Systemeinstellungen für Schriftgrösse (Dynamic Type), erhöhten Kontrast und reduzierte Bewegung.")
        }
    }

    private var deleteAccountSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAccount = true
            } label: {
                Text("Alle Daten löschen und Konto entfernen")
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
