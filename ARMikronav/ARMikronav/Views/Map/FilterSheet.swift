// FilterSheet.swift
// ARMikronav
//
// Bottom-Sheet zum Setzen des Kartenfilters: Toggle pro Barrierentyp +
// Suchradius-Slider. Der Sheet arbeitet auf einer lokalen Draft-Kopie und
// übergibt das Endergebnis beim Schliessen an den Caller (MapView/MapViewModel).
//
// Styling gemäss Styleguide v1.0: ausschliesslich Design-Tokens (AppColor,
// AppTypography, AppMetrics) in klar getrennten, angehobenen Karten.

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
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: AppMetrics.Space.l) {
                    barrierTypesSection
                    radiusSection
                }
                .padding(AppMetrics.Space.m)
                .padding(.bottom, AppMetrics.Space.l)
            }
        }
        .background(AppColor.backgroundPrimary)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AppMetrics.Radius.sheet + AppMetrics.Space.s)
    }

    // MARK: - Kopfzeile (Abbrechen · Filter · Fertig)

    private var header: some View {
        HStack {
            Button("Abbrechen") { dismiss() }
                .font(AppTypography.headline.weight(.regular))
                .foregroundStyle(AppColor.accentPrimary)

            Spacer()

            Text("Filter")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            Button("Fertig") {
                onApply(draft)
                dismiss()
            }
            .font(AppTypography.headline.weight(.semibold))
            .foregroundStyle(AppColor.accentPrimary)
        }
        .padding(.horizontal, AppMetrics.Space.m)
        .padding(.vertical, AppMetrics.Space.m)
    }

    // MARK: - Barrierentypen

    private var barrierTypesSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.Space.s + AppMetrics.Space.xs) {
            sectionTitle("Barrierentypen")

            VStack(spacing: 0) {
                let types = BarrierType.allCases
                ForEach(Array(types.enumerated()), id: \.element) { index, type in
                    Toggle(isOn: binding(for: type)) {
                        Label {
                            Text(type.localizedLabel)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.textPrimary)
                        } icon: {
                            Image(systemName: type.symbolName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppColor.accentPrimary)
                                .frame(width: 28)
                        }
                    }
                    .tint(AppColor.accentPrimary)
                    .padding(.horizontal, AppMetrics.Space.m)
                    .padding(.vertical, AppMetrics.Space.s + AppMetrics.Space.xs)
                    .frame(minHeight: AppMetrics.Touch.minimum)
                    .accessibilityLabel(type.localizedLabel)

                    if index < types.count - 1 {
                        Rectangle()
                            .fill(AppColor.borderDecorative)
                            .frame(height: 0.5)
                            .padding(.leading, AppMetrics.Space.m + 28 + AppMetrics.Space.m)
                    }
                }
            }
            .cardBackground()
        }
    }

    // MARK: - Suchradius

    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.Space.s + AppMetrics.Space.xs) {
            sectionTitle("Suchradius")

            VStack(alignment: .leading, spacing: AppMetrics.Space.s) {
                HStack {
                    Text("Radius")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    Text("\(Int(draft.radius)) m")
                        .font(AppTypography.body.weight(.semibold))
                        .foregroundStyle(AppColor.textSecondary)
                        .monospacedDigit()
                }

                Slider(
                    value: $draft.radius,
                    in: BarrierFilterState.minRadius...BarrierFilterState.maxRadius,
                    step: BarrierFilterState.radiusStep
                ) {
                    Text("Suchradius")
                } minimumValueLabel: {
                    Text("\(Int(BarrierFilterState.minRadius))")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                } maximumValueLabel: {
                    Text("\(Int(BarrierFilterState.maxRadius))")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .tint(AppColor.accentPrimary)
                .accessibilityValue("\(Int(draft.radius)) Meter")
            }
            .padding(AppMetrics.Space.m)
            .cardBackground()

            Text("Bestimmt, wie weit um deine Position nach Orten (POIs) gesucht wird. Barrieren werden immer für den ganzen Kreis 1 angezeigt.")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppMetrics.Space.xs)
        }
    }

    // MARK: - Bausteine

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.subheadline.weight(.semibold))
            .foregroundStyle(AppColor.textSecondary)
            .padding(.horizontal, AppMetrics.Space.xs)
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

// MARK: - Card helper

private extension View {
    /// Angehobene Kartenfläche gemäss Styleguide (SurfaceRaised, Card-Radius,
    /// dezente Kontur für Abgrenzung auch im hellen Modus).
    func cardBackground() -> some View {
        self
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous)
                    .fill(AppColor.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous)
                    .strokeBorder(AppColor.borderDecorative, lineWidth: 0.5)
            )
    }
}
