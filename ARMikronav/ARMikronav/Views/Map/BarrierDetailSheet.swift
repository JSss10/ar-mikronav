// BarrierDetailSheet.swift
// ARMikronav
//
// Detail-Bottom-Sheet für eine Barriere.
// Zeigt Typ + Icon, formatierten Wert gegen persönliches Limit
// und eine Warum-Erklärung. AR-Button ist bis Task A2 deaktiviert.

import SwiftUI

struct BarrierDetailSheet: View {
    let barrier: Barrier
    let profile: UserProfile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                comparison
                explanation
                sourceFooter
                arButton
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(barrier.type.tint)
                    .frame(width: 56, height: 56)
                Image(systemName: barrier.type.symbolName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(barrier.type.localizedLabel)
                    .font(.title2)
                    .bold()
                if let valueText = formattedValue {
                    Text(valueText)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var comparison: some View {
        if let limitText = formattedLimit {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dein Limit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(limitText)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Warum?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(explanationText)
                .font(.body)
        }
    }

    private var sourceFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
            Text("Quelle: \(barrier.source.uppercased())")
            if let last = barrier.lastVerified {
                Text("· geprüft \(last.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var arButton: some View {
        Button {
            // AR wird in Task A2 verdrahtet.
        } label: {
            Label("In AR ansehen", systemImage: "arkit")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(true)
        .accessibilityHint("Noch nicht verfügbar")
    }

    // MARK: - Formatting

    private var formattedValue: String? {
        switch barrier.type {
        case .steps:
            return barrier.value.map { "\(Int($0)) Stufen" }
        case .curb, .curbMissing:
            return barrier.value.map { "\(Int($0)) cm hoch" }
        case .incline:
            return barrier.value.map { "\(Int($0)) %" }
        case .narrow:
            return barrier.value.map { "\(Int($0)) cm Durchgang" }
        case .surface:
            return barrier.subtype?.replacingOccurrences(of: "_", with: " ").capitalized
        case .temporary:
            return nil
        }
    }

    private var formattedLimit: String? {
        switch barrier.type {
        case .steps:
            return profile.wheelchairType.canClimbStairs ? "Du kannst Stufen überwinden" : "Stufen sind nicht passierbar"
        case .curb, .curbMissing:
            return "Bis \(Int(profile.effectiveMaxCurb)) cm Bordsteinhöhe"
        case .incline:
            return "Bis \(Int(profile.effectiveMaxIncline)) % Steigung"
        case .narrow:
            return "Mindestens \(profile.effectiveWidthNeeded) cm Durchgang"
        case .surface:
            return "Oberflächentoleranz: \(surfaceToleranceText(profile.surfaceTolerance))"
        case .temporary:
            return nil
        }
    }

    private func surfaceToleranceText(_ tolerance: SurfaceTolerance) -> String {
        switch tolerance {
        case .smoothOnly:  return "nur glatt"
        case .fineCobble:  return "feines Kopfsteinpflaster"
        case .almostAll:   return "fast alles"
        }
    }

    private var explanationText: String {
        shouldWarn(barrier: barrier, profile: profile) ? personalReason : neutralReason
    }

    private var personalReason: String {
        switch barrier.type {
        case .steps:
            return "Stufen sind mit deinem Rollstuhltyp nicht überwindbar."
        case .curb:
            return "Der Bordstein ist höher als das, was du sicher überwinden kannst."
        case .curbMissing:
            return "An dieser Stelle fehlt eine Bordsteinabsenkung – Übergang nicht garantiert befahrbar."
        case .incline:
            return "Die Steigung übersteigt das, was dein Rollstuhl bewältigen kann."
        case .surface:
            return "Diese Oberfläche liegt außerhalb deiner gewählten Toleranz."
        case .narrow:
            return "Der Durchgang ist schmaler als die Breite, die du brauchst."
        case .temporary:
            return "Hier ist der Weg aktuell blockiert."
        }
    }

    private var neutralReason: String {
        switch barrier.type {
        case .steps:        return "Diese Stufen liegen innerhalb dessen, was du bewältigen kannst."
        case .curb:         return "Der Bordstein liegt unter deinem Limit."
        case .curbMissing:  return "Fehlende Absenkung – siehe Detail."
        case .incline:      return "Die Steigung liegt unter deinem Limit."
        case .surface:      return "Die Oberfläche passt zu deiner gewählten Toleranz."
        case .narrow:       return "Der Durchgang ist breit genug für dich."
        case .temporary:    return "Hier ist der Weg aktuell blockiert."
        }
    }
}