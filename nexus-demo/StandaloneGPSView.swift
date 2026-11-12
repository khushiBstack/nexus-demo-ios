import SwiftUI
import CoreLocation
import Combine

// MARK: 8) GPS test

struct GPSTestView: View {
    @StateObject private var locationManager = GPSLocationManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 52)).foregroundColor(.green)
                        .accessibilityHidden(true)
                    Text("GPS Location").font(.title2.bold())
                    Text("Get exact coordinates and reverse-geocoded address")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }.padding(.top, 8)

                if locationManager.isLocating {
                    ProgressView(locationManager.statusMessage).padding()
                } else if let coord = locationManager.coordinate {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("GPS Result", systemImage: "location.fill").font(.headline)
                        Divider()
                        gpsRow(icon: "arrow.up.and.down", label: "Latitude",
                               value: String(format: "%.6f°", coord.latitude))
                        gpsRow(icon: "arrow.left.and.right", label: "Longitude",
                               value: String(format: "%.6f°", coord.longitude))
                        if let alt = locationManager.altitude {
                            gpsRow(icon: "mountain.2.fill", label: "Altitude",
                                   value: String(format: "%.1f m", alt))
                        }
                        if let acc = locationManager.accuracy {
                            gpsRow(icon: "scope", label: "Accuracy",
                                   value: String(format: "±%.0f m", acc))
                        }
                        if let addr = locationManager.address {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Address", systemImage: "mappin.and.ellipse")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(addr).font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                } else if let err = locationManager.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36)).foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text(err).font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 44)).foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("Tap to get your GPS location").foregroundStyle(.secondary)
                    }.padding(.vertical, 20)
                }

                Button {
                    locationManager.requestLocation()
                } label: {
                    Label(locationManager.isLocating ? "Locating…" : "Get My Location",
                          systemImage: "location.fill")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(locationManager.isLocating ? Color.gray : Color.green,
                                    in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(locationManager.isLocating)
                .padding(.horizontal)
                .accessibilityLabel("Get GPS location")
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("GPS Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func gpsRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.green).frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.medium))
            }
            Spacer()
        }
    }
}

final class GPSLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var address: String?
    @Published var altitude: Double?
    @Published var accuracy: Double?
    @Published var errorMessage: String?
    @Published var isLocating = false
    @Published var statusMessage = "Acquiring GPS…"

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        errorMessage = nil; coordinate = nil; address = nil
        altitude = nil; accuracy = nil; isLocating = true
        statusMessage = "Acquiring GPS signal…"
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.coordinate = location.coordinate
            self.altitude = location.altitude
            self.accuracy = location.horizontalAccuracy
            self.statusMessage = "Reverse geocoding…"
        }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                if let p = placemarks?.first {
                    let parts = [p.subThoroughfare, p.thoroughfare, p.subLocality,
                                 p.locality, p.administrativeArea, p.postalCode, p.country]
                        .compactMap { $0 }.filter { !$0.isEmpty }
                    self?.address = parts.joined(separator: ", ")
                } else {
                    self?.address = "Address unavailable"
                }
                self?.isLocating = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Location failed: \(error.localizedDescription)"
            self.isLocating = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            DispatchQueue.main.async {
                self.errorMessage = "Location access denied. Enable it in Settings."
                self.isLocating = false
            }
        }
    }
}

#Preview {
    NavigationStack { GPSTestView() }
}
