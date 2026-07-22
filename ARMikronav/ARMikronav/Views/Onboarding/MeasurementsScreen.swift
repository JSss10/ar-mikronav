// Screen13_Measurements.swift
// ARMikronav – Onboarding Schritt 3/6: Masse (Breite, Höhe, Gewicht).
// Slider werden mit Defaults aus WheelchairType vorbelegt.

import SwiftUI

struct Screen13_Measurements: View {
    @Binding var draft: DraftProfile

    var body: some View {
        VStack(spacing: 28) {
            MeasurementSlider(
                icon: "arrow.left.and.right",
                label: "Rollstuhlbreite",
                value: Binding(
                    get: { Double(draft.widthCm) },
                    set: { draft.widthCm = Int($0) }
                ),
                range: 50...100,
                step: 1,
                unit: "cm",
                hint: "Gesamtbreite inklusive Räder und Antriebe"
            )

            MeasurementSlider(
                icon: "arrow.up.and.down",
                label: "Gesamthöhe (sitzend)",
                value: Binding(
                    get: { Double(draft.heightCm) },
                    set: { draft.heightCm = Int($0) }
                ),
                range: 100...180,
                step: 1,
                unit: "cm",
                hint: "Wichtig für niedrige Durchgänge und Überdachungen"
            )

            MeasurementSlider(
                icon: "arrow.up.to.line.compact",
                label: "Sitzhöhe",
                value: Binding(
                    get: { Double(draft.seatHeightCm) },
                    set: { draft.seatHeightCm = Int($0) }
                ),
                range: 35...70,
                step: 1,
                unit: "cm",
                hint: "Oberkante Sitzfläche inkl. Kissen ab Boden – damit der AR-Pfad aus deiner Perspektive exakt auf dem Boden liegt"
            )

            MeasurementSlider(
                icon: "arrow.forward.to.line",
                label: "Gesamtlänge",
                value: Binding(
                    get: { Double(draft.lengthCm) },
                    set: { draft.lengthCm = Int($0) }
                ),
                range: 80...160,
                step: 1,
                unit: "cm",
                hint: "Inklusive Fussstützen – relevant für Lifte und Wendeflächen"
            )

            MeasurementSlider(
                icon: "scalemass",
                label: "Gesamtgewicht",
                value: Binding(
                    get: { Double(draft.weightKg) },
                    set: { draft.weightKg = Int($0) }
                ),
                range: 40...250,
                step: 1,
                unit: "kg",
                hint: "Rollstuhl + Person (relevant für Rampen und Lifte)"
            )
        }
    }
}

private struct MeasurementSlider: View {
    let icon: String
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let hint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                Text(label)
                    .font(.headline)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.accentColor)
            }
            Slider(value: $value, in: range, step: step)
                .tint(Color.accentColor)
            Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Int(value)) \(unit)")
    }
}
