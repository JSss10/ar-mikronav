// HomeView.swift
// ARMikronav
//
// Haupt-Container für authentifizierte User. Hält das MapViewModel und schaltet
// zwischen Karten- und AR-Modus (Task A5). Filter- und Barrieren-State bleiben
// beim Wechsel erhalten, weil beide Modi auf dem gleichen ViewModel laufen.

import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    let profile: UserProfile

    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationService = LocationService.shared
    @State private var mode: DisplayMode = .map

    enum DisplayMode {
        case map, ar
    }

    var body: some View {
        Group {
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

    private var mapContent: some View {
        MapView(profile: profile, viewModel: viewModel)
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .topTrailing) { signOutButton }
            .overlay(alignment: .bottomTrailing) { arFAB }
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
        .padding()
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