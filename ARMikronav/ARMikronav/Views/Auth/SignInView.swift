// SignInView.swift
// ARMikronav
//
// Anmeldung mit E-Mail und Passwort – Felder im Styleguide-Stil
// (.appField mit sichtbarem Fokusring), Aktionen als Kapsel-Buttons.

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email: String = ""
    @State private var password: String = ""

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @State private var showResetPassword: Bool = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppMetrics.Space.m + 4) {
                Text("Anmelden")
                    .font(AppTypography.displayLarge)
                    .foregroundColor(AppColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppMetrics.Space.m)
                    .accessibilityAddTraits(.isHeader)

                Text("Melde dich mit deinem Konto an.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, AppMetrics.Space.s)

                // E-Mail
                VStack(alignment: .leading, spacing: 6) {
                    Text("E-Mail")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColor.textSecondary)
                    TextField("name@beispiel.ch", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .appField(isFocused: focusedField == .email)
                }

                // Passwort
                VStack(alignment: .leading, spacing: 6) {
                    Text("Passwort")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColor.textSecondary)
                    SecureField("••••••••", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .appField(isFocused: focusedField == .password)
                }

                // Passwort vergessen
                Button("Passwort vergessen?") {
                    showResetPassword = true
                }
                .font(AppTypography.subheadline)
                .foregroundColor(AppColor.accentPrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(minHeight: AppMetrics.Touch.minimum)

                // Error
                if let errorMessage = errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColor.Status.blockedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Sign In Button
                Button {
                    Task { await handleSignIn() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(AppColor.onAccent)
                    } else {
                        Text("Anmelden")
                    }
                }
                .buttonStyle(.appPrimary)
                .disabled(!isFormValid || isLoading)
                .padding(.top, AppMetrics.Space.s)

                Spacer()
            }
            .padding(.horizontal, AppMetrics.Space.l)
        }
        .background(AppColor.backgroundPrimary)
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
        } catch {
            errorMessage = "Anmeldung fehlgeschlagen: \(error.localizedDescription)"
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

    @FocusState private var emailFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: AppMetrics.Space.m + 4) {
                Text("Wir senden dir einen Link zum Zurücksetzen deines Passworts.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("E-Mail", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($emailFocused)
                    .appField(isFocused: emailFocused)

                if let message = message {
                    Label(
                        message,
                        systemImage: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
                    )
                    .font(AppTypography.subheadline)
                    .foregroundColor(isError ? AppColor.Status.blockedText : AppColor.Status.openText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await handleReset() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(AppColor.onAccent)
                    } else {
                        Text("Reset-Link senden")
                    }
                }
                .buttonStyle(.appPrimary)
                .disabled(email.isEmpty || isLoading)

                Spacer()
            }
            .padding(AppMetrics.Space.l)
            .background(AppColor.backgroundPrimary)
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
