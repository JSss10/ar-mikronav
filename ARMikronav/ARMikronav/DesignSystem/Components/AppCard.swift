// AppCard.swift
// ARMikronav
//
// Geteilte Flächen-Bausteine der Formsprache v2: Karten mit durchgehend
// gerundeten Ecken (continuous corners) und weichem Schatten statt hartem
// Rand, kreisrunde Icon-Discs und der Eingabefeld-Stil. Alle Farben kommen
// aus den geprüften Tokens (AppColor), alle Masse aus AppMetrics.

import SwiftUI

// MARK: - Karte

/// Standard-Kartenfläche: SurfaceRaised, Radius 20 (continuous), hauchdünne
/// Trennlinie plus weicher Schatten für Tiefe ohne harte Kanten.
private struct AppCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppColor.surfaceRaised,
                in: RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous)
            )
            // Inhalt (z. B. gedrückte Zeilen-Hervorhebung) bleibt innerhalb
            // der gerundeten Ecken.
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.Radius.card, style: .continuous)
                    .strokeBorder(
                        AppColor.borderDecorative.opacity(colorScheme == .dark ? 1 : 0.55),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0 : AppMetrics.Shadow.cardOpacity),
                radius: AppMetrics.Shadow.cardRadius,
                y: AppMetrics.Shadow.cardY
            )
    }
}

extension View {
    /// Hebt den Inhalt als Karte an (Fläche, Radius, weicher Schatten).
    func appCard(padding: CGFloat = AppMetrics.Space.m) -> some View {
        modifier(AppCardModifier(padding: padding))
    }
}

// MARK: - Icon-Disc

/// Kreisrunde Icon-Fläche – der Grundbaustein der Formsprache: Symbol auf
/// getöntem oder gefülltem Kreis, skaliert über `size`.
struct IconDisc: View {
    let systemName: String
    /// Kreisfüllung (z. B. Akzent oder Statusfarbe).
    var fill: Color = AppColor.accentPrimary
    /// Symbolfarbe auf der Füllung.
    var symbolColor: Color = AppColor.onAccent
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
            Image(systemName: systemName)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(symbolColor)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Sanft getönte Variante der Icon-Disc (Violett 100 + Akzentsymbol).
extension IconDisc {
    static func tinted(_ systemName: String, size: CGFloat = 40) -> IconDisc {
        IconDisc(
            systemName: systemName,
            fill: AppColor.Violet.v100,
            symbolColor: AppColor.accentPrimary,
            size: size
        )
    }
}

// MARK: - Eingabefelder

/// Eingabefeld-Fläche: Radius 14 (continuous), SurfaceRaised-Füllung und
/// funktionaler Rand; bei Fokus ein 2,5-pt-Ring in der Fokusfarbe.
private struct AppFieldModifier: ViewModifier {
    var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .font(AppTypography.body)
            .padding(.horizontal, AppMetrics.Space.m)
            .frame(minHeight: 52)
            .background(
                AppColor.surfaceRaised,
                in: RoundedRectangle(cornerRadius: AppMetrics.Radius.field, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.Radius.field, style: .continuous)
                    .strokeBorder(
                        isFocused ? AppColor.focusRing : AppColor.borderFunctional,
                        lineWidth: isFocused ? 2.5 : 1.25
                    )
            )
            .animation(AppMotion.fade, value: isFocused)
    }
}

extension View {
    /// Styleguide-Eingabefeld; `isFocused` aus einem `@FocusState` speisen.
    func appField(isFocused: Bool = false) -> some View {
        modifier(AppFieldModifier(isFocused: isFocused))
    }
}
