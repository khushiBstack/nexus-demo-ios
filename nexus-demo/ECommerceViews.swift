import SwiftUI
import PassKit
import CoreLocation
import Combine

extension Color {
    static let shopAccent = Color(red: 0.95, green: 0.42, blue: 0.13)
    static let shopBg     = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let shopCard   = Color(.secondarySystemGroupedBackground)
}

struct Product: Identifiable, Hashable {
    let id = UUID()
    let name: String; let price: Double; let imageName: String; let imageURL: String
    let category: String; let rating: Double; let reviewCount: Int
    let description: String; let tags: [String]
}
struct CartItem: Identifiable {
    let id = UUID(); let product: Product; var quantity: Int
}
struct PlacedOrder: Identifiable {
    let id = UUID(); let date: Date; let items: [CartItem]
    let total: Double; let paymentMethod: String; let deliveryAddress: String
}

enum ECommerceSampleData {
    static let products: [Product] = [
        Product(name: "Wireless Headphones", price: 79.99, imageName: "headphones",
                imageURL: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80",
                category: "Electronics", rating: 4.5, reviewCount: 128,
                description: "Premium over-ear headphones with active noise cancellation.", tags: ["Bestseller", "ANC"]),
        Product(name: "Running Shoes", price: 64.50, imageName: "figure.run",
                imageURL: "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80",
                category: "Sports", rating: 4.2, reviewCount: 84,
                description: "Lightweight mesh running shoes with responsive cushioning.", tags: ["New"]),
        Product(name: "Smart Watch", price: 149.00, imageName: "applewatch",
                imageURL: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80",
                category: "Electronics", rating: 4.7, reviewCount: 210,
                description: "Track fitness and monitor health metrics from your wrist.", tags: ["Bestseller", "Top Rated"]),
        Product(name: "Backpack", price: 39.99, imageName: "bag.fill",
                imageURL: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&q=80",
                category: "Accessories", rating: 4.3, reviewCount: 56,
                description: "Durable 30L backpack with laptop compartment.", tags: []),
        Product(name: "Sunglasses", price: 24.99, imageName: "sun.max.fill",
                imageURL: "https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400&q=80",
                category: "Accessories", rating: 4.0, reviewCount: 42,
                description: "UV400 polarised lenses in a lightweight frame.", tags: ["Sale"]),
        Product(name: "Yoga Mat", price: 34.99, imageName: "figure.yoga",
                imageURL: "https://images.unsplash.com/photo-1601925228008-f5e4c5e5e5e5?w=400&q=80",
                category: "Sports", rating: 4.6, reviewCount: 97,
                description: "Non-slip 6mm thick mat with alignment lines.", tags: ["Top Rated"]),
        Product(name: "Desk Lamp", price: 29.99, imageName: "lamp.desk.fill",
                imageURL: "https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400&q=80",
                category: "Home", rating: 4.1, reviewCount: 33,
                description: "LED desk lamp with 5 colour temperatures and USB-C charging.", tags: [])
    ]
    static let categories = ["All", "Electronics", "Sports", "Accessories", "Home"]
}

struct ProductImage: View {
    let url: String; let fallback: String; var height: CGFloat = 110
    var body: some View {
        if let u = URL(string: url) {
            AsyncImage(url: u) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill().frame(maxWidth: .infinity).frame(height: height).clipped()
                case .failure: fallbackView
                default: ZStack { Color.shopAccent.opacity(0.07); ProgressView().tint(.shopAccent) }.frame(maxWidth: .infinity).frame(height: height)
                }
            }
        } else { fallbackView }
    }
    private var fallbackView: some View {
        ZStack {
            Color.shopAccent.opacity(0.07)
            Image(systemName: fallback).font(.system(size: height * 0.35)).foregroundColor(.shopAccent).accessibilityHidden(true)
        }.frame(maxWidth: .infinity).frame(height: height)
    }
}

struct ECommerceRootView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        Group {
            if session.ecommerceLoggedIn && session.ecommerceOTPVerified {
                ECommerceTabView().toolbar(.hidden, for: .navigationBar)
            } else if session.ecommerceLoggedIn && !session.ecommerceOTPVerified {
                OTPVerificationView(title: "ShopNexus", tint: .shopAccent, icon: "bag.fill") { session.ecommerceOTPVerified = true }
            } else {
                IndustryLoginView(title: "ShopNexus", icon: "bag.fill", tint: .shopAccent) { email, name in
                    session.ecommerceUserEmail = email; session.ecommerceUserName = name
                    session.ecommerceLoggedIn = true; session.ecommerceOTPVerified = false
                }
            }
        }
        .navigationTitle("E-commerce").navigationBarTitleDisplayMode(.inline)
    }
}

