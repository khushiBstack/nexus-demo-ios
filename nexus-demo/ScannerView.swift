import SwiftUI
import AVFoundation

struct ScannerView: View {
    @State private var scannedCode: String?
    @State private var isShowingScanner = true
    @State private var navigateToResult = false

    var body: some View {
        VStack(spacing: 20) {
            if isShowingScanner {
                CameraScannerRepresentable { code in
                    scannedCode = code
                    isShowingScanner = false
                    navigateToResult = true
                }
                .frame(height: 350)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.secondary, lineWidth: 1)
                )
                .padding(.horizontal)

                Text("Point your camera at a QR code")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .navigationTitle("Scan QR Code")
        .navigationDestination(isPresented: $navigateToResult) {
            if let code = scannedCode {
                QRResultView(scannedText: code) {
                    scannedCode = nil
                    isShowingScanner = true
                    navigateToResult = false
                }
            }
        }
    }
}

struct QRResultView: View {
    let scannedText: String
    let onScanAgain: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.indigo)

            Text("QR Code Result")
                .font(.title2.bold())

            Text(scannedText)
                .font(.body.monospaced())
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .accessibilityIdentifier("qr_result_text")

            Button(action: onScanAgain) {
                Label("Scan Again", systemImage: "qrcode.viewfinder")
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)

            Spacer()
        }
        .navigationTitle("Scan Result")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Wraps an AVFoundation capture session as a SwiftUI view.
struct CameraScannerRepresentable: UIViewControllerRepresentable {
    var onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private let session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.configureSession() }
                }
            }
        default:
            break
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        session.stopRunning()
        onCodeScanned?(value)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.forEach { $0.frame = view.bounds }
    }
}

#Preview {
    NavigationStack {
        ScannerView()
    }
}
