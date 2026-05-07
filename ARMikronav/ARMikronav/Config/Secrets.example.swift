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
// Der #if false-Block sorgt dafür, dass die Vorlage nicht kompiliert wird,
// während die echte Secrets.swift im selben Ordner gebaut wird.

import Foundation

#if false

enum Secrets {
    // Supabase – aus dem Project Dashboard:
    // https://app.supabase.com/project/<id>/settings/api
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = "YOUR_ANON_KEY"

    // ginto Guide API – Bearer-Token aus dem Partner-Account.
    static let gintoAPIKey = "YOUR_GINTO_BEARER_TOKEN"
}

#endif