struct ECommerceTabView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var cartItems: [CartItem] = []
    @State private var orders: [PlacedOrder] = []
    var cartCount: Int { cartItems.reduce(0) { $0 + $1.quantity } }
    var body: some View {
        TabView {
            NavigationStack { ShopHomeView(cartItems: $cartItems) }.tabItem { Label("Shop", systemImage: "storefront.fill") }
            NavigationStack { SearchView(cartItems: $cartItems) }.tabItem { Label("Search", systemImage: "magnifyingglass") }
            NavigationStack { CartView(cartItems: $cartItems, orders: $orders) }.tabItem { Label("Cart", systemImage: "cart.fill") }.badge(cartCount > 0 ? cartCount : 0)
            NavigationStack { OrderHistoryView(orders: orders) }.tabItem { Label("Orders", systemImage: "clock.arrow.circlepath") }
            NavigationStack {
                ProfileView(domainName: "E-commerce") {
                    session.ecommerceLoggedIn = false; session.ecommerceUserName = ""; session.ecommerceUserEmail = ""; session.ecommerceOTPVerified = false
                }
            }.tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }.tint(.shopAccent)

    }
}

struct ShopHomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var geo: IPGeoManager
    @Binding var cartItems: [CartItem]
    @StateObject private var locationMgr = ECommerceLocationManager()
    @State private var selectedCategory = "All"
    @State private var bannerIndex = 0
    @State private var showAlerts = false
    private let bannerTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    private var banners: [(String, String, String, Color)] {
        let city = geo.city ?? "your city"
        return [
            ("Deals in \(city)", "Exclusive local offers", "tag.fill", Color.shopAccent),
            ("New Arrivals", "Fresh picks just in", "sparkles", Color(red: 0.45, green: 0.30, blue: 0.80)),
            ("Free Shipping", "On orders over $50", "shippingbox.fill", Color(red: 0.15, green: 0.50, blue: 0.75))
        ]
    }
    private var featured: [Product] {
        ECommerceSampleData.products.filter { selectedCategory == "All" || $0.category == selectedCategory }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hello, \(firstName)").font(.title2.bold())
                        if let city = geo.city {
                            Label(city, systemImage: "location.fill").font(.caption).foregroundStyle(.secondary)
                        } else if let country = geo.country {
                            Label(country, systemImage: "network").font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("What are you looking for?").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(LinearGradient(colors: [.shopAccent, Color(red: 0.85, green: 0.25, blue: 0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 46, height: 46)
                        Text(initials(session.ecommerceUserName)).font(.subheadline.bold()).foregroundStyle(.white)
                    }
                }.padding(.horizontal).padding(.top, 8)
                HStack { Spacer(); NetworkSpeedWidget() }.padding(.horizontal)
                TabView(selection: $bannerIndex) {
                    ForEach(banners.indices, id: \.self) { i in
                        let b = banners[i]
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(b.0).font(.headline.bold()).foregroundStyle(.white)
                                Text(b.1).font(.subheadline).foregroundStyle(.white.opacity(0.88))
                            }
                            Spacer()
                            Image(systemName: b.2).font(.system(size: 38)).foregroundStyle(.white.opacity(0.75)).accessibilityHidden(true)
                        }
                        .padding(20).frame(maxWidth: .infinity).frame(height: 100)
                        .background(LinearGradient(colors: [b.3, b.3.opacity(0.65)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 100)
                .onReceive(bannerTimer) { _ in withAnimation { bannerIndex = (bannerIndex + 1) % banners.count } }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ECommerceSampleData.categories, id: \.self) { cat in
                            Button(cat) { selectedCategory = cat }
                                .font(.subheadline.weight(.medium)).padding(.horizontal, 16).padding(.vertical, 8)
                                .background(selectedCategory == cat ? Color.shopAccent : Color.shopAccent.opacity(0.08), in: Capsule())
                                .foregroundColor(selectedCategory == cat ? .white : Color.shopAccent)
                                .accessibilityLabel(cat + (selectedCategory == cat ? ", selected" : ""))
                        }
                    }.padding(.horizontal)
                }
                Text("Featured").font(.headline).padding(.horizontal)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(featured) { product in
                        NavigationLink(destination: ProductDetailView(product: product, cartItems: $cartItems)) { ProductCard(product: product) }.buttonStyle(.plain)
                    }
                }.padding(.horizontal)
            }.padding(.bottom, 24)
        }
        .navigationTitle("ShopNexus").navigationBarTitleDisplayMode(.inline)
        .onAppear { locationMgr.requestLocation(); geo.fetchIfNeeded() }
        .sheet(isPresented: $showAlerts) {
            NavigationStack {
                PushNotificationDemoView(
                    domainTitle: "ShopNexus",
                    domainTint: Color.shopAccent,
                    domainIcon: "bell.badge.fill"
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAlerts = true } label: {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(Color.shopAccent)
                }
                .accessibilityLabel("Notifications")
            }
        }
    }
    private var firstName: String {
        let n = session.ecommerceUserName
        return n.isEmpty ? "there" : n.split(separator: " ").first.map(String.init) ?? n
    }
    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1)) + String(parts[1].prefix(1)) }
        return name.prefix(2).uppercased()
    }
}

