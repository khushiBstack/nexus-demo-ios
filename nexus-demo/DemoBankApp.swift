import SwiftUI
import Combine
import UserNotifications
import UIKit

// MARK: - App Delegate

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        ShakeWindowInstaller.install()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - Foreground Notification Delegate (fallback)
// Used when AppDelegate hasn't set the delegate yet (e.g. on BrowserStack cold start)

final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundNotificationDelegate()
    private override init() {}

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - Session Store

final class SessionStore: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var kycCompleted: Bool = false
    @Published var ecommerceLoggedIn: Bool = false
    @Published var ecommerceUserName: String = ""
    @Published var ecommerceUserEmail: String = ""
    @Published var ecommerceOTPVerified: Bool = false
    @Published var healthcareLoggedIn: Bool = false
    @Published var healthcareUserName: String = ""
    @Published var healthcareUserEmail: String = ""
    @Published var healthcareOTPVerified: Bool = false
    @Published var travelLoggedIn: Bool = false
    @Published var travelUserName: String = ""
    @Published var travelUserEmail: String = ""
    @Published var travelOTPVerified: Bool = false
    @Published var bfsiOTPVerified: Bool = false

    static func displayName(from email: String) -> String {
        let local = email.split(separator: "@").first.map(String.init) ?? email
        return local.split(separator: ".").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}

@main
struct DemoBankApp: App {
    @StateObject private var session = SessionStore()
    @StateObject private var bfsiStore = BFSIStore()
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var geo = IPGeoManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DomainSelectionView()
            }
            .shakeDetector()
            .environmentObject(session)
            .environmentObject(bfsiStore)
            .environmentObject(theme)
            .environmentObject(geo)
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            .overlay(alignment: .bottom) {
                if theme.showShakeToast {
                    ShakeThemeToast(isDarkMode: theme.isDarkMode)
                        .padding(.bottom, 48)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: theme.showShakeToast)
                        .zIndex(1000)
                }
            }
        }
    }
}

// MARK: - IP Geo Manager

final class IPGeoManager: ObservableObject {
    static let shared = IPGeoManager()

    @Published var city: String?
    @Published var country: String?
    @Published var countryCode: String?
    @Published var region: String?
    @Published var ip: String?
    @Published var isLoading: Bool = false
    @Published var hasFetched: Bool = false

    var currencyCode: String {
        switch countryCode?.uppercased() {
        case "US": return "USD"
        case "GB": return "GBP"
        case "DE", "FR", "IT", "ES", "NL", "BE", "AT", "PT", "IE", "FI", "GR": return "EUR"
        case "IN": return "INR"
        case "JP": return "JPY"
        case "AU": return "AUD"
        case "CA": return "CAD"
        case "SG": return "SGD"
        case "AE": return "AED"
        default: return "USD"
        }
    }

    var locationLabel: String {
        if let c = city, let cc = countryCode { return "\(c), \(cc)" }
        if let co = country { return co }
        return "your location"
    }

    /// GPS-based city (more accurate than IP geo for device location)
    @Published var gpsCity: String?

    /// Best available city: GPS first, then IP geo
    var bestCity: String? { gpsCity ?? city }

    private init() {}

    func fetchIfNeeded() {
        guard !hasFetched, !isLoading else { return }
        fetch()
    }

    func fetch() {
        isLoading = true
        guard let url = URL(string: "https://ipapi.co/json/") else { isLoading = false; return }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.hasFetched = true
                guard let data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                self.ip          = json["ip"] as? String
                self.city        = json["city"] as? String
                self.region      = json["region"] as? String
                self.country     = json["country_name"] as? String
                self.countryCode = json["country_code"] as? String
            }
        }.resume()
    }
}

// MARK: - IP Location Badge

struct IPLocationBadge: View {
    @EnvironmentObject var geo: IPGeoManager
    var tint: Color = .blue
    var body: some View {
        if let label = geo.city ?? geo.country {
            Label(label, systemImage: "network").font(.caption).foregroundStyle(tint)
                .accessibilityLabel("IP location: \(label)")
        }
    }
}
