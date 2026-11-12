import SwiftUI
import Network
import Combine

// MARK: 7) Network test

struct NetworkTestView: View {
    @StateObject private var monitor = NetworkMonitor()
    @State private var showOfflineAlert = false
    @State private var showLowBandwidthAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: monitor.isConnected ? "wifi" : "wifi.slash")
                        .font(.system(size: 52))
                        .foregroundColor(statusColor)
                        .accessibilityHidden(true)
                    Text(statusLabel)
                        .font(.title2.bold())
                        .foregroundColor(statusColor)
                }.padding(.top, 8)

                VStack(alignment: .leading, spacing: 14) {
                    Label("Network Details", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline)
                    Divider()
                    netRow(icon: "wifi.circle.fill", label: "Interface", value: monitor.interfaceName)
                    netRow(icon: "dollarsign.circle.fill", label: "Metered (Cellular)", value: monitor.isExpensive ? "Yes" : "No")
                    netRow(icon: "bolt.circle.fill", label: "Low Data Mode", value: monitor.isConstrained ? "Yes" : "No")
                    if let speed = monitor.estimatedSpeed {
                        netRow(icon: "speedometer", label: "Est. Speed", value: speed)
                    }
                    if let measured = monitor.measuredSpeedKbps {
                        netRow(icon: "gauge.with.dots.needle.bottom.50percent",
                               label: "Measured Speed",
                               value: measured < 1000
                                   ? String(format: "%.0f Kbps", measured)
                                   : String(format: "%.1f Mbps", measured / 1000))
                    } else if monitor.isMeasuringSpeed {
                        netRow(icon: "arrow.clockwise", label: "Measured Speed", value: "Measuring…")
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Re-measure button
                if monitor.isConnected {
                    Button {
                        monitor.measureBandwidth()
                    } label: {
                        Label(monitor.isMeasuringSpeed ? "Measuring…" : "Measure Speed Now",
                              systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(monitor.isMeasuringSpeed)
                }

                if monitor.isConnected && monitor.isExpensive {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text("On cellular — data charges may apply")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Network Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { monitor.measureBandwidth() }
        .onChange(of: monitor.isConnected) { connected in
            if !connected { showOfflineAlert = true }
        }
        .onChange(of: monitor.isLowBandwidth) { low in
            if low { showLowBandwidthAlert = true }
        }
        .alert("You're Offline", isPresented: $showOfflineAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No active network connection detected. Some features may not work.")
        }
        .alert("Low Bandwidth Detected", isPresented: $showLowBandwidthAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your connection speed is very low (under 150 Kbps). Some features may be slow or unavailable.")
        }
    }

    private var statusColor: Color {
        if !monitor.isConnected { return .red }
        if monitor.isLowBandwidth { return .orange }
        return .green
    }

    private var statusLabel: String {
        if !monitor.isConnected { return "Offline" }
        if monitor.isLowBandwidth { return "Low Bandwidth" }
        return "Connected"
    }

    @ViewBuilder
    private func netRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.medium))
            }
            Spacer()
        }
    }
}

final class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var isExpensive = false
    @Published var isConstrained = false
    @Published var interfaceName = "Unknown"
    @Published var estimatedSpeed: String?
    @Published var hasChecked = false

    // Actual measured bandwidth
    @Published var measuredSpeedKbps: Double?
    @Published var isMeasuringSpeed = false
    @Published var isLowBandwidth = false

    /// Threshold in Kbps below which we consider the connection "low bandwidth" (≈ 2G edge)
    static let lowBandwidthThresholdKbps: Double = 150

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
                self.hasChecked = true
                if path.usesInterfaceType(.wifi) {
                    self.interfaceName = "Wi-Fi"
                    self.estimatedSpeed = "High (Wi-Fi)"
                } else if path.usesInterfaceType(.cellular) {
                    self.interfaceName = "Cellular"
                    self.estimatedSpeed = path.isConstrained ? "Low (Low Data Mode)" : "Medium (Cellular)"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.interfaceName = "Ethernet"
                    self.estimatedSpeed = "High (Ethernet)"
                } else if path.status == .satisfied {
                    self.interfaceName = "Other"
                    self.estimatedSpeed = nil
                } else {
                    self.interfaceName = "None"
                    self.estimatedSpeed = nil
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }

    // MARK: - Actual bandwidth measurement

    /// Downloads a 1 MB payload from Cloudflare's speed-test CDN and measures throughput.
    /// Uses a large payload so TCP connection-setup overhead is negligible relative to
    /// transfer time, giving an accurate Kbps reading even on throttled connections.
    func measureBandwidth() {
        guard !isMeasuringSpeed else { return }
        isMeasuringSpeed = true
        measuredSpeedKbps = nil

        // 1 MB from Cloudflare speed-test — reliable, globally distributed, no rate limit
        let urlString = "https://speed.cloudflare.com/__down?bytes=1000000&_=\(Int(Date().timeIntervalSince1970))"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.isMeasuringSpeed = false }
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        request.httpMethod = "GET"

        let start = Date()
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isMeasuringSpeed = false

                guard let data, error == nil, data.count > 0 else { return }

                let elapsed = Date().timeIntervalSince(start)
                guard elapsed > 0.01 else { return }

                // Kbps = (bytes × 8 bits/byte) ÷ elapsed_seconds ÷ 1000
                let kbps = (Double(data.count) * 8.0) / elapsed / 1000.0
                self.measuredSpeedKbps = kbps
                self.isLowBandwidth = kbps < NetworkMonitor.lowBandwidthThresholdKbps
            }
        }.resume()
    }
}

#Preview {
    NavigationStack { NetworkTestView() }
}
