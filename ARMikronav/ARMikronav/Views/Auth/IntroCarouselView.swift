// IntroCarouselView.swift
// ARMikronav
//
// Zweiseitiger Intro-Carousel vor der Registrierung.
// "Überspringen" und "Los geht's" führen beide zur Registrierung.
// Illustrationen sind bewusst SF-Symbol-Platzhalter, bis finale Assets da sind.

import SwiftUI

struct IntroCarouselView: View {
    @State private var page = 0
    @State private var showSignUp = false

    private let slides: [IntroSlide] = [
        IntroSlide(
            symbolName: "map.fill",
            title: "Barrieren erkennen, bevor du dort ankommst",
            subtitle: "Die Karte zeigt dir Stufen, Steigungen und Engstellen in deiner Umgebung."
        ),
        IntroSlide(
            symbolName: "person.crop.circle.badge.checkmark",
            title: "Persönlich. Nur Warnungen, die DICH betreffen.",
            subtitle: "Dein Profil bestimmt, was eine Barriere ist. Keine Warnung = für dich passierbar."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Überspringen") { showSignUp = true }
                    .font(.subheadline)
                    .padding()
            }

            TabView(selection: $page) {
                ForEach(slides.indices, id: \.self) { index in
                    slideView(slides[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < slides.count - 1 {
                    withAnimation(AppMotion.spring) { page += 1 }
                } else {
                    showSignUp = true
                }
            } label: {
                Text(page < slides.count - 1 ? "Weiter" : "Los geht's")
            }
            .buttonStyle(.appPrimary)
            .padding(.horizontal, AppMetrics.Space.l)
            .padding(.bottom, AppMetrics.Space.xxl)
        }
        .background(AppColor.backgroundPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSignUp) {
            SignUpView()
        }
    }

    private func slideView(_ slide: IntroSlide) -> some View {
        VStack(spacing: AppMetrics.Space.l) {
            Spacer()

            // Illustration auf kreisrunder, getönter Disc – die Kreisform
            // ist das wiederkehrende Grundmotiv der App.
            ZStack {
                Circle()
                    .fill(AppColor.Violet.v100)
                    .frame(width: 220, height: 220)
                Circle()
                    .strokeBorder(AppColor.Violet.v300.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 260, height: 260)
                Image(systemName: slide.symbolName)
                    .font(.system(size: 88))
                    .foregroundStyle(AppColor.accentPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .accessibilityHidden(true)

            Text(slide.title)
                .font(AppTypography.displayTitle2)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppMetrics.Space.xl)

            Text(slide.subtitle)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppMetrics.Space.xl)

            Spacer()
        }
    }
}

private struct IntroSlide {
    let symbolName: String
    let title: String
    let subtitle: String
}