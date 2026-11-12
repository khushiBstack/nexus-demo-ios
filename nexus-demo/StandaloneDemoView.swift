import SwiftUI
import Combine

struct StandaloneFeature: Identifiable {
    let id = UUID()
    let index: Int
    let title: String
    let subtitle: String
    let icon: String
}

enum StandaloneFeatureData {
    static let features: [StandaloneFeature] = [
        StandaloneFeature(index: 1,  title: "Image injection",        subtitle: "Camera still capture",          icon: "camera.fill"),
        StandaloneFeature(index: 2,  title: "Biometric test",         subtitle: "Fingerprint / face prompt",     icon: "touchid"),
        StandaloneFeature(index: 3,  title: "Video injection",        subtitle: "Record + play video",           icon: "video.fill"),
        StandaloneFeature(index: 4,  title: "File upload & download", subtitle: "Document pick + share",         icon: "folder.fill"),
        StandaloneFeature(index: 5,  title: "Audio injection test",   subtitle: "Microphone record & play",      icon: "mic.fill"),
        StandaloneFeature(index: 6,  title: "IP geo location test",   subtitle: "Public IP → location",          icon: "globe"),
        StandaloneFeature(index: 7,  title: "Network test",           subtitle: "Connection status",             icon: "wifi"),
        StandaloneFeature(index: 8,  title: "GPS test",               subtitle: "Device GPS + reverse geocode",  icon: "location.fill"),
        StandaloneFeature(index: 9,  title: "OTP test",               subtitle: "Send + verify code",            icon: "ellipsis.message.fill"),
        StandaloneFeature(index: 10, title: "Push notifications",     subtitle: "Schedule & receive alerts",     icon: "bell.badge.fill"),
        StandaloneFeature(index: 11, title: "QR code scanner",        subtitle: "Scan QR → view text result",    icon: "qrcode.viewfinder")
    ]
}

struct StandaloneDemoView: View {
    var body: some View {
        List {
            // Network speed widget at the top
            Section {
                HStack {
                    Text("Network Status")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    NetworkSpeedWidget()
                }
                .padding(.vertical, 4)
            }

            // Feature list
            ForEach(StandaloneFeatureData.features) { feature in
                NavigationLink {
                    destination(for: feature.index)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.indigo, in: RoundedRectangle(cornerRadius: 10))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(feature.index)) \(feature.title)").font(.headline)
                            Text(feature.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .accessibilityLabel("\(feature.index), \(feature.title), \(feature.subtitle)")
            }
        }
        .navigationTitle("Standalone demo")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func destination(for index: Int) -> some View {
        switch index {
        case 1:  ImageInjectionView()
        case 2:  BiometricTestView()
        case 3:  VideoInjectionView()
        case 4:  FileUploadDownloadView()
        case 5:  AudioInjectionTestView()
        case 6:  IPGeoLocationTestView()
        case 7:  NetworkTestView()
        case 8:  GPSTestView()
        case 9:  OTPTestView()
        case 10: PushNotificationDemoView()
        case 11: ScannerView()
        default: EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        StandaloneDemoView()
    }
}
