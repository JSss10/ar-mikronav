// BiometricAuthService.swift
// ARMikronav
//
// Face ID / Touch ID-Anmeldung. Nach einer erfolgreichen Passwort-Anmeldung
// können die Zugangsdaten biometrisch geschützt im Keychain abgelegt werden
// (kSecAccessControlBiometryCurrentSet). Beim nächsten Start genügt dann
// Face ID: Das Auslesen des Keychain-Eintrags verlangt die Biometrie,
// anschliessend wird regulär über AuthService angemeldet.

import Foundation
import LocalAuthentication
import Security

@MainActor
final class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()

    private static let service = "ch.armikronav.biometric-login"
    private static let account = "credentials"
    private static let enabledKey = "armikronav.biometricLoginEnabled"

    /// Spiegelt, ob Zugangsdaten hinterlegt sind – ohne Keychain-Zugriff,
    /// damit beim Anzeigen des Login-Screens kein Face-ID-Prompt erscheint.
    @Published private(set) var isEnabled: Bool

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    // MARK: - Verfügbarkeit

    /// Ob das Gerät Face ID / Touch ID anbietet und eingerichtet hat.
    var isAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// "Face ID" oder "Touch ID" für Button- und Hinweistexte.
    var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .touchID: return "Touch ID"
        default: return "Face ID"
        }
    }

    // MARK: - Aktivieren / Deaktivieren

    /// Legt E-Mail und Passwort biometrisch geschützt im Keychain ab.
    func enable(email: String, password: String) throws {
        let payload = try JSONEncoder().encode(StoredCredentials(email: email, password: password))

        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            nil
        ) else {
            throw BiometricError.keychain(errSecParam)
        }

        // Alten Eintrag entfernen, damit SecItemAdd nicht mit duplicateItem scheitert.
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = payload
        attributes[kSecAttrAccessControl as String] = accessControl

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BiometricError.keychain(status)
        }

        UserDefaults.standard.set(true, forKey: Self.enabledKey)
        isEnabled = true
    }

    /// Entfernt die hinterlegten Zugangsdaten wieder.
    func disable() {
        SecItemDelete(baseQuery as CFDictionary)
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
        isEnabled = false
    }

    // MARK: - Anmelden

    /// Fragt Face ID ab, liest die Zugangsdaten und meldet über AuthService an.
    func signIn(using authService: AuthService) async throws {
        let context = LAContext()
        context.localizedReason = "Mit \(biometryName) bei ARMikronav anmelden"
        context.localizedCancelTitle = "Abbrechen"

        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationContext as String] = context

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            break
        case errSecUserCanceled, errSecAuthFailed:
            throw BiometricError.cancelled
        case errSecItemNotFound:
            // Biometrie wurde neu eingerichtet oder der Eintrag fehlt – Status zurücksetzen.
            disable()
            throw BiometricError.notEnrolled
        default:
            throw BiometricError.keychain(status)
        }

        guard let data = result as? Data,
              let credentials = try? JSONDecoder().decode(StoredCredentials.self, from: data) else {
            disable()
            throw BiometricError.notEnrolled
        }

        try await authService.signIn(email: credentials.email, password: credentials.password)
    }

    // MARK: - Intern

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account
        ]
    }

    private struct StoredCredentials: Codable {
        let email: String
        let password: String
    }
}

enum BiometricError: LocalizedError {
    case cancelled
    case notEnrolled
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Anmeldung abgebrochen."
        case .notEnrolled:
            return "Face ID-Anmeldung ist nicht mehr eingerichtet. Bitte melde dich mit deinem Passwort an und aktiviere sie erneut."
        case .keychain(let status):
            return "Schlüsselbund-Fehler (\(status))."
        }
    }
}
