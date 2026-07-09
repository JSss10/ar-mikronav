// AboutView.swift
// ARMikronav
//
// Über die App: Version aus dem Bundle, Datenquellen mit Lizenz-Hinweisen,
// verwendete SDKs und Bachelor-Projekt-Kontext.

import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            appSection
            sourcesSection
            linksSection
            librariesSection
            projectSection
        }
        .navigationTitle("Über die App")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var appSection: some View {
        Section("App") {
            row("Name", "ARMikronav")
            row("Version", Self.versionString)
            row("Build", Self.buildString)
        }
    }

    private var sourcesSection: some View {
        Section {
            sourceRow(
                "OpenStreetMap (ODbL)",
                "Barrieren-Geometrien (Stufen, Bordsteine, Steigungen, Oberflächen)",
                "https://www.openstreetmap.org/copyright"
            )
            sourceRow(
                "ginto / Accessibility Cloud",
                "Barrierefreiheits-Bewertungen für POIs",
                "https://ginto.guide"
            )
            sourceRow(
                "Wheelmap",
                "Rollstuhl-Tags für öffentliche Orte",
                "https://wheelmap.org"
            )
        } header: {
            Text("Datenquellen")
        } footer: {
            Text("OSM-Daten unterliegen der Open Database License (ODbL). ginto-Daten werden über die offizielle API bezogen.")
        }
    }

    private var linksSection: some View {
        Section {
            NavigationLink {
                PrivacyView()
            } label: {
                Label("Datenschutzerklärung", systemImage: "lock")
            }

            Link(destination: URL(string: "mailto:jessica.schneiter@bluewin.ch?subject=ARMikronav%20Feedback")!) {
                Label("Feedback senden", systemImage: "envelope")
            }
        }
    }

    private var librariesSection: some View {
        Section {
            row("supabase-swift", "MIT")
            row("ARKit", "Apple SDK")
            row("RealityKit", "Apple SDK")
            row("MapKit", "Apple SDK")
        } header: {
            Text("Verwendete Bibliotheken")
        }
    }

    private var projectSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bachelor-Projekt")
                    .font(.headline)
                Text("AR-gestützte Mikronavigation für Rollstuhlnutzende – ein prototypisches System zur Entscheidungsunterstützung in barrierekritischen urbanen Situationen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Entwickelt von Jessica Schneiter\nSAE Institute Zürich · B.Sc. Web Development\nSupervisor: Julian Heeb (ginto)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func sourceRow(_ name: String, _ detail: String, _ url: String) -> some View {
        Link(destination: URL(string: url)!) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Bundle Info

    static var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    static var buildString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}
