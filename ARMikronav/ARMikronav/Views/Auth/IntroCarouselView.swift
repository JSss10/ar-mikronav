// IntroCarouselView.swift
// ARMikronav
//
// Zweiseitiger Intro-Carousel vor der Registrierung.
// "Überspringen" und "Los geht's" führen beide zur Registrierung.
//
// Styling gemäss Styleguide v1.0: Design-Tokens (AppColor, AppTypography,
// AppMetrics) und der gemeinsame Primär-Button. Grosszügiges, ruhiges
// Layout mit fixierter Aktion am unteren Rand und eigenem Seitenindikator.

import SwiftUI

struct IntroCarouselView: View {
    @State private var page = 0
    @State private var showSignUp = false

    private let slides: [IntroSlide] = [
        IntroSlide(
            symbol: "map.fill",
            title: "Barrieren erkennen, bevor du dort ankommst",
            subtitle: "Die Karte zeigt dir Stufen, Steigungen und Engstellen in deiner Umgebung."
        ),
        IntroSlide(
            symbol: "person.crop.circle.badge.checkmark",
            title: "Persönlich. Nur Warnungen, die DICH betreffen.",
            subtitle: "Dein Profil bestimmt, was eine Barriere ist. Keine Warnung = für dich passierbar."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            skipBar

            TabView(selection: $page) {
                ForEach(slides.indices, id: \.self) { index in
                    slideView(slides[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            pageIndicator
                .padding(.bottom, AppMetrics.Space.l)

            primaryButton
                .padding(.horizontal, AppMetrics.Space.l)
                .padding(.bottom, AppMetrics.Space.xxl)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSignUp) {
            SignUpView()
        }
    }

    // MARK: - Sections

    private var skipBar: some View {
        HStack {
            Spacer()
            Button("Überspringen") { showSignUp = true }
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.accentPrimary)
                .padding(.horizontal, AppMetrics.Space.l)
                .padding(.vertical, AppMetrics.Space.m)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: AppMetrics.Space.s) {
            ForEach(slides.indices, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AppColor.accentPrimary : AppColor.borderDecorative)
                    .frame(width: index == page ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Seite \(page + 1) von \(slides.count)")
    }

    private var primaryButton: some View {
        Button {
            if page < slides.count - 1 {
                withAnimation { page += 1 }
            } else {
                showSignUp = true
            }
        } label: {
            Text(page < slides.count - 1 ? "Weiter" : "Los geht's")
        }
        .buttonStyle(.appPrimary)
    }

    private func slideView(_ slide: IntroSlide) -> some View {
        VStack(spacing: AppMetrics.Space.l) {
            Spacer(minLength: AppMetrics.Space.l)

            illustration(symbol: slide.symbol)
                .padding(.horizontal, AppMetrics.Space.l)

            VStack(spacing: AppMetrics.Space.m) {
                Text(slide.title)
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(slide.subtitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppMetrics.Space.xl)

            Spacer(minLength: AppMetrics.Space.l)
        }
    }

    /// Getönte Bild-Fläche mit Symbol in der Leitfarbe. Ersetzt den früheren
    /// "Bild folgt"-Platzhalter durch eine ruhige, markenkonforme Darstellung,
    /// bis die finalen Illustrationen vorliegen.
    private func illustration(symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppMetrics.Radius.card + AppMetrics.Space.xs, style: .continuous)
                .fill(AppColor.Violet.v50)

            Image(systemName: symbol)
                .font(.system(size: 92, weight: .semibold))
                .foregroundStyle(AppColor.accentPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .accessibilityHidden(true)
    }
}

private struct IntroSlide {
    let symbol: String
    let title: String
    let subtitle: String
}

#Preview {
    NavigationStack {
        IntroCarouselView()
    }
}