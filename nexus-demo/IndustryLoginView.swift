import SwiftUI
import LocalAuthentication
import Combine

/// Reusable login screen for E-commerce, Healthcare, and Travel domains.
/// Captures the email/name and writes them into the domain-specific session slot.
struct IndustryLoginView: View {
    let title: String
    let icon: String
    let tint: Color
    let onSuccess: (_ email: String, _ name: String) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    private var canSignIn: Bool {
        email.contains("@") && !password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                // Hero
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Image(systemName: icon)
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                            .accessibilityLabel(title + " logo")
                    }
                    Text(title)
                        .font(.largeTitle.bold())
                    Text("Sign in to continue")
                        .foregroundStyle(.secondary)
                }

                // Form card
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                                .accessibilityHidden(true)
                            TextField("Email", text: $email)
                                .textContentType(.username)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .accessibilityLabel("Email address")
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                                .accessibilityHidden(true)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .accessibilityLabel("Password")
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                                .accessibilityHidden(true)
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }

                    // Inline hint when email has no @
                    if !email.isEmpty && !email.contains("@") {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            Text("Enter a valid email address")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        signIn()
                    } label: {
                        Text("Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                canSignIn ? tint : Color.secondary.opacity(0.3),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(!canSignIn)
                    .accessibilityLabel("Sign In")

                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                        Text("or").font(.caption).foregroundStyle(.secondary)
                        Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                    }

                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        HStack {
                            Image(systemName: "faceid")
                                .accessibilityHidden(true)
                            Text("Sign in with Face ID")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .tint(tint)
                    .disabled(isAuthenticating)
                    .accessibilityLabel("Sign in with Face ID")
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding()
        }
    }

    private func signIn() {
        let name = SessionStore.displayName(from: email)
        onSuccess(email, name.isEmpty ? "User" : name)
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var evalError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evalError) else {
            errorMessage = "Biometric authentication isn't available on this device."
            return
        }
        isAuthenticating = true
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Sign in to \(title)"
        ) { success, authError in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    onSuccess("", "User")
                } else {
                    errorMessage = authError?.localizedDescription ?? "Authentication failed."
                }
            }
        }
    }
}
