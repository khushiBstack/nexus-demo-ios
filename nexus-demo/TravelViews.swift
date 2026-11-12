import SwiftUI
import PassKit
import Combine
import CoreLocation

// MARK: - Models

struct Trip: Identifiable {
    let id = UUID()
    let destination: String
    let country: String
    let dates: String
    let type: String
    let icon: String
    let imageGradient: [Color]
    let price: Double
    let status: TripStatus
}

enum TripStatus: String {
    case upcoming = "Upcoming"
    case active   = "Active"
    case past     = "Past"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
}

struct FlightResult: Identifiable {
    let id = UUID()
    let airline: String
    let from: String
    let to: String
    let departure: String
    let arrival: String
    let duration: String
    let price: Double
    let stops: Int
    let airlineCode: String
}

struct HotelResult: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let rating: Double
    let reviewCount: Int
    let pricePerNight: Double
    let amenities: [String]
    let imageIcon: String
}

struct TravelBooking: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let subtitle: String
    let total: Double
    let paymentMethod: String
    let icon: String
    let gradient: [Color]
}

enum TravelSampleData {
    static let trips: [Trip] = [
        Trip(destination: "Tokyo", country: "Japan", dates: "Sep 12 – Sep 19",
             type: "Flight + Hotel", icon: "airplane",
             imageGradient: [Color(red: 0.9, green: 0.2, blue: 0.3), Color(red: 0.6, green: 0.1, blue: 0.5)],
             price: 1840, status: .upcoming),
        Trip(destination: "Lisbon", country: "Portugal", dates: "Oct 3 – Oct 8",
             type: "Hotel", icon: "building.2.fill",
             imageGradient: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.1, green: 0.3, blue: 0.7)],
             price: 620, status: .upcoming),
        Trip(destination: "San Francisco", country: "USA", dates: "Nov 20 – Nov 23",
             type: "Flight", icon: "airplane",
             imageGradient: [Color(red: 0.9, green: 0.5, blue: 0.1), Color(red: 0.8, green: 0.2, blue: 0.1)],
             price: 380, status: .past)
    ]
    static let flights: [FlightResult] = [
        FlightResult(airline: "ANA", from: "SFO", to: "NRT", departure: "10:30", arrival: "14:45+1",
                     duration: "11h 15m", price: 820, stops: 0, airlineCode: "NH"),
        FlightResult(airline: "Japan Airlines", from: "SFO", to: "NRT", departure: "13:00", arrival: "17:20+1",
                     duration: "11h 20m", price: 760, stops: 0, airlineCode: "JL"),
        FlightResult(airline: "United", from: "SFO", to: "NRT", departure: "08:15", arrival: "13:30+1",
                     duration: "12h 15m", price: 640, stops: 1, airlineCode: "UA")
    ]
    static let hotels: [HotelResult] = [
        HotelResult(name: "Park Hyatt Tokyo", location: "Shinjuku, Tokyo", rating: 4.8, reviewCount: 2140,
                    pricePerNight: 420, amenities: ["Pool", "Spa", "Gym", "Restaurant"], imageIcon: "building.2.fill"),
        HotelResult(name: "Andaz Tokyo", location: "Toranomon, Tokyo", rating: 4.6, reviewCount: 1380,
                    pricePerNight: 310, amenities: ["Bar", "Gym", "Concierge"], imageIcon: "building.fill"),
        HotelResult(name: "Shinjuku Granbell", location: "Shinjuku, Tokyo", rating: 4.3, reviewCount: 890,
                    pricePerNight: 180, amenities: ["Bar", "Concierge"], imageIcon: "house.fill")
    ]
}

// MARK: - Root

