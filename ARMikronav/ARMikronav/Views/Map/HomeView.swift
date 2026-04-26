// HomeView.swift
// ARMikronav
//
// Haupt-Container für authentifizierte User. Zeigt aktuell die Karte;
// AR-Modus, Settings-Eingang und Filter folgen in späteren Tasks (M3, A5, S1).

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    let profile: UserProfile

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MapView(profile: profile)
                .ignoresSafeArea(edges: .bottom)

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
    }
}