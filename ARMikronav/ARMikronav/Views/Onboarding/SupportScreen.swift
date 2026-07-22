// Screen15_Support.swift
// ARMikronav – Onboarding Schritt 5/6: Unterstützung / Begleitung.
// Beeinflusst effectiveMaxIncline und effectiveMaxCurb in der Barrierenlogik.

import SwiftUI

struct Screen15_Support: View {
    @Binding var draft: DraftProfile

    private let options: [(CompanionStatus, String, String, String)] = [
        (.alwaysAlone,
         "Ich bin immer allein unterwegs",
         "figure.roll",
         "Alle Barrieren werden auf Basis deiner persönlichen Werte bewertet."),
        (.sometimes,
         "Manchmal mit Begleitung",
         "figure.2",
         "Du kannst vor jeder Fahrt in den Einstellungen umschalten."),
        (.usually,
         "Meistens mit Begleitung",
         "figure.2.arms.open",
         "Steigungen bis +3 % und Bordsteine bis +4 cm werden als passierbar eingestuft.")
    ]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(options, id: \.0) { status, label, icon, hint in
                SupportCard(
                    icon: icon,
                    label: label,
                    hint: hint,
                    selected: draft.companionStatus == status
                ) {
                    draft.companionStatus = status
                }
            }

            Text("Mit Begleitperson passt die App die Schwellenwerte automatisch an: +3 % max. Steigung und +4 cm max. Bordsteinhöhe.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.top, 8)

            eurokeyToggle
        }
    }

    // Eurokey-Besitz: schaltet abgeschlossene Eurokey-WCs als zugänglich frei.
    private var eurokeyToggle: some View {
        Toggle(isOn: $draft.hasEurokey) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Ich besitze einen Eurokey")
                    .font(.body.weight(.medium))
                Text("Viele Behinderten-WCs in der Schweiz sind mit dem Eurokey zugänglich.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.top, 4)
    }
}

private struct SupportCard: View {
    let icon: String
    let label: String
    let hint: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
