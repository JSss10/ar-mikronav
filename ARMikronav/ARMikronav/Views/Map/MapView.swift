// MapView.swift
// ARMikronav
//
// Kartenansicht (iOS 17 Map API, Wireframe 2.1). Default-Region: Altstadt Zürich.
// Zeigt Userposition, profilrelevante Barrieren, POI-Marker mit
// Zugänglichkeits-Status, Suchleiste (2.1a), Kategorie-Chips und ein
// Annäherungs-Banner (2.1b). MapViewModel kommt vom HomeView, damit Filter-
// und Barrieren-State mit dem AR-Modus geteilt werden.

import SwiftUI
import Combine
import MapKit
import CoreLocation

struct MapView: View {
    let profile: UserProfile
    @ObservedObject var viewModel: MapViewModel

    @StateObject private var locationService = LocationService.shared
    @StateObject private var connectivity = ConnectivityMonitor.shared
    @StateObject private var proximityService = ProximityWarningService()

    @State private var cameraPosition: MapCameraPosition = .region(MapView.defaultRegion)
    @State private var selectedBarrier: Barrier?
    @State private var selectedPOI: POI?
    @State private var showingFilter = false
    @State private var showingSearch = false

    private static let categoryChips = ["Café", "WC", "Restaurant", "Apotheke", "Haltestelle"]

    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: (AppConfig.testAreaMinLat + AppConfig.testAreaMaxLat) / 2,
            longitude: (AppConfig.testAreaMinLng + AppConfig.testAreaMaxLng) / 2
        ),
        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
    )

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(viewModel.filteredBarriers) { barrier in
                Annotation(
                    barrier.type.localizedLabel,
                    coordinate: CLLocationCoordinate2D(
                        latitude: barrier.latitude,
                        longitude: barrier.longitude
                    )
                ) {
                    BarrierAnnotation(barrier: barrier)
                        .onTapGesture { selectedBarrier = barrier }
                }
            }

            ForEach(viewModel.pois) { poi in
                Annotation(
                    poi.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude: poi.latitude,
                        longitude: poi.longitude
                    )
                ) {
                    POIMarker(status: poi.accessStatus)
                        .onTapGesture { selectedPOI = poi }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            viewModel.start()
        }
        .onReceive(locationService.$currentLocation.compactMap { $0 }.first()) { location in
            withAnimation(.easeInOut) {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                    )
                )
            }
        }
        .onReceive(locationService.$currentLocation) { _ in
            evaluateProximity()
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                searchBar
                    .padding(.leading)
                    .padding(.trailing, 116) // Platz für Settings/Abmelden (HomeView)

                if let warning = proximityService.activeWarning {
                    approachBanner(warning)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !connectivity.isOnline {
                    OfflineOverlay()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if viewModel.isLoading {
                    ProgressView()
                        .padding(8)
                        .background(.thinMaterial, in: Capsule())
                }
            }
            .padding(.top, 8)
            .animation(.easeInOut(duration: 0.25), value: connectivity.isOnline)
            .animation(.spring(duration: 0.35), value: proximityService.activeWarning?.barrier.id)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 10) {
                filterButton
                categoryChipRow
            }
            .padding(.leading)
            .padding(.bottom, 12)
        }
        .overlay {
            if showEmptyState {
                EmptyStateView { showingFilter = true }
            }
        }
        .overlay(alignment: .bottom) {
            if let error = viewModel.loadError {
                Text(error)
                    .font(.footnote)
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
        .sheet(item: $selectedBarrier) { barrier in
            BarrierDetailSheet(barrier: barrier, profile: profile)
        }
        .sheet(item: $selectedPOI) { poi in
            POIDetailSheet(poi: poi)
        }
        .sheet(isPresented: $showingFilter) {
            FilterSheet(initial: viewModel.filterState) { newFilter in
                viewModel.applyFilter(newFilter)
            }
        }
        .sheet(isPresented: $showingSearch) {
            SearchSheet(viewModel: viewModel) { poi in
                focus(on: poi)
            }
        }
    }

    // MARK: - Components

    private var searchBar: some View {
        Button {
            showingSearch = true
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Café suchen…")
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("Orte suchen")
    }

    private var filterButton: some View {
        Button {
            showingFilter = true
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.title)
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Filter")
    }

    private var categoryChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Self.categoryChips, id: \.self) { chip in
                    let isActive = viewModel.activeCategory == chip
                    Button {
                        viewModel.toggleCategory(chip)
                    } label: {
                        Text(chip)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isActive ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.thinMaterial),
                                in: Capsule()
                            )
                            .foregroundStyle(isActive ? .white : .primary)
                    }
                    .accessibilityLabel("\(chip) anzeigen")
                    .accessibilityAddTraits(isActive ? .isSelected : [])
                }
            }
            .padding(.trailing, 96) // Platz für den AR-FAB (HomeView)
        }
    }

    // Wireframe 2.1b: Banner ~30 m vor profilrelevanter Barriere.
    // Tap → Detail-Sheet (2.2), X → dismiss, auto-dismiss nach 10 s.
    private func approachBanner(_ warning: BarrierWarning) -> some View {
        Button {
            selectedBarrier = warning.barrier
            proximityService.dismissCurrent()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.square")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(warning.barrierValue) in \(Int(warning.distance)) m voraus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Tippen für Details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    proximityService.dismissCurrent()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
                .accessibilityLabel("Warnung ausblenden")
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .task(id: warning.barrier.id) {
            try? await Task.sleep(for: .seconds(10))
            proximityService.dismissCurrent()
        }
    }

    // MARK: - Helpers

    private func focus(on poi: POI) {
        withAnimation(.easeInOut) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                )
            )
        }
        selectedPOI = poi
    }

    private func evaluateProximity() {
        proximityService.evaluate(
            userLocation: locationService.currentLocation,
            barriers: viewModel.filteredBarriers,
            profile: profile
        )
    }

    private var showEmptyState: Bool {
        !viewModel.isLoading
            && viewModel.loadError == nil
            && viewModel.filteredBarriers.isEmpty
            && viewModel.pois.isEmpty
            && locationService.currentLocation != nil
    }
}

/// Tropfen-Marker für POIs mit Status-Farbe (grün/orange/rot/grau).
struct POIMarker: View {
    let status: POIAccessStatus

    var body: some View {
        ZStack {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white, status.tint)
                .shadow(radius: 2)
        }
        .accessibilityLabel(status.shortLabel)
    }
}
