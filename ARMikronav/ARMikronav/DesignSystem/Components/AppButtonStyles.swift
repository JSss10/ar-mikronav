// AppButtonStyles.swift
// ARMikronav
//
// Button-Stile gemäss Styleguide v1.0 (§4.1 Buttons), Formsprache v2:
// Kapselform (Kreis-Enden), sanfter Akzentverlauf und federndes
// Druck-Feedback. Primäraktionen bleiben 56 pt hoch; alle Kontraste
// stammen weiterhin aus den geprüften Farbtokens (AccentPrimary >= 7:1).
// Bei «Bewegung reduzieren» entfällt die Skalierung, der Zustandswechsel
// bleibt über die Farbe erkennbar.

import SwiftUI

/// Primäraktion: gefüllte Kapsel mit Akzentverlauf und weichem Glow.
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(AppColor.onAccent)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: AppMetrics.Touch.primary)
            .padding(.horizontal, AppMetrics.Space.l)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [AppColor.accentPressed, AppColor.accentPressed]
                        : [AppColor.accentPrimary, AppColor.accentPressed],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .contentShape(Capsule())
            .shadow(
                color: isEnabled
                    ? AppColor.accentPrimary.opacity(
                        configuration.isPressed
                            ? AppMetrics.Shadow.buttonOpacity * 0.5
                            : AppMetrics.Shadow.buttonOpacity
                    )
                    : .clear,
                radius: AppMetrics.Shadow.buttonRadius,
                y: AppMetrics.Shadow.buttonY
            )
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(AppMotion.press, value: configuration.isPressed)
    }
}

/// Sekundäraktion: Kapsel-Umriss in Akzentfarbe auf transparentem Grund.
struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(AppColor.accentPrimary)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: AppMetrics.Touch.primary)
            .padding(.horizontal, AppMetrics.Space.l)
            .background(
                configuration.isPressed ? AppColor.accentPrimary.opacity(0.1) : Color.clear
            )
            .overlay(
                Capsule().strokeBorder(AppColor.accentPrimary, lineWidth: 2)
            )
            .clipShape(Capsule())
            .contentShape(Capsule())
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(AppMotion.press, value: configuration.isPressed)
    }
}

/// Zurückhaltende Aktion: getönte Kapsel (Violett 100), Text in Akzentfarbe.
struct QuietButtonStyle: ButtonStyle {
    var fullWidth: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(AppColor.accentPrimary)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: AppMetrics.Touch.primary)
            .padding(.horizontal, AppMetrics.Space.l)
            .background(
                AppColor.Violet.v100.opacity(configuration.isPressed ? 0.7 : 1)
            )
            .clipShape(Capsule())
            .contentShape(Capsule())
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(AppMotion.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Primäraktion (gefüllt). Benennt immer die Aktion («Route starten», nie «OK»).
    static var appPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func appPrimary(fullWidth: Bool) -> PrimaryButtonStyle { PrimaryButtonStyle(fullWidth: fullWidth) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// Sekundäraktion (Umriss).
    static var appSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    static func appSecondary(fullWidth: Bool) -> SecondaryButtonStyle { SecondaryButtonStyle(fullWidth: fullWidth) }
}

extension ButtonStyle where Self == QuietButtonStyle {
    /// Zurückhaltende Aktion (getönt).
    static var appQuiet: QuietButtonStyle { QuietButtonStyle() }
    static func appQuiet(fullWidth: Bool) -> QuietButtonStyle { QuietButtonStyle(fullWidth: fullWidth) }
}
