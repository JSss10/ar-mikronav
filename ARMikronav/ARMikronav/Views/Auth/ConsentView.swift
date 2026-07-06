// ConsentView.swift
// ARMikronav
//
// Screen 0.5 – Datenschutz/Einwilligung nach nDSG. Wird einmalig nach dem
// ersten Login gezeigt, bevor das Onboarding startet. Die drei Karten sind
// informativ (was wird erhoben); die eigentliche Einwilligung ist die
// Checkbox unten. Der Consent-Zeitpunkt wird lokal persistiert.

import SwiftUI

enum ConsentStore {
    private static let key = "armikronav.consentGivenAt"

    static var hasConsent: Bool {
        UserDefaults.standard.object(forKey: key) != nil
    }

    static func recordConsent() {
        UserDefaults.standard.set(Date(), forKey: key)
    }
}

struct ConsentView: View {
    let onContinue: () -> Void

    @State private var agreed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Deine Daten, deine Kontrolle")
                .font(.title)
                .bold()
                .padding(.top, 24)

            Text("Diese Daten werden erhoben:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            dataCard(
                symbolName: "location.fill",
                title: "Standort",
                detail: "für Barrieren in deiner Nähe"
            )
            dataCard(
                symbolName: "camera.fill",
                title: "Kamera",
                detail: "für die AR-Ansicht"
            )
            dataCard(
                symbolName: "person.crop.rectangle.fill",
                title: "Profildaten",
                detail: "verschlüsselt in der Cloud (Supabase)"
            )

            Spacer()

            Toggle(isOn: $agreed) {
                Text("Ich stimme der Datenschutzerklärung zu")
                    .font(.subheadline)
            }
            .toggleStyle(CheckboxToggleStyle())

            NavigationLink {
                PrivacyView()
            } label: {
                Text("Vollständige Datenschutzerklärung")
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
            }

            Button {
                ConsentStore.recordConsent()
                onContinue()
            } label: {
                Text("Weiter")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(agreed ? Color.accentColor : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!agreed)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private func dataCard(symbolName: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Checkbox-Optik für die Einwilligung (statt Standard-Switch).
private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(configuration.isOn ? Color.accentColor : Color.secondary)
                configuration.label
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
