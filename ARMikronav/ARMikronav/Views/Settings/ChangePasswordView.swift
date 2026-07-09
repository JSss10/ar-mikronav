// ChangePasswordView.swift
// ARMikronav
//
// Wireframe 4.3 – Passwort ändern mit Verifikation des aktuellen Passworts
// und einfacher Stärke-Anzeige. Bei künftigem Apple/Google Sign-in ist der
// Screen nicht anwendbar (Passwort liegt beim Provider) – Hinweis im Footer.

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didSucceed = false

    private var strength: PasswordStrength { PasswordStrength(newPassword) }

    private var canSubmit: Bool {
        !currentPassword.isEmpty
            && newPassword.count >= 6
            && newPassword == confirmPassword
            && !isSaving
    }

    var body: some View {
        Form {
            Section("Aktuelles Passwort") {
                SecureField("••••••••", text: $currentPassword)
                    .textContentType(.password)
            }

            Section {
                SecureField("••••••••", text: $newPassword)
                    .textContentType(.newPassword)
                strengthIndicator
            } header: {
                Text("Neues Passwort")
            } footer: {
                Text("Mindestens 6 Zeichen.")
            }

            Section("Neues Passwort bestätigen") {
                SecureField("••••••••", text: $confirmPassword)
                    .textContentType(.newPassword)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    changePassword()
                } label: {
                    if isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Passwort ändern")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .disabled(!canSubmit)
            } footer: {
                Text("Bei Apple/Google Sign-in nicht verfügbar – das Passwort wird über den Provider verwaltet.")
            }
        }
        .navigationTitle("Passwort ändern")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Passwort geändert", isPresented: $didSucceed) {
            Button("OK") { dismiss() }
        }
    }

    // MARK: - Stärke-Anzeige

    @ViewBuilder
    private var strengthIndicator: some View {
        if !newPassword.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index < strength.filledBars ? strength.color : Color.gray.opacity(0.25))
                            .frame(height: 5)
                    }
                }
                Text("Passwortstärke: \(strength.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func changePassword() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await authService.changePassword(current: currentPassword, new: newPassword)
                isSaving = false
                didSucceed = true
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// Sehr einfache Heuristik: Länge + Zeichenvielfalt.
private struct PasswordStrength {
    let filledBars: Int
    let label: String
    let color: Color

    init(_ password: String) {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        let hasDigits = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSymbols = password.rangeOfCharacter(from: .punctuationCharacters.union(.symbols)) != nil
        if hasDigits && hasSymbols { score += 1 }

        switch score {
        case 0:  (filledBars, label, color) = (1, "schwach", .red)
        case 1:  (filledBars, label, color) = (1, "schwach", .red)
        case 2:  (filledBars, label, color) = (2, "gut", .green)
        default: (filledBars, label, color) = (3, "stark", .green)
        }
    }
}
