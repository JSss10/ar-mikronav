// WarningBannerView.swift
// ARMikronav
//
// Push-Style Warnbanner, das im AR-Modus oben einrollt, sobald sich der User
// einer für ihn warnpflichtigen Barriere nähert (siehe ProximityWarningService).

import SwiftUI

struct WarningBannerView: View {
    let warning: BarrierWarning
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                Text(warning.barrier.type.localizedLabel)
                    .font(.headline)
                Text("in \(Int(warning.distance)) m · \(warning.barrierValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(warning.userLimit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(6)
            }
            .accessibilityLabel("Warnung ausblenden")
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 6)
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(warning.barrier.type.tint)
                .frame(width: 44, height: 44)
            Image(systemName: warning.barrier.type.symbolName)
                .foregroundStyle(.white)
                .font(.title3.weight(.semibold))
        }
    }
}
