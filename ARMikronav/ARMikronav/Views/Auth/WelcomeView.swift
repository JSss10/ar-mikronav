// WelcomeView.swift
// ARMikronav
//
// Welcome / Sign in / Sign up Auswahl

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Logo + Titel
                VStack(spacing: AppMetrics.Space.m) {
                    Image(systemName: "figure.roll")
                        .font(.system(size: 80))
                        .foregroundColor(AppColor.accentPrimary)

                    Text("AR-Mikronavigation")
                        .font(AppTypography.largeTitle)
                        .foregroundColor(AppColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Barrieren erkennen, bevor du dort ankommst.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Buttons
                VStack(spacing: AppMetrics.Touch.spacing + 4) {
                    NavigationLink {
                        IntroCarouselView()
                    } label: {
                        Text("Registrieren")
                    }
                    .buttonStyle(.appPrimary)

                    NavigationLink {
                        SignInView()
                    } label: {
                        Text("Anmelden")
                    }
                    .buttonStyle(.appSecondary)

                    // Apple Sign-in Stub (kommt später)
                    Button {
                        // TODO: Apple Sign-in implementieren (braucht Apple Developer Account)
                    } label: {
                        Label("Mit Apple anmelden", systemImage: "apple.logo")
                    }
                    .buttonStyle(.appQuiet(fullWidth: true))
                    .disabled(true)
                    .opacity(0.38)
                }
                .padding(.horizontal, AppMetrics.Space.l)
                .padding(.bottom, AppMetrics.Space.xxl)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthService.shared)
}