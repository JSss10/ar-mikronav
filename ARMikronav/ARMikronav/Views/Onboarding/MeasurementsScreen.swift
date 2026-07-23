// Screen13_Measurements.swift
// ARMikronav – Onboarding Schritt 3/6: Masse (Breite, Höhe, Gewicht).
// Werte werden mit Defaults aus WheelchairType vorbelegt und sind frei
// zwischen 0 und unendlich eingebbar.

import SwiftUI

struct Screen13_Measurements: View {
    @Binding var draft: DraftProfile

    var body: some View {
        VStack(spacing: 20) {
            OnboardingNumberField(
                icon: "arrow.left.and.right",
                label: "Rollstuhlbreite",
                value: intBinding(\.widthCm),
                unit: "cm",
                hint: "Gesamtbreite inklusive Räder und Antriebe"
            )

            OnboardingNumberField(
                icon: "arrow.up.and.down",
                label: "Gesamthöhe (sitzend)",
                value: intBinding(\.heightCm),
                unit: "cm",
                hint: "Höchster Punkt im Sitzen, inklusive Handyhalterung, falls diese übersteht – wichtig für niedrige Durchgänge und Überdachungen"
            )

            OnboardingNumberField(
                icon: "iphone.gen3",
                label: "Handyhalterung",
                value: intBinding(\.phoneMountHeightCm),
                unit: "cm",
                hint: "Höhe der Halterung ab Boden, falls dein iPhone am Rollstuhl montiert ist – bestimmt die Kamerahöhe im AR-Modus. 0 = keine Halterung (iPhone in der Hand)"
            )

            OnboardingNumberField(
                icon: "arrow.up.to.line.compact",
                label: "Sitzhöhe",
                value: intBinding(\.seatHeightCm),
                unit: "cm",
                hint: "Oberkante Sitzfläche inkl. Kissen ab Boden – damit der AR-Pfad aus deiner Perspektive exakt auf dem Boden liegt"
            )

            OnboardingNumberField(
                icon: "arrow.forward.to.line",
                label: "Gesamtlänge",
                value: intBinding(\.lengthCm),
                unit: "cm",
                hint: "Inklusive Fussstützen – relevant für Lifte und Wendeflächen"
            )

            OnboardingNumberField(
                icon: "scalemass",
                label: "Gesamtgewicht",
                value: intBinding(\.weightKg),
                unit: "kg",
                hint: "Rollstuhl + Person (relevant für Rampen und Lifte)"
            )
        }
    }

    /// Verbindet ein Int-Feld des Drafts mit dem Double-basierten Eingabefeld.
    private func intBinding(_ keyPath: WritableKeyPath<DraftProfile, Int>) -> Binding<Double> {
        Binding(
            get: { Double(draft[keyPath: keyPath]) },
            set: { draft[keyPath: keyPath] = Int($0.rounded()) }
        )
    }
}