struct TravelRootView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        Group {
            if session.travelLoggedIn && session.travelOTPVerified {
                TravelTabView().toolbar(.hidden, for: .navigationBar)
            } else if session.travelLoggedIn && !session.travelOTPVerified {
                OTPVerificationView(title: "TripNexus", tint: .pink, icon: "airplane") {
                    session.travelOTPVerified = true
                }
            } else {
                IndustryLoginView(title: "TripNexus", icon: "airplane", tint: .pink) { email, name in
                    session.travelUserEmail = email
                    session.travelUserName = name
                    session.travelLoggedIn = true
                    session.travelOTPVerified = false
                }
            }
        }
        .navigationTitle("Travel")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TravelTabView: View {
    @EnvironmentObject var session: SessionStore
    @State private var bookings: [TravelBooking] = []
    var body: some View {
        TabView {
            NavigationStack { TravelHomeView(bookings: $bookings) }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { TravelSearchView(bookings: $bookings) }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            NavigationStack { TripsListView(bookings: $bookings) }
                .tabItem { Label("Trips", systemImage: "suitcase.fill") }
            NavigationStack {
                ProfileView(domainName: "Travel") {
                    session.travelLoggedIn = false
                    session.travelUserName = ""
                    session.travelUserEmail = ""
                    session.travelOTPVerified = false
                }
            }.tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(.pink)
    }
}

// MARK: - Home

struct TravelHomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var geo: IPGeoManager
    @Environment(\.dismiss) private var dismiss
    @Binding var bookings: [TravelBooking]
    private let upcomingTrips = TravelSampleData.trips.filter { $0.status == .upcoming }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(session.travelUserName.isEmpty ? "Traveller" : session.travelUserName)")
                            .font(.title2.bold())
                        if let place = geo.city ?? geo.country {
                            Label("Departing from \(place)", systemImage: "location.fill")
                                .font(.caption).foregroundStyle(.pink)
                        } else {
                            Text("Where to next?").foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    NetworkSpeedWidget()
                }
                .padding(.horizontal).padding(.top)


                // Quick actions
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    TravelQuickAction(title: "Flights", icon: "airplane", tint: .pink)
                    TravelQuickAction(title: "Hotels", icon: "building.2.fill", tint: .purple)
                    TravelQuickAction(title: "Cars", icon: "car.fill", tint: .orange)
                    TravelQuickAction(title: "Trains", icon: "tram.fill", tint: .blue)
                }.padding(.horizontal)

                // Upcoming trips
                if !upcomingTrips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Trips").font(.headline).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(upcomingTrips) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip, bookings: $bookings)) {
                                        TripCard(trip: trip)
                                    }.buttonStyle(.plain)
                                }
                            }.padding(.horizontal)
                        }
                    }
                }

                // Hot deals
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hot Deals").font(.headline).padding(.horizontal)
                    ForEach(TravelSampleData.flights.prefix(2)) { flight in
                        NavigationLink(destination: FlightDetailView(flight: flight, bookings: $bookings)) {
                            FlightDealCard(flight: flight)
                        }
                        .buttonStyle(.plain).padding(.horizontal)
                    }
                }

                // Recent bookings
                if !bookings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Bookings").font(.headline).padding(.horizontal)
                        ForEach(bookings.prefix(2)) { booking in
                            BookingRowCard(booking: booking)
                                .padding(.horizontal)
                        }
                    }
                }
            }.padding(.bottom, 24)
        }
        .navigationTitle("TripNexus")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { geo.fetchIfNeeded() }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left.square.fill")
                        .font(.title3).foregroundStyle(.pink)
                }
                .accessibilityLabel("Back to domains")
            }
        }
    }
}

struct TravelQuickAction: View {
    let title: String; let icon: String; let tint: Color
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(tint.opacity(0.12)).frame(height: 52)
                Image(systemName: icon).font(.title3).foregroundStyle(tint).accessibilityHidden(true)
            }
            Text(title).font(.caption.weight(.medium)).foregroundStyle(.primary)
        }.accessibilityLabel(title)
    }
}

struct TripCard: View {
    let trip: Trip
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: trip.imageGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 100)
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.destination).font(.headline.bold()).foregroundStyle(.white)
                    Text(trip.country).font(.caption).foregroundStyle(.white.opacity(0.85))
                }.padding(10)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "calendar").font(.caption).foregroundStyle(.secondary).accessibilityHidden(true)
                    Text(trip.dates).font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Text(trip.type).font(.caption2).padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.pink.opacity(0.12), in: Capsule()).foregroundStyle(.pink)
                    Spacer()
                    Text(trip.price, format: .currency(code: "USD")).font(.subheadline.bold()).foregroundStyle(.pink)
                }
            }.padding(10).background(Color(.secondarySystemGroupedBackground))
        }
        .frame(width: 200).clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(trip.destination + ", " + trip.dates + ", " + trip.type)
    }
}

