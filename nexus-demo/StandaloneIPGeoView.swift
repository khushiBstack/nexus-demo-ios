import SwiftUI
import CoreLocation

struct IPGeoLocationTestView: View {
    @State private var isLoading = false
    @State private var country: String?
    @State private var city: String?
    @State private var region: String?
    @State private var postalCode: String?
    @State private var fullAddress: String?
    @State private var ip: String?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "network")
                        .font(.system(size: 52))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                    Text("IP Geolocation")
                        .font(.title2.bold())
                    Text("Lookup your public IP address and geographic location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 8)

                // Result card
                if let country = country {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Location Details", systemImage: "mappin.and.ellipse")
                            .font(.headline)

                        Divider()

                        if let ip = ip {
                            geoRow(icon: "wifi", label: "IP Address", value: ip)
                        }
                        geoRow(icon: "flag.fill", label: "Country", value: country)
                        if let region = region {
                            geoRow(icon: "map.fill", label: "Region", value: region)
                        }
                        if let city = city {
                            geoRow(icon: "building.2.fill", label: "City", value: city)
                        }
                        if let postal = postalCode {
                            geoRow(icon: "envelope.fill", label: "Postal Code", value: postal)
                        }
                        if let addr = fullAddress {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Full Address", systemImage: "location.fill")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(addr)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                } else if let error = errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36)).foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text(error)
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                } else if !isLoading {
                    VStack(spacing: 8) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 44)).foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("Tap Lookup to fetch your IP location")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                }

                if isLoading {
                    ProgressView("Looking up location…")
                        .padding()
                }

                Button {
                    performLookup()
                } label: {
                    Label(isLoading ? "Looking up…" : "Lookup My Location",
                          systemImage: "location.magnifyingglass")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isLoading ? Color.gray : Color.blue, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isLoading)
                .padding(.horizontal)
                .accessibilityLabel("Lookup IP geolocation")

                if country != nil {
                    Button {
                        resetResults()
                    } label: {
                        Text("Clear Results")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Clear geolocation results")
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("IP Geolocation")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func geoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.medium))
            }
            Spacer()
        }
    }

    private func performLookup() {
        isLoading = true
        errorMessage = nil
        country = nil

        guard let url = URL(string: "https://ipapi.co/json/") else {
            isLoading = false
            errorMessage = "Invalid URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    errorMessage = "Failed to parse response"
                    return
                }
                ip = json["ip"] as? String
                country = json["country_name"] as? String ?? "Unknown"
                region = json["region"] as? String
                city = json["city"] as? String
                postalCode = json["postal"] as? String

                var parts: [String] = []
                if let c = city { parts.append(c) }
                if let r = region { parts.append(r) }
                if let p = postalCode { parts.append(p) }
                if let co = country { parts.append(co) }
                fullAddress = parts.isEmpty ? nil : parts.joined(separator: ", ")
            }
        }.resume()
    }

    private func resetResults() {
        country = nil; city = nil; region = nil
        postalCode = nil; fullAddress = nil; ip = nil; errorMessage = nil
    }
}

#Preview {
    NavigationStack { IPGeoLocationTestView() }
}
