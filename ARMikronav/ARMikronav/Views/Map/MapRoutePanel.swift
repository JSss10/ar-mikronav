// MapRoutePanel.swift
// ARMikronav
//
// Bottom-Panel während der Navigation in der Kartenansicht: Zielname,
// Restzeit/-distanz und Stop-Button. Darunter eine Zeile mit der Anzahl
// Barrieren auf der Route – Tippen öffnet die Listenansicht
// (RouteBarrierListSheet), damit man vorab weiss, was auf einen zukommt.
// Die Route selbst liegt als Polyline direkt auf der Hauptkarte (MapView).
// Bei Ankunft (< 10 m Restweg) wechselt die Zeile in den "Ziel erreicht"-
// Zustand mit Fertig-Button. Die RouteInfoBar wird auch vom ARRoutePanel
// verwendet, damit Karte und AR-Modus dieselbe Fortschrittsdarstellung zeigen.

import SwiftUI

struct MapRoutePanel: View {
    let route: ActiveRoute
    let progress: RouteProgress?
    var maneuver: RouteManeuver? = nil
    /// Barrieren im Korridor der aktiven Route (für die Zähler-Zeile).
    var barrierCount: Int = 0
    /// Davon fürs eigene Profil kritisch (shouldWarn).
    var criticalCount: Int = 0
    /// Öffnet die Barrieren-Liste; nil blendet die Zeile aus.
    var onShowBarriers: (() -> Void)? = nil
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RouteInfoBar(route: route, progress: progress, maneuver: maneuver, onStop: onStop)

            if let onShowBarriers {
                Divider()
                    .padding(.vertical, 10)
                barrierRow(action: onShowBarriers)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 6)
    }

    /// Zeile "X Barrieren auf der Route" mit Warnfarbe, sobald mindestens
    /// eine Barriere fürs Profil kritisch ist.
    private func barrierRow(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: barrierCount == 0 ? "checkmark.circle" : "exclamationmark.triangle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        barrierCount == 0
                            ? AppColor.Status.openIcon
                            : (criticalCount > 0 ? AppColor.Status.blockedIcon : AppColor.Status.limitedIcon)
                    )

                Text(barrierRowText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel("\(barrierRowText), Liste öffnen")
    }

    private var barrierRowText: String {
        if barrierCount == 0 {
            return "Keine bekannten Barrieren auf der Route"
        }
        let base = barrierCount == 1
            ? "1 Barriere auf der Route"
            : "\(barrierCount) Barrieren auf der Route"
        guard criticalCount > 0 else { return base }
        return "\(base) · \(criticalCount) kritisch"
    }
}

/// Infozeile einer aktiven Route: Richtungspfeil mit Abbiege-Anweisung
/// (geradeaus/links/rechts), Zielname, Restzeit/-distanz und Stop-Button,
/// mit "Ziel erreicht"-Zustand bei Ankunft. Bei der Fussgänger-Fallback-
/// Route (kein Rollstuhl-Routing verfügbar) erscheint ein Warnhinweis.
struct RouteInfoBar: View {
    let route: ActiveRoute
    let progress: RouteProgress?
    var maneuver: RouteManeuver? = nil
    let onStop: () -> Void

    private var hasArrived: Bool {
        progress?.hasArrived ?? false
    }

    private var routeIcon: String {
        if hasArrived { return "checkmark.circle.fill" }
        if let maneuver { return maneuver.direction.symbolName }
        return route.kind == .wheelchair ? "figure.roll" : "figure.walk"
    }

    private var headlineText: String {
        if hasArrived { return "Ziel erreicht" }
        return maneuver?.instruction ?? route.destinationName
    }

    private var subheadlineText: String {
        if hasArrived { return route.destinationName }
        guard maneuver != nil else { return progressText }
        return "\(route.destinationName) · \(progressText)"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Abbiege-Symbol prominent im Akzentkreis (Apple-Maps-Manier),
            // damit «wo man durch muss» sofort erfassbar ist.
            ZStack {
                Circle()
                    .fill(hasArrived ? AppColor.Status.openFill : AppColor.accentPrimary)
                    .frame(width: 48, height: 48)
                Image(systemName: routeIcon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(hasArrived ? AppColor.Status.openIcon : AppColor.onAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(headlineText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(subheadlineText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .monospacedDigit()
                if !hasArrived, route.kind == .walkingFallback {
                    Label(
                        "Fussgängerroute – Barrieren nicht berücksichtigt",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(AppColor.Status.limitedText)
                }
            }

            Spacer(minLength: 8)

            Button(action: onStop) {
                Text(hasArrived ? "Fertig" : "Stopp")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.onAccent)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(AppColor.accentPrimary, in: Capsule())
            }
            .accessibilityLabel(hasArrived ? "Navigation abschliessen" : "Navigation beenden")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Formatierung

    private var progressText: String {
        let distance = progress?.remainingDistanceM ?? route.totalDistanceM
        let time = progress?.remainingTimeS ?? route.expectedTravelTimeS
        return "\(minutesText(time)) · \(distanceText(distance))"
    }

    private func minutesText(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int((seconds / 60).rounded(.up)))
        return "\(minutes) min"
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(max(0, Int(meters.rounded()))) m"
    }

    private var accessibilitySummary: String {
        if hasArrived {
            return "Ziel erreicht: \(route.destinationName)"
        }
        var summary = "Navigation zu \(route.destinationName), noch \(progressText)"
        if let maneuver {
            summary = "\(maneuver.instruction). \(summary)"
        }
        if route.kind == .walkingFallback {
            summary += ". Achtung: Fussgängerroute, Barrieren nicht berücksichtigt"
        }
        return summary
    }
}