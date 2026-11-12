import Combine
import SwiftUI
import CoreLocation
import MapKit

// MARK: - ATM Model

struct ATMLocation: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let distance: String
    let distanceMeters: Double
    let coordinate: CLLocationCoordinate2D
    let type: String
}

// MARK: - ATM View

struct BFSIATMView: View {
    @StateObject private var atmMgr = ATMSearchManager()
    @State private var searchText = ""
    @State private var showMap = false

    private var filtered: [ATMLocation] {
        guard !searchText.isEmpty else { return atmMgr.atms }
        return atmMgr.atms.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.address.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            VStack(alignment: .leading, spacing: 4) {
                Text("Search").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
                    TextField("ATM name or address", text: $searchText)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Search ATMs by name or address")
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }.accessibilityLabel("Clear search")
                    }
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal).padding(.top, 8)

            // Location status banner
            if let city = atmMgr.cityName {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill").font(.caption2).foregroundStyle(.indigo).accessibilityHidden(true)
                    Text("Showing ATMs near \(city)").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showMap = true
                    } label: {
                        Label("Map", systemImage: "map.fill").font(.caption.weight(.medium))
                    }
                    .tint(.indigo)
                }
                .padding(.horizontal).padding(.vertical, 6)
            }

            if atmMgr.isSearching {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Finding ATMs near you...").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = atmMgr.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "location.slash").font(.system(size: 48)).foregroundStyle(.secondary).accessibilityHidden(true)
                    Text(error).font(.headline)
                    Text("Please enable location access in Settings.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Try Again") { atmMgr.start() }.buttonStyle(.borderedProminent).tint(.indigo)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity).padding()
            } else if filtered.isEmpty && !atmMgr.isSearching {
                VStack(spacing: 12) {
                    Image(systemName: "banknote").font(.system(size: 48)).foregroundStyle(.secondary).accessibilityHidden(true)
                    Text("No ATMs found").font(.headline)
                    Text("Try a different search or refresh your location.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity).padding()
            } else {
                List(filtered) { atm in
                    ATMRow(atm: atm)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("ATMs Near You")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { atmMgr.start() } label: {
                    Image(systemName: "arrow.clockwise").foregroundStyle(.indigo)
                }
                .accessibilityLabel("Refresh ATMs")
                .disabled(atmMgr.isSearching)
            }
        }
        .onAppear { atmMgr.start() }
        .sheet(isPresented: $showMap) {
            if #available(iOS 17, *) { ATMMapView(atms: filtered, userLocation: atmMgr.userLocation) } else { Text("Map requires iOS 17+").padding() }
        }
    }
}

// MARK: - ATM Row

struct ATMRow: View {
    let atm: ATMLocation

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.indigo.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: atmIcon(for: atm.name))
                    .font(.title3).foregroundStyle(.indigo).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(atm.name).font(.subheadline.weight(.semibold))
                Text(atm.address).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(atm.distance).font(.caption.monospacedDigit()).foregroundStyle(.indigo)
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                    .accessibilityLabel("View ATM details")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(atm.name + ", " + atm.address + ", " + atm.distance + " away")
    }

    private func atmIcon(for name: String) -> String {
        let n = name.lowercased()
        if n.contains("chase") || n.contains("wells") || n.contains("bank") || n.contains("citi") || n.contains("hsbc") || n.contains("barclays") || n.contains("sbi") || n.contains("hdfc") || n.contains("icici") { return "building.columns.fill" }
        if n.contains("7-eleven") || n.contains("cvs") || n.contains("walgreen") || n.contains("store") { return "storefront.fill" }
        return "creditcard.fill"
    }
}

// MARK: - Map View

@available(iOS 17, *)
@available(iOS 17, *)
struct ATMMapView: View {
    let atms: [ATMLocation]
    let userLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss

    var region: MKCoordinateRegion {
        if let loc = userLocation {
            return MKCoordinateRegion(center: loc.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312), latitudinalMeters: 2000, longitudinalMeters: 2000)
    }

