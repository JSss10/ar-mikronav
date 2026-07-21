// HomeView.swift
// ARMikronav
//
// Haupt-Container für authentifizierte User. Hält das MapViewModel und schaltet
// zwischen Start- (Homescreen), Karten- und AR-Modus (Task A5). Filter- und
// Barrieren-State bleiben beim Wechsel erhalten, weil Karte und AR auf dem
// gleichen ViewModel laufen. Profil-Binding fließt von hier weiter ins
// SettingsSheet (S1).

import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var profile: UserProfile

    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationService = LocationService.shared
    @State private var mode: DisplayMode = .map
    @State private var selectedTab: Tab = .home
    @State private var showingSettings = false
    @State private var showingSignOutConfirm = false

    enum DisplayMode {
        case map, ar
    }

    enum Tab {
        case home, map
    }

    var body: some View {
        Group {
            if needsLocationPermission {
                LocationPermissionView(locationService: locationService)
            } else {
                switch mode {
                case .map:
                    tabContent
                case .ar:
                    ARModeView(
                        profile: profile,
                        viewModel: viewModel,
                        originCoordinate: locationService.currentLocation?.coordinate,
                        onClose: { mode = .map }
                    )
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(profile: $profile)
                .environmentObject(authService)
        }
    }

    // Start-Tab (Homescreen) und Karten-Tab; der AR-Modus bleibt Vollbild
    // ausserhalb der TabView.
    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            HomeDashboardView(
                onOpenMap: { selectedTab = .map },
                onShowSettings: { showingSettings = true }
            )
            .tabItem {
                Label("Start", systemImage: "house.fill")
            }
            .tag(Tab.home)

            mapContent
                .tabItem {
                    Label("Karte", systemImage: "map.fill")
                }
                .tag(Tab.map)
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
            .overlay(alignment: .topTrailing) { topRightStack }
            .overlay(alignment: .bottomTrailing) { arFAB }
    }

    /// "Route in AR starten" aus dem POI-Detail: Route berechnen,
    /// bei Erfolg in den AR-Modus wechseln.
    private func startARRoute(to poi: POI) {
        Task {
            if await viewModel.startNavigation(to: poi, profile: profile) {
                mode = .ar
            }
        }
    }

    private var topRightStack: some View {
        HStack(spacing: 8) {
            settingsButton
            signOutButton
        }
        .padding()
    }

    private var settingsButton: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                // Gleiche Höhe wie die Suchleiste (MapView).
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Einstellungen")
    }

    // Destruktive Aktion mit Bestätigungs-Action-Sheet.
    private var signOutButton: some View {
        Button {
            showingSignOutConfirm = true
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.title3)
                // Gleiche Höhe wie die Suchleiste (MapView).
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Abmelden")
        .confirmationDialog(
            "Du kannst dich jederzeit wieder anmelden. Dein Profil bleibt gespeichert.",
            isPresented: $showingSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Abmelden", role: .destructive) {
                Task { try? await authService.signOut() }
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private var arFAB: some View {
        Button {
            mode = .ar
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