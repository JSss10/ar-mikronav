// FilterSheet.swift
// ARMikronav
//
// Bottom-Sheet zum Setzen des Kartenfilters: Toggle pro Barrierentyp + Radius-Slider.
// Der Sheet arbeitet auf einer lokalen Draft-Kopie und übergibt das Endergebnis
// beim Schliessen an den Caller (MapView/MapViewModel).

import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BarrierFilterState
    let onApply: (BarrierFilterState) -> Void

    init(initial: BarrierFilterState, onApply: @escaping (BarrierFilterState) -> Void) {
        self._draft = State(initialValue: initial)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Barrierentypen") {
                    ForEach(BarrierType.allCases, id: \.self) { type in
                        Toggle(isOn: binding(for: type)) {
                            Label(type.localizedLabel, systemImage: type.symbolName)
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel(type.localizedLabel)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Radius")
                            Spacer()
                            Text("\(Int(draft.radius)) m")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: $draft.radius,
                            in: BarrierFilterState.minRadius...BarrierFilterState.maxRadius,
                            step: BarrierFilterState.radiusStep
                        )
                        .accessibilityValue("\(Int(draft.radius)) Meter")
                    }
                } header: {
                    Text("Suchradius")
                } footer: {
                    Text("Bestimmt, wie weit um deine Position Barrieren geladen werden.")
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        onApply(draft)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func binding(for type: BarrierType) -> Binding<Bool> {
        Binding(
            get: { draft.enabledTypes.contains(type) },
            set: { isOn in
                if isOn {
                    draft.enabledTypes.insert(type)
                } else {
                    draft.enabledTypes.remove(type)
                }
            }
        )
    }
}