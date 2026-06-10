// LocationPermissionView.swift
// ARMikronav
//
// Erklärungs-Screen vor dem System-Permission-Prompt für CoreLocation.
// Wird von HomeView angezeigt, solange `authorizationStatus` nicht erlaubt ist.
// Erlauben fragt den System-Prompt an; bei bereits abgelehntem Status leitet
// der Button zu den iOS-Einstellungen weiter.

import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @ObservedObject var locationService: LocationService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.tint)

            Text("Standort verwenden")
                .font(.title)
                .bold()

            Text("ARMikronav zeigt dir Barrieren in deiner Nähe und warnt vor Hindernissen auf deinem Weg. Dafür brauchen wir deinen Standort.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            primaryAction
                .padding(.horizontal, 24)

            Spacer().frame(height: 40)
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch locationService.authorizationStatus {
        case .denied, .restricted:
            VStack(spacing: 12) {
                Text("Du hast den Standort-Zugriff bisher nicht erlaubt. Öffne die Einstellungen, um es nachzuholen.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button {
                    openSystemSettings()
                } label: {
                    Text("Einstellungen öffnen")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        default:
            Button {
                locationService.requestAuthorization()
            } label: {
                Text("Standort erlauben")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