struct FlightDealCard: View {
    let flight: FlightResult
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.pink.opacity(0.10)).frame(width: 44, height: 44)
                Text(flight.airlineCode).font(.caption.bold()).foregroundStyle(.pink)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(flight.from) → \(flight.to)").font(.subheadline.weight(.semibold))
                Text("\(flight.airline) · \(flight.stops == 0 ? "Nonstop" : "\(flight.stops) stop") · \(flight.duration)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(flight.price, format: .currency(code: "USD")).font(.subheadline.bold()).foregroundStyle(.pink)
                Text("per person").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(flight.from) to \(flight.to), \(flight.airline), \(flight.price.formatted(.currency(code: "USD")))")
    }
}

struct BookingRowCard: View {
    let booking: TravelBooking
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: booking.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Image(systemName: booking.icon).foregroundStyle(.white).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(booking.title).font(.subheadline.weight(.semibold))
                Text(booking.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(booking.total, format: .currency(code: "USD")).font(.subheadline.bold()).foregroundStyle(.pink)
                Text(booking.paymentMethod).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Search

struct TravelSearchView: View {
    @Binding var bookings: [TravelBooking]
    @EnvironmentObject var geo: IPGeoManager
    @State private var searchTab: SearchTab = .flights
    @State private var origin = ""
    @State private var destination = ""
    @State private var departDate = Date().addingTimeInterval(86400 * 30)
    @State private var passengers = 1
    @State private var hasSearched = false
    enum SearchTab: String, CaseIterable { case flights = "Flights"; case hotels = "Hotels" }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Search type", selection: $searchTab) {
                    ForEach(SearchTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).padding(.horizontal).padding(.top)

                // Location auto-fill banner
                if let city = geo.city ?? geo.country {
                    Button {
                        if searchTab == .flights { origin = city } else { destination = city }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill").foregroundStyle(.pink).accessibilityHidden(true)
                            Text("Use current location: \(city)")
                                .font(.subheadline.weight(.medium)).foregroundStyle(.pink)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill").foregroundStyle(.pink).accessibilityHidden(true)
                        }
                        .padding(12)
                        .background(Color.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Use current location \(city) as \(searchTab == .flights ? "origin" : "destination")")
                }

                if searchTab == .flights { flightSearchForm } else { hotelSearchForm }
                if hasSearched {
                    if searchTab == .flights { flightResults } else { hotelResults }
                }
            }.padding(.bottom, 24)
        }
        .navigationTitle("Search").navigationBarTitleDisplayMode(.inline)
        .onAppear { geo.fetchIfNeeded() }
    }

