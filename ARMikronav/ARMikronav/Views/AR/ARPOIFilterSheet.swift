// ARPOIFilterSheet.swift
// ARMikronav
//
// Kategorie-Filter für den AR-Modus: listet alle verfügbaren
// ginto-Kategorien (POICategory.chips) mit Icon und Trefferzahl.
// Eine Auswahl filtert die projizierten POIs im Kamerabild; "Alle Orte"
// hebt den Filter wieder auf.

import SwiftUI

struct ARPOIFilterSheet: View {
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row(
                        label: "Alle Orte",
                        symbol: "mappin.and.ellipse",
                        count: viewModel.cityPOIs.count,
                        isSelected: viewModel.activeCategory == nil
                    ) {
                        viewModel.setCategory(nil)
                        dismiss()
                    }
                }

                Section("Kategorien") {
                    ForEach(POICategory.chips) { chip in
                        row(
                            label: chip.label,
                            symbol: chip.symbol,
                            count: viewModel.poisForCategory(chip.label).count,
                            isSelected: viewModel.activeCategory == chip.label
                        ) {
                            viewModel.setCategory(chip.label)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Orte filtern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func row(
        label: String,
        symbol: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: symbol)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .accessibilityLabel("\(label), \(count) Orte")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}