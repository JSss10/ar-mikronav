// SplashView.swift
// ARMikronav
//
// Screen 0.1 - Splash Screen während Auth-Check läuft

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.roll")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("AR-Mikronavigation")
                .font(.title)
                .bold()
            
            ProgressView()
                .padding(.top, 20)
        }
    }
}

#Preview {
    SplashView()
}
