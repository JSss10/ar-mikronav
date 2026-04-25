// Screen11_MobilityCategory.swift
// ARMikronav – Onboarding Schritt 1/6: Mobilitätskategorie wählen.
// 10 Kategorien sichtbar, nur "wheelchair" ist im Prototyp auswählbar.

import SwiftUI

struct Screen11_MobilityCategory: View {
    @Binding var draft: DraftProfile

    private let categories: [(MobilityCategory, String, String, Bool)] = [
        (.wheelchair,         "Rollstuhlnutzende",          "figure.roll",                 true),
        (.walkingDisability,  "Gehbehinderung",             "figure.walk.motion",          false),
        (.rollator,           "Rollator",                   "figure.walk",                 false),
        (.visualImpairment,   "Sehbehinderung",             "eye.trianglebadge.exclamationmark", false),
        (.blind,              "Blindheit",                  "eye.slash",                   false),
        (.hearingImpairment,  "Hörbehinderung",             "ear.badge.waveform",          false),
        (.deaf,               "Gehörlosigkeit",             "ear.trianglebadge.exclamationmark", false),
        (.stroller,           "Kinderwagen / temporär",     "figure.and.child.holdinghands", false),
        (.elderly,            "Altersbedingt",              "figure.walk.arrival",         false),
        (.none,               "Ohne Einschränkung",         "figure.walk",                 false)
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(categories, id: \.0) { category, label, icon, enabled in
                CategoryRow(
                    label: label,
                    icon: icon,
                    enabled: enabled,
                    selected: draft.mobilityCategory == category
                ) {
                    guard enabled else { return }
                    draft.mobilityCategory = category
                }
            }

            Text("Im Prototyp ist aktuell nur die Rollstuhl-Kategorie verfügbar. Weitere Mobilitätsformen folgen in zukünftigen Versionen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
}

private struct CategoryRow: View {
    let label: String
    let icon: String
    let enabled: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 32)
                    .foregroundStyle(enabled ? Color.accentColor : Color.secondary)

                Text(label)
                    .font(.body.weight(.medium))
                    .foregroundStyle(enabled ? Color.primary : Color.secondary)

                Spacer()

                if !enabled {
                    Text("Bald")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.15), in: Capsule())
                        .foregroundStyle(.secondary)
                } else if selected {
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
        .disabled(!enabled)
        .accessibilityLabel(label)
        .accessibilityHint(enabled ? "Wählen" : "Nicht verfügbar im Prototyp")
    }
}
