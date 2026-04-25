// OnboardingProgressBar.swift
// ARMikronav – Geteilte Progress-Bar für alle 6 Onboarding-Screens.

import SwiftUI

struct OnboardingProgressBar: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? Color.accentColor : Color.gray.opacity(0.25))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.25), value: step)
                }
            }
            HStack {
                Text("Schritt \(step.rawValue) von \(OnboardingStep.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct OnboardingHeader: View {
    let step: OnboardingStep

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(step.title)
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text(step.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 16)
    }
}

struct OnboardingNavigationBar: View {
    let canProceed: Bool
    let isLastStep: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Label("Zurück", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button(action: onNext) {
                Text(isLastStep ? "Fertig" : "Weiter")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canProceed)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}
