import SwiftUI
import UIKit
import Combine

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore

    var domainName: String? = nil
    var onSignOut: (() -> Void)? = nil

    @State private var faceIDEnabled = true
    @State private var notificationsEnabled = true
    @State private var showAlerts = false
    @State private var showAvatarSourceSheet = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .camera
    @State private var avatarImage: UIImage?

    private var avatarStorageKey: String { "profileAvatar_\(domainName ?? "bfsi")" }

    private var displayName: String {
        switch domainName {
        case "E-commerce": return session.ecommerceUserName
        case "Healthcare":  return session.healthcareUserName
        case "Travel":      return session.travelUserName
        default:            return session.userName
        }
    }

    private var displayEmail: String {
        switch domainName {
        case "E-commerce": return session.ecommerceUserEmail
        case "Healthcare":  return session.healthcareUserEmail
        case "Travel":      return session.travelUserEmail
        default:            return session.userEmail
        }
    }

    private var alertConfig: (title: String, tint: Color, icon: String) {
        switch domainName {
        case "E-commerce": return ("ShopNexus", Color(red: 0.95, green: 0.42, blue: 0.13), "bell.badge.fill")
        case "Healthcare":  return ("CareNexus", Color(red: 0.18, green: 0.55, blue: 0.50), "bell.badge.fill")
        case "Travel":      return ("TravelNexus", Color.pink, "bell.badge.fill")
        default:            return ("Nexus Alerts", Color.indigo, "bell.badge.fill")
        }
    }

    var body: some View {
        List {
            // Avatar row — Button as the entire row content
            Section {
                Button {
                    showAvatarSourceSheet = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let img = avatarImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .accessibilityLabel("Profile picture for \(displayName.isEmpty ? "User" : displayName)")
                                } else {
                                    ZStack {
                                        LinearGradient(
                                            colors: [.indigo, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        Text(initials(for: displayName))
                                            .font(.title3.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())

                            Image(systemName: "camera.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Color.blue, in: Circle())
                                .offset(x: 3, y: 3)
                                .accessibilityHidden(true)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName.isEmpty ? "User" : displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if !displayEmail.isEmpty {
                                Text(displayEmail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Change Photo")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .accessibilityLabel("Change profile picture for \(displayName.isEmpty ? "User" : displayName)")
                .accessibilityIdentifier("changeProfilePicture")
            }

            Section("Security") {
                Toggle("Face ID Sign-In", isOn: $faceIDEnabled)
                    .accessibilityLabel("Face ID Sign-In: \(faceIDEnabled ? "enabled" : "disabled")")
                NavigationLink("Change Password") {
                    ChangePasswordPlaceholder()
                }
            }

            Section("Preferences") {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                    .accessibilityLabel("Push Notifications: \(notificationsEnabled ? "enabled" : "disabled")")
                Button {
                    showAlerts = true
                } label: {
                    Label("Send Alerts", systemImage: "bell.badge.fill")
                }
                .accessibilityLabel("Send Alerts")
                .accessibilityIdentifier("sendAlertsButton")
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    if let onSignOut {
                        onSignOut()
                    } else {
                        session.isLoggedIn = false
                        session.userName = ""
                        session.userEmail = ""
                        session.bfsiOTPVerified = false
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear { loadAvatar() }
        .confirmationDialog("Profile Picture", isPresented: $showAvatarSourceSheet, titleVisibility: .visible) {
            Button("Take Photo") {
                imagePickerSource = .camera
                showImagePicker = true
            }
            Button("Choose from Library") {
                imagePickerSource = .photoLibrary
                showImagePicker = true
            }
            if avatarImage != nil {
                Button("Remove Photo", role: .destructive) {
                    avatarImage = nil
                    UserDefaults.standard.removeObject(forKey: avatarStorageKey)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerRepresentable(sourceType: imagePickerSource) { image in
                if let image {
                    avatarImage = image
                    saveAvatar(image)
                }
                showImagePicker = false
            }
        }
        .sheet(isPresented: $showAlerts) {
            NavigationStack {
                PushNotificationDemoView(
                    domainTitle: alertConfig.title,
                    domainTint: alertConfig.tint,
                    domainIcon: alertConfig.icon
                )
            }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "U"
    }

    private func saveAvatar(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: avatarStorageKey)
        }
    }

    private func loadAvatar() {
        if let data = UserDefaults.standard.data(forKey: avatarStorageKey),
           let image = UIImage(data: data) {
            avatarImage = image
        }
    }
}

private struct ChangePasswordPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Change Password")
                .font(.title2.bold())
            Text("This screen would connect to your auth backend.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileView().environmentObject(SessionStore())
    }
}
