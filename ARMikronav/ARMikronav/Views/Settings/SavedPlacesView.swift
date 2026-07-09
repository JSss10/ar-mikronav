// SavedPlacesView.swift
// ARMikronav
//
// Wireframe 4.4 – gespeicherte Orte mit Swipe-to-delete, Empty-State und
// "+ Ort hinzufügen" (4.4a: eigener Ort über Karten-Pin).

import SwiftUI
import MapKit
import CoreLocation

struct SavedPlacesView: View {
    @State private var places: [SavedPlace] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddPlace = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if places.isEmpty {
                emptyState
            } else {
                placeList
            }
        }
        .navigationTitle("Gespeicherte Orte")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                showingAddPlace = true
            } label: {
                Label("Ort hinzufügen", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(.bar)
        }
        .sheet(isPresented: $showingAddPlace) {
            AddPlaceView {
                Task { await reload() }
            }
        }
        .task { await reload() }
    }

    // MARK: - Components

    private var placeList: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            ForEach(places) { place in
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name ?? "Unbenannter Ort")
                        .font(.body.weight(.semibold))
                    Text(subtitle(for: place))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in
                delete(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bookmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Du hast noch keine Orte gespeichert.")
                .font(.subheadline.weight(.semibold))
            Text("Tippe auf das Lesezeichen-Icon, um Orte zu speichern.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func subtitle(for place: SavedPlace) -> String {
        let typeLabel = place.placeType == "custom" ? "eigene Notiz" : "POI"
        let date = place.createdAt.formatted(date: .numeric, time: .omitted)
        return "\(typeLabel) · gespeichert \(date)"
    }

    // MARK: - Actions

    private func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            places = try await SavedPlacesService.shared.list()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { places[$0] }
        places.remove(atOffsets: offsets)
        Task {
            for place in toDelete {
                try? await SavedPlacesService.shared.delete(id: place.id)
            }
        }
    }
}

// MARK: - 4.4a Ort hinzufügen

struct AddPlaceView: View {
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationService.shared

    @State private var name = ""
    @State private var note = ""
    @State private var centerCoordinate = CLLocationCoordinate2D(
        latitude: (AppConfig.testAreaMinLat + AppConfig.testAreaMaxLat) / 2,
        longitude: (AppConfig.testAreaMinLng + AppConfig.testAreaMaxLng) / 2
    )
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Map(initialPosition: .region(initialRegion)) {
                    UserAnnotation()
                }
                .onMapCameraChange { context in
                    centerCoordinate = context.region.center
                }
                .ignoresSafeArea(edges: .bottom)

                // Fester Pin in der Kartenmitte
                VStack(spacing: 0) {
                    Image(systemName: "mappin")
                        .font(.system(size: 36))
                        .foregroundStyle(.red)
                        .shadow(radius: 2)
                    Spacer().frame(height: 36)
                }
                .accessibilityHidden(true)

                VStack {
                    Text("Karte bewegen, um den Ort zu markieren")
                        .font(.footnote.weight(.medium))
                        .padding(10)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 12)
                    Spacer()
                }
            }
            .safeAreaInset(edge: .bottom) {
                form
            }
            .navigationTitle("Ort hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private var initialRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: locationService.currentLocation?.coordinate ?? centerCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name (Pflicht)".uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("z.B. gute Rampe Rathaus", text: $name)
                .textFieldStyle(.roundedBorder)

            Text("Notiz (optional)".uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("…", text: $note)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                save()
            } label: {
                if isSaving {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Speichern")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
        }
        .padding()
        .background(.bar)
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        // Notiz wird an den Namen angehängt – saved_places hat keine eigene Spalte.
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        let fullName = trimmedNote.isEmpty ? name : "\(name) – \(trimmedNote)"

        Task {
            do {
                try await SavedPlacesService.shared.saveCustomPlace(
                    name: fullName,
                    coordinate: centerCoordinate
                )
                isSaving = false
                onSaved()
                dismiss()
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