    @ViewBuilder private var flightSearchForm: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SearchField(label: "From", placeholder: "Origin", text: $origin, icon: "airplane.departure")
                SearchField(label: "To", placeholder: "Destination", text: $destination, icon: "airplane.arrival")
            }.padding(.horizontal)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Depart").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    DatePicker("", selection: $departDate, displayedComponents: .date)
                        .labelsHidden().padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Passengers").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Stepper("\(passengers)", value: $passengers, in: 1...9)
                        .padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }.padding(.horizontal)
            Button { hasSearched = true } label: {
                Label("Search Flights", systemImage: "magnifyingglass").font(.headline)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.pink, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
            }.padding(.horizontal).accessibilityLabel("Search flights")
        }
    }

    @ViewBuilder private var hotelSearchForm: some View {
        VStack(spacing: 12) {
            SearchField(label: "Destination", placeholder: "City or hotel name", text: $destination, icon: "mappin.circle.fill")
                .padding(.horizontal)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-in").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    DatePicker("", selection: $departDate, displayedComponents: .date)
                        .labelsHidden().padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guests").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Stepper("\(passengers)", value: $passengers, in: 1...9)
                        .padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }.padding(.horizontal)
            Button { hasSearched = true } label: {
                Label("Search Hotels", systemImage: "magnifyingglass").font(.headline)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.purple, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
            }.padding(.horizontal).accessibilityLabel("Search hotels")
        }
    }

    private var dynamicFlights: [FlightResult] {
        let from = origin.trimmingCharacters(in: .whitespaces).isEmpty ? "SFO" : origin.trimmingCharacters(in: .whitespaces)
        let to = destination.trimmingCharacters(in: .whitespaces).isEmpty ? "Destination" : destination.trimmingCharacters(in: .whitespaces)
        return TravelSampleData.flights.map { f in
            FlightResult(airline: f.airline, from: from, to: to, departure: f.departure,
                         arrival: f.arrival, duration: f.duration, price: f.price,
                         stops: f.stops, airlineCode: f.airlineCode)
        }
    }

    @ViewBuilder private var flightResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3 flights found: \(origin) → \(destination)").font(.headline).padding(.horizontal)
            ForEach(dynamicFlights) { flight in
                NavigationLink(destination: FlightDetailView(flight: flight, bookings: $bookings)) {
                    FlightResultCard(flight: flight)
                }.buttonStyle(.plain).padding(.horizontal)
            }
        }
    }

    private var dynamicHotels: [HotelResult] {
        let city = destination.isEmpty ? "Tokyo" : destination
        return [
            HotelResult(name: "Grand \(city) Hotel", location: "\(city) City Centre", rating: 4.7, reviewCount: 1840,
                        pricePerNight: 280, amenities: ["Pool", "Spa", "Gym", "Restaurant"], imageIcon: "building.2.fill"),
            HotelResult(name: "\(city) Boutique Inn", location: "\(city) Old Town", rating: 4.4, reviewCount: 920,
                        pricePerNight: 160, amenities: ["Bar", "Concierge"], imageIcon: "building.fill"),
            HotelResult(name: "\(city) Budget Stay", location: "\(city) Airport Area", rating: 4.1, reviewCount: 540,
                        pricePerNight: 90, amenities: ["Gym", "Concierge"], imageIcon: "house.fill")
        ]
    }

    @ViewBuilder private var hotelResults: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3 hotels found in \(destination)").font(.headline).padding(.horizontal)
            ForEach(dynamicHotels) { hotel in
                NavigationLink(destination: HotelDetailView(hotel: hotel, bookings: $bookings)) {
                    HotelResultCard(hotel: hotel)
                }.buttonStyle(.plain).padding(.horizontal)
            }
        }
    }
}

struct SearchField: View {
    let label: String; let placeholder: String; @Binding var text: String; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack {
                Image(systemName: icon).foregroundStyle(.pink).accessibilityHidden(true)
                TextField(placeholder, text: $text).autocorrectionDisabled().accessibilityLabel(label)
            }.padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct FlightResultCard: View {
    let flight: FlightResult
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(flight.airline).font(.subheadline.weight(.semibold))
                Spacer()
                Text(flight.stops == 0 ? "Nonstop" : "\(flight.stops) stop")
                    .font(.caption).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(flight.stops == 0 ? Color.green.opacity(0.12) : Color.orange.opacity(0.12), in: Capsule())
                    .foregroundStyle(flight.stops == 0 ? .green : .orange)
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(flight.departure).font(.title3.bold())
                    Text(flight.from).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "airplane").foregroundStyle(.pink).accessibilityHidden(true)
                    Text(flight.duration).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(flight.arrival).font(.title3.bold())
                    Text(flight.to).font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack {
                Spacer()
                Text(flight.price, format: .currency(code: "USD")).font(.title3.bold()).foregroundStyle(.pink)
                Text("/ person").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(flight.airline), \(flight.from) to \(flight.to), \(flight.price.formatted(.currency(code: "USD")))")
    }
}

struct HotelResultCard: View {
    let hotel: HotelResult
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.purple.opacity(0.10)).frame(width: 60, height: 60)
                Image(systemName: hotel.imageIcon).font(.title2).foregroundStyle(.purple).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(hotel.name).font(.subheadline.weight(.semibold))
                Text(hotel.location).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow).accessibilityHidden(true)
                    Text(String(format: "%.1f", hotel.rating)).font(.caption)
                    Text("(\(hotel.reviewCount))").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(hotel.pricePerNight, format: .currency(code: "USD")).font(.subheadline.bold()).foregroundStyle(.purple)
                Text("/ night").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(hotel.name), \(hotel.location), \(hotel.pricePerNight.formatted(.currency(code: "USD"))) per night")
    }
}

// MARK: - Flight Detail

