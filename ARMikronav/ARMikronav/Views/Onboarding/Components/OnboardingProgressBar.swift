// OnboardingProgressBar.swift
// ARMikronav – Geteilte Progress-Bar für alle 6 Onboarding-Screens.
// Formsprache v2: Kapsel-Segmente in Token-Farben, der aktuelle Schritt
// dehnt sich federnd aus (Reduce-Motion: nur Farbwechsel, keine Breite).

import SwiftUI

struct OnboardingProgressBar: View {
    let step: OnboardingStep
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                    let isDone = s.rawValue <= step.rawValue
                    let isCurrent = s.rawValue == step.rawValue
                    Capsule()
                        .fill(isDone ? AppColor.accentPrimary : AppColor.borderDecorative)
                        // Der aktuelle Schritt ist etwas kräftiger (8 statt 6 pt).
                        .frame(height: isCurrent ? 8 : 6)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 8)
            .animation(reduceMotion ? AppMotion.fade : AppMotion.spring, value: step)

            HStack {
                Text("Schritt \(step.rawValue) von \(OnboardingStep.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
            }
        }
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Schritt \(step.rawValue) von \(OnboardingStep.allCases.count)")
    }
}

struct OnboardingHeader: View {
    let step: OnboardingStep

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(step.title)
                .font(AppTypography.displayLarge)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(step.subtitle)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, AppMetrics.Space.m)
    }
}

struct OnboardingNavigationBar: View {
    let canProceed: Bool
    let isLastStep: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: AppMetrics.Space.s + 4) {
            Button(action: onBack) {
                Label("Zurück", systemImage: "chevron.left")
            }
            .buttonStyle(.appSecondary)

            Button(action: onNext) {
                Text(isLastStep ? "Fertig" : "Weiter")
            }
            .buttonStyle(.appPrimary)
            .disabled(!canProceed)
        }
        .padding(.horizontal)
        .padding(.bottom, AppMetrics.Space.m)
    }
}
