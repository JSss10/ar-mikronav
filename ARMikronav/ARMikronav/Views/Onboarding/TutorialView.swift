// TutorialView.swift
// ARMikronav
//
// Screen 5.1 – dreiseitiges Tutorial nach dem Onboarding, vor der ersten
// Karten-Nutzung. Überspringbar; wird nur einmal gezeigt (TutorialStore).
// Zweiter Einstiegspunkt aus den Einstellungen ist als Follow-up vorgesehen.

import SwiftUI

enum TutorialStore {
    private static let key = "armikronav.tutorialSeen"

    static var wasSeen: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: key)
    }
}

struct TutorialView: View {
    let onFinished: () -> Void

    @State private var page = 0

    private let slides: [TutorialSlide] = [
        TutorialSlide(
            symbolName: "map.fill",
            text: "Die Karte zeigt dir Barrieren in deiner Umgebung"
        ),
        TutorialSlide(
            symbolName: "arkit",
            text: "Wechsle in die AR-Ansicht für Details vor Ort"
        ),
        TutorialSlide(
            symbolName: "bell.badge.fill",
            text: "Du wirst nur gewarnt, wenn etwas für DICH relevant ist"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Überspringen") { finish() }
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
                    finish()
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
    }

    private func slideView(_ slide: TutorialSlide) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: slide.symbolName)
                .font(.system(size: 96))
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, minHeight: 260)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

            Text(slide.text)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func finish() {
        TutorialStore.markSeen()
        onFinished()
    }
}

private struct TutorialSlide {
    let symbolName: String
    let text: String
}
