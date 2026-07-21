// AppMotion.swift
// ARMikronav
//
// Zentrale Animations-Tokens gemäss Styleguide (§07 Bewegung).
// Bewegung ist gezielt und funktional: sie lenkt Aufmerksamkeit, bestätigt
// Eingaben und schafft räumliche Orientierung – nie Dauerschleifen.
// Jede Animation respektiert «Bewegung reduzieren» (WCAG 2.3.3): dann
// bleibt nur ein sanftes Ein-/Ausblenden ohne Versatz oder Skalierung.

import SwiftUI

enum AppMotion {

    /// Standard-Feder für Zustandswechsel (Auswahl, Fortschritt, Layout).
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)

    /// Schnelle Feder für direktes Touch-Feedback (Buttons, Zeilen).
    static let press = Animation.spring(response: 0.28, dampingFraction: 0.7)

    /// Auftritt von Inhalten (Karten, Listen) beim Erscheinen eines Screens.
    static let entrance = Animation.spring(response: 0.55, dampingFraction: 0.9)

    /// Reines Ein-/Ausblenden – die einzige Bewegung bei «Bewegung reduzieren».
    static let fade = Animation.easeOut(duration: 0.25)
}

// MARK: - Sanfter Auftritt (Fade + leichter Versatz)

/// Blendet Inhalte beim ersten Erscheinen sanft ein. Ohne «Bewegung
/// reduzieren» gleiten sie zusätzlich 14 pt nach oben; mit der Einstellung
/// bleibt nur das Einblenden. Über `delay` lassen sich Abschnitte gestaffelt
/// aufbauen (z. B. 0 / 0.05 / 0.1 s).
private struct AppEntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let delay: Double
    @State private var isShown = false

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : 14)
            .onAppear {
                guard !isShown else { return }
                let animation = reduceMotion
                    ? AppMotion.fade.delay(delay * 0.5)
                    : AppMotion.entrance.delay(delay)
                withAnimation(animation) { isShown = true }
            }
    }
}

extension View {
    /// Gestaffelter, sanfter Auftritt beim Erscheinen (Reduce-Motion-sicher).
    func appEntrance(delay: Double = 0) -> some View {
        modifier(AppEntranceModifier(delay: delay))
    }
}

// MARK: - Druck-Feedback für Listenzeilen und Karten

/// Button-Stil für tappbare Zeilen/Karten: hebt die Fläche beim Drücken
/// dezent hervor und skaliert minimal (99 %). Bei «Bewegung reduzieren»
/// bleibt nur die Hervorhebung – keine Skalierung.
struct PressableRowStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                AppColor.accentPrimary
                    .opacity(configuration.isPressed ? 0.08 : 0)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.99 : 1)
            .animation(AppMotion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableRowStyle {
    /// Tappbare Zeile/Karte mit dezentem Druck-Feedback.
    static var appRow: PressableRowStyle { PressableRowStyle() }
}
