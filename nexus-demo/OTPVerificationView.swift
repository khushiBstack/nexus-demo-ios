import SwiftUI
import Combine

// MARK: - OTP Send State

enum OTPSendState: Equatable {
    case idle
    case sending
    case sent
    case failed(String)
}

enum OTPVerifyState: Equatable {
    case idle
    case verifying
    case verified
    case failed(String)
}

// MARK: - Single digit box

struct OTPDigitBox: View {
    @Binding var digit: String
    let tint: Color
    let isFocused: Bool
    var position: Int = 0

    var body: some View {
        VStack(spacing: 3) {
            Text("\(position + 1)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField("–", text: $digit)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2.bold())
                .frame(width: 44, height: 54)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? tint : Color.secondary.opacity(0.3),
                                lineWidth: isFocused ? 2 : 1)
                )
                .accessibilityLabel("Digit \(position + 1) of 6")
                .accessibilityValue(digit.isEmpty ? "empty" : digit)
        }
    }
}

// MARK: - Shared OTP Verification View (used by all domains)

struct OTPVerificationView: View {
    let title: String
    let tint: Color
    let icon: String
    let onSuccess: () -> Void

    @State private var phone = ""
    @State private var sendState: OTPSendState = .idle
    @State private var verifyState: OTPVerifyState = .idle
    @State private var digits = Array(repeating: "", count: 6)
    @State private var resendCountdown = 0
    @State private var timer: AnyCancellable?
    @FocusState private var focusedIndex: Int?

    private var codeSent: Bool {
        if case .sent = sendState { return true }
        return false
    }
    private var isVerified: Bool {
        if case .verified = verifyState { return true }
        return false
    }
    private var enteredCode: String { digits.joined() }
    private var isComplete: Bool { digits.allSatisfy { $0.count == 1 } }

