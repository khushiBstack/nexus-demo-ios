import Foundation

// MARK: - Twilio Verify Service
// Replace the placeholder values below with your real Twilio credentials.
// In production, these calls should go through your own backend server
// so credentials are never shipped in the app binary.
//
// Setup:
//   1. Create a Twilio account at https://www.twilio.com
//   2. Create a Verify Service at https://console.twilio.com/us1/verify/services
//   3. Fill in the three constants below with your Account SID, Auth Token, and Service SID

enum TwilioConfig {
    /// Your Twilio Account SID (starts with "AC...")
    static let accountSID  = "TWILIO_ACCOUNT_SID"
    /// Your Twilio Auth Token
    static let authToken   = "TWILIO_AUTH_TOKEN"
    /// Your Twilio Verify Service SID (starts with "VA...")
    static let serviceSID  = "TWILIO_VERIFY_SERVICE_SID"

    /// Returns true when all three values have been filled in
    static var isConfigured: Bool {
        !accountSID.hasPrefix("TWILIO_") &&
        !authToken.hasPrefix("TWILIO_") &&
        !serviceSID.hasPrefix("TWILIO_")
    }
}

// MARK: - Twilio Verify API

enum TwilioVerifyError: LocalizedError {
    case notConfigured
    case networkError(String)
    case twilioError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Twilio credentials not configured. Open TwilioVerifyService.swift and fill in your Account SID, Auth Token, and Service SID."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .twilioError(let code, let msg):
            return "Twilio error \(code): \(msg)"
        }
    }
}

final class TwilioVerifyService {
    static let shared = TwilioVerifyService()
    private init() {}

    /// Send a verification code to the given phone number (E.164 format, e.g. +14155552671)
    func sendOTP(to phoneNumber: String) async throws {
        guard TwilioConfig.isConfigured else { throw TwilioVerifyError.notConfigured }

        let url = URL(string: "https://verify.twilio.com/v2/Services/\(TwilioConfig.serviceSID)/Verifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let credentials = "\(TwilioConfig.accountSID):\(TwilioConfig.authToken)"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

        let body = "To=\(phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? phoneNumber)&Channel=sms"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode == 201 { return } // success

        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        let message = json["message"] as? String ?? "Unknown error"
        throw TwilioVerifyError.twilioError(statusCode, message)
    }

    /// Check the verification code entered by the user
    func verifyOTP(phoneNumber: String, code: String) async throws -> Bool {
        guard TwilioConfig.isConfigured else { throw TwilioVerifyError.notConfigured }

        let url = URL(string: "https://verify.twilio.com/v2/Services/\(TwilioConfig.serviceSID)/VerificationCheck")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let credentials = "\(TwilioConfig.accountSID):\(TwilioConfig.authToken)"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

        let encodedPhone = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? phoneNumber
        let body = "To=\(encodedPhone)&Code=\(code)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]

        if statusCode == 200 {
            let status = json["status"] as? String ?? ""
            return status == "approved"
        }

        let message = json["message"] as? String ?? "Unknown error"
        throw TwilioVerifyError.twilioError(statusCode, message)
    }
}
