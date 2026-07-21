// HomeView.swift
// ARMikronav
//
// Haupt-Container für authentifizierte User. Hält das MapViewModel und die
// schwebende Bottom-Navigation (AppTabBar) mit Home, Karte, Kamera (AR),
// gespeicherten Orten und Profil. Filter- und Barrieren-State bleiben beim
// Wechsel erhalten, weil Karte und AR auf dem gleichen ViewModel laufen.
// Profil-Binding fliesst von hier weiter in den Profil-Tab und das
// SettingsSheet (S1).

import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var profile: UserProfile

    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationService = LocationService.shared
    @State private var mode: DisplayMode = .map
    @State private var selectedTab: AppTab = .home
    @State private var showingSettings = false
    @State private var showingSignOutConfirm = false

    enum DisplayMode {
        case map, ar
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

    // Tabs mit eigener schwebender Bottom-Navigation (AppTabBar). Der
    // Kamera-Tab schaltet direkt in den AR-Vollbildmodus; der zuletzt aktive
    // Tab bleibt ausgewählt und ist nach dem Schliessen wieder sichtbar.
    private var tabContent: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeDashboardView(
                        onOpenMap: { selectedTab = .map },
                        onShowSettings: { showingSettings = true }
                    )
                case .map:
                    mapContent
                case .camera:
                    // Nie ausgewählt – Kamera öffnet den AR-Vollbildmodus.
                    mapContent
                case .saved:
                    NavigationStack {
                        SavedPlacesListView()
                    }
                case .profile:
                    SettingsView(profile: $profile, showsDoneButton: false)
                }
            }
            // Inhalte halten unten Platz für die schwebende Leiste frei;
            // Scroll-Inhalte laufen darunter durch.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AppTabBar.clearance)
            }

            AppTabBar(selection: tabSelection)
        }
    }

    /// Fängt den Kamera-Tab ab: statt Tab-Wechsel startet der AR-Modus.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == .camera {
                    mode = .ar
                } else {
                    selectedTab = newTab
                }
            }
        )
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

    // Der frühere AR-FAB entfällt: Der AR-Modus ist über den Kamera-Tab
    // der AppTabBar erreichbar.
    private var mapContent: some View {
        MapView(profile: profile, viewModel: viewModel, onStartARRoute: startARRoute)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .topTrailing) { topRightStack }
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

}