struct FlightDetailView: View {
    let flight: FlightResult
    @Binding var bookings: [TravelBooking]
    @State private var paymentDone = false
    @State private var paymentMethod = "Card"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero
                ZStack {
                    LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(spacing: 8) {
                        HStack(spacing: 24) {
                            VStack {
                                Text(flight.departure).font(.largeTitle.bold()).foregroundStyle(.white)
                                Text(flight.from).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                            }
                            Image(systemName: "airplane").font(.title).foregroundStyle(.white).accessibilityHidden(true)
                            VStack {
                                Text(flight.arrival).font(.largeTitle.bold()).foregroundStyle(.white)
                                Text(flight.to).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        Text(flight.duration + " · " + (flight.stops == 0 ? "Nonstop" : "\(flight.stops) stop"))
                            .font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(flight.from) to \(flight.to), \(flight.duration)")

                // Details
                VStack(spacing: 0) {
                    TravelDetailRow(label: "Airline", value: flight.airline)
                    Divider().padding(.leading, 16)
                    TravelDetailRow(label: "Stops", value: flight.stops == 0 ? "Nonstop" : "\(flight.stops) stop")
                    Divider().padding(.leading, 16)
                    TravelDetailRow(label: "Duration", value: flight.duration)
                    Divider().padding(.leading, 16)
                    TravelDetailRow(label: "Price", value: flight.price.formatted(.currency(code: "USD")), valueColor: .pink)
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .padding(.horizontal)

                if paymentDone {
                    BookingConfirmedView(
                        title: "Flight Booked!",
                        subtitle: "Your flight to \(flight.to) is confirmed.",
                        paymentMethod: paymentMethod,
                        total: flight.price
                    )
                    .padding(.horizontal)
                } else {
                    TravelPaymentButtons(
                        total: flight.price,
                        itemLabel: "\(flight.from) → \(flight.to)",
                        tint: .pink
                    ) { method in
                        paymentMethod = method
                        let booking = TravelBooking(
                            date: Date(),
                            title: "\(flight.from) → \(flight.to)",
                            subtitle: "\(flight.airline) · \(flight.duration)",
                            total: flight.price,
                            paymentMethod: method,
                            icon: "airplane",
                            gradient: [.pink, .purple]
                        )
                        bookings.append(booking)
                        paymentDone = true
                    }
                    .padding(.horizontal)
                }
            }.padding(.vertical)
        }
        .navigationTitle("Flight Details").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Hotel Detail

struct HotelDetailView: View {
    let hotel: HotelResult
    @Binding var bookings: [TravelBooking]
    @State private var nights = 3
    @State private var paymentDone = false
    @State private var paymentMethod = "Card"
    private var total: Double { hotel.pricePerNight * Double(nights) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hotel.name).font(.title2.bold()).foregroundStyle(.white)
                        Text(hotel.location).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                    }.padding()
                }.padding(.horizontal)

                VStack(spacing: 0) {
                    TravelDetailRow(label: "Rating", value: String(format: "%.1f / 5.0", hotel.rating))
                    Divider().padding(.leading, 16)
                    TravelDetailRow(label: "Reviews", value: "\(hotel.reviewCount)")
                    Divider().padding(.leading, 16)
                    TravelDetailRow(label: "Per night", value: hotel.pricePerNight.formatted(.currency(code: "USD")), valueColor: .purple)
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2).padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Amenities").font(.headline).padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(hotel.amenities, id: \.self) { a in
                                Text(a).font(.caption.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.10), in: Capsule()).foregroundStyle(.purple)
                            }
                        }.padding(.horizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nights").font(.headline).padding(.horizontal)
                    Stepper(value: $nights, in: 1...30) {
                        Text("\(nights) night\(nights == 1 ? "" : "s") — \(total.formatted(.currency(code: "USD")))")
                    }.padding(.horizontal)
                }

                if paymentDone {
                    BookingConfirmedView(
                        title: "Hotel Booked!",
                        subtitle: "Your stay at \(hotel.name) is confirmed.",
                        paymentMethod: paymentMethod,
                        total: total
                    ).padding(.horizontal)
                } else {
                    TravelPaymentButtons(
                        total: total,
                        itemLabel: "\(hotel.name) · \(nights) night\(nights == 1 ? "" : "s")",
                        tint: .purple
                    ) { method in
                        paymentMethod = method
                        let booking = TravelBooking(
                            date: Date(),
                            title: hotel.name,
                            subtitle: "\(nights) night\(nights == 1 ? "" : "s") · \(hotel.location)",
                            total: total,
                            paymentMethod: method,
                            icon: "building.2.fill",
                            gradient: [.purple, .indigo]
                        )
                        bookings.append(booking)
                        paymentDone = true
                    }.padding(.horizontal)
                }
            }.padding(.vertical)
        }
        .navigationTitle("Hotel Details").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared Payment Components

