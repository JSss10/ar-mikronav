// ARMikronavApp.swift
// ARMikronav
//
// App Entry Point - Routes basierend auf Auth-State

import SwiftUI
import Supabase
import Auth

@main
struct ARMikronavApp: App {
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isLoading {
                SplashView()
            } else if authService.isAuthenticated {
                AuthenticatedRootView()
            } else {
                WelcomeView()
            }
        }
    }
}

// Routet nach erfolgreichem Login: Onboarding wenn noch kein Profil, sonst Home.
struct AuthenticatedRootView: View {
    @EnvironmentObject var authService: AuthService
    @State private var profileState: ProfileState = .loading

    enum ProfileState {
        case loading
        case needsOnboarding
        case ready(UserProfile)
    }

    var body: some View {
        Group {
            switch profileState {
            case .loading:
                SplashView()
            case .needsOnboarding:
                OnboardingCoordinator {
                    Task { await checkProfile() }
                }
            case .ready(let profile):
                HomeView(profile: profile)
            }
        }
        .task {
            await checkProfile()
        }
    }

    private func checkProfile() async {
        do {
            if let profile = try await ProfileService.shared.loadProfile() {
                profileState = .ready(profile)
            } else {
                profileState = .needsOnboarding
            }
        } catch {
            profileState = .needsOnboarding
        }
    }
}