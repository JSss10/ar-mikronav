// SignUpView.swift
// ARMikronav
//
// Registrierung mit E-Mail, Passwort, Vor- und Nachname

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSuccess: Bool = false
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == passwordConfirm
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Konto erstellen")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                
                Text("Erstelle ein Konto, um deine persönlichen Barriere-Einstellungen zu speichern.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
                
                // Vorname / Nachname
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Vorname")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Jessica", text: $firstName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.givenName)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nachname")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Schneiter", text: $lastName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.familyName)
                    }
                }
                
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
                    Text("Passwort (min. 6 Zeichen)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("••••••••", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }
                
                // Passwort bestätigen
                VStack(alignment: .leading, spacing: 6) {
                    Text("Passwort bestätigen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("••••••••", text: $passwordConfirm)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }
                
                // Error
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Sign Up Button
                Button {
                    Task { await handleSignUp() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("Konto erstellen")
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
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Erfolgreich registriert", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Bitte bestätige deine E-Mail-Adresse, um dein Konto zu aktivieren.")
        }
    }
    
    private func handleSignUp() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await authService.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            // Wenn Email-Bestätigung deaktiviert ist, ist man direkt eingeloggt
            // Sonst muss man die E-Mail bestätigen
            if !authService.isAuthenticated {
                showSuccess = true
            }
        } catch {
            errorMessage = "Registrierung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthService.shared)
    }
}
