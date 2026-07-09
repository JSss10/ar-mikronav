// POI.swift
// ARMikronav
//
// Point of Interest aus poi_accessibility (ginto + OSM Import).
// Geliefert von der RPC pois_within_radius mit explizitem lat/lng und Distanz.

import Foundation
import SwiftUI
import Supabase

struct POI: Decodable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let latitude: Double
    let longitude: Double
    let address: String?
    let wheelchairAccessible: String?
    let accessibilityDetails: [String: AnyJSON]?
    let source: String
    let distanceM: Double

    enum CodingKeys: String, CodingKey {
        case id, name, category, latitude, longitude, address, source
        case wheelchairAccessible = "wheelchair_accessible"
        case accessibilityDetails = "accessibility_details"
        case distanceM = "distance_m"
    }

    var accessStatus: POIAccessStatus {
        switch wheelchairAccessible?.lowercased() {
        case "yes":     return .accessible
        case "limited": return .limited
        case "no":      return .notAccessible
        default:        return .unknown
        }
    }
}

enum POIAccessStatus {
    case accessible
    case limited
    case notAccessible
    case unknown

    var label: String {
        switch self {
        case .accessible:    return "Zugänglich für dein Profil"
        case .limited:       return "Eingeschränkt zugänglich"
        case .notAccessible: return "Nicht zugänglich"
        case .unknown:       return "Zugänglichkeit unbekannt"
        }
    }

    var shortLabel: String {
        switch self {
        case .accessible:    return "zugänglich für dich"
        case .limited:       return "eingeschränkt"
        case .notAccessible: return "nicht zugänglich"
        case .unknown:       return "unbekannt"
        }
    }

    /// Signalfarbe für grafische Elemente (Marker, Icons). Styleguide §2.3:
    /// die gesättigten Status-Icon-Farben (>= 3:1 Grafikkontrast).
    var tint: Color {
        switch self {
        case .accessible:    return AppColor.Status.openIcon
        case .limited:       return AppColor.Status.limitedIcon
        case .notAccessible: return AppColor.Status.blockedIcon
        case .unknown:       return AppColor.textSecondary
        }
    }

    /// Textfarbe auf der zugehörigen Statusfläche (`fillColor`). AAA auf der Fläche.
    var textColor: Color {
        switch self {
        case .accessible:    return AppColor.Status.openText
        case .limited:       return AppColor.Status.limitedText
        case .notAccessible: return AppColor.Status.blockedText
        case .unknown:       return AppColor.textSecondary
        }
    }

    /// Getönte Hintergrundfläche des Status-Badges.
    var fillColor: Color {
        switch self {
        case .accessible:    return AppColor.Status.openFill
        case .limited:       return AppColor.Status.limitedFill
        case .notAccessible: return AppColor.Status.blockedFill
        case .unknown:       return AppColor.surfaceRaised
        }
    }

    /// SF-Symbol mit Grundform + Symbol (P2: Farbe trägt nie allein Information).
    /// Kreis+Häkchen · Dreieck+Ausrufezeichen · Achteck+Kreuz.
    var symbolName: String {
        switch self {
        case .accessible:    return "checkmark.circle.fill"
        case .limited:       return "exclamationmark.triangle.fill"
        case .notAccessible: return "xmark.octagon.fill"
        case .unknown:       return "questionmark.circle.fill"
        }
    }
}