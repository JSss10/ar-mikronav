// AuthService.swift
// ARMikronav
//
// Wrapper um Supabase Auth - Sign Up, Sign In, Sign Out, Session Management

import Foundation
import Combine
import Supabase
import Auth

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var isLoading: Bool = true
    
    private let client = SupabaseService.shared.client
    
    private init() {
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Session
    
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "first_name": .string(firstName),
                "last_name": .string(lastName)
            ]
        )
        
        self.currentUser = response.user
        self.isAuthenticated = response.session != nil
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        self.currentUser = session.user
        self.isAuthenticated = true
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - E-Mail-Bestätigung erneut senden

    func resendConfirmation(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
    }

    // MARK: - Passwort ändern (Wireframe 4.3)

    enum PasswordChangeError: LocalizedError {
        case notAuthenticated
        case wrongCurrentPassword

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:      return "Nicht eingeloggt."
            case .wrongCurrentPassword:  return "Das aktuelle Passwort ist falsch."
            }
        }
    }

    /// Verifiziert das aktuelle Passwort über einen Re-Login und setzt danach
    /// das neue. Supabase kann das alte Passwort nicht direkt prüfen.
    func changePassword(current: String, new: String) async throws {
        guard let email = currentUser?.email else {
            throw PasswordChangeError.notAuthenticated
        }

        do {
            _ = try await client.auth.signIn(email: email, password: current)
        } catch {
            throw PasswordChangeError.wrongCurrentPassword
        }

        try await client.auth.update(user: UserAttributes(password: new))
    }
}
