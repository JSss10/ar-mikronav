// CompassView.swift
// ARMikronav
//
// Kompass-Overlay für Karten- und AR-Ansicht. Zeigt eine Kompassrose mit
// allen vier Himmelsrichtungen (N/O/S/W), die sich mit der Blickrichtung
// des Geräts dreht: Die rote Nordnadel und das „N" zeigen immer nach
// geografisch Norden, unabhängig davon, wie das iPhone gehalten wird.
// Die Blickrichtung selbst ist immer „oben" – markiert durch den festen
// Akzent-Strich am oberen Rand – und wird zusätzlich als Text unter der
// Rose angezeigt (z. B. „NO 47°"). Die Blickrichtung kommt vom
// LocationService.

import SwiftUI
import CoreLocation

struct CompassView: View {
    /// Geräteausrichtung in Grad (0 = Norden). `nil` → Kompass ist inaktiv.
    let heading: CLLocationDirection?

    private var diameter: CGFloat = 56

    init(heading: CLLocationDirection?) {
        self.heading = heading
    }

    /// Die vier Himmelsrichtungen der Rose (Winkel im Uhrzeigersinn ab Norden).
    private static let cardinals: [(label: String, angle: Double)] = [
        ("N", 0), ("O", 90), ("S", 180), ("W", 270)
    ]

    /// Kurz- und Langnamen der 8 Himmelsrichtungen (45°-Sektoren).
    private static let shortNames = ["N", "NO", "O", "SO", "S", "SW", "W", "NW"]
    private static let longNames = ["Norden", "Nordosten", "Osten", "Südosten",
                                    "Süden", "Südwesten", "Westen", "Nordwesten"]

    /// Index des 45°-Sektors, in den die Blickrichtung fällt.
    private static func sectorIndex(for heading: CLLocationDirection) -> Int {
        Int((heading / 45).rounded()) % 8
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))

                // Kompassrose dreht entgegen der Blickrichtung, damit Norden
                // ortsfest bleibt.
                rose
                    .rotationEffect(.degrees(-(heading ?? 0)))

                // Fester Blickrichtungs-Marker („Steuerstrich"): zeigt an,
                // wohin das Gerät gerade schaut – immer oben.
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 8)
                    .offset(y: -(diameter / 2) + 4)
            }
            .frame(width: diameter, height: diameter)
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)

            // Blickrichtung als Text, z. B. „NO 47°".
            if let heading {
                Text("\(Self.shortNames[Self.sectorIndex(for: heading)]) \(Int(heading.rounded()))°")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.thinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            }
        }
        .animation(.easeOut(duration: 0.2), value: heading)
        .accessibilityElement()
        .accessibilityLabel("Kompass")
        .accessibilityValue(accessibilityValue)
    }

    private var rose: some View {
        ZStack {
            // Zwischenmarken (NO/SO/SW/NW) als kleine Striche.
            ForEach([45.0, 135.0, 225.0, 315.0], id: \.self) { angle in
                Capsule()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 1.5, height: 5)
                    .offset(y: -(diameter / 2) + 7)
                    .rotationEffect(.degrees(angle))
            }

            // Nord-Nadel (rot) oben, Süd-Nadel (grau) unten.
            VStack(spacing: 0) {
                Triangle()
                    .fill(.red)
                    .frame(width: 8, height: 10)
                Triangle()
                    .fill(Color(.systemGray))
                    .frame(width: 8, height: 10)
                    .rotationEffect(.degrees(180))
            }

            // Alle vier Himmelsrichtungen am Rand; „N" rot hervorgehoben.
            ForEach(Self.cardinals, id: \.angle) { cardinal in
                Text(cardinal.label)
                    .font(.system(size: 9, weight: cardinal.angle == 0 ? .bold : .semibold))
                    .foregroundStyle(cardinal.angle == 0 ? Color.red : Color.primary)
                    .offset(y: -(diameter / 2) + 13)
                    .rotationEffect(.degrees(cardinal.angle))
            }
        }
    }

    private var accessibilityValue: String {
        guard let heading else { return "Richtung unbekannt" }
        let index = Self.sectorIndex(for: heading)
        return "Blickrichtung \(Self.longNames[index]), \(Int(heading.rounded())) Grad"
    }
}

/// Gleichschenkliges Dreieck mit Spitze oben (für die Kompassnadel).
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
