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

    init() {
        // UNUserNotificationCenter-Delegate früh setzen, damit Barriere-
        // Warnungen als System-Mitteilungen zugestellt und Taps darauf
        // verarbeitet werden können.
        BarrierNotificationService.activate()
    }

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

// Routet nach erfolgreichem Login:
// Consent → Onboarding (wenn kein Profil) → Notification-Permission (einmalig) →
// Home. Hält das Profil separat, damit es als Binding an HomeView
// und weiter an Settings gereicht werden kann (S1).
struct AuthenticatedRootView: View {
    @EnvironmentObject var authService: AuthService
    @State private var profile: UserProfile?
    @State private var loadState: LoadState = .loading
    @State private var hasConsent = ConsentStore.hasConsent
    @State private var notificationAsked = NotificationPermissionStore.wasAsked

    enum LoadState {
        case loading
        case needsOnboarding
        case ready
    }

    var body: some View {
        Group {
            if !hasConsent {
                NavigationStack {
                    ConsentView {
                        hasConsent = true
                    }
                }
            } else {
                switch loadState {
                case .loading:
                    SplashView()
                case .needsOnboarding:
                    OnboardingCoordinator {
                        Task { await checkProfile() }
                    }
                case .ready:
                    if !notificationAsked {
                        NotificationPermissionView {
                            notificationAsked = true
                        }
                    } else {
                        HomeView(profile: profileBinding)
                    }
                }
            }
        }
        .task {
            await checkProfile()
        }
    }

    private var profileBinding: Binding<UserProfile> {
        Binding(
            get: { profile ?? .placeholder },
            set: { newValue in
                profile = newValue
                Task { try? await ProfileService.shared.saveProfile(newValue) }
            }
        )
    }

    private func checkProfile() async {
        loadState = .loading
        do {
            if let loaded = try await ProfileService.shared.loadProfile() {
                profile = loaded
                loadState = .ready
            } else {
                loadState = .needsOnboarding
            }
        } catch {
            loadState = .needsOnboarding
        }
    }
}

private extension UserProfile {
    static var placeholder: UserProfile {
        UserProfile(
            id: UUID(),
            mobilityCategory: .wheelchair,
            wheelchairType: .manual,
            widthCm: 65,
            heightCm: 130,
            weightKg: 75,
            maxIncline: 6,
            maxCurbHeight: 3,
            surfaceTolerance: .fineCobble,
            companionStatus: .alwaysAlone,
            companionTodayOverride: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}