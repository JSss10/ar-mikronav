// POIDetailSheet.swift
// ARMikronav
//
// POI-Detail als Bottom-Sheet: Name, Kategorie, Adresse, Distanz, Fotos
// (ginto), Zugänglichkeits-Status fürs Profil, ginto-Bewertung für den
// eigenen Rollstuhltyp, Detail-Werte aus accessibility_details, Quellen und
// Aktionen (Route in AR starten, Ort speichern, Route auf der Karte anzeigen).

import SwiftUI
import MapKit
import Supabase

struct POIDetailSheet: View {
    let poi: POI
    /// Profil des Users – bestimmt, welche ginto-Bewertung angezeigt wird
    /// (nur der eigene Rollstuhltyp, nicht alle Profile).
    let profile: UserProfile
    /// Startet die AR-Navigation zu diesem POI. Ohne Callback bleibt der
    /// Button deaktiviert (Kontext ohne AR-Zugang).
    var onStartARRoute: ((POI) -> Void)? = nil
    /// Berechnet die Route in-App und zeigt sie auf der Karte. Ohne Callback
    /// öffnet "Route anzeigen" als Fallback Apple Maps.
    var onShowRoute: ((POI) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var saveState: SaveState = .idle

    enum SaveState {
        case idle, saving, saved, failed
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                photoCarousel
                statusBadge
                eurokeyHint
                ratingsCard
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

    // MARK: - Eurokey (Quick Win): nur wenn die POI-Daten Eurokey erwähnen.
    @ViewBuilder
    private var eurokeyHint: some View {
        if mentionsEurokey {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(profile.hasEurokey ? .green : .orange)
                Text(profile.hasEurokey
                     ? "Mit deinem Eurokey zugänglich"
                     : "Eurokey erforderlich")
                    .font(.subheadline.weight(.medium))
            }
            .padding(10)
            .background(
                (profile.hasEurokey ? Color.green : Color.orange).opacity(0.1),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
    }

    private var mentionsEurokey: Bool {
        guard let details = poi.accessibilityDetails else { return false }
        for (key, value) in details {
            if key.lowercased().contains("eurokey") { return true }
            if case .string(let s) = value, s.lowercased().contains("eurokey") { return true }
        }
        return false
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
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

            if let subtitle = headerSubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Kategorie (deutscher ginto-Name) und Adresse, soweit vorhanden.
    private var headerSubtitle: String? {
        let parts = [poi.categoryDisplayName, poi.address].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Horizontales Foto-Karussell (ginto-Bilder des Ortes).
    @ViewBuilder
    private var photoCarousel: some View {
        let urls = poi.imageURLs
        if !urls.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(urls, id: \.absoluteString) { url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            default:
                                ProgressView()
                            }
                        }
                        .frame(width: 220, height: 150)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .accessibilityLabel("Fotos von \(poi.name)")
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: poi.accessStatus.symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(poi.accessStatus.tint)
            Text(poi.accessStatus.label)
                .font(.body.weight(.medium))
        }
        .accessibilityElement(children: .combine)
    }

    /// ginto-Bewertung für den eigenen Rollstuhltyp mit Einstufung und
    /// erfüllten Kriterien in Prozent. Bewertungen anderer Profile werden
    /// bewusst nicht angezeigt.
    @ViewBuilder
    private var ratingsCard: some View {
        if let rating = poi.gintoRating(for: profile.wheelchairType) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Zugänglichkeit im Detail")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: rating.status.symbolName)
                        .foregroundStyle(rating.status.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rating.profileLabel)
                        Text("Dein Rollstuhltyp")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(rating.gradeLabel)
                            .foregroundStyle(.secondary)
                        if let percent = rating.conformancePercent {
                            Text("\(Int(percent)) % der Kriterien erfüllt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .accessibilityElement(children: .combine)
            }
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

            if let gintoURL = poi.gintoURL {
                Text("·")
                Link("Auf ginto ansehen", destination: gintoURL)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var arButton: some View {
        Button {
            guard let onStartARRoute else { return }
            dismiss()
            onStartARRoute(poi)
        } label: {
            Label("Route in AR starten", systemImage: "arkit")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(onStartARRoute == nil)
        .accessibilityHint(
            onStartARRoute == nil
                ? "Noch nicht verfügbar"
                : "Berechnet die rollstuhlgerechte Route und zeigt sie im Kamerabild"
        )
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
                if let onShowRoute {
                    dismiss()
                    onShowRoute(poi)
                } else {
                    openInMaps()
                }
            } label: {
                Label("Route anzeigen", systemImage: "arrow.triangle.turn.up.right.diamond")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityHint(
                onShowRoute == nil
                    ? "Öffnet die Route in Apple Karten"
                    : "Berechnet die rollstuhlgerechte Route und zeigt sie auf der Karte"
            )
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