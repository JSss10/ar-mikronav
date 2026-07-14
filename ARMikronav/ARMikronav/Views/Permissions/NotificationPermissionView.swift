// NotificationPermissionView.swift
// ARMikronav
//
// Erklärungs-Screen vor dem System-Prompt für Benachrichtigungen.
// "Später" überspringt; die Permission ist danach jederzeit über die
// Einstellungen (S2) nachholbar. Der Screen wird nur einmal gezeigt.

import SwiftUI
import UserNotifications

enum NotificationPermissionStore {
    private static let key = "armikronav.notificationPermissionAsked"

    static var wasAsked: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markAsked() {
        UserDefaults.standard.set(true, forKey: key)
    }
}

struct NotificationPermissionView: View {
    let onFinished: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.tint)

            Text("Warum Benachrichtigungen?")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)

            Text("Benachrichtigungen warnen dich vorausschauend, bevor du eine Barriere erreichst.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    requestPermission()
                } label: {
                    if isRequesting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("Benachrichtigungen erlauben")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(Color.accentColor)
                .cornerRadius(12)
                .disabled(isRequesting)

                Button("Später") {
                    NotificationPermissionStore.markAsked()
                    onFinished()
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func requestPermission() {
        isRequesting = true
        Task {
            await BarrierNotificationService.shared.requestAuthorization()
            NotificationPermissionStore.markAsked()
            isRequesting = false
            onFinished()
        }
    }
}