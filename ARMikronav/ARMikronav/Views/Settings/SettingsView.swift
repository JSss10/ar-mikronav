// SettingsView.swift
// ARMikronav
//
// Einstellungs-Hauptseite. Zeigt Profil-Übersicht und den "Heute mit Begleitung"-
// Toggle, der direkt auf das gebundene UserProfile schreibt. Weitere Settings
// (Benachrichtigungen, Datenschutz, Konto) folgen in S2/S3.

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: UserProfile

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                companionSection
                editSection
                placeholderSections
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .bold()
                }
            }
        }
    }

    // MARK: - Profil

    private var profileSection: some View {
        Section("Mein Profil") {
            row("Rollstuhltyp", profile.wheelchairType.displayName)
            row("Mobilitätskategorie", profile.mobilityCategory.displayName)
            row("Breite", "\(profile.widthCm) cm  (effektiv \(profile.effectiveWidthNeeded) cm)")
            row("Sitzhöhe", "\(profile.heightCm) cm")
            row("Gewicht", "\(profile.weightKg) kg")
            row("Max. Steigung", "\(Int(profile.effectiveMaxIncline)) %")
            row("Max. Bordstein", "\(Int(profile.effectiveMaxCurb)) cm")
            row("Oberflächentoleranz", profile.surfaceTolerance.displayName)
        }
    }

    // MARK: - Begleitung

    private var companionSection: some View {
        Section {
            Toggle("Heute mit Begleitung", isOn: $profile.companionTodayOverride)
        } header: {
            Text("Begleitung")
        } footer: {
            Text(companionFooter)
        }
    }

    private var companionFooter: String {
        let base: String
        switch profile.companionStatus {
        case .alwaysAlone: base = "Standard: alleine unterwegs."
        case .sometimes:   base = "Standard: manchmal in Begleitung."
        case .usually:     base = "Standard: meistens in Begleitung."
        }
        let suffix = profile.companionTodayOverride
            ? " Heute hebt der Toggle dein Limit etwas an (mehr Steigung und Bordsteinhöhe erlaubt)."
            : ""
        return base + suffix
    }

    // MARK: - Edit-Link

    private var editSection: some View {
        Section {
            NavigationLink {
                ProfileEditView(profile: $profile)
            } label: {
                Label("Profil bearbeiten", systemImage: "pencil")
            }
        }
    }

    // MARK: - Platzhalter

    private var placeholderSections: some View {
        Section {
            placeholderRow("Benachrichtigungen", systemImage: "bell")
            placeholderRow("Datenschutz", systemImage: "lock")
            placeholderRow("Über die App", systemImage: "info.circle")
        } footer: {
            Text("Weitere Bereiche kommen in den nächsten Versionen.")
        }
    }

    private func placeholderRow(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Display Names

extension WheelchairType {
    var displayName: String {
        switch self {
        case .manual:        return "Manuell"
        case .emotion:       return "Manuell + E-Motion"
        case .joystick:      return "Joystick-gesteuert"
        case .electric:      return "Elektrisch"
        case .stairClimbing: return "Treppensteiger (Scewo)"
        }
    }
}

extension MobilityCategory {
    var displayName: String {
        switch self {
        case .none:               return "Keine Einschränkung"
        case .wheelchair:         return "Rollstuhl"
        case .visualImpairment:   return "Sehbehinderung"
        case .blind:              return "Blind"
        case .hearingImpairment:  return "Hörbehinderung"
        case .deaf:               return "Gehörlos"
        case .walkingDisability:  return "Gehbehinderung"
        case .stroller:           return "Kinderwagen"
        case .rollator:           return "Rollator"
        case .elderly:            return "Senior:in"
        }
    }
}

extension SurfaceTolerance {
    var displayName: String {
        switch self {
        case .smoothOnly:  return "Nur glatt"
        case .fineCobble:  return "Feines Kopfsteinpflaster ok"
        case .almostAll:   return "Fast alles ok"
        }
    }
}

extension CompanionStatus {
    var displayName: String {
        switch self {
        case .alwaysAlone: return "Immer alleine"
        case .sometimes:   return "Manchmal in Begleitung"
        case .usually:     return "Meistens in Begleitung"
        }
    }
}
