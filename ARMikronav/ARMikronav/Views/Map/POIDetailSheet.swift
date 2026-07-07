// POIDetailSheet.swift
// ARMikronav
//
// POI-Detail als Bottom-Sheet: Name, Distanz, Zugänglichkeits-
// Status fürs Profil, Detail-Werte aus accessibility_details, Quellen und
// Aktionen (AR folgt später, Ort speichern, Route via Apple Maps).

import SwiftUI
import MapKit
import Supabase

struct POIDetailSheet: View {
    let poi: POI

    @State private var saveState: SaveState = .idle

    enum SaveState {
        case idle, saving, saved, failed
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                statusBadge
                detailsCard
                sourceFooter
                arButton
                actionRow
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(poi.name)
                .font(.title2)
                .bold()
            Spacer()
            Text("\(Int(poi.distanceM)) m")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(poi.accessStatus.tint)
                .frame(width: 12, height: 12)
            Text(poi.accessStatus.label)
                .font(.body.weight(.medium))
        }
    }

    @ViewBuilder
    private var detailsCard: some View {
        if let details = poi.accessibilityDetails, !details.isEmpty {
            VStack(spacing: 0) {
                ForEach(details.keys.sorted(), id: \.self) { key in
                    if let text = displayValue(details[key]) {
                        HStack {
                            Text(displayKey(key))
                            Spacer()
                            Text(text)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 0.5),
                            alignment: .bottom
                        )
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var sourceFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
            Text("Quelle: \(poi.source.uppercased())")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var arButton: some View {
        Button {
            // AR-POI-Ansicht folgt in einer späteren Version.
        } label: {
            Label("In AR ansehen", systemImage: "arkit")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(true)
        .accessibilityHint("Noch nicht verfügbar")
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                savePlace()
            } label: {
                switch saveState {
                case .idle:
                    Label("Ort speichern", systemImage: "bookmark")
                        .frame(maxWidth: .infinity)
                case .saving:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                case .saved:
                    Label("Gespeichert", systemImage: "bookmark.fill")
                        .frame(maxWidth: .infinity)
                case .failed:
                    Label("Fehlgeschlagen", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(saveState == .saving || saveState == .saved)

            Button {
                openInMaps()
            } label: {
                Label("Route anzeigen", systemImage: "arrow.triangle.turn.up.right.diamond")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    // MARK: - Actions

    private func savePlace() {
        saveState = .saving
        Task {
            do {
                try await SavedPlacesService.shared.save(poi: poi)
                saveState = .saved
            } catch {
                saveState = .failed
            }
        }
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: poi.latitude,
            longitude: poi.longitude
        ))
        let item = MKMapItem(placemark: placemark)
        item.name = poi.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    // MARK: - Detail Formatting

    /// Bekannte ginto/OSM-Schlüssel eingedeutscht; Rest als Fallback roh.
    private func displayKey(_ key: String) -> String {
        switch key.lowercased() {
        case "door_width", "doorwidth":   return "Türbreite"
        case "entrance", "entry":         return "Eingang"
        case "wc", "toilet", "restroom":  return "WC"
        case "ramp":                      return "Rampe"
        case "elevator", "lift":          return "Aufzug"
        case "parking":                   return "Parkplatz"
        default:
            return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func displayValue(_ value: AnyJSON?) -> String? {
        switch value {
        case .string(let s): return s
        case .double(let d): return d == d.rounded() ? "\(Int(d))" : String(format: "%.1f", d)
        case .integer(let i): return "\(i)"
        case .bool(let b):   return b ? "ja" : "nein"
        default:             return nil
        }
    }
}