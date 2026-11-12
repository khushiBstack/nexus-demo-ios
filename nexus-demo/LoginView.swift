import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var session: SessionStore

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                // Hero
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                    Text("DemoBank")
                        .font(.largeTitle.bold())
                    Text("Sign in to your account")
                        .foregroundStyle(.secondary)
                }

                // Form card
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            TextField("Email", text: $email)
                                .textContentType(.username)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }

                    Button {
                        logIn()
                    } label: {
                        Text("Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (email.isEmpty || password.isEmpty)
                                    ? Color.secondary.opacity(0.3)
                                    : Color.indigo,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(email.isEmpty || password.isEmpty)

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
                            Text("Sign in with Face ID")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isAuthenticating)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding()
        }
    }

    private func logIn() {
        errorMessage = nil
        let name = SessionStore.displayName(from: email)
        session.userEmail = email
        session.userName = name.isEmpty ? "User" : name
        session.isLoggedIn = true
        session.bfsiOTPVerified = false
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
            localizedReason: "Sign in to DemoBank"
        ) { success, authError in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    if session.userName.isEmpty { session.userName = "User" }
                    session.isLoggedIn = true
                } else {
                    errorMessage = authError?.localizedDescription ?? "Authentication failed."
                }
            }
        }
    }
}

#Preview {
    LoginView().environmentObject(SessionStore())
}