struct TravelPaymentButtons: View {
    let total: Double
    let itemLabel: String
    let tint: Color
    let onPaid: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            TravelApplePayButton(total: total, itemLabel: itemLabel) { success in
                if success { onPaid("Apple Pay") }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("Pay with Apple Pay")

            Button { onPaid("Card") } label: {
                Text("Pay \(total.formatted(.currency(code: "USD"))) with Card")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(tint, in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Pay with card")
        }
    }
}

struct BookingConfirmedView: View {
    let title: String
    let subtitle: String
    let paymentMethod: String
    let total: Double
    @State private var showShareSheet = false
    @State private var receiptURL: URL?
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 48)).foregroundStyle(.green).accessibilityHidden(true)
            Text(title).font(.title2.bold())
            Text(subtitle).foregroundStyle(.secondary)
            Text("Paid via \(paymentMethod)").font(.caption).foregroundStyle(.secondary)
            Button {
                if let url = generateTravelReceiptPDF(title: title, subtitle: subtitle, total: total, paymentMethod: paymentMethod) { presentShareSheet(url: url) }
            } label: {
                Label("Download Receipt (PDF)", systemImage: "arrow.down.doc.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.green)
            }
            .accessibilityLabel("Download receipt as PDF")
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

func generateTravelReceiptPDF(title: String, subtitle: String, total: Double, paymentMethod: String) -> URL? {
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.label]
        let bodyAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.secondaryLabel]
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.label]
        NSString(string: "TripNexus Receipt").draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttrs)
        NSString(string: title).draw(at: CGPoint(x: 40, y: 80), withAttributes: valueAttrs)
        NSString(string: subtitle).draw(at: CGPoint(x: 40, y: 104), withAttributes: bodyAttrs)
        NSString(string: "Payment Method: \(paymentMethod)").draw(at: CGPoint(x: 40, y: 140), withAttributes: bodyAttrs)
        NSString(string: "Total: \(total.formatted(.currency(code: "USD")))").draw(at: CGPoint(x: 40, y: 164), withAttributes: valueAttrs)
        NSString(string: "Date: \(Date().formatted(date: .long, time: .shortened))").draw(at: CGPoint(x: 40, y: 188), withAttributes: bodyAttrs)
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("TripNexus_Receipt.pdf")
    try? data.write(to: url)
    return url
}

// MARK: - Real Apple Pay for Travel

struct TravelApplePayButton: UIViewRepresentable {
    let total: Double
    let itemLabel: String
    let onResult: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    func makeUIView(context: Context) -> PKPaymentButton {
        let btn = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        btn.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        context.coordinator.total = total
        context.coordinator.itemLabel = itemLabel
        return btn
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        context.coordinator.total = total
        context.coordinator.itemLabel = itemLabel
    }

    final class Coordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
        var total: Double = 0
        var itemLabel: String = ""
        let onResult: (Bool) -> Void
        init(onResult: @escaping (Bool) -> Void) { self.onResult = onResult }

        @objc func tapped() {
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant.com.bstack.nexus-demo"
            request.supportedNetworks = [.visa, .masterCard, .amex]
            request.merchantCapabilities = .capability3DS
            request.countryCode = "US"
            request.currencyCode = "USD"
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(
                    label: itemLabel,
                    amount: NSDecimalNumber(string: String(format: "%.2f", (total * 100).rounded() / 100))
                )
            ]
            let controller = PKPaymentAuthorizationController(paymentRequest: request)
            controller.delegate = self
            controller.present(completion: nil)
        }

        func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }

        func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
            controller.dismiss {
                DispatchQueue.main.async { self.onResult(true) }
            }
        }
    }
}

// MARK: - Shared Detail Row

