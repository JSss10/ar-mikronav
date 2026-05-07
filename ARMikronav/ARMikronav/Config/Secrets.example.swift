// Secrets.example.swift
// ARMikronav
//
// Template für Secrets.swift.
//
// Setup:
//   1. Diese Datei nach Secrets.swift kopieren (gleicher Ordner).
//   2. Echte Werte einsetzen.
//   3. Secrets.swift NICHT committen (ist via .gitignore ausgeschlossen).
//
// Wenn die App später auf xcconfig + Info.plist umgestellt wird, kann
// Secrets.swift entfallen und durch Bundle.main-Lookups ersetzt werden.

import Foundation

enum Secrets {
    // Supabase – aus dem Project Dashboard:
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = "YOUR_ANON_KEY"

    // ginto Guide API – Bearer-Token aus dem Partner-Account.
    static let gintoAPIKey = "YOUR_GINTO_BEARER_TOKEN"
}