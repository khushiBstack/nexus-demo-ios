import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import Combine

// MARK: 5) Audio injection test

struct AudioInjectionTestView: View {
    @State private var showFilePicker = false
    @State private var selectedFileName: String?
    @State private var selectedFileURL: URL?
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: isPlaying ? "waveform" : "music.note")
                        .font(.system(size: 52))
                        .foregroundColor(isPlaying ? .purple : .indigo)
                        .accessibilityHidden(true)
                    Text("Audio Injection").font(.title2.bold())
                    Text("Pick an audio file from Files to play or inject")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }.padding(.top, 8)

                if let name = selectedFileName {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Selected File", systemImage: "doc.fill").font(.headline)
                        Divider()
                        HStack(spacing: 12) {
                            Image(systemName: "music.note.list").foregroundColor(.indigo)
                                .accessibilityHidden(true)
                            Text(name).font(.subheadline).lineLimit(2)
                            Spacer()
                        }
                        if isPlaying {
                            HStack(spacing: 8) {
                                ProgressView().scaleEffect(0.8)
                                Text("Playing…").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                if let err = errorMessage {
                    Text(err).font(.caption).foregroundColor(.red).padding(.horizontal)
                }

                Button {
                    showFilePicker = true
                } label: {
                    Label("Open Audio File", systemImage: "folder.fill")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.indigo, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .accessibilityLabel("Open audio file picker")

                if selectedFileURL != nil {
                    HStack(spacing: 12) {
                        Button {
                            playAudio()
                        } label: {
                            Label(isPlaying ? "Playing…" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                                .font(.headline).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(isPlaying ? Color.gray : Color.green, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isPlaying)
                        .accessibilityLabel("Play selected audio")

                        Button {
                            stopAudio()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.headline).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Color.red, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isPlaying)
                        .accessibilityLabel("Stop audio playback")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Audio Injection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilePicker) {
            AudioDocumentPicker { url in
                selectedFileURL = url
                selectedFileName = url.lastPathComponent
                errorMessage = nil
                isPlaying = false
            }
        }
    }

    private func playAudio() {
        guard let url = selectedFileURL else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            isPlaying = true
            errorMessage = nil
            // Auto-reset when done
            DispatchQueue.main.asyncAfter(deadline: .now() + (player?.duration ?? 0) + 0.5) {
                isPlaying = false
            }
        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
        }
    }

    private func stopAudio() {
        player?.stop()
        isPlaying = false
    }
}

struct AudioDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tmp)
            try? FileManager.default.copyItem(at: url, to: tmp)
            onPick(tmp)
        }
    }
}

#Preview {
    NavigationStack { AudioInjectionTestView() }
}
