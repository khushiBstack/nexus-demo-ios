import SwiftUI
import Network
import Combine

// MARK: - Shared Network Speed Widget
// Drop this into any view as an overlay or inline row.
// Uses the existing NetworkMonitor from StandaloneNetworkView.swift.

struct NetworkSpeedWidget: View {
    @StateObject private var monitor = NetworkMonitor()
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: statusIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)
                Text(statusLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(monitor.interfaceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Network: \(statusLabel), \(monitor.interfaceName)")
        .sheet(isPresented: $showDetail) {
            NetworkDetailSheet(monitor: monitor)
                .presentationDetents([.medium])
        }
    }

    private var statusIcon: String {
        guard monitor.hasChecked else { return "wifi" }
        if !monitor.isConnected { return "wifi.slash" }
        return monitor.isExpensive ? "antenna.radiowaves.left.and.right" : "wifi"
    }

    private var statusColor: Color {
        guard monitor.hasChecked else { return .secondary }
        return monitor.isConnected ? (monitor.isExpensive ? .orange : .green) : .red
    }

    private var statusLabel: String {
        guard monitor.hasChecked else { return "Checking…" }
        if !monitor.isConnected { return "Offline" }
        return monitor.isExpensive ? "Cellular" : "Online"
    }
}

// MARK: - Detail sheet

struct NetworkDetailSheet: View {
    @ObservedObject var monitor: NetworkMonitor
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    NetworkDetailRow(label: "Connection", value: monitor.isConnected ? "Connected" : "Offline",
                                     valueColor: monitor.isConnected ? .green : .red)
                    NetworkDetailRow(label: "Interface", value: monitor.interfaceName)
                    NetworkDetailRow(label: "Cellular (expensive)", value: monitor.isExpensive ? "Yes" : "No",
                                     valueColor: monitor.isExpensive ? .orange : .primary)
                }

                Section("Simulated Speed Tier") {
                    NetworkDetailRow(label: "Estimated tier", value: speedTier)
                    NetworkDetailRow(label: "Latency class", value: latencyClass)
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: monitor.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(monitor.isConnected ? .green : .red)
                                .accessibilityHidden(true)
                            Text(monitor.isConnected ? "Network is reachable" : "No network connection")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Network Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var speedTier: String {
        guard monitor.isConnected else { return "N/A" }
        if monitor.isExpensive { return "3G / LTE (cellular)" }
        return "High-speed (Wi-Fi / Ethernet)"
    }

    private var latencyClass: String {
        guard monitor.isConnected else { return "N/A" }
        return monitor.isExpensive ? "Medium (~50–150 ms)" : "Low (<20 ms)"
    }
}

struct NetworkDetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(valueColor).fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    VStack {
        NetworkSpeedWidget()
    }
    .padding()
}
