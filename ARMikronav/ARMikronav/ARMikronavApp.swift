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
                // TODO: Wird später durch HomeView ersetzt
                AuthenticatedPlaceholderView()
            } else {
                WelcomeView()
            }
        }
    }
}

// Temporärer Placeholder bis HomeView/Onboarding fertig ist
struct AuthenticatedPlaceholderView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Eingeloggt!")
                .font(.title)
                .bold()
            
            if let email = authService.currentUser?.email {
                Text(email)
                    .foregroundColor(.secondary)
            }
            
            Text("Onboarding kommt morgen")
                .foregroundColor(.secondary)
                .padding(.top)
            
            Button("Abmelden") {
                Task {
                    try? await authService.signOut()
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 40)
        }
        .padding()
    }
}