// MapView.swift
// ARMikronav
//
// Kartenansicht (iOS 17 Map API). Default-Region: Altstadt Zürich.
// Zeigt Userposition (UserAnnotation) und Barrieren als Annotations.

import SwiftUI
import Combine
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationService = LocationService.shared

    @State private var cameraPosition: MapCameraPosition = .region(MapView.defaultRegion)
    @State private var selectedBarrier: Barrier?

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

            ForEach(viewModel.barriers) { barrier in
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
        .overlay(alignment: .top) {
            if viewModel.isLoading {
                ProgressView()
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 8)
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
            BarrierDetailSheet(barrier: barrier, profile: nil)
        }
    }
}