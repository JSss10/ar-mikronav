// CameraPermissionView.swift
// ARMikronav
//
// Erklärungs-Screen vor dem System-Permission-Prompt für die Kamera (AR-Modus).
// Erlauben fragt den System-Prompt an; bei bereits abgelehntem Status leitet
// der Button zu den iOS-Einstellungen weiter. Der aktuelle Status fließt als
// Binding zum Caller zurück, damit dieser die Permission-View entfernen kann,
// sobald `granted` ankommt.

import SwiftUI
import AVFoundation

struct CameraPermissionView: View {
    @Binding var status: AVAuthorizationStatus

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.tint)

            Text("Kamera verwenden")
                .font(.title)
                .bold()

            Text("Im AR-Modus zeigt ARMikronav Barrieren direkt im Live-Kamerabild. Es werden keine Bilder gespeichert oder übertragen.")
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
        switch status {
        case .denied, .restricted:
            VStack(spacing: 12) {
                Text("Du hast den Kamera-Zugriff bisher nicht erlaubt. Öffne die Einstellungen, um es nachzuholen.")
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
                requestAccess()
            } label: {
                Text("Kamera erlauben")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            Task { @MainActor in
                status = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
