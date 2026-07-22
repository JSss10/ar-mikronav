// POICategory.swift
// ARMikronav
//
// Mapping zwischen den deutschen Kategorie-Chips der UI, den englischen
// Kategorie-Keys aus poi_accessibility (ginto/OSM, z.B. "coffee",
// "public_toilets") und passenden SF-Symbols für die kreisförmigen
// POI-Marker in Karte und AR-Modus.

import Foundation

enum POICategory {
    /// Chip-Label (deutsch) → Suchbegriff für die RPC `pois_within_radius`.
    /// Die RPC matcht per ILIKE über Name UND Kategorie; die Kategorien in
    /// der DB sind englisch, deshalb würden die deutschen Labels sonst
    /// (fast) nichts finden.
    private static let chipSearchTerms: [String: String] = [
        "Café": "coffee",
        "Restaurant": "restaurant",
        "WC": "toilet",        // matcht "public_toilets"
        "Apotheke": "pharmacy",
        "Haltestelle": "bus_stop"
    ]

    /// Kategorie-Chips (deutsche Labels) in fixer Reihenfolge für die Filter
    /// in der Suche (SearchSheet) und im AR-Modus.
    static let chipLabels = ["Café", "Restaurant", "WC", "Apotheke", "Haltestelle"]

    /// SF-Symbol für einen Kategorie-Chip (deutsches Label), z. B. für die
    /// Filter-Chips in der Suche.
    static func symbol(forChip chip: String) -> String {
        symbol(for: searchTerm(forChip: chip))
    }

    /// Case-insensitiv, damit auch Freitext-Eingaben wie "wc" oder "café"
    /// auf den DB-Kategorie-Begriff gemappt werden.
    static func searchTerm(forChip chip: String) -> String {
        let normalized = chip.trimmingCharacters(in: .whitespaces)
        let match = chipSearchTerms.first {
            $0.key.caseInsensitiveCompare(normalized) == .orderedSame
        }
        return match?.value ?? normalized
    }

    /// SF-Symbol zur DB-Kategorie (contains-Matching, damit Varianten wie
    /// "gastronomy_other" oder "shopping_other" mit abgedeckt sind).
    static func symbol(for category: String?) -> String {
        let key = category?.lowercased() ?? ""
        switch true {
        case key.contains("restaurant"), key.contains("gastronomy"):
            return "fork.knife"
        case key.contains("fastfood"):
            return "takeoutbag.and.cup.and.straw.fill"
        case key.contains("coffee"), key.contains("cafe"), key.contains("bakery"):
            return "cup.and.saucer.fill"
        case key.contains("bar"), key.contains("club"):
            return "wineglass.fill"
        case key.contains("toilet"):
            return "toilet.fill"
        case key.contains("pharmacy"):
            return "cross.case.fill"
        case key.contains("hotel"):
            return "bed.double.fill"
        case key.contains("bus"), key.contains("station"), key.contains("stop"):
            return "bus.fill"
        case key.contains("parking"):
            return "parkingsign"
        case key.contains("grocery"), key.contains("market"):
            return "basket.fill"
        case key.contains("museum"), key.contains("landmark"),
             key.contains("administration"), key.contains("community"):
            return "building.columns.fill"
        case key.contains("theatre"), key.contains("cinema"), key.contains("concert"):
            return "theatermasks.fill"
        case key.contains("hairdresser"):
            return "scissors"
        case key.contains("bank"):
            return "banknote.fill"
        case key.contains("education"):
            return "graduationcap.fill"
        case key.contains("fashion"), key.contains("shopping"),
             key.contains("bookstore"), key.contains("services"):
            return "bag.fill"
        case key.contains("bath"):
            return "drop.fill"
        case key.contains("park"):
            return "tree.fill"
        default:
            return "mappin"
        }
    }
}

extension POI {
    /// Kategorie-Icon für die kreisförmigen Marker.
    var categorySymbol: String {
        POICategory.symbol(for: category)
    }
}