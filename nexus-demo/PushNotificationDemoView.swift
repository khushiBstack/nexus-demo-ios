import SwiftUI
import UserNotifications

// MARK: - Push Notification Demo View
// Shared across all domains and the standalone tab.
// Requests permission, then lets the user schedule a local push notification
// with a custom title, body, and delay — simulating a real push for testing.

struct PushNotification: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let scheduledAt: Date
    var delivered: Bool = false
}

// MARK: - iOS-style notification banner overlay

struct NotificationBannerView: View {
    let notifTitle: String
    let notifBody: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(notifTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .accessibilityIdentifier("notification_banner_title")
                Text(notifBody)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .accessibilityIdentifier("notification_banner_body")
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(tint.gradient)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Push notification: \(notifTitle). \(notifBody)")
        .accessibilityIdentifier("notification_banner")
    }
}

struct PushNotificationDemoView: View {
    /// Domain branding — pass nil for the standalone version
    var domainTitle: String = "Push Notifications"
    var domainTint: Color = .indigo
    var domainIcon: String = "bell.badge.fill"

    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var notifTitle = ""
    @State private var notifBody = ""
    @State private var delaySeconds: Double = 5
    @State private var scheduled: [PushNotification] = []
    @State private var showScheduledBanner = false
    @State private var bannerMessage = ""

    // In-app notification banner state
    @State private var showNotificationBanner = false
    @State private var bannerTitle = ""
    @State private var bannerBody = ""

    var body: some View {
        ZStack(alignment: .top) {
            Form {
                // Permission section
                Section {
                    HStack {
                        Image(systemName: permissionIcon)
                            .foregroundStyle(permissionColor)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notification Permission")
                                .font(.subheadline.weight(.semibold))
                            Text(permissionLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if permissionStatus == .notDetermined {
                            Button("Allow") { requestPermission() }
                                .buttonStyle(.borderedProminent)
                                .tint(domainTint)
                                .accessibilityLabel("Allow notifications")
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Permission")
                }

                // Compose section
                Section {
                    LabeledContent("Title") {
                        TextField("Notification title", text: $notifTitle)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Notification title")
                    }

                    LabeledContent("Body") {
                        TextField("Notification body", text: $notifBody)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Notification body")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Delay")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(delaySeconds))s")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(domainTint)
                        }
                        Slider(value: $delaySeconds, in: 3...60, step: 1)
                            .tint(domainTint)
                            .accessibilityLabel("Delay in seconds: \(Int(delaySeconds))")
                    }
                } header: {
                    Text("Compose")
                }

                // Schedule button
                Section {
                    Button {
                        scheduleNotification()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "paperplane.fill")
                                .accessibilityHidden(true)
                            Text("Schedule Notification")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(!canSchedule)
                    .tint(domainTint)
                    .accessibilityLabel("Schedule notification")
                }

                // Scheduled list
                if !scheduled.isEmpty {
                    Section {
                        ForEach(scheduled) { notif in
                            HStack(spacing: 12) {
                                Image(systemName: notif.delivered ? "checkmark.circle.fill" : "clock.fill")
                                    .foregroundStyle(notif.delivered ? .green : domainTint)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(notif.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(notif.body)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(notif.scheduledAt, style: .time)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Text(notif.delivered ? "Sent" : "Pending")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        (notif.delivered ? Color.green : domainTint).opacity(0.12),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(notif.delivered ? .green : domainTint)
                            }
                            .padding(.vertical, 4)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(notif.title): \(notif.body), \(notif.delivered ? "sent" : "pending")")
                        }
                    } header: {
                        Text("Scheduled (\(scheduled.count))")
                    }
                }
            }
            .navigationTitle(domainTitle)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if showScheduledBanner {
                    Text(bannerMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(domainTint, in: RoundedRectangle(cornerRadius: 0))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                        .accessibilityLabel(bannerMessage)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showScheduledBanner)
            .onAppear { checkPermission() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkPermission()
                markDelivered()
            }

            // iOS-style in-app notification banner
            if showNotificationBanner {
                NotificationBannerView(notifTitle: bannerTitle, notifBody: bannerBody, tint: domainTint)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showNotificationBanner = false
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showNotificationBanner)
    }

    // MARK: - Computed

    private var canSchedule: Bool {
        permissionStatus == .authorized && !notifTitle.isEmpty && !notifBody.isEmpty
    }

    private var permissionIcon: String {
        switch permissionStatus {
        case .authorized: return "checkmark.circle.fill"
        case .denied:     return "xmark.circle.fill"
        default:          return "questionmark.circle.fill"
        }
    }

    private var permissionColor: Color {
        switch permissionStatus {
        case .authorized: return .green
        case .denied:     return .red
        default:          return .orange
        }
    }

    private var permissionLabel: String {
        switch permissionStatus {
        case .authorized: return "Notifications are enabled"
        case .denied:     return "Notifications denied — enable in Settings"
        case .provisional: return "Provisional permission granted"
        default:          return "Tap Allow to enable notifications"
        }
    }

    // MARK: - Actions

    private func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                permissionStatus = settings.authorizationStatus
            }
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                permissionStatus = granted ? .authorized : .denied
            }
        }
    }

    private func scheduleNotification() {
        // Ensure the delegate is set so foreground banners are shown
        if UNUserNotificationCenter.current().delegate == nil {
            UNUserNotificationCenter.current().delegate = ForegroundNotificationDelegate.shared
        }

        let content = UNMutableNotificationContent()
        content.title = notifTitle
        content.body  = notifBody
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)
        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        let capturedTitle = notifTitle
        let capturedBody = notifBody

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    let notif = PushNotification(
                        title: capturedTitle,
                        body: capturedBody,
                        scheduledAt: Date().addingTimeInterval(delaySeconds)
                    )
                    scheduled.insert(notif, at: 0)
                    bannerMessage = "Notification scheduled in \(Int(delaySeconds))s"
                    showScheduledBanner = true
                    notifTitle = ""
                    notifBody = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showScheduledBanner = false
                    }
                    // Show in-app banner after the delay (visible in session recording)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
                        bannerTitle = capturedTitle
                        bannerBody = capturedBody
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showNotificationBanner = true
                        }
                        // Auto-dismiss after 4 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation(.spring(response: 0.3)) {
                                showNotificationBanner = false
                            }
                        }
                        markDelivered()
                    }
                }
            }
        }
    }

    private func markDelivered() {
        let now = Date()
        for i in scheduled.indices where !scheduled[i].delivered && scheduled[i].scheduledAt <= now {
            scheduled[i].delivered = true
        }
    }
}

#Preview {
    NavigationStack {
        PushNotificationDemoView(domainTitle: "Push Notifications", domainTint: .indigo, domainIcon: "bell.badge.fill")
    }
}
