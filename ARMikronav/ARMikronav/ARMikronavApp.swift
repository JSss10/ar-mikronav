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
                HomeView()
            } else {
                WelcomeView()
            }
        }
    }
}