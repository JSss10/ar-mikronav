// Screen14_Abilities.swift
// ARMikronav – Onboarding Schritt 4/6: Persönliche Fähigkeiten.
// Max. Steigung, max. Bordsteinhöhe, Untergrund-Toleranz.
// Default-Werte kommen aus dem gewählten WheelchairType (Screen 1.2).

import SwiftUI

struct Screen14_Abilities: View {
    @Binding var draft: DraftProfile

    var body: some View {
        VStack(spacing: 24) {
            // MARK: Steigung
            AbilityCard(
                icon: "triangle",
                title: "Maximale Steigung",
                subtitle: "Welche Steigung schaffst du noch komfortabel?",
                valueText: "\(Int(draft.maxIncline)) %"
            ) {
                Slider(
                    value: $draft.maxIncline,
                    in: 3...15,
                    step: 1
                )
                .tint(Color.accentColor)

                HStack {
                    Text("3 %")
                    Spacer()
                    Text("9 % (SIA-Norm)")
                    Spacer()
                    Text("15 %")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            // MARK: Bordstein
            AbilityCard(
                icon: "square.stack.3d.up",
                title: "Maximale Bordsteinhöhe",
                subtitle: "Welche Kante überwindest du allein?",
                valueText: "\(String(format: "%.0f", draft.maxCurbHeight)) cm"
            ) {
                Slider(
                    value: $draft.maxCurbHeight,
                    in: 0...10,
                    step: 0.5
                )
                .tint(Color.accentColor)

                HStack {
                    Text("0 cm")
                    Spacer()
                    Text("3 cm (abgesenkt)")
                    Spacer()
                    Text("10 cm")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            // MARK: Manövrier-Spielraum
            AbilityCard(
                icon: "arrow.left.and.right.square",
                title: "Manövrier-Spielraum",
                subtitle: "Wie viel Platz brauchst du zusätzlich zur Rollstuhlbreite, um eine Engstelle sicher zu passieren?",
                valueText: "+\(draft.maneuverBufferCm) cm"
            ) {
                Slider(
                    value: Binding(
                        get: { Double(draft.maneuverBufferCm) },
                        set: { draft.maneuverBufferCm = Int($0) }
                    ),
                    in: 0...25,
                    step: 1
                )
                .tint(Color.accentColor)

                HStack {
                    Text("0 cm")
                    Spacer()
                    Text("10 cm (empfohlen)")
                    Spacer()
                    Text("25 cm")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                Text("Bei Engstellen warnt dich die App, wenn der Durchgang schmaler ist als \(draft.widthCm + draft.maneuverBufferCm) cm (Breite + Spielraum).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // MARK: Untergrund
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "road.lanes")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    Text("Untergrund-Toleranz")
                        .font(.headline)
                }

                Text("Welche Beläge sind für dich passierbar?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(SurfaceTolerance.allCases, id: \.self) { tolerance in
                    SurfaceRow(
                        tolerance: tolerance,
                        selected: draft.surfaceTolerance == tolerance
                    ) {
                        draft.surfaceTolerance = tolerance
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

private struct AbilityCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let valueText: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(valueText)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.accentColor)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct SurfaceRow: View {
    let tolerance: SurfaceTolerance
    let selected: Bool
    let action: () -> Void

    var label: String {
        switch tolerance {
        case .smoothOnly:  return "Nur glatte Beläge (Asphalt, Beton)"
        case .fineCobble:  return "Kleines Kopfsteinpflaster OK"
        case .almostAll:   return "Fast alles (auch grobes Pflaster)"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
