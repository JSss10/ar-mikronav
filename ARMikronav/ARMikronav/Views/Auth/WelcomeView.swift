// WelcomeView.swift
// ARMikronav
//
// Welcome / Sign in / Sign up Auswahl – Formsprache v2: weiche, unscharfe
// Violett-Kreise als Hintergrund, das Logo auf einer kreisrunden
// Verlaufs-Disc, Aktionen als Kapsel-Buttons. Der Auftritt ist gestaffelt
// animiert (Reduce-Motion-sicher über .appEntrance).

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundShapes

                VStack(spacing: 0) {
                    Spacer()

                    // Logo + Titel
                    VStack(spacing: AppMetrics.Space.m) {
                        logoDisc

                        Text("AR-Mikronavigation")
                            .font(AppTypography.displayLarge)
                            .foregroundColor(AppColor.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Barrieren erkennen, bevor du dort ankommst.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .appEntrance()

                    Spacer()

                    // Buttons
                    VStack(spacing: AppMetrics.Touch.spacing + 4) {
                        // Feldtest Altstadt Zürich: Testpersonen wählen ein
                        // vorgefertigtes Profil statt sich zu registrieren.
                        if AppConfig.fieldTestModeEnabled {
                            NavigationLink {
                                TestProfileSelectionView()
                            } label: {
                                Label("Feldtest starten", systemImage: "person.crop.circle.badge.checkmark")
                            }
                            .buttonStyle(.appPrimary)
                        }

                        if AppConfig.fieldTestModeEnabled {
                            NavigationLink {
                                IntroCarouselView()
                            } label: {
                                Text("Registrieren")
                            }
                            .buttonStyle(.appSecondary)
                        } else {
                            NavigationLink {
                                IntroCarouselView()
                            } label: {
                                Text("Registrieren")
                            }
                            .buttonStyle(.appPrimary)
                        }

                        NavigationLink {
                            SignInView()
                        } label: {
                            Text("Anmelden")
                        }
                        .buttonStyle(.appSecondary)

                        // Apple Sign-in Stub (kommt später)
                        Button {
                            // TODO: Apple Sign-in implementieren (braucht Apple Developer Account)
                        } label: {
                            Label("Mit Apple anmelden", systemImage: "apple.logo")
                        }
                        .buttonStyle(.appQuiet(fullWidth: true))
                        .disabled(true)
                    }
                    .padding(.horizontal, AppMetrics.Space.l)
                    .padding(.bottom, AppMetrics.Space.xxl)
                    .appEntrance(delay: 0.1)
                }
            }
            .background(AppColor.backgroundPrimary)
        }
    }

    /// Logo auf kreisrunder Verlaufs-Disc mit weichem Akzent-Glow.
    private var logoDisc: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColor.accentPrimary, AppColor.accentPressed],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 128, height: 128)
                .shadow(
                    color: AppColor.accentPrimary.opacity(AppMetrics.Shadow.buttonOpacity),
                    radius: 24,
                    y: 10
                )
            Image(systemName: "figure.roll")
                .font(.system(size: 60))
                .foregroundColor(AppColor.onAccent)
        }
        .accessibilityHidden(true)
    }

    /// Dekorative, weich verwischte Violett-Kreise – reine Formsprache,
    /// funktioniert in Hell und Dunkel über die Token-Farben.
    private var backgroundShapes: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(AppColor.Violet.v300.opacity(0.22))
                    .frame(width: 320, height: 320)
                    .blur(radius: 60)
                    .offset(x: -proxy.size.width * 0.35, y: -proxy.size.height * 0.32)
                Circle()
                    .fill(AppColor.accentPrimary.opacity(0.12))
                    .frame(width: 380, height: 380)
                    .blur(radius: 70)
                    .offset(x: proxy.size.width * 0.4, y: proxy.size.height * 0.35)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthService.shared)
}