struct ProductCard: View {
    let product: Product
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProductImage(url: product.imageURL, fallback: product.imageName).clipShape(RoundedRectangle(cornerRadius: 12))
            productInfo
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(product.name + ", " + product.price.formatted(.currency(code: "USD")))
    }
    @ViewBuilder private var productInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name).font(.caption.weight(.semibold)).lineLimit(1)
            HStack {
                Text(product.price, format: .currency(code: "USD")).font(.caption.bold()).foregroundColor(Color.shopAccent)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "star.fill").font(.caption2).foregroundColor(.yellow).accessibilityHidden(true)
                    Text(String(format: "%.1f", product.rating)).font(.caption2)
                }
            }
            if !product.tags.isEmpty {
                Text(product.tags[0]).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.shopAccent.opacity(0.12), in: Capsule()).foregroundColor(Color.shopAccent)
            }
        }.padding(8)
    }
}

struct ProductDetailView: View {
    let product: Product; @Binding var cartItems: [CartItem]
    @State private var addedToCart = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProductImage(url: product.imageURL, fallback: product.imageName, height: 260)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(product.name).font(.title2.bold())
                        Spacer()
                        Text(product.price, format: .currency(code: "USD")).font(.title3.bold()).foregroundColor(Color.shopAccent)
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<5) { i in Image(systemName: i < Int(product.rating) ? "star.fill" : "star").font(.caption).foregroundColor(.yellow).accessibilityHidden(true) }
                        Text("(\(product.reviewCount))").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(product.description).foregroundStyle(.secondary)
                    Button {
                        if let idx = cartItems.firstIndex(where: { $0.product.id == product.id }) { cartItems[idx].quantity += 1 }
                        else { cartItems.append(CartItem(product: product, quantity: 1)) }
                        addedToCart = true
                    } label: {
                        Label(addedToCart ? "Added to Cart" : "Add to Cart", systemImage: addedToCart ? "checkmark.circle.fill" : "cart.badge.plus")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                            .background(addedToCart ? Color.green : Color.shopAccent, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                    }.accessibilityLabel(addedToCart ? "Added to cart" : "Add to cart")
                }.padding()
            }
        }
        .navigationTitle(product.name).navigationBarTitleDisplayMode(.inline)
    }
}

struct SearchView: View {
    @Binding var cartItems: [CartItem]
    @State private var query = ""
    private var results: [Product] {
        guard !query.isEmpty else { return [] }
        return ECommerceSampleData.products.filter { $0.name.lowercased().contains(query.lowercased()) || $0.category.lowercased().contains(query.lowercased()) }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
                TextField("Search products...", text: $query).autocorrectionDisabled().accessibilityLabel("Search products")
                if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.accessibilityLabel("Clear search") }
            }.padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12)).padding()
            if results.isEmpty && !query.isEmpty {
                VStack(spacing: 12) { Image(systemName: "magnifyingglass").font(.system(size: 44)).foregroundStyle(.secondary).accessibilityHidden(true); Text("No results for: \(query)").foregroundStyle(.secondary) }.padding(.top, 40)
            } else if query.isEmpty {
                VStack(spacing: 12) { Image(systemName: "magnifyingglass").font(.system(size: 44)).foregroundStyle(.secondary).accessibilityHidden(true); Text("Search for products").foregroundStyle(.secondary) }.padding(.top, 60)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(results) { product in NavigationLink(destination: ProductDetailView(product: product, cartItems: $cartItems)) { ProductCard(product: product) }.buttonStyle(.plain) }
                    }.padding()
                }
            }
            Spacer()
        }.navigationTitle("Search").navigationBarTitleDisplayMode(.inline)
    }
}

