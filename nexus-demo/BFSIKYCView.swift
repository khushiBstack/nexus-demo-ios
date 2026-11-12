import SwiftUI
import AVFoundation
import UIKit

enum KYCStep { case intro, liveness, document, review, complete }

struct BFSIKYCView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: KYCStep = .intro
    @State private var livenessComplete = false
    @State private var documentUploaded = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(stepIndex >= i ? Color.indigo : Color.secondary.opacity(0.2))
                            .frame(height: 4)
                    }
                }.padding(.horizontal).padding(.top, 8)
                switch step {
                case .intro:    KYCIntroStep { step = .liveness }
                case .liveness: KYCLivenessStep(complete: $livenessComplete) { step = .document }
                case .document: KYCDocumentStep(uploaded: $documentUploaded) { step = .review }
                case .review:   KYCReviewStep(livenessOK: livenessComplete, docOK: documentUploaded) { step = .complete }
                case .complete: KYCCompleteStep { dismiss() }
                }
            }
            .navigationTitle("Identity Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
    private var stepIndex: Int {
        switch step {
        case .intro: return 0; case .liveness: return 1
        case .document: return 2; case .review: return 3; case .complete: return 4
        }
    }
}

private struct KYCIntroStep: View {
    let onNext: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                ZStack {
                    Circle().fill(Color.indigo.opacity(0.10)).frame(width: 90, height: 90)
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.system(size: 40)).foregroundColor(.indigo)
                }
                Text("Verify Your Identity").font(.title2.bold())
                Text("We need to verify your identity to comply with KYC regulations.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                VStack(alignment: .leading, spacing: 14) {
                    KYCRow(icon: "faceid", text: "Facial liveness check (front camera)")
                    KYCRow(icon: "doc.text.viewfinder", text: "Government-issued ID")
                    KYCRow(icon: "lock.shield.fill", text: "Your data is encrypted and secure")
                }
                .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                Button(action: onNext) {
                    Text("Start Verification").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.indigo, in: RoundedRectangle(cornerRadius: 12))
                }.padding(.horizontal)
                Spacer(minLength: 24)
            }
        }
    }
}

private struct KYCRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundColor(.indigo).frame(width: 24)
            Text(text).font(.subheadline)
        }
    }
}

private struct KYCLivenessStep: View {
    @Binding var complete: Bool
    let onNext: () -> Void
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            ZStack {
                Circle().stroke(complete ? Color.green : Color.indigo.opacity(0.3), lineWidth: 6)
                    .frame(width: 200, height: 200)
                if let img = capturedImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 188, height: 188).clipShape(Circle())
                } else {
                    Image(systemName: "faceid").font(.system(size: 60)).foregroundColor(.indigo)
                }
            }
            if complete {
                Label("Liveness check passed!", systemImage: "checkmark.circle.fill")
                    .font(.headline).foregroundColor(.green)
            } else {
                Text("Position your face in the circle").font(.headline)
            }
            if !complete {
                Button { showCamera = true } label: {
                    Label("Open Front Camera", systemImage: "camera.fill")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.indigo, in: RoundedRectangle(cornerRadius: 12))
                }.padding(.horizontal)
            } else {
                Button(action: onNext) {
                    Text("Continue").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.indigo, in: RoundedRectangle(cornerRadius: 12))
                }.padding(.horizontal)
            }
            Spacer(minLength: 24)
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(sourceType: .camera, cameraDevice: .front) { img in
                capturedImage = img; complete = true
            }
        }
    }
}

private struct KYCDocumentStep: View {
    @Binding var uploaded: Bool
    let onNext: () -> Void
    @State private var selectedDoc = 0
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var capturedImage: UIImage?
    private let docTypes = ["Passport", "Driving Licence", "National ID"]
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color.indigo.opacity(0.07)).frame(width: 220, height: 140)
                if let img = capturedImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 220, height: 140).clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: uploaded ? "checkmark.seal.fill" : "doc.text.viewfinder")
                        .font(.system(size: 50)).foregroundColor(uploaded ? .green : .indigo)
                }
            }
            Text(uploaded ? "Document uploaded!" : "Upload your ID").font(.title3.bold())
            if !uploaded {
                Picker("Document type", selection: $selectedDoc) {
                    ForEach(docTypes.indices, id: \.self) { i in Text(docTypes[i]).tag(i) }
                }.pickerStyle(.segmented).padding(.horizontal)
                Button { showCamera = true } label: {
                    Label("Scan with Camera", systemImage: "camera.viewfinder")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.indigo, in: RoundedRectangle(cornerRadius: 12))
                }.padding(.horizontal)
                Button { showPhotoPicker = true } label: {
                    Label("Upload from Photos", systemImage: "photo.on.rectangle")
                        .font(.headline).foregroundColor(.indigo)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                }.padding(.horizontal)
            } else {
                Button(action: onNext) {
                    Text("Continue").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.indigo, in: RoundedRectangle(cornerRadius: 12))
                }.padding(.horizontal)
            }
            Spacer(minLength: 24)
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(sourceType: .camera, cameraDevice: .rear) { img in capturedImage = img; uploaded = true }
        }
        .sheet(isPresented: $showPhotoPicker) {
            CameraPickerView(sourceType: .photoLibrary, cameraDevice: .rear) { img in capturedImage = img; uploaded = true }
        }
    }
}

private struct KYCReviewStep: View {
    let livenessOK: Bool; let docOK: Bool; let onSubmit: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            Image(systemName: "checkmark.shield.fill").font(.system(size: 60)).foregroundColor(.indigo)
            Text("Review and Submit").font(.title3.bold())
            VStack(spacing: 12) {
                KYCStatusRow(label: "Facial Liveness", ok: livenessOK)
                KYCStatusRow(label: "Document Upload", ok: docOK)
            }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
            Button(action: onSubmit) {
                Text("Submit for Verification").font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.indigo, in: RoundedRectangle(cornerRadius: 12))
            }.padding(.horizontal)
            Spacer(minLength: 24)
        }
    }
}

private struct KYCStatusRow: View {
    let label: String; let ok: Bool
    var body: some View {
        HStack {
            Text(label).font(.subheadline); Spacer()
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(ok ? .green : .red)
        }
    }
}

private struct KYCCompleteStep: View {
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Color.green.opacity(0.12)).frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundColor(.green)
            }
            Text("Verification Submitted!").font(.title2.bold())
            Text("Your KYC documents have been submitted. Verification typically takes 1-2 business days.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            Button(action: onDone) {
                Text("Done").font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.indigo, in: RoundedRectangle(cornerRadius: 12))
            }.padding(.horizontal)
            Spacer()
        }
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let cameraDevice: UIImagePickerController.CameraDevice
    let onCapture: (UIImage) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        if picker.sourceType == .camera {
            picker.cameraDevice = UIImagePickerController.isCameraDeviceAvailable(cameraDevice) ? cameraDevice : .rear
        }
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { onCapture(img) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}
