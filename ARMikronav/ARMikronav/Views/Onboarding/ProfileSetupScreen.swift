// ProfileSetupScreen.swift
// ARMikronav – Onboarding Schritt 1/7: Name und Profilbild.
// Name bei E-Mail-Registrierung vorbelegt aus user_metadata; Pflichtfeld bei
// Apple/Google Sign-in. Das Profilbild ist optional: aufnehmen (Kamera) oder
// ein Bild hochladen (Galerie via PhotosPicker, braucht keine Berechtigung).
// Gespeichert wird direkt über den AvatarStore (lokal + Storage-Sync).

import SwiftUI
import PhotosUI

struct Screen10_ProfileSetup: View {
    @Binding var draft: DraftProfile

    @StateObject private var avatarStore = AvatarStore.shared
    @State private var showingCamera = false
    @State private var galleryItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 24) {
            avatarPreview
                .padding(.top, 8)

            photoButtons

            VStack(alignment: .leading, spacing: 6) {
                Text("Vorname")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Jessica", text: $draft.firstName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.givenName)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Nachname")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Muster", text: $draft.lastName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.familyName)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                avatarStore.save(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: galleryItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    avatarStore.save(image)
                }
                galleryItem = nil
            }
        }
    }

    // MARK: - Profilbild

    private var avatarPreview: some View {
        ZStack {
            if let photo = avatarStore.image {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color(.systemGray6))
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var photoButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    showingCamera = true
                } label: {
                    Label("Foto aufnehmen", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                PhotosPicker(selection: $galleryItem, matching: .images) {
                    Label("Bild hochladen", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if avatarStore.image != nil {
                Button("Foto entfernen", role: .destructive) {
                    avatarStore.delete()
                }
                .font(.footnote)
            } else {
                Text("Profilbild (optional)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