struct CartView: View {
    @Binding var cartItems: [CartItem]; @Binding var orders: [PlacedOrder]
    private var subtotal: Double { cartItems.reduce(0) { $0 + $1.product.price * Double($1.quantity) } }
    private var tax: Double { subtotal * 0.08 }
    private var shipping: Double { subtotal >= 50 ? 0 : 5.99 }
    private var total: Double { subtotal + tax + shipping }
    var body: some View { cartContent.navigationTitle("Cart").navigationBarTitleDisplayMode(.inline) }
    @ViewBuilder private var cartContent: some View {
        if cartItems.isEmpty {
            VStack(spacing: 12) { Image(systemName: "cart").font(.system(size: 44)).foregroundStyle(.secondary).accessibilityHidden(true); Text("Your cart is empty").font(.headline); Text("Add items from the Shop tab").foregroundStyle(.secondary) }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section("Items") {
                    ForEach($cartItems) { $item in
                        HStack(spacing: 14) {
                            ProductImage(url: item.product.imageURL, fallback: item.product.imageName, height: 44).frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) { Text(item.product.name).font(.subheadline.weight(.semibold)); Text(item.product.price, format: .currency(code: "USD")).font(.caption).foregroundColor(Color.shopAccent) }
                            Spacer()
                            Stepper("\(item.quantity)", value: $item.quantity, in: 1...99).labelsHidden()
                        }
                        .accessibilityElement(children: .combine).accessibilityLabel(item.product.name + ", quantity \(item.quantity)")
                    }.onDelete { cartItems.remove(atOffsets: $0) }
                }
                Section("Summary") {
                    HStack { Text("Subtotal").foregroundStyle(.secondary); Spacer(); Text(subtotal, format: .currency(code: "USD")) }
                    HStack { Text("Tax (8%)").foregroundStyle(.secondary); Spacer(); Text(tax, format: .currency(code: "USD")) }
                    HStack { Text("Shipping").foregroundStyle(.secondary); Spacer(); Text(shipping == 0 ? "Free" : shipping.formatted(.currency(code: "USD"))).foregroundColor(shipping == 0 ? .green : .primary) }
                    HStack { Text("Total").font(.headline); Spacer(); Text(total, format: .currency(code: "USD")).font(.headline).foregroundColor(Color.shopAccent) }
                }
                Section { NavigationLink(destination: CheckoutView(cartItems: $cartItems, orders: $orders)) { Text("Proceed to Checkout").font(.headline).frame(maxWidth: .infinity).foregroundColor(Color.shopAccent) }.accessibilityLabel("Proceed to checkout") }
            }
        }
    }
}

struct OrderHistoryView: View {
    let orders: [PlacedOrder]
    var body: some View { orderContent.navigationTitle("Orders").navigationBarTitleDisplayMode(.inline) }
    @ViewBuilder private var orderContent: some View {
        if orders.isEmpty {
            VStack(spacing: 12) { Image(systemName: "clock.arrow.circlepath").font(.system(size: 44)).foregroundStyle(.secondary).accessibilityHidden(true); Text("No orders yet").font(.headline); Text("Your placed orders will appear here").foregroundStyle(.secondary) }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(orders) { order in
                NavigationLink(destination: ReceiptView(order: order)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text(order.date, style: .date).font(.subheadline.weight(.semibold)); Spacer(); Text(order.total, format: .currency(code: "USD")).font(.subheadline.bold()).foregroundColor(Color.shopAccent) }
                        Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s") · \(order.paymentMethod)").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 4)
                }.accessibilityLabel("Order, \(order.total.formatted(.currency(code: "USD")))")
            }
        }
    }
}

final class ECommerceLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let mgr = CLLocationManager(); private let geocoder = CLGeocoder()
    @Published var city: String?; @Published var detectedAddress: String?; @Published var isLocating: Bool = false
    override init() { super.init(); mgr.delegate = self }
    func requestLocation() { isLocating = true; mgr.requestWhenInUseAuthorization(); mgr.requestLocation() }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { isLocating = false; return }
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                if let p = placemarks?.first {
                    self?.city = p.locality
                    let parts = [p.subThoroughfare, p.thoroughfare, p.locality, p.administrativeArea, p.postalCode].compactMap { $0 }.filter { !$0.isEmpty }
                    self?.detectedAddress = parts.isEmpty ? nil : parts.joined(separator: ", ")
                }
                self?.isLocating = false
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { isLocating = false }
}

#Preview {
    NavigationStack { ECommerceRootView() }.environmentObject(SessionStore()).environmentObject(IPGeoManager.shared)
}
