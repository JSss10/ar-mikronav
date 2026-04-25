// OnboardingViewModel.swift
// ARMikronav – State Management für den 6-stufigen Onboarding-Flow.

import Foundation
import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .mobilityCategory
    @Published var draft: DraftProfile = DraftProfile()
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var didComplete: Bool = false

    private let profileService: ProfileServiceProtocol

    init(profileService: ProfileServiceProtocol? = nil) {
        self.profileService = profileService ?? ProfileService.shared
    }

    // MARK: - Navigation

    func next() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = nextStep
        }
    }

    func back() {
        guard let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = prevStep
        }
    }

    // MARK: - Step Validation

    var canProceed: Bool {
        switch currentStep {
        case .mobilityCategory:
            return draft.mobilityCategory == .wheelchair
        case .wheelchairType:
            return draft.wheelchairSubtype != nil
        case .measurements, .abilities, .support:
            return true
        case .summary:
            return draft.isComplete
        }
    }

    // MARK: - Screen 1.2 Side Effect

    func selectWheelchairSubtype(_ subtype: WheelchairSubtype) {
        draft.wheelchairSubtype = subtype
        draft.applyDefaults(for: subtype)
    }

    // MARK: - Save (Screen 1.6)

    func saveProfile() async {
        guard let userId = profileService.currentUserId else {
            errorMessage = "Nicht eingeloggt. Bitte erneut anmelden."
            return
        }
        guard let profile = draft.buildUserProfile(userId: userId) else {
            errorMessage = "Profil ist unvollständig."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await profileService.saveProfile(profile)
            didComplete = true
        } catch {
            errorMessage = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

// MARK: - OnboardingStep

enum OnboardingStep: Int, CaseIterable {
    case mobilityCategory = 1
    case wheelchairType   = 2
    case measurements     = 3
    case abilities        = 4
    case support          = 5
    case summary          = 6

    var progress: Double {
        Double(rawValue) / Double(Self.allCases.count)
    }

    var title: String {
        switch self {
        case .mobilityCategory: return "Wer bist du?"
        case .wheelchairType:   return "Dein Rollstuhl"
        case .measurements:     return "Masse"
        case .abilities:        return "Deine Fähigkeiten"
        case .support:          return "Unterstützung"
        case .summary:          return "Zusammenfassung"
        }
    }

    var subtitle: String {
        switch self {
        case .mobilityCategory: return "Wähle deine Mobilitätssituation"
        case .wheelchairType:   return "Welchen Rollstuhl nutzt du?"
        case .measurements:     return "Für genauere Barrierenwarnungen"
        case .abilities:        return "Was traust du dir im Alltag zu?"
        case .support:          return "Bist du meist allein unterwegs?"
        case .summary:          return "Überprüfe dein Profil"
        }
    }
}