    /// Normalise phone to E.164 — prepend + if missing
    private var e164Phone: String {
        let stripped = phone.filter { $0.isNumber || $0 == "+" }
        return stripped.hasPrefix("+") ? stripped : "+\(stripped)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 30)

                // Hero
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.6)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Image(systemName: icon)
                            .font(.system(size: 34))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                    Text(title)
                        .font(.largeTitle.bold())
                    Text("OTP Verification")
                        .foregroundStyle(.secondary)
                }

                if !codeSent {
                    // Phone entry
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Phone Number")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                                .accessibilityHidden(true)
                            TextField("+1 555 000 0000", text: $phone)
                                .keyboardType(.phonePad)
                                .accessibilityLabel("Phone number")
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        // Send error
                        if case .failed(let msg) = sendState {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 4)
                                .accessibilityLabel(msg)
                        }

                        Button {
                            Task { await sendOTP() }
                        } label: {
                            HStack {
                                if case .sending = sendState {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 4)
                                }
                                Text(sendState == .sending ? "Sending…" : "Send OTP")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                phone.count >= 6 ? tint : Color.secondary.opacity(0.3),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(.white)
                        }
                        .disabled(phone.count < 6 || sendState == .sending)
                        .accessibilityLabel("Send OTP")
                    }
                    .padding(.horizontal)
                } else {
                    // OTP entry
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Enter the 6-digit code")
                                .font(.headline)
                            Text("Sent to \(phone)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Code sent to \(phone)")
                        }

                        // 6-box OTP input
                        HStack(spacing: 10) {
                            ForEach(0..<6, id: \.self) { i in
                                OTPDigitBox(
                                    digit: $digits[i],
                                    tint: tint,
                                    isFocused: focusedIndex == i,
                                    position: i
                                )
                                .focused($focusedIndex, equals: i)
                                .onChange(of: digits[i]) { newVal in
                                    handleDigitChange(index: i, value: newVal)
                                }
                            }
                        }

                        // Twilio not configured — show fallback hint
                        if !TwilioConfig.isConfigured {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                    .accessibilityHidden(true)
                                Text("Twilio not configured — enter any 6 digits to demo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        }

                        // Verify result
                        switch verifyState {
                        case .verified:
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .accessibilityHidden(true)
                                Text("Verified successfully ✓")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.green)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Verified successfully")

                        case .failed(let msg):
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .accessibilityHidden(true)
                                Text(msg)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel(msg)

                        default:
                            EmptyView()
                        }

                        if isVerified {
                            Button { onSuccess() } label: {
                                Text("Continue")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                            }
                            .accessibilityLabel("Continue to app")
                        } else {
                            Button {
                                Task { await verify() }
                            } label: {
                                HStack {
                                    if case .verifying = verifyState {
                                        ProgressView().tint(.white).padding(.trailing, 4)
                                    }
                                    Text(verifyState == .verifying ? "Verifying…" : "Verify")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    isComplete ? tint : Color.secondary.opacity(0.3),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .foregroundStyle(.white)
                            }
                            .disabled(!isComplete || verifyState == .verifying)
                            .accessibilityLabel("Verify OTP")

                            if resendCountdown > 0 {
                                Text("Resend in \(resendCountdown)s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Button("Resend OTP") { Task { await resend() } }
                                    .font(.caption)
                                    .tint(tint)
                                    .accessibilityLabel("Resend OTP")
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 30)
            }
            .padding()
        }
        .navigationTitle("OTP Verification")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if codeSent { focusedIndex = 0 } }
    }

    // MARK: - Actions

    private func sendOTP() async {
        sendState = .sending
        digits = Array(repeating: "", count: 6)
        verifyState = .idle

        if TwilioConfig.isConfigured {
            do {
                try await TwilioVerifyService.shared.sendOTP(to: e164Phone)
                sendState = .sent
                startResendTimer()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focusedIndex = 0 }
            } catch {
                sendState = .failed(error.localizedDescription)
            }
        } else {
            // Demo fallback — no real SMS sent
            sendState = .sent
            startResendTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focusedIndex = 0 }
        }
    }

    private func resend() async {
        digits = Array(repeating: "", count: 6)
        verifyState = .idle
        await sendOTP()
    }

    private func verify() async {
        verifyState = .verifying

        if TwilioConfig.isConfigured {
            do {
                let approved = try await TwilioVerifyService.shared.verifyOTP(
                    phoneNumber: e164Phone, code: enteredCode)
                if approved {
                    verifyState = .verified
                    focusedIndex = nil
                } else {
                    verifyState = .failed("Incorrect code. Try again.")
                    digits = Array(repeating: "", count: 6)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focusedIndex = 0 }
                }
            } catch {
                verifyState = .failed(error.localizedDescription)
                digits = Array(repeating: "", count: 6)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focusedIndex = 0 }
            }
        } else {
            // Demo fallback — accept any 6-digit code
            verifyState = .verified
            focusedIndex = nil
        }
    }

    private func handleDigitChange(index: Int, value: String) {
        if value.count > 1 { digits[index] = String(value.suffix(1)) }
        if digits[index].count == 1 && index < 5 {
            focusedIndex = index + 1
        } else if digits[index].count == 1 && index == 5 {
            focusedIndex = nil
            Task {
                await verify()
            }
        }
        if digits[index].isEmpty && index > 0 { focusedIndex = index - 1 }
    }

    private func startResendTimer() {
        resendCountdown = 30
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if resendCountdown > 0 { resendCountdown -= 1 }
                else { timer?.cancel() }
            }
    }
}

// MARK: - Standalone OTP Test View

struct OTPTestView: View {
    @State private var phone = ""
    @State private var sendState: OTPSendState = .idle
    @State private var verifyState: OTPVerifyState = .idle
    @State private var digits = Array(repeating: "", count: 6)
    @State private var resendCountdown = 0
    @State private var timer: AnyCancellable?
    @FocusState private var focusedIndex: Int?

    private var codeSent: Bool {
        if case .sent = sendState { return true }
        return false
    }
    private var isVerified: Bool {
        if case .verified = verifyState { return true }
        return false
    }
    private var enteredCode: String { digits.joined() }
    private var isComplete: Bool { digits.allSatisfy { $0.count == 1 } }
    private var e164Phone: String {
        let stripped = phone.filter { $0.isNumber || $0 == "+" }
        return stripped.hasPrefix("+") ? stripped : "+\(stripped)"
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phone Number")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("+1 555 000 0000", text: $phone)
                        .keyboardType(.phonePad)
                        .accessibilityLabel("Phone number")
                }

