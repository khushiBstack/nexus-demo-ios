import SwiftUI
import LocalAuthentication
import Combine

// MARK: 2) Biometric test

struct BiometricTestView: View {
    @State private var resultMessage: String?
    @State private var succeeded = false
    @State private var isTesting = false
    @State private var showResult = false

    private var biometricType: String {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            return "Passcode"
        }
        switch ctx.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Biometrics"
        }
    }

    private var biometricIcon: String {
        switch biometricType {
        case "Face ID": return "faceid"
        case "Touch ID": return "touchid"
        default: return "lock.shield.fill"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: succeeded ? "checkmark.seal.fill" : biometricIcon)
                        .font(.system(size: 64))
                        .foregroundColor(succeeded ? .green : .indigo)
                        .accessibilityHidden(true)
                    Text("Biometric Authentication").font(.title2.bold())
                    Text("Tests \(biometricType) on this device")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }.padding(.top, 8)

                if showResult, let msg = resultMessage {
                    VStack(spacing: 12) {
                        Image(systemName: succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(succeeded ? .green : .red)
                            .accessibilityHidden(true)
                        Text(succeeded ? "Success" : "Failed")
                            .font(.headline)
                            .foregroundColor(succeeded ? .green : .red)
                        Text(msg).font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                Button {
                    runTest()
                } label: {
                    Label(isTesting ? "Authenticating…" : "Run \(biometricType) Test",
                          systemImage: biometricIcon)
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(isTesting ? Color.gray : Color.indigo,
                                    in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isTesting)
                .padding(.horizontal)
                .accessibilityLabel("Run biometric authentication test")

                if showResult {
                    Button("Reset") {
                        showResult = false; succeeded = false; resultMessage = nil
                    }
                    .foregroundColor(.indigo)
                    .accessibilityLabel("Reset biometric test")
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Biometric Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runTest() {
        isTesting = true
        showResult = false
        let context = LAContext()
        var evalError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evalError) else {
            DispatchQueue.main.async {
                succeeded = false
                resultMessage = "Not available: \(evalError?.localizedDescription ?? "unknown error")"
                showResult = true
                isTesting = false
            }
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication,
                                localizedReason: "Authenticate to test Nexus Demo biometrics") { success, error in
            DispatchQueue.main.async {
                isTesting = false
                succeeded = success
                showResult = true
                if success {
                    resultMessage = "Authentication succeeded."
                } else if let err = error as? LAError {
                    switch err.code {
                    case .userCancel, .appCancel, .systemCancel:
                        resultMessage = "Cancelled by user."
                    case .userFallback:
                        resultMessage = "User chose passcode fallback."
                    case .biometryNotAvailable:
                        resultMessage = "Biometry not available on this device."
                    case .biometryNotEnrolled:
                        resultMessage = "No biometrics enrolled."
                    case .biometryLockout:
                        resultMessage = "Biometry locked out. Use passcode."
                    default:
                        resultMessage = err.localizedDescription
                    }
                } else {
                    resultMessage = error?.localizedDescription ?? "Authentication failed."
                }
            }
        }
    }
}

#Preview {
    NavigationStack { BiometricTestView() }
}
