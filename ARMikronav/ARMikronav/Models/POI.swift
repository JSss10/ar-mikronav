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

    var tint: Color {
        switch self {
        case .accessible:    return .green
        case .limited:       return .orange
        case .notAccessible: return .red
        case .unknown:       return .gray
        }
    }
}
