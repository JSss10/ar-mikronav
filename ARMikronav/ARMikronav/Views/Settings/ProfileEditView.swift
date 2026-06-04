// ProfileEditView.swift
// ARMikronav
//
// Edit-Formular für ein bestehendes UserProfile. Spiegelt die Felder aus dem
// Onboarding 1.1–1.5 in einem einzelnen Form-Sheet wider, mit lokalem Draft,
// damit Änderungen verworfen werden können.

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: UserProfile

    @State private var draft: UserProfile

    init(profile: Binding<UserProfile>) {
        self._profile = profile
        self._draft = State(initialValue: profile.wrappedValue)
    }

    var body: some View {
        Form {
            mobilitySection
            wheelchairSection
            measurementsSection
            abilitiesSection
            surfaceSection
            companionSection
        }
        .navigationTitle("Profil bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    draft.updatedAt = Date()
                    profile = draft
                    dismiss()
                }
                .bold()
            }
        }
    }

    // MARK: - Sections

    private var mobilitySection: some View {
        Section("Mobilitätskategorie") {
            Picker("Kategorie", selection: $draft.mobilityCategory) {
                ForEach(MobilityCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
        }
    }

    private var wheelchairSection: some View {
        Section("Rollstuhltyp") {
            Picker("Typ", selection: $draft.wheelchairType) {
                ForEach(WheelchairType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
        }
    }

    private var measurementsSection: some View {
        Section("Maße") {
            Stepper("Breite: \(draft.widthCm) cm",
                    value: $draft.widthCm, in: 50...100, step: 1)
            Stepper("Sitzhöhe: \(draft.heightCm) cm",
                    value: $draft.heightCm, in: 80...160, step: 1)
            Stepper("Gewicht: \(draft.weightKg) kg",
                    value: $draft.weightKg, in: 30...200, step: 1)
        }
    }

    private var abilitiesSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Max. Steigung: \(Int(draft.maxIncline)) %")
                Slider(value: $draft.maxIncline, in: 0...15, step: 1)
            }
            VStack(alignment: .leading) {
                Text("Max. Bordsteinhöhe: \(Int(draft.maxCurbHeight)) cm")
                Slider(value: $draft.maxCurbHeight, in: 0...15, step: 1)
            }
        } header: {
            Text("Was du bewältigst")
        } footer: {
            Text("Werte beziehen sich aufs Fahren ohne Begleitung. Mit Begleitung werden sie automatisch leicht erhöht.")
        }
    }

    private var surfaceSection: some View {
        Section("Oberflächentoleranz") {
            Picker("Toleranz", selection: $draft.surfaceTolerance) {
                ForEach(SurfaceTolerance.allCases, id: \.self) { tolerance in
                    Text(tolerance.displayName).tag(tolerance)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }

    private var companionSection: some View {
        Section("Begleitung") {
            Picker("Standard", selection: $draft.companionStatus) {
                ForEach(CompanionStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
        }
    }
}