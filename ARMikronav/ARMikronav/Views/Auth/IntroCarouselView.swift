// IntroCarouselView.swift
// ARMikronav
//
// Screens 0.1a/0.1b – zweiseitiger Intro-Carousel vor der Registrierung.
// "Überspringen" und "Los geht's" führen beide zur Registrierung (0.2).
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
                    withAnimation { page += 1 }
                } else {
                    showSignUp = true
                }
            } label: {
                Text(page < slides.count - 1 ? "Weiter" : "Los geht's")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSignUp) {
            SignUpView()
        }
    }

    private func slideView(_ slide: IntroSlide) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: slide.symbolName)
                .font(.system(size: 96))
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

            Text(slide.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(slide.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

private struct IntroSlide {
    let symbolName: String
    let title: String
    let subtitle: String
}
