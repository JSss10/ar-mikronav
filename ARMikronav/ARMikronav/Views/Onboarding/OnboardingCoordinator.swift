// OnboardingCoordinator.swift
// ARMikronav – Container-View, die zwischen den 6 Onboarding-Screens wechselt.

import SwiftUI

struct OnboardingCoordinator: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(step: viewModel.currentStep)
                .padding(.top, 12)

            OnboardingHeader(step: viewModel.currentStep)
                .padding(.bottom, 8)

            ScrollView {
                Group {
                    switch viewModel.currentStep {
                    case .profileSetup:
                        Screen10_ProfileSetup(draft: $viewModel.draft)
                    case .mobilityCategory:
                        Screen11_MobilityCategory(draft: $viewModel.draft)
                    case .wheelchairType:
                        Screen12_WheelchairType(
                            draft: $viewModel.draft,
                            onSelect: viewModel.selectWheelchairSubtype
                        )
                    case .measurements:
                        Screen13_Measurements(draft: $viewModel.draft)
                    case .abilities:
                        Screen14_Abilities(draft: $viewModel.draft)
                    case .support:
                        Screen15_Support(draft: $viewModel.draft)
                    case .summary:
                        Screen16_Summary(
                            draft: viewModel.draft,
                            isSaving: viewModel.isSaving,
                            errorMessage: viewModel.errorMessage
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }

            OnboardingNavigationBar(
                canProceed: viewModel.canProceed,
                isLastStep: viewModel.currentStep == .summary,
                onBack: viewModel.back,
                onNext: {
                    if viewModel.currentStep == .summary {
                        Task {
                            await viewModel.saveProfile()
                        }
                    } else {
                        viewModel.next()
                    }
                }
            )
        }
        .onChange(of: viewModel.didComplete) { _, completed in
            if completed { onFinish() }
        }
    }
}

#Preview {
    OnboardingCoordinator(onFinish: {})
}