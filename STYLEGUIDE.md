# Styleguide v1.0 — AR-Mikronavigation

**Projekt:** AR-gestützte Mikronavigation für Rollstuhlnutzende
**Plattform:** iOS 17+ (Swift/SwiftUI) · Design-Frame: iPhone 17, 402 × 874 pt
**Konformitätsziel:** WCAG 2.2, Stufe AAA
**Stand:** Konsolidiert aus der Design-System-Implementierung (`ARMikronav/DesignSystem/`)

> Alle Werte in diesem Dokument entsprechen der umgesetzten Codebasis.
> Komponenten referenzieren ausschliesslich Tokens (`AppColor`, `AppTypography`,
> `AppMetrics`), nie Hex-Werte direkt.

---

## §01 Grundprinzipien

1. **Token-first:** Farben, Masse und Schriften existieren nur als benannte
   Tokens mit Light-/Dark-Variante. Kein Hex-Wert im Komponentencode.
2. **P2 — Farbe trägt nie allein Information:** Jeder Barriere-Status ist
   vierfach codiert: **Farbe + Form + Symbol + Text**. Die Semantik bleibt auch
   in Graustufen und bei Farbfehlsichtigkeit eindeutig.
3. **Fokus ist Teil der Komponente:** Der Fokusindikator (3-pt-Ring) ist in
   jede Komponente eingebaut, kein nachträglicher Zusatz (WCAG 2.4.13 AAA).
4. **Dynamic Type verlustfrei:** Alle Schriften laufen über die
   SwiftUI-Text-Styles und skalieren bis zur grössten Accessibility-Stufe (AX5).
5. **Aktionen benennen:** Buttons benennen immer die Aktion
   («Route starten»), nie generisch («OK»).
6. **Dark Mode ohne reines Schwarz:** Der dunkelste Hintergrund ist #141019.

---

## §02 Farbsystem

Leitfarbe ist Violett. Jedes Token liegt als Colorset mit Light-/Dark-Variante
in `Assets.xcassets` (siehe §08).

### §2.1 Violett-Palette (Referenzstufen)

| Stufe | Hex     | Token                  |
| ----- | ------- | ---------------------- |
| 50    | #F5F3FF | `AppColor.Violet.v50`  |
| 100   | #EDE9FE | `AppColor.Violet.v100` |
| 300   | #C4B5FD | `AppColor.Violet.v300` |
| 500   | #8B5CF6 | `AppColor.Violet.v500` |
| 600   | #7C3AED | `AppColor.Violet.v600` |
| 700   | #6D28D9 | `AppColor.Violet.v700` |
| 800   | #5B21B6 | `AppColor.Violet.v800` |
| 900   | #4C1D95 | `AppColor.Violet.v900` |
| 950   | #2E1065 | `AppColor.Violet.v950` |

### §2.2 Semantische Tokens

Kontrastangaben beziehen sich auf den jeweiligen Hintergrund im Light Mode
(AAA-Ziel: Text ≥ 7:1, grafische Elemente ≥ 3:1).

| Token               | Light    | Dark     | Verwendung                                  |
| ------------------- | -------- | -------- | ------------------------------------------- |
| `BackgroundPrimary` | #FFFFFF  | #141019  | App-Hintergrund (Dark: nie reines Schwarz)  |
| `SurfaceRaised`     | #FAF9FC  | #1E1830  | Karten, Sheets, angehobene Flächen          |
| `TextPrimary`       | #1A1523 (17,9:1) | #F4F1FA | Fliesstext, Titel                  |
| `TextSecondary`     | #524A5E (8,4:1)  | #B3ACC4 | Metadaten, Hinweise                |
| `AccentPrimary`     | #5B21B6 (9,0:1)  | #C4B5FD | Buttons, Links, aktive Zustände    |
| `AccentPressed`     | #4C1D95 (10,9:1) | #DDD6FE | Gedrückte Zustände                 |
| `OnAccent`          | #FFFFFF  | #2E1065  | Text/Icon auf AccentPrimary                 |
| `FocusRing`         | #6D28D9 (7,1:1)  | #C4B5FD | Fokusindikator                     |
| `ScrimAR`           | #2E1065  | #2E1065  | AR-Label-Hintergrund (≥ 93 % Deckkraft)     |
| `BorderFunctional`  | #8E8699  | #8A80A3  | Eingabefelder, funktionale Ränder (≥ 3:1)   |
| `BorderDecorative`  | #DDD8E4  | #3D3552  | Dekorative Trennlinien ohne Funktionsinfo   |

`AccentColor` (Asset) ist auf `AccentPrimary` gesetzt, damit `.accentColor`/
`.tint`-Aufrufe automatisch die Leitfarbe übernehmen.

### §2.3 Status-Semantik (Barriere-Codierung)

Vierfach codiert (P2). Grundformen folgen etablierten Konventionen
(Achteck = Stopp). Textfarbe erreicht AAA auf der zugehörigen Fläche;
Icon-Farben erreichen ≥ 3:1 Grafikkontrast.

| Status | Bedeutung | Form | SF Symbol | Text (L/D) | Fläche (L/D) | Icon (L/D) |
| ------ | --------- | ---- | --------- | ---------- | ------------ | ---------- |
| **Zugänglich** | «Zugänglich für dein Profil» | Kreis | `checkmark.circle.fill` | #14532D / #BBF7D0 | #DCFCE7 / #14532D | #15803D (beide) |
| **Eingeschränkt** | «Eingeschränkt zugänglich» | Dreieck | `exclamationmark.triangle.fill` | #78350F / #FDE68A | #FEF3C7 / #78350F | #B45309 (beide) |
| **Barriere** | «Nicht zugänglich» | Achteck | `xmark.octagon.fill` | #7F1D1D / #FEE2E2 | #FEE2E2 / #7F1D1D | #DC2626 (beide) |
| **Unbekannt** | «Zugänglichkeit unbekannt» | Kreis | `questionmark.circle.fill` | `TextSecondary` | `SurfaceRaised` | `TextSecondary` |

Die Zuordnung hängt an `POIAccessStatus` (`Models/POI.swift`) über
`tint`, `textColor`, `fillColor`, `symbolName`.

---

## §03 Typografie

Systemschrift **SF Pro** über die SwiftUI-Text-Styles → Dynamic Type bis AX5.
Die pt-Werte sind Referenzwerte bei Standard-Textgrösse (Grösse/Zeilenhöhe).

| Stil          | Referenz | Gewicht  | Verwendung                              |
| ------------- | -------- | -------- | --------------------------------------- |
| Large Title   | 34/41    | Bold     | Screen-Titel                            |
| Title 1       | 28/34    | Bold     | Abschnittstitel                         |
| Title 2       | 22/28    | Semibold | Karten-Titel                            |
| Headline      | 17/22    | Semibold | Hervorgehobene Zeile, Button-Label      |
| Body          | 17/26    | Regular  | Fliesstext (Zeilenhöhe 1,5×, WCAG 1.4.8)|
| Callout       | 16/24    | Regular  | Sekundäre Hinweise                      |
| Subheadline   | 15/22    | Regular  | Kleinste Stufe für essenzielle Inhalte  |
| Footnote      | 13/18    | Regular  | Nur ergänzend, nie essenziell           |
| Mono          | 15, SF Mono | Regular | Messwerte, Codes                      |

Fliesstext verwendet `Text.bodyStyle()` (Body + `TextPrimary` + 1,5-fache
Zeilenhöhe).

---

## §04 Komponenten

### §4.1 Buttons

Alle Buttons: Höhe min. 56 pt, Eckenradius 14 pt (continuous), Label in
Headline, horizontales Padding 24 pt. Fokusring gemäss §6.2.

| Stil | API | Fläche | Text | Gedrückt |
| ---- | --- | ------ | ---- | -------- |
| **Primär** | `.buttonStyle(.appPrimary)` | `AccentPrimary` | `OnAccent` | `AccentPressed` (Violett 900) |
| **Sekundär** | `.appSecondary` | transparent, 2-pt-Umriss `AccentPrimary` | `AccentPrimary` | Fläche `AccentPrimary` 10 % |
| **Quiet** | `.appQuiet` | Violett 100 (getönt) | `AccentPrimary` | Fläche 70 % Deckkraft |

Primär- und Sekundärbuttons sind standardmässig volle Breite, Quiet-Buttons
nur inhaltsbreit (`fullWidth:` steuerbar).

### §4.2 StatusBadge

Kapselform: SF Symbol (18 pt Semibold) + Label (Headline), Textfarbe
`Status*Text`, Fläche `Status*Fill`, Padding 16/9 pt. Für VoiceOver als ein
Element kombiniert, Label = volle Statusbeschreibung. Kurzform (`short:`)
für enge Layouts.

### §4.3 POIStatusIcon

Rundes Marker-Icon (Karte + AR): weisser Trägerkreis (Standard 15 pt,
Schatten 20 % Schwarz) mit Status-SF-Symbol in `tint`-Farbe. Grundform +
Symbol statt reinem Farbpunkt (P2). Für Screenreader verborgen — die
Statusinformation liefert der zugehörige Marker-Text.

### Eckenradien

| Element | Radius |
| ------- | ------ |
| Chip    | 6 pt   |
| Eingabefeld | 12 pt |
| Button  | 14 pt  |
| Karte (Card) | 16 pt |
| Sheet   | 18 pt  |

---

## §05 AR-Overlays

- Weltverankerte Labels unterschreiten **nie 17 pt** auf dem Display.
- Label-Hintergrund: Scrim `ScrimAR` (#2E1065) mit **≥ 93 % Deckkraft**;
  im Draussen-Modus 100 %.
- Helle Kontur um den Scrim: 1,5 pt.
- Kritische AR-Aktionen: Touch-Ziel 72 pt (§6.1).

---

## §06 Interaktion

### §6.1 Touch-Ziele (WCAG 2.5.5 AAA)

| Kontext | Grösse |
| ------- | ------ |
| Minimum für alle interaktiven Ziele | 44 pt |
| Primäraktionen, Navigationsentscheide | 56 pt |
| Kritische Aktionen im AR-Modus (in Bewegung) | 72 pt |
| Mindestabstand zwischen benachbarten Zielen | 8 pt |

### §6.2 Fokusindikator (WCAG 2.4.13 AAA)

3-pt-Ring in `FocusRing`, 2–3 pt Abstand zwischen Element und Ring.

### Abstände (4-pt-Raster)

| Token | Wert |
| ----- | ---- |
| xs    | 4 pt |
| s     | 8 pt |
| m     | 16 pt |
| l     | 24 pt |
| xl    | 32 pt |
| xxl   | 40 pt |

---

## §08 Design-Tokens (Implementierung)

| Ebene | Ort |
| ----- | --- |
| Farb-Colorsets (Light/Dark) | `ARMikronav/Assets.xcassets/*.colorset` |
| Farb-API | `DesignSystem/AppColor.swift` (`AppColor.*`, `AppColor.Status.*`, `AppColor.Violet.*`) |
| Typografie | `DesignSystem/AppTypography.swift` |
| Masse/Radien/Touch | `DesignSystem/AppMetrics.swift` (`Touch`, `Radius`, `Space`, `Focus`, `AR`) |
| Button-Stile | `DesignSystem/Components/AppButtonStyles.swift` |
| Status-Komponenten | `DesignSystem/Components/StatusBadge.swift`, `POIStatusIcon.swift` |
| Status-Semantik | `Models/POI.swift` (`POIAccessStatus`) |

Regeln:

1. Neue Farben entstehen als Colorset mit Light-/Dark-Variante und werden in
   `AppColor` registriert — nie als Inline-Hex.
2. Neue Masse folgen dem 4-pt-Raster und werden in `AppMetrics` ergänzt.
3. Kontraste neuer Kombinationen werden gegen AAA geprüft (Text ≥ 7:1,
   grafische Elemente / UI-Komponenten ≥ 3:1).
