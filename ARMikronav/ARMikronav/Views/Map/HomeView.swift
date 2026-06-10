// HomeView.swift
// ARMikronav
//
// Haupt-Container für authentifizierte User. Hält das MapViewModel und schaltet
// zwischen Karten- und AR-Modus (Task A5). Filter- und Barrieren-State bleiben
// beim Wechsel erhalten, weil beide Modi auf dem gleichen ViewModel laufen.
// Profil-Binding fließt von hier weiter ins SettingsSheet (S1).

import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var profile: UserProfile

    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationService = LocationService.shared
    @State private var mode: DisplayMode = .map
    @State private var showingSettings = false

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
                    mapContent
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
        MapView(profile: profile, viewModel: viewModel)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .topTrailing) { topRightStack }
            .overlay(alignment: .bottomTrailing) { arFAB }
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
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Einstellungen")
    }

    private var signOutButton: some View {
        Button {
            Task { try? await authService.signOut() }
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.title3)
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Abmelden")
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
