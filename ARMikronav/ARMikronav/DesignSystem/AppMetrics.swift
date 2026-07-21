// AppMetrics.swift
// ARMikronav
//
// Masse, Radien und Touch-Ziele gemäss Styleguide v1.0
// (§04 Komponenten, §06 Interaktion). Werte in Points (pt).

import CoreGraphics

enum AppMetrics {

    // MARK: - Touch-Ziele (§6.1)

    enum Touch {
        /// Minimum für alle interaktiven Ziele (WCAG 2.5.5 AAA).
        static let minimum: CGFloat = 44
        /// Primäraktionen und Navigationsentscheide.
        static let primary: CGFloat = 56
        /// Kritische Aktionen im AR-Modus (in Bewegung).
        static let arCritical: CGFloat = 72
        /// Mindestabstand zwischen benachbarten Zielen.
        static let spacing: CGFloat = 8
    }

    // MARK: - Eckenradien

    enum Radius {
        static let chip: CGFloat = 10
        static let field: CGFloat = 14
        /// Buttons sind Kapseln (Capsule); der Radius dient als Fallback,
        /// wo eine RoundedRectangle-Form gebraucht wird.
        static let button: CGFloat = 18
        static let card: CGFloat = 20
        static let sheet: CGFloat = 24
    }

    // MARK: - Schatten (weiche Tiefenstaffelung, kein harter Rand)

    enum Shadow {
        /// Karten: sehr weicher, tiefer Schatten.
        static let cardRadius: CGFloat = 14
        static let cardY: CGFloat = 6
        static let cardOpacity: Double = 0.06
        /// Primärbuttons: farbiger Glow in Akzentfarbe.
        static let buttonRadius: CGFloat = 12
        static let buttonY: CGFloat = 5
        static let buttonOpacity: Double = 0.28
    }

    // MARK: - Abstände (4-pt-Raster)

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    // MARK: - Fokusindikator (§4.1, WCAG 2.4.13 AAA)

    enum Focus {
        /// 3-pt-Ring.
        static let ringWidth: CGFloat = 3
        /// 2–3 pt Abstand zwischen Element und Ring.
        static let ringOffset: CGFloat = 3
    }

    // MARK: - AR-Overlays (§05)

    enum AR {
        /// Weltverankerte Labels unterschreiten nie 17 pt auf dem Display.
        static let minLabelSize: CGFloat = 17
        /// Scrim-Mindestdeckkraft (Draussen-Modus: 1.0).
        static let scrimOpacity: Double = 0.93
        /// Helle Kontur um den Scrim.
        static let scrimBorderWidth: CGFloat = 1.5
    }
}
