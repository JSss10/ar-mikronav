// Screen12_WheelchairType.swift
// ARMikronav – Onboarding Schritt 2/6: Rollstuhltyp wählen.
// 15 Subtypen in 5 Kategorien gruppiert, Mapping auf internen WheelchairType.

import SwiftUI

struct Screen12_WheelchairType: View {
    @Binding var draft: DraftProfile
    let onSelect: (WheelchairSubtype) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(WheelchairCategory.allCases) { category in
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.displayName)
                        .font(.headline)
                        .padding(.horizontal, 4)

                    ForEach(category.subtypes) { subtype in
                        WheelchairRow(
                            subtype: subtype,
                            selected: draft.wheelchairSubtype == subtype
                        ) {
                            onSelect(subtype)
                        }
                    }
                }
            }

            Text("Dein gewählter Typ bestimmt die Standard-Schwellenwerte für Breite, Steigung und Bordsteine. Du kannst diese in den nächsten Schritten anpassen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }
}

private struct WheelchairRow: View {
    let subtype: WheelchairSubtype
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(subtype.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(subtype.displayName)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
