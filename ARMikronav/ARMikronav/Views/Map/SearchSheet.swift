// SearchSheet.swift
// ARMikronav
//
// Screen 2.1a – POI-Suche mit Ergebnisliste (sortiert nach Distanz, mit
// Zugänglichkeits-Status) und letzten Suchen. Tap auf ein Ergebnis schließt
// das Sheet und übergibt den POI an die Karte (zentrieren + Detail).

import SwiftUI

struct SearchSheet: View {
    @ObservedObject var viewModel: MapViewModel
    let onSelect: (POI) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [POI] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding()

                if isSearching {
                    ProgressView()
                        .padding(.top, 40)
                    Spacer()
                } else if hasSearched && results.isEmpty {
                    emptyState
                    Spacer()
                } else if !results.isEmpty {
                    resultsList
                } else {
                    recentSearches
                    Spacer()
                }
            }
            .navigationTitle("Suche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
        .onAppear { searchFieldFocused = true }
    }

    // MARK: - Components

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Café suchen…", text: $query)
                .focused($searchFieldFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit { runSearch(query) }
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                    hasSearched = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Suche löschen")
            }
        }
        .padding(10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }

    private var resultsList: some View {
        List {
            Section {
                ForEach(results) { poi in
                    Button {
                        onSelect(poi)
                        dismiss()
                    } label: {
                        resultRow(poi)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("\(results.count) Ergebnisse · nach Entfernung")
            }
        }
        .listStyle(.plain)
    }

    private func resultRow(_ poi: POI) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(poi.name)
                    .font(.body.weight(.semibold))
                if let address = poi.address {
                    Text(address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(poi.accessStatus.tint)
                        .frame(width: 10, height: 10)
                    Text(poi.accessStatus.shortLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(Int(poi.distanceM)) m")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }

    private var recentSearches: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.recentSearches.isEmpty {
                Text("Letzte Suchen".uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                FlowChips(items: viewModel.recentSearches) { term in
                    query = term
                    runSearch(term)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Keine zugänglichen Orte für \u{201E}\(query)\u{201C} in der Nähe gefunden.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 40)
    }

    // MARK: - Actions

    private func runSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        hasSearched = false
        Task {
            results = await viewModel.searchPOIs(query: trimmed)
            isSearching = false
            hasSearched = true
        }
    }
}

/// Einfache horizontale Chip-Reihe für die letzten Suchen.
private struct FlowChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button {
                        onTap(item)
                    } label: {
                        Text(item)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(.systemGray6), in: Capsule())
                            .overlay(Capsule().stroke(Color(.systemGray3), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
