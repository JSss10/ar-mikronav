# Commit Convention

Dieses Projekt verwendet [Conventional Commits](https://www.conventionalcommits.org/de/v1.0.0/).

## Format

```
<type>(<scope>): <beschreibung>
```

## Types

| Type       | Beschreibung        | Beispiel                                    |
| ---------- | ------------------- | ------------------------------------------- |
| `feat`     | Neues Feature       | `feat(ar): add barrier overlay rendering`   |
| `fix`      | Bugfix              | `fix(map): correct marker position offset`  |
| `docs`     | Dokumentation       | `docs(readme): add setup instructions`      |
| `style`    | Formatierung        | `style(views): apply SwiftLint formatting`  |
| `refactor` | Code-Umbau          | `refactor(services): split SupabaseService` |
| `test`     | Tests               | `test(barrier-logic): add shouldWarn tests` |
| `chore`    | Build, Deps, Config | `chore(deps): update supabase-swift`        |
| `perf`     | Performance         | `perf(map): lazy-load barrier markers`      |

## Scopes

| Scope           | Bereich                         |
| --------------- | ------------------------------- |
| `onboarding`    | Screens 1.1–1.6                 |
| `auth`          | Sign-up, Sign-in, Supabase Auth |
| `map`           | Kartenansicht, MapKit, Marker   |
| `ar`            | ARKit, RealityKit, AR-Overlays  |
| `barrier-logic` | shouldWarn(), Schwellenwerte    |
| `profile`       | UserProfile, Einstellungen      |
| `data`          | Supabase, OSM-Import, ginto API |
| `ui`            | Shared UI-Komponenten           |
| `a11y`          | Barrierefreiheit der App        |
| `poi`           | POI-Suche, Filter, Detail       |

## Branch-Strategie

```
main              ← Stabile Releases / Abgabeversion
├── develop       ← Aktuelle Entwicklung
│   ├── feat/onboarding-flow
│   ├── feat/map-view
│   ├── feat/ar-session
│   └── fix/barrier-logic-scewo
```

## Initiale Commits

```bash
git add .gitignore
git commit -m "chore: add .gitignore for Xcode/Swift project"

git add README.md COMMITS.md
git commit -m "docs: add README and conventional commits guide"

git add Database/
git commit -m "chore(data): add Supabase schema with PostGIS and RLS"

git add Config.example.swift
git commit -m "chore(config): add Supabase config template"

git add ARMikronav/
git commit -m "feat: add UserProfile model and shouldWarn barrier logic"

git push
git checkout -b develop
git push -u origin develop
```

## Feature-Log

### Map rotates in travel direction

```bash
git commit -m "feat(map): rotate map into travel direction when showing a route"
```

Tapping "Route anzeigen" in the POI detail used to only zoom the map onto the
route, always north-up. It now also rotates so the travel direction points up –
you can immediately see which way to go.

- `RouteService.initialBearingDegrees(of:)` derives the route's initial travel
  direction as a compass heading (stable over the first ~20 m so short GPS/
  geometry segments at the start don't skew it), plus `bearingDegrees(from:to:)`
  as a general heading helper.
- `MapView.fitCamera` uses a rotated `MapCamera` (heading = travel direction)
  instead of a north-up `MKMapRect`; center and distance come from the route's
  bounding box so the whole route stays visible even when rotated. Applies to
  the alternative route as well.
- Tests for the initial heading and the heading helper.

```bash
git commit -m "feat(map): keep map rotated to travel direction during navigation"
```

The map used to rotate only once when the route was shown. During active
navigation it now follows the location and keeps rotating with the route – it
turns right when the route turns right, left when it turns left – so the map
orientation matches the instruction in the route panel.

- `RouteService.travelBearingDegrees(of:at:)`: travel direction at the current
  location – projects the location onto the nearest route segment and takes the
  direction ~18 m ahead (smooths the rotation across bends).
- `MapView.followCamera`: on every location update during navigation it sets a
  rotated `MapCamera` (heading = travel direction), centered slightly ahead so
  the position sits in the lower third and more of the route ahead is visible.
- Tests for the travel direction before/after right and left turns.
```
