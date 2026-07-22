// HomeView.swift
// ARMikronav
//
// Haupt-Container für authentifizierte User. Hält das MapViewModel und stellt
// die Tab-Navigation bereit: Start (Homescreen), Karte, AR, Gespeicherte Orte
// und Profil. Karte und AR laufen im Vollbild – dort wird die Tab-Leiste
// ausgeblendet, die Navigation ist also nur auf Start, Gespeicherte Orte und
// Profil sichtbar. Filter- und Barrieren-State bleiben beim Tab-Wechsel
// erhalten, weil Karte und AR auf dem gleichen ViewModel laufen. Das
// Profil-Binding fliesst von hier weiter ins Profil (Settings/Abmelden, S1).

import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var profile: UserProfile

    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationService = LocationService.shared
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, map, ar, saved, profile
    }

    var body: some View {
        Group {
            if needsLocationPermission {
                LocationPermissionView(locationService: locationService)
            } else {
                tabView
            }
        }
    }

    // Fünf Tabs; Karte und AR blenden die Tab-Leiste aus (Vollbild), damit die
    // Navigation nur auf Start, Gespeicherte Orte und Profil erscheint.
    private var tabView: some View {
        TabView(selection: $selectedTab) {
            HomeDashboardView(
                onOpenMap: { selectedTab = .map },
                onOpenProfile: { selectedTab = .profile }
            )
            .tabItem {
                Label("Start", systemImage: "house.fill")
            }
            .tag(Tab.home)

            mapContent
                .toolbar(.hidden, for: .tabBar)
                .tabItem {
                    Label("Karte", systemImage: "map.fill")
                }
                .tag(Tab.map)

            arContent
                .toolbar(.hidden, for: .tabBar)
                .tabItem {
                    Label("AR", systemImage: "arkit")
                }
                .tag(Tab.ar)

            NavigationStack {
                SavedPlacesListView()
            }
            .tabItem {
                Label("Orte", systemImage: "bookmark.fill")
            }
            .tag(Tab.saved)

            SettingsView(profile: $profile)
                .environmentObject(authService)
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
    }

    private var needsLocationPermission: Bool {
        switch locationService.authorizationStatus {
        case .notDetermined, .denied, .restricted:
            return true
        case .authorizedWhenInUse, .authorizedAlways:
            return false
        @unknown default:
            return true
        }
    }

    private var mapContent: some View {
        MapView(profile: profile, viewModel: viewModel, onStartARRoute: startARRoute)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .topTrailing) { homeButton }
            .overlay(alignment: .bottomTrailing) { arFAB }
    }

    // AR erst aufbauen, wenn der Tab aktiv ist – so starten Kamera und
    // AR-Session (samt zugehöriger Services) nicht im Hintergrund.
    @ViewBuilder
    private var arContent: some View {
        if selectedTab == .ar {
            ARModeView(
                profile: profile,
                viewModel: viewModel,
                originCoordinate: locationService.currentLocation?.coordinate,
                onClose: { selectedTab = .map }
            )
        } else {
            Color.black.ignoresSafeArea()
        }
    }

    /// "Route in AR starten" aus dem POI-Detail: Route berechnen,
    /// bei Erfolg in den AR-Tab wechseln.
    private func startARRoute(to poi: POI) {
        Task {
            if await viewModel.startNavigation(to: poi, profile: profile) {
                selectedTab = .ar
            }
        }
    }

    // Zurück zum Start – die Tab-Leiste ist auf der Vollbild-Karte ausgeblendet,
    // dieser Button ist der Weg zurück zur Navigation.
    private var homeButton: some View {
        Button {
            selectedTab = .home
        } label: {
            Image(systemName: "house.fill")
                .font(.title3)
                // Gleiche Höhe wie die Suchleiste (MapView).
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())
        }
        .padding()
        .accessibilityLabel("Zurück zum Start")
    }

    private var arFAB: some View {
        Button {
            selectedTab = .ar
        } label: {
            Image(systemName: "arkit")
                .font(.title)
                .foregroundStyle(.white)
                .padding(18)
                .background(Color.accentColor, in: Circle())
                .shadow(radius: 4)
        }
        .padding()
        .accessibilityLabel("In AR ansehen")
    }
}
