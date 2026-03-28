# AR-Mikronavigation

> AR-gestützte Mikronavigation für Rollstuhlnutzende – iOS-Prototyp zur Entscheidungsunterstützung in barrierekritischen urbanen Situationen.

## Über das Projekt

Diese iOS-App visualisiert situative Barrieren (Stufen, Steigungen, Engstellen, Oberflächen) in Echtzeit über ARKit und zeigt die Zugänglichkeit von Points of Interest im Kamerabild an. Die Barrierenbewertung ist **personalisiert** – die App warnt nur, wenn eine Barriere für das individuelle Profil der Nutzer:in nicht passierbar ist.

**Bachelorarbeit** | SAE Institut Zürich | BSc Web Development  
**Studentin:** Jessica Schneiter  
**Supervisor:** Julian Heeb (ginto)  
**Zeitraum:** 21.02.2026 – 14.08.2026

## Features

- 🗺️ **Kartenansicht** – MapKit mit personalisierten Barrieren-Markern und POI-Filtern
- 📱 **AR-Ansicht** – Barrieren und zugängliche Orte als AR-Overlays im Kamerabild
- 👤 **Persönliche Barrierenlogik** – Binäre Bewertung basierend auf Rollstuhltyp, Masse und Fähigkeiten
- ♿ **5 Rollstuhltypen** – Manuell, e-motion, Joystick, Elektro, Treppensteiger (Scewo Bro)
- 📍 **Testgebiet** – Altstadt Zürich (Niederdorf/Oberdorf)

## Tech Stack

| Komponente   | Technologie                                     |
| ------------ | ----------------------------------------------- |
| iOS App      | Swift / SwiftUI                                 |
| AR           | ARKit + RealityKit (ARGeoTrackingConfiguration) |
| Karten       | MapKit                                          |
| Backend      | Supabase (PostgreSQL + PostGIS)                 |
| Auth         | Supabase Auth (E-Mail, Google, Apple Sign-in)   |
| Datenquellen | OSM/Overpass API, ginto API (GraphQL), Wheelmap |
| Design       | Figma (iPhone 17, 402×874pt)                    |

## Projektstruktur

```
ARMikronav/
├── App/
│   └── ARMikronavApp.swift
├── Models/
│   ├── UserProfile.swift
│   ├── Barrier.swift
│   ├── BarrierWarning.swift
│   └── POIAccessibility.swift
├── Services/
│   ├── SupabaseService.swift
│   ├── AuthService.swift
│   ├── BarrierService.swift
│   ├── LocationService.swift
│   └── BarrierLogic.swift
├── Views/
│   ├── Auth/
│   ├── Onboarding/
│   ├── Map/
│   ├── AR/
│   ├── Settings/
│   └── Shared/
├── Resources/
│   ├── Assets.xcassets/
│   └── Info.plist
└── Tests/
    ├── BarrierLogicTests.swift
    └── UserProfileTests.swift
```

## Setup

### Voraussetzungen

- Xcode 16+ (iOS 17 SDK)
- iPhone 12+ (ARKit ARGeoTracking)
- Supabase Account
- macOS Sequoia+

### Installation

```bash
git clone https://github.com/JSss10/ar-micronav-app.git
cd ar-micronav-app
open ARMikronav.xcodeproj
cp Config.example.swift Config.swift
# → Supabase URL und Anon Key eintragen
```

## Datenquellen

| Quelle        | Typ                                              | Lizenz                    |
| ------------- | ------------------------------------------------ | ------------------------- |
| OpenStreetMap | Barrieren (kerb, incline, surface, width, steps) | ODbL                      |
| ginto API     | POI-Zugänglichkeit (GraphQL, 440 POIs Altstadt)  | Nutzungsbedingungen ginto |
| Wheelmap      | POI wheelchair=yes/limited/no                    | CC-BY-SA                  |

## Commit Convention

Dieses Projekt verwendet [Conventional Commits](https://www.conventionalcommits.org/). Siehe [COMMITS.md](COMMITS.md).

## Lizenz

© 2026 Jessica Schneiter, SAE Institut Zürich. Bachelorarbeit, nicht für kommerzielle Nutzung.  
OpenStreetMap: © OpenStreetMap Contributors, ODbL | ginto: © ginto guide AG
