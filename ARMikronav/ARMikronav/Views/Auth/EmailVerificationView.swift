// EmailVerificationView.swift
// ARMikronav
//
// Screen 0.4b – nach der Registrierung: Hinweis auf die Bestätigungs-E-Mail
// mit der Möglichkeit, sie erneut zu senden.

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService
    let email: String

    @State private var isResending = false
    @State private var message: String?
    @State private var isError = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.tint)

            Text("Wir haben dir eine E-Mail geschickt.")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text("Bitte bestätige dein Konto über den Link in der E-Mail.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(isError ? .red : .green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                Task { await resend() }
            } label: {
                if isResending {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                } else {
                    Text("E-Mail erneut senden")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .disabled(isResending)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(false)
    }

    private func resend() async {
        isResending = true
        message = nil
        defer { isResending = false }

        do {
            try await authService.resendConfirmation(email: email)
            message = "E-Mail wurde erneut gesendet."
            isError = false
        } catch {
            message = "Senden fehlgeschlagen: \(error.localizedDescription)"
            isError = true
        }
    }
}