struct TravelDetailRow: View {
    let label: String; let value: String; var valueColor: Color = .primary
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary).padding(.leading, 16)
            Spacer()
            Text(value).fontWeight(.medium).foregroundStyle(valueColor).padding(.trailing, 16)
        }
        .frame(minHeight: 44)
    }
}

// MARK: - Trips List

struct TripsListView: View {
    @Binding var bookings: [TravelBooking]
    var body: some View {
        List {
            Section("Sample Trips") {
                ForEach(TravelSampleData.trips) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip, bookings: $bookings)) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(colors: trip.imageGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                Image(systemName: trip.icon).foregroundStyle(.white).accessibilityHidden(true)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(trip.destination).font(.subheadline.weight(.semibold))
                                Text(trip.dates).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(trip.status.rawValue).font(.caption2).padding(.horizontal, 8).padding(.vertical, 3)
                                .background(trip.status == .upcoming ? Color.green.opacity(0.12) : Color.secondary.opacity(0.10), in: Capsule())
                                .foregroundStyle(trip.status == .upcoming ? .green : .secondary)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(trip.destination + ", " + trip.dates + ", " + trip.status.rawValue)
                    }
                }
            }
            if !bookings.isEmpty {
                Section("My Bookings") {
                    ForEach(bookings) { booking in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(colors: booking.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 44, height: 44)
                                Image(systemName: booking.icon).foregroundStyle(.white).accessibilityHidden(true)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(booking.title).font(.subheadline.weight(.semibold))
                                Text(booking.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(booking.total, format: .currency(code: "USD")).font(.subheadline.bold()).foregroundStyle(.pink)
                                Text(booking.paymentMethod).font(.caption2).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("My Trips").navigationBarTitleDisplayMode(.inline)
    }
}

struct TripDetailView: View {
    let trip: Trip
    @Binding var bookings: [TravelBooking]
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(colors: trip.imageGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.destination).font(.largeTitle.bold()).foregroundStyle(.white)
                        Text(trip.country).font(.title3).foregroundStyle(.white.opacity(0.85))
                    }.padding()
                }.padding(.horizontal)

                VStack(spacing: 0) {
                    TravelDetailRow(label: "Dates", value: trip.dates)
                    Divider().padding(.leading, 16)
                    TravelDetailRow(label: "Type", value: trip.type)
                    Divider().padding(.leading, 16)
                    TravelDetailRow(label: "Status", value: trip.status.rawValue)
                    Divider().padding(.leading, 16)
                    TravelDetailRow(label: "Total", value: trip.price.formatted(.currency(code: "USD")), valueColor: .pink)
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2).padding(.horizontal)
            }.padding(.vertical)
        }
        .navigationTitle(trip.destination).navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Digital Key

struct DigitalKeyView: View {
    @State private var keyUnlocked = false
    @State private var roomNumber = "412"
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(keyUnlocked ? Color.green.opacity(0.12) : Color.pink.opacity(0.10))
                    .frame(width: 140, height: 140)
                Image(systemName: keyUnlocked ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(keyUnlocked ? .green : .pink)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 8) {
                Text(keyUnlocked ? "Room \(roomNumber) Unlocked" : "Digital Room Key").font(.title2.bold())
                Text(keyUnlocked ? "Your room door is now open." : "Room \(roomNumber) · Tap to unlock.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            HStack(spacing: 12) {
                ForEach(["410", "412", "501"], id: \.self) { room in
                    Button { roomNumber = room; keyUnlocked = false } label: {
                        Text("Room \(room)").font(.caption.weight(.semibold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(roomNumber == room ? Color.pink : Color.pink.opacity(0.10), in: Capsule())
                            .foregroundStyle(roomNumber == room ? .white : .pink)
                    }.accessibilityLabel("Select room \(room)")
                }
            }
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { keyUnlocked.toggle() }
            } label: {
                Text(keyUnlocked ? "Lock Room" : "Unlock Room")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(keyUnlocked ? Color.green : Color.pink, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .accessibilityLabel(keyUnlocked ? "Lock room" : "Unlock room")
            Spacer()
        }
        .navigationTitle("Digital Key").navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { TravelRootView() }
        .environmentObject(SessionStore())
        .environmentObject(IPGeoManager.shared)
}
