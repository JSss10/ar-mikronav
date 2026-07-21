// AppTabBar.swift
// ARMikronav
//
// Schwebende Bottom-Navigation im modernen Apple-Stil: abgerundete Leiste mit
// Abstand rundherum, weicher Schatten und organischem "Blob" hinter dem aktiven
// Icon. Der Blob wandert per matchedGeometryEffect animiert zum angetippten
// Tab (Spring), das Icon federt per Symbol-Effekt mit. Farben ausschliesslich
// über AppColor-Tokens (§02), Touch-Ziele >= 44 pt (§6.1).

import SwiftUI

// MARK: - Tabs

enum AppTab: CaseIterable, Identifiable {
    case home
    case map
    case camera
    case saved
    case profile

    var id: Self { self }

    /// Kurzes Label unter dem Icon (Platz für 5 Tabs).
    var title: String {
        switch self {
        case .home: return "Home"
        case .map: return "Karte"
        case .camera: return "Kamera"
        case .saved: return "Orte"
        case .profile: return "Profil"
        }
    }

    /// Ausgeschriebenes Label für VoiceOver.
    var accessibilityLabel: String {
        switch self {
        case .home: return "Home"
        case .map: return "Karte"
        case .camera: return "Kamera, AR-Modus"
        case .saved: return "Gespeicherte Orte"
        case .profile: return "Profil"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .map: return "map"
        case .camera: return "camera"
        case .saved: return "bookmark"
        case .profile: return "person"
        }
    }

    var selectedIcon: String {
        icon + ".fill"
    }
}

// MARK: - Tab-Bar

struct AppTabBar: View {
    @Binding var selection: AppTab

    /// Platz, den Inhalte unten freihalten sollten (Leiste + Bodenabstand),
    /// z. B. via safeAreaInset. Scrollende Inhalte laufen darunter durch.
    static let clearance: CGFloat = 88

    @Namespace private var blobNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, AppMetrics.Space.s)
        .padding(.vertical, AppMetrics.Space.s + 2)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppColor.surfaceRaised)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(AppColor.borderDecorative, lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        }
        // Abstand rundherum: die Leiste schwebt frei über dem Inhalt.
        .padding(.horizontal, AppMetrics.Space.m)
        .padding(.bottom, AppMetrics.Space.s)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation")
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selection == tab

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selection = tab
            }
        } label: {
            VStack(spacing: AppMetrics.Space.xs) {
                ZStack {
                    if isSelected {
                        TabBlobShape()
                            .fill(AppColor.accentPrimary)
                            .matchedGeometryEffect(id: "blob", in: blobNamespace)
                            .frame(width: 48, height: 40)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.textSecondary)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(height: 40)

                Text(tab.title)
                    .font(.caption2.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? AppColor.accentPrimary : AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: AppMetrics.Touch.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Blob-Form

/// Organische, leicht unregelmässige Fläche hinter dem aktiven Icon
/// (vgl. Referenzdesign). Glatte geschlossene Kurve durch Punkte mit
/// variierenden Radien.
struct TabBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radii: [CGFloat] = [0.96, 0.84, 1.0, 0.88, 0.94, 0.82, 1.0, 0.9]
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let points = radii.enumerated().map { index, radius -> CGPoint in
            let angle = CGFloat(index) / CGFloat(radii.count) * 2 * .pi - .pi / 2
            return CGPoint(
                x: center.x + cos(angle) * rect.width / 2 * radius,
                y: center.y + sin(angle) * rect.height / 2 * radius
            )
        }

        var path = Path()
        path.move(to: midpoint(points[0], points[1]))
        for index in 1...points.count {
            let current = points[index % points.count]
            let next = points[(index + 1) % points.count]
            path.addQuadCurve(to: midpoint(current, next), control: current)
        }
        path.closeSubpath()
        return path
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selection: AppTab = .map

        var body: some View {
            VStack {
                Spacer()
                AppTabBar(selection: $selection)
            }
            .background(AppColor.backgroundPrimary)
        }
    }
    return PreviewWrapper()
}