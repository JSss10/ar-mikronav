// SignInView.swift
// ARMikronav
//
// Anmeldung mit E-Mail und Passwort

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var biometricService = BiometricAuthService.shared

    @State private var email: String = ""
    @State private var password: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @State private var showResetPassword: Bool = false
    @State private var enableBiometrics: Bool = false

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Anmelden")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                
                Text("Melde dich mit deinem Konto an.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                
                // E-Mail
                VStack(alignment: .leading, spacing: 6) {
                    Text("E-Mail")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("name@beispiel.ch", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Passwort
                VStack(alignment: .leading, spacing: 6) {
                    Text("Passwort")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("••••••••", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
                
                // Passwort vergessen
                Button("Passwort vergessen?") {
                    showResetPassword = true
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .trailing)

                // Face ID für künftige Anmeldungen aktivieren
                if biometricService.isAvailable && !biometricService.isEnabled {
                    Toggle(isOn: $enableBiometrics) {
                        Text("Künftig mit \(biometricService.biometryName) anmelden")
                            .font(.subheadline)
                    }
                }

                // Error
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Sign In Button
                Button {
                    Task { await handleSignIn() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("Anmelden")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(isFormValid ? Color.accentColor : Color.gray)
                .cornerRadius(12)
                .disabled(!isFormValid || isLoading)
                .padding(.top, 8)

                // Face ID-Anmeldung (wenn zuvor aktiviert)
                if biometricService.isEnabled && biometricService.isAvailable {
                    Button {
                        Task { await handleBiometricSignIn() }
                    } label: {
                        Label("Mit \(biometricService.biometryName) anmelden",
                              systemImage: "faceid")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .disabled(isLoading)
                }

                // Alternative: Anmeldung per Einmalcode
                NavigationLink {
                    OTPLoginView()
                } label: {
                    Text("Mit E-Mail-Code anmelden")
                        .font(.subheadline)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView()
        }
    }

    private func handleSignIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
            // Erst nach erfolgreicher Anmeldung hinterlegen, damit nur
            // gültige Zugangsdaten im Keychain landen.
            if enableBiometrics {
                try? biometricService.enable(email: email, password: password)
            }
        } catch {
            errorMessage = "Anmeldung fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func handleBiometricSignIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await biometricService.signIn(using: authService)
        } catch BiometricError.cancelled {
            // Abbruch durch die Person – kein Fehler anzeigen
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Reset Password Sheet

struct ResetPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var message: String? = nil
    @State private var isError: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Wir senden dir einen Link zum Zurücksetzen deines Passworts.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("E-Mail", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(isError ? .red : .green)
                }
                
                Button {
                    Task { await handleReset() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("Reset-Link senden")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(email.isEmpty ? Color.gray : Color.accentColor)
                .cornerRadius(12)
                .disabled(email.isEmpty || isLoading)
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Passwort vergessen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schliessen") { dismiss() }
                }
            }
        }
    }
    
    private func handleReset() async {
        isLoading = true
        message = nil
        defer { isLoading = false }
        
        do {
            try await authService.resetPassword(email: email)
            message = "E-Mail gesendet. Prüfe dein Postfach."
            isError = false
        } catch {
            message = "Fehler: \(error.localizedDescription)"
            isError = true
        }
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environmentObject(AuthService.shared)
    }
}