    var body: some View {
        NavigationStack {
            Map(initialPosition: .region(region)) {
                if let loc = userLocation {
                    Annotation("You", coordinate: loc.coordinate) {
                        ZStack {
                            Circle().fill(.blue).frame(width: 16, height: 16)
                            Circle().stroke(.white, lineWidth: 2).frame(width: 16, height: 16)
                        }
                    }
                }
                ForEach(atms) { atm in
                    Annotation(atm.name, coordinate: atm.coordinate) {
                        ZStack {
                            Circle().fill(.indigo).frame(width: 32, height: 32)
                            Image(systemName: "creditcard.fill").font(.caption).foregroundStyle(.white)
                        }
                    }
                }
            }
            .navigationTitle("ATM Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - ATM Search Manager

final class ATMSearchManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationMgr = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published var atms: [ATMLocation] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var cityName: String?
    @Published var userLocation: CLLocation?

    override init() {
        super.init()
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start() {
        isSearching = true
        errorMessage = nil
        locationMgr.requestWhenInUseAuthorization()
        locationMgr.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { isSearching = false; return }
        userLocation = location

        // Reverse geocode for city name
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                let city = placemarks?.first?.locality
                self?.cityName = city
                // Share GPS city with IPGeoManager so dashboard shows same city
                IPGeoManager.shared.gpsCity = city
            }
        }

        // Search for real ATMs using MapKit
        searchATMs(near: location)
    }

    private func searchATMs(near location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "ATM"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        )
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSearching = false

                if let error = error {
                    // Fall back to bank search if ATM search fails
                    self.searchBanks(near: location)
                    return
                }

                guard let items = response?.mapItems, !items.isEmpty else {
                    self.searchBanks(near: location)
                    return
                }

                self.atms = items.prefix(20).compactMap { item in
                    let itemLoc = CLLocation(latitude: item.placemark.coordinate.latitude,
                                            longitude: item.placemark.coordinate.longitude)
                    let distMeters = location.distance(from: itemLoc)
                    let distStr = distMeters < 1000
                        ? String(format: "%.0f m", distMeters)
                        : String(format: "%.1f km", distMeters / 1000)

                    let address = [
                        item.placemark.subThoroughfare,
                        item.placemark.thoroughfare,
                        item.placemark.locality
                    ].compactMap { $0 }.joined(separator: " ")

                    return ATMLocation(
                        name: item.name ?? "ATM",
                        address: address.isEmpty ? (item.placemark.locality ?? "Nearby") : address,
                        distance: distStr,
                        distanceMeters: distMeters,
                        coordinate: item.placemark.coordinate,
                        type: "ATM"
                    )
                }.sorted { $0.distanceMeters < $1.distanceMeters }
            }
        }
    }

    private func searchBanks(near location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Bank"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        )
        request.resultTypes = .pointOfInterest

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSearching = false

                guard let items = response?.mapItems, !items.isEmpty else {
                    self.errorMessage = "No ATMs found nearby"
                    return
                }

                self.atms = items.prefix(15).compactMap { item in
                    let itemLoc = CLLocation(latitude: item.placemark.coordinate.latitude,
                                            longitude: item.placemark.coordinate.longitude)
                    let distMeters = location.distance(from: itemLoc)
                    let distStr = distMeters < 1000
                        ? String(format: "%.0f m", distMeters)
                        : String(format: "%.1f km", distMeters / 1000)

                    let address = [
                        item.placemark.subThoroughfare,
                        item.placemark.thoroughfare,
                        item.placemark.locality
                    ].compactMap { $0 }.joined(separator: " ")

                    return ATMLocation(
                        name: item.name ?? "Bank",
                        address: address.isEmpty ? (item.placemark.locality ?? "Nearby") : address,
                        distance: distStr,
                        distanceMeters: distMeters,
                        coordinate: item.placemark.coordinate,
                        type: "Bank"
                    )
                }.sorted { $0.distanceMeters < $1.distanceMeters }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            self.errorMessage = "Location unavailable"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isSearching = false
                self.errorMessage = "Location access denied"
            }
        case .authorizedWhenInUse, .authorizedAlways:
            locationMgr.requestLocation()
        default:
            break
        }
    }
}

#Preview {
    NavigationStack { BFSIATMView() }
}