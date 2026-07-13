import SwiftUI
import SwiftData
import PhotosUI

#if os(iOS)
import UIKit

/// Selettore fotocamera o libreria foto.
struct ImagePicker: UIViewControllerRepresentable {
    enum Source: Equatable {
        case camera, photoLibrary
    }

    let source: Source
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = source == .camera ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Prompt post-partita: scatta o scegli una foto ricordo (non va nella card social).
struct MatchPhotoPromptSheet: View {
    let matchDate: Date
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var context
    @State private var pickerSource: ImagePicker.Source? = nil
    @State private var pickedImage: UIImage? = nil
    @State private var saving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.lime)
                    .padding(.top, 12)

                VStack(spacing: 10) {
                    Text("Un ricordo di oggi?")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                    Text("Scatta una foto di fine partita. Resta nel tuo storico e si sincronizza su iPhone e Apple Watch, ma non compare sulla card social.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        pickerSource = .camera
                    } label: {
                        Label("Scatta una foto", systemImage: "camera.fill")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)

                    Button {
                        pickerSource = .photoLibrary
                    } label: {
                        Label("Scegli dalla libreria", systemImage: "photo.on.rectangle")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.accent)

                    Button("Più tardi") {
                        MatchPhotoSync.shared.skipPrompt(for: matchDate)
                        onDismiss()
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
                .padding(.horizontal)

                if saving {
                    ProgressView("Salvataggio…")
                        .font(.system(.caption, design: .rounded))
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical)
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        MatchPhotoSync.shared.skipPrompt(for: matchDate)
                        onDismiss()
                    }
                }
            }
            .fullScreenCover(item: $pickerSource) { source in
                ImagePicker(source: source, image: $pickedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: pickedImage) { _, image in
                guard let image else { return }
                saving = true
                Task {
                    await MatchPhotoSync.shared.savePhoto(image, matchDate: matchDate, context: context)
                    saving = false
                    onDismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

extension ImagePicker.Source: Identifiable {
    var id: String { self == .camera ? "camera" : "library" }
}
#endif
