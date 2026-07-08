// Screen11_MobilityCategory.swift
// ARMikronav – Onboarding Schritt 2/7: Mobilitätskategorie wählen.
// Alle Kategorien sind wählbar; bei nicht-Rollstuhl-Profilen erscheint der
// Dialog 1.1a ("in zukünftiger Version verfügbar"), die Auswahl wird aber
// gespeichert. Weiter geht es im Prototyp nur mit dem Rollstuhl-Profil.

import SwiftUI

struct Screen11_MobilityCategory: View {
    @Binding var draft: DraftProfile
    @State private var showingUnavailableDialog = false

    private let categories: [(MobilityCategory, String, String)] = [
        (.wheelchair,         "Rollstuhlnutzende",          "figure.roll"),
        (.walkingDisability,  "Gehbehinderung",             "figure.walk.motion"),
        (.rollator,           "Rollator",                   "figure.walk"),
        (.visualImpairment,   "Sehbehinderung",             "eye.trianglebadge.exclamationmark"),
        (.blind,              "Blindheit",                  "eye.slash"),
        (.hearingImpairment,  "Hörbehinderung",             "ear.badge.waveform"),
        (.deaf,               "Gehörlosigkeit",             "ear.trianglebadge.exclamationmark"),
        (.stroller,           "Kinderwagen / temporär",     "figure.and.child.holdinghands"),
        (.elderly,            "Altersbedingt",              "figure.walk.arrival"),
        (.none,               "Ohne Einschränkung",         "figure.walk")
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(categories, id: \.0) { category, label, icon in
                CategoryRow(
                    label: label,
                    icon: icon,
                    selected: draft.mobilityCategory == category
                ) {
                    draft.mobilityCategory = category
                    if category != .wheelchair {
                        showingUnavailableDialog = true
                    }
                }
            }

            Text("Im Prototyp ist aktuell nur die Rollstuhl-Kategorie vollständig umgesetzt.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .alert("Dieses Profil wird in einer zukünftigen Version verfügbar.", isPresented: $showingUnavailableDialog) {
            Button("Verstanden") {}
            Button("Rollstuhl-Profil wählen") {
                draft.mobilityCategory = .wheelchair
            }
        } message: {
            Text("Im Prototyp ist aktuell nur das Rollstuhl-Profil vollständig umgesetzt. Deine Auswahl wird gespeichert.")
        }
    }
}

private struct CategoryRow: View {
    let label: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 32)
                    .foregroundStyle(Color.accentColor)

                Text(label)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.primary)

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
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
