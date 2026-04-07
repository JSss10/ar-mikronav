// WelcomeView.swift
// ARMikronav
//
// Screen 0.2 - Welcome / Sign in / Sign up Auswahl

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Logo + Titel
                VStack(spacing: 16) {
                    Image(systemName: "figure.roll")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                    
                    Text("AR-Mikronavigation")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text("Persönliche Barrieren-Warnung\nim Kamerabild")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Konto erstellen")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    
                    NavigationLink {
                        SignInView()
                    } label: {
                        Text("Anmelden")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Apple Sign-in Stub (kommt später)
                    Button {
                        // TODO: Apple Sign-in implementieren (braucht Apple Developer Account)
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Mit Apple anmelden")
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .disabled(true)
                    .opacity(0.5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthService.shared)
}