                if case .failed(let msg) = sendState {
                    Text(msg).font(.caption).foregroundStyle(.red)
                }

                Button {
                    Task { await sendOTP() }
                } label: {
                    HStack {
                        if case .sending = sendState {
                            ProgressView().scaleEffect(0.8)
                        }
                        Text(sendState == .sending ? "Sending…" : "Send OTP")
                    }
                }
                .disabled(phone.count < 6 || sendState == .sending)
                .accessibilityLabel("Send OTP")
            } header: {
                Text("Phone Number")
            }

            if codeSent {
                if !TwilioConfig.isConfigured {
                    Section {
                        Label("Twilio not configured — enter any 6 digits to demo",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { i in
                            OTPDigitBox(
                                digit: $digits[i],
                                tint: .indigo,
                                isFocused: focusedIndex == i,
                                position: i
                            )
                            .focused($focusedIndex, equals: i)
                            .onChange(of: digits[i]) { newVal in
                                if newVal.count > 1 { digits[i] = String(newVal.suffix(1)) }
                                if digits[i].count == 1 && i < 5 { focusedIndex = i + 1 }
                                if digits[i].count == 1 && i == 5 {
                                    focusedIndex = nil
                                    Task { await verify() }
                                }
                                if digits[i].isEmpty && i > 0 { focusedIndex = i - 1 }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    switch verifyState {
                    case .verified:
                        Label("Verified successfully ✓", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .accessibilityLabel("Verified successfully")
                    case .failed(let msg):
                        Label(msg, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .accessibilityLabel(msg)
                    default:
                        EmptyView()
                    }

                    if isVerified {
                        Button("Continue") { }
                            .foregroundStyle(.green)
                            .accessibilityLabel("Verified")
                    } else {
                        Button {
                            Task { await verify() }
                        } label: {
                            HStack {
                                if case .verifying = verifyState {
                                    ProgressView().scaleEffect(0.8)
                                }
                                Text(verifyState == .verifying ? "Verifying…" : "Verify")
                            }
                        }
                        .disabled(!isComplete || verifyState == .verifying)
                        .accessibilityLabel("Verify OTP")

                        if resendCountdown > 0 {
                            Text("Resend in \(resendCountdown)s")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Button("Resend OTP") { Task { await resend() } }
                                .tint(.indigo)
                                .accessibilityLabel("Resend OTP")
                        }
                    }
                } header: {
                    Text("OTP Code")
                }
            }
        }
        .navigationTitle("OTP Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if codeSent { focusedIndex = 0 } }
    }

    private func sendOTP() async {
        sendState = .sending
        digits = Array(repeating: "", count: 6)
        verifyState = .idle
        if TwilioConfig.isConfigured {
            do {
                try await TwilioVerifyService.shared.sendOTP(to: e164Phone)
                sendState = .sent
                startResendTimer()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focusedIndex = 0 }
            } catch {
                sendState = .failed(error.localizedDescription)
            }
        } else {
            sendState = .sent
            startResendTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focusedIndex = 0 }
        }
    }

    private func resend() async {
        digits = Array(repeating: "", count: 6)
        verifyState = .idle
        await sendOTP()
    }

    private func verify() async {
        verifyState = .verifying
        if TwilioConfig.isConfigured {
            do {
                let approved = try await TwilioVerifyService.shared.verifyOTP(
                    phoneNumber: e164Phone, code: enteredCode)
                verifyState = approved ? .verified : .failed("Incorrect code. Try again.")
                if !approved {
                    digits = Array(repeating: "", count: 6)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focusedIndex = 0 }
                } else {
                    focusedIndex = nil
                }
            } catch {
                verifyState = .failed(error.localizedDescription)
                digits = Array(repeating: "", count: 6)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focusedIndex = 0 }
            }
        } else {
            verifyState = .verified
            focusedIndex = nil
        }
    }

    private func startResendTimer() {
        resendCountdown = 30
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if resendCountdown > 0 { resendCountdown -= 1 }
                else { timer?.cancel() }
            }
    }
}

#Preview {
    NavigationStack {
        OTPVerificationView(title: "ShopNexus", tint: .orange, icon: "bag.fill") {}
    }
}
