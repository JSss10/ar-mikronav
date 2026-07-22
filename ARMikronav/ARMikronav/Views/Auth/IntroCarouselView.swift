// IntroCarouselView.swift
// ARMikronav
//
// Zweiseitiger Intro-Carousel vor der Registrierung.
// "Überspringen" und "Los geht's" führen beide zur Registrierung.
// Die Illustrationen sind bewusst Bild-Platzhalter, bis finale Assets da sind.

import SwiftUI

struct IntroCarouselView: View {
    @State private var page = 0
    @State private var showSignUp = false

    private let slides: [IntroSlide] = [
        IntroSlide(
            title: "Barrieren erkennen, bevor du dort ankommst",
            subtitle: "Die Karte zeigt dir Stufen, Steigungen und Engstellen in deiner Umgebung."
        ),
        IntroSlide(
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

            // Platzhalter-Bild: klarer "Bild folgt"-Rahmen, bis die finalen
            // Illustrationen vorliegen.
            imagePlaceholder
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

    private var imagePlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            Text("Bild folgt")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityHidden(true)
    }
}

private struct IntroSlide {
    let title: String
    let subtitle: String
}