import SwiftUI
import AVKit
import UIKit
import UniformTypeIdentifiers
import Combine

// MARK: 1) Image injection

struct ImageInjectionView: View {
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var showGallery = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let img = capturedImage {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 52)).foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("No image selected").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).frame(height: 220)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        } else {
                            showGallery = true
                        }
                    } label: {
                        Label("Capture with Camera", systemImage: "camera.fill")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(UIImagePickerController.isSourceTypeAvailable(.camera) ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Capture image with camera")

                    Button {
                        showGallery = true
                    } label: {
                        Label("Choose from Gallery", systemImage: "photo.fill.on.rectangle.fill")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.indigo, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Choose image from photo gallery")

                    if capturedImage != nil {
                        Button("Clear") { capturedImage = nil }
                            .foregroundColor(.red)
                            .accessibilityLabel("Clear selected image")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Image Injection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            ImagePickerRepresentable(sourceType: .camera) { image in
                if let image { capturedImage = image }
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showGallery) {
            ImagePickerRepresentable(sourceType: .photoLibrary) { image in
                if let image { capturedImage = image }
                showGallery = false
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: 3) Video injection

struct VideoInjectionView: View {
    @State private var videoURL: URL?
    @State private var showCamera = false
    @State private var showGallery = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let url = videoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 52)).foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("No video selected").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).frame(height: 220)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        } else {
                            showGallery = true
                        }
                    } label: {
                        Label("Record with Camera", systemImage: "video.badge.plus")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(UIImagePickerController.isSourceTypeAvailable(.camera) ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Record video with camera")

                    Button {
                        showGallery = true
                    } label: {
                        Label("Choose from Gallery", systemImage: "film.fill")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.indigo, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Choose video from gallery")

                    if videoURL != nil {
                        Button("Clear") { videoURL = nil }
                            .foregroundColor(.red)
                            .accessibilityLabel("Clear selected video")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Video Injection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            VideoCameraPickerRepresentable(sourceType: .camera) { url in videoURL = url }
        }
        .sheet(isPresented: $showGallery) {
            VideoCameraPickerRepresentable(sourceType: .photoLibrary) { url in videoURL = url }
        }
    }
}

// MARK: 4) File upload / download

struct FileUploadDownloadView: View {
    @State private var showFilePicker = false
    @State private var uploadedFileName: String?
    @State private var uploadedFileSize: String?
    @State private var downloadStatus: String?
    @State private var isDownloading = false
    @State private var downloadedURL: URL?
    @State private var showShareSheet = false
    @State private var showSavePrompt = false
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.system(size: 52)).foregroundColor(.teal)
                        .accessibilityHidden(true)
                    Text("File Upload & Download").font(.title2.bold())
                    Text("Upload any file from Files, or download a sample PDF")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }.padding(.top, 8)

                // Upload section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Upload", systemImage: "arrow.up.doc.fill").font(.headline)
                    Divider()
                    if let name = uploadedFileName {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.fill").foregroundColor(.teal)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name).font(.subheadline).lineLimit(1)
                                if let size = uploadedFileSize {
                                    Text(size).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                .accessibilityHidden(true)
                        }
                    } else {
                        Text("No file selected").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Open Files", systemImage: "folder.fill")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.teal, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityLabel("Open file picker to upload")
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Download section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Download", systemImage: "arrow.down.doc.fill").font(.headline)
                    Divider()
                    if let status = downloadStatus {
                        HStack(spacing: 8) {
                            Image(systemName: downloadedURL != nil ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(downloadedURL != nil ? .green : .orange)
                                .accessibilityHidden(true)
                            Text(status).font(.subheadline).foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Download a sample PDF to your device")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        Button {
                            downloadSamplePDF()
                        } label: {
                            Label(isDownloading ? "Downloading…" : "Download PDF",
                                  systemImage: "arrow.down.doc.fill")
                                .font(.headline).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(isDownloading ? Color.gray : Color.orange,
                                            in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isDownloading)
                        .accessibilityLabel("Download sample PDF")

                        if downloadedURL != nil {
                            Button {
                                showSavePrompt = true
                            } label: {
                                Label("Save to Files", systemImage: "square.and.arrow.up")
                                    .font(.headline).foregroundStyle(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .accessibilityLabel("Save downloaded PDF to Files app")
                        }
                    }

                    // Save instructions banner
                    if downloadedURL != nil {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("How to save the file")
                                    .font(.caption.weight(.semibold))
                                Text("Tap \"Save to Files\" → in the share sheet tap \"Save to Files\" → choose On My iPhone → Chrome folder.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("How to save: Tap Save to Files, choose On My iPhone, then the Chrome folder.")
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("File Upload / Download")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilePicker) {
            GenericDocumentPicker { url, size in
                uploadedFileName = url.lastPathComponent
                uploadedFileSize = size
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = downloadedURL { ShareSheetView(items: [url]) }
        }
        .alert("File Downloaded ✓", isPresented: $showSavePrompt) {
            Button("Save to Files") { showShareSheet = true }
            Button("Later", role: .cancel) {}
        } message: {
            Text("To save the file:\n1. Tap \"Save to Files\"\n2. In the share sheet, tap \"Save to Files\"\n3. Choose: On My iPhone → Chrome\n\nThis makes the file accessible in the iOS Files app and Chrome.")
        }
    }

    private func downloadSamplePDF() {
        isDownloading = true
        downloadStatus = nil
        downloadedURL = nil
        DispatchQueue.global(qos: .userInitiated).async {
            let url = generateNexusPDF()
            DispatchQueue.main.async {
                isDownloading = false
                if let url = url {
                    downloadedURL = url
                    downloadStatus = "Downloaded: nexus_demo_info.pdf"
                    showSavePrompt = true
                } else {
                    downloadStatus = "Failed to generate PDF"
                }
            }
        }
    }
}

// MARK: - Helpers

struct GenericDocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL, String) -> Void
        init(onPick: @escaping (URL, String) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            let size: String
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let bytes = attrs[.size] as? Int64 {
                size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
            } else {
                size = "Unknown size"
            }
            onPick(url, size)
        }
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ImagePickerRepresentable: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    /// Called once when the picker finishes. `nil` means cancelled / no image.
    /// The caller is responsible for dismissing the sheet (via its binding).
    var onImagePicked: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onImagePicked: onImagePicked) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage?) -> Void
        init(onImagePicked: @escaping (UIImage?) -> Void) { self.onImagePicked = onImagePicked }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            var image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            if image == nil, let url = info[.imageURL] as? URL,
               let data = try? Data(contentsOf: url) {
                image = UIImage(data: data)
            }
            if image == nil, let url = info[.mediaURL] as? URL,
               let data = try? Data(contentsOf: url) {
                image = UIImage(data: data)
            }
            onImagePicked(image)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
        }
    }
}

struct VideoCameraPickerRepresentable: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onVideoPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onVideoPicked: onVideoPicked) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onVideoPicked: (URL) -> Void
        init(onVideoPicked: @escaping (URL) -> Void) { self.onVideoPicked = onVideoPicked }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let url = info[.mediaURL] as? URL { onVideoPicked(url) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

func generateNexusPDF() -> URL? {
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let title = "Nexus Demo — Sample PDF"
        let body = """
        This PDF was generated by the Nexus Demo app.

        It demonstrates the file download and share capability
        of the app.
        """
        title.draw(at: CGPoint(x: 50, y: 60),
                   withAttributes: [.font: UIFont.boldSystemFont(ofSize: 24)])
        body.draw(in: CGRect(x: 50, y: 110, width: 495, height: 600),
                  withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("nexus_demo_info.pdf")
    do { try data.write(to: url); return url } catch { return nil }
}
