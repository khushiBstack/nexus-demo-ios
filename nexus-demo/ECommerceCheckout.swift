import SwiftUI
import PassKit
import CoreLocation
import Combine

// MARK: - Helpers

struct CartSummaryRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }.font(.subheadline)
    }
}

// MARK: - Checkout

struct CheckoutView: View {
    @Binding var cartItems: [CartItem]
    @Binding var orders: [PlacedOrder]
    @StateObject private var locationMgr = ECommerceLocationManager()

    @State private var addressLine = ""
    @State private var city = ""
    @State private var zip = ""
    @State private var useDetectedLocation = false
    @State private var placedOrder: PlacedOrder?
    @State private var paymentMethod: String = "Card"

    private var subtotal: Double { cartItems.reduce(0) { $0 + $1.product.price * Double($1.quantity) } }
    private var tax: Double { subtotal * 0.08 }
    private var shipping: Double { subtotal >= 50 ? 0 : 5.99 }
    private var total: Double { subtotal + tax + shipping }

    private var deliveryAddress: String {
        if useDetectedLocation, let addr = locationMgr.detectedAddress { return addr }
        let parts = [addressLine, city, zip].filter { !$0.isEmpty }
        return parts.isEmpty ? "Not specified" : parts.joined(separator: ", ")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ── Delivery address ──────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Label("Delivery Address", systemImage: "mappin.and.ellipse").font(.headline)

                    Button {
                        useDetectedLocation = true
                        locationMgr.requestLocation()
                    } label: {
                        HStack {
                            Image(systemName: "location.fill").accessibilityHidden(true)
                            if locationMgr.isLocating {
                                ProgressView().scaleEffect(0.8)
                                Text("Detecting…")
                            } else if let addr = locationMgr.detectedAddress, useDetectedLocation {
                                Text(addr).lineLimit(1)
                            } else {
                                Text("Use my current location")
                            }
                            Spacer()
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.shopAccent)
                        .padding(12)
                        .background(Color.shopAccent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel("Use current location for delivery")

                    Text("or enter manually").font(.caption).foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        HStack {
                            Text("Street").font(.caption).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
                            TextField("Street address", text: $addressLine)
                                .padding(10)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                .accessibilityLabel("Street address")
                        }
                        HStack(spacing: 10) {
                            HStack {
                                Text("City").font(.caption).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
                                TextField("City", text: $city)
                                    .padding(10)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                    .accessibilityLabel("City")
                            }
                            HStack {
                                Text("ZIP").font(.caption).foregroundStyle(.secondary).frame(width: 30, alignment: .leading)
                                TextField("ZIP", text: $zip)
                                    .keyboardType(.numberPad)
                                    .padding(10)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                    .frame(maxWidth: 90)
                                    .accessibilityLabel("ZIP code")
                            }
                        }
                    }
                }
                .padding()
                .background(Color.shopCard, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                // ── Order summary ─────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("Order Summary").font(.headline)
                    ForEach(cartItems) { item in
                        HStack {
                            Text("\(item.product.name) × \(item.quantity)").font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                            Text((item.product.price * Double(item.quantity)).formatted(.currency(code: "USD"))).font(.subheadline)
                        }
                    }
                    Divider()
                    CartSummaryRow(label: "Subtotal", value: subtotal.formatted(.currency(code: "USD")))
                    CartSummaryRow(label: "Shipping", value: shipping == 0 ? "Free" : shipping.formatted(.currency(code: "USD")))
                    CartSummaryRow(label: "Tax (8%)", value: tax.formatted(.currency(code: "USD")))
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(total.formatted(.currency(code: "USD"))).font(.headline).foregroundColor(.shopAccent)
                    }
                    if shipping == 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).accessibilityHidden(true)
                            Text("Free shipping applied!").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.shopCard, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                // ── Payment ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment").font(.headline)

                    // Apple Pay button — styled to match card button
                    ApplePayButton(total: total, cartItems: cartItems) { success in
                        if success {
                            paymentMethod = "Apple Pay"
                            placeOrder()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Pay with Apple Pay")

                    Button {
                        paymentMethod = "Card"
                        placeOrder()
                    } label: {
                        Text("Pay \(total.formatted(.currency(code: "USD"))) with Card")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.shopAccent, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Pay with card")
                }
                .padding()
                .background(Color.shopCard, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
            .padding(.vertical)
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { placedOrder != nil },
            set: { if !$0 { placedOrder = nil } }
        )) {
            if let order = placedOrder {
                OrderConfirmationView(order: order) {
                    cartItems.removeAll()
                }
            }
        }
        .onAppear { locationMgr.requestLocation() }
    }

    private func placeOrder() {
        let order = PlacedOrder(
            date: Date(),
            items: cartItems,
            total: total,
            paymentMethod: paymentMethod,
            deliveryAddress: deliveryAddress
        )
        orders.append(order)
        placedOrder = order
    }
}

// MARK: - Apple Pay button (real PKPaymentAuthorizationController)

struct ApplePayButton: UIViewRepresentable {
    let total: Double
    let cartItems: [CartItem]
    let onResult: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    func makeUIView(context: Context) -> PKPaymentButton {
        let btn = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        btn.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        context.coordinator.total = total
        context.coordinator.cartItems = cartItems
        return btn
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        context.coordinator.total = total
        context.coordinator.cartItems = cartItems
    }

    final class Coordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
        var total: Double = 0
        var cartItems: [CartItem] = []
        let onResult: (Bool) -> Void
        init(onResult: @escaping (Bool) -> Void) { self.onResult = onResult }

        @objc func tapped() {
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant.com.bstack.nexus-demo"
            request.supportedNetworks = [.visa, .masterCard, .amex]
            request.merchantCapabilities = .capability3DS
            request.countryCode = "US"
            request.currencyCode = "USD"
            request.paymentSummaryItems = cartItems.map { item in
                let lineAmt = (item.product.price * Double(item.quantity) * 100).rounded() / 100
                return PKPaymentSummaryItem(
                    label: item.product.name,
                    amount: NSDecimalNumber(string: String(format: "%.2f", lineAmt))
                )
            } + [PKPaymentSummaryItem(
                label: "ShopNexus",
                amount: NSDecimalNumber(string: String(format: "%.2f", (total * 100).rounded() / 100))
            )]

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

// MARK: - Order confirmation

struct OrderConfirmationView: View {
    let order: PlacedOrder
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var receiptURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 20)

                ZStack {
                    Circle().fill(Color.green.opacity(0.12)).frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundColor(.green)
                        .accessibilityLabel("Order placed successfully")
                }

                VStack(spacing: 8) {
                    Text("Order Placed!").font(.title.bold())
                    Text("Paid via \(order.paymentMethod)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("Order #\(String(order.id.uuidString.prefix(8)).uppercased())")
                        .font(.caption).foregroundStyle(.secondary)
                }

                // Receipt card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Receipt").font(.headline)
                    Divider()
                    ForEach(order.items) { item in
                        HStack {
                            Text("\(item.product.name) × \(item.quantity)").font(.subheadline)
                            Spacer()
                            Text((item.product.price * Double(item.quantity)).formatted(.currency(code: "USD")))
                                .font(.subheadline)
                        }
                    }
                    Divider()
                    let sub = order.items.reduce(0.0) { $0 + $1.product.price * Double($1.quantity) }
                    let tax = sub * 0.08
                    let ship = sub >= 50 ? 0.0 : 5.99
                    CartSummaryRow(label: "Subtotal", value: sub.formatted(.currency(code: "USD")))
                    CartSummaryRow(label: "Shipping", value: ship == 0 ? "Free" : ship.formatted(.currency(code: "USD")))
                    CartSummaryRow(label: "Tax (8%)", value: tax.formatted(.currency(code: "USD")))
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(order.total.formatted(.currency(code: "USD"))).font(.headline).foregroundColor(.shopAccent)
                    }
                    Divider()
                    HStack {
                        Text("Delivery to").foregroundStyle(.secondary).font(.caption)
                        Spacer()
                        Text(order.deliveryAddress).font(.caption).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Date").foregroundStyle(.secondary).font(.caption)
                        Spacer()
                        Text(order.date.formatted(date: .abbreviated, time: .shortened)).font(.caption)
                    }
                }
                .padding()
                .background(Color.shopCard, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                .padding(.horizontal)

                // Download receipt
                Button {
                    if let url = generateReceiptPDF(order: order) { presentShareSheet(url: url) }
                } label: {
                    Label("Download Receipt (PDF)", systemImage: "arrow.down.doc.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.shopAccent)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.shopAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .accessibilityLabel("Download receipt as PDF")

                Button {
                    onDone()
                    dismiss()
                } label: {
                    Text("Continue Shopping")
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.shopAccent, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer(minLength: 24)
            }
        }
        .navigationTitle("Order Confirmed")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Receipt view (from order history)

struct ReceiptView: View {
    let order: PlacedOrder
    @State private var showShareSheet = false
    @State private var receiptURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(String(order.id.uuidString.prefix(8)).uppercased())").font(.title3.bold())
                    Text(order.date.formatted(date: .long, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                    Text("Paid via \(order.paymentMethod)").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Items").font(.headline)
                    ForEach(order.items) { item in
                        HStack {
                            Text("\(item.product.name) × \(item.quantity)").font(.subheadline)
                            Spacer()
                            Text((item.product.price * Double(item.quantity)).formatted(.currency(code: "USD"))).font(.subheadline)
                        }
                    }
                    Divider()
                    let sub = order.items.reduce(0.0) { $0 + $1.product.price * Double($1.quantity) }
                    let tax = sub * 0.08
                    let ship = sub >= 50 ? 0.0 : 5.99
                    CartSummaryRow(label: "Subtotal", value: sub.formatted(.currency(code: "USD")))
                    CartSummaryRow(label: "Shipping", value: ship == 0 ? "Free" : ship.formatted(.currency(code: "USD")))
                    CartSummaryRow(label: "Tax (8%)", value: tax.formatted(.currency(code: "USD")))
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(order.total.formatted(.currency(code: "USD"))).font(.headline).foregroundColor(.shopAccent)
                    }
                }
                .padding()
                .background(Color.shopCard, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                Button {
                    if let url = generateReceiptPDF(order: order) { presentShareSheet(url: url) }
                } label: {
                    Label("Download Receipt (PDF)", systemImage: "arrow.down.doc.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.shopAccent)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.shopAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .accessibilityLabel("Download receipt as PDF")
            }
            .padding(.vertical)
        }
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - PDF receipt generator

func generateReceiptPDF(order: PlacedOrder) -> URL? {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
        let boldAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
        var y: CGFloat = 40

        func draw(_ text: String, x: CGFloat = 40, bold: Bool = false) {
            let a = bold ? boldAttrs : attrs
            text.draw(at: CGPoint(x: x, y: y), withAttributes: a)
            y += 22
        }

        draw("ShopNexus — Order Receipt", bold: true)
        draw("Order #\(String(order.id.uuidString.prefix(8)).uppercased())")
        draw("Date: \(order.date.formatted(date: .long, time: .shortened))")
        draw("Payment: \(order.paymentMethod)")
        draw("Delivery: \(order.deliveryAddress)")
        y += 10
        draw("─────────────────────────────────────────")
        for item in order.items {
            let line = "\(item.product.name) × \(item.quantity)"
            let price = (item.product.price * Double(item.quantity)).formatted(.currency(code: "USD"))
            line.draw(at: CGPoint(x: 40, y: y), withAttributes: attrs)
            price.draw(at: CGPoint(x: 450, y: y), withAttributes: attrs)
            y += 22
        }
        draw("─────────────────────────────────────────")
        let sub = order.items.reduce(0.0) { $0 + $1.product.price * Double($1.quantity) }
        draw("Subtotal: \(sub.formatted(.currency(code: "USD")))")
        let ship = sub >= 50 ? 0.0 : 5.99
        draw("Shipping: \(ship == 0 ? "Free" : ship.formatted(.currency(code: "USD")))")
        draw("Tax (8%): \((sub * 0.08).formatted(.currency(code: "USD")))")
        draw("TOTAL: \(order.total.formatted(.currency(code: "USD")))", bold: true)
    }

    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("Receipt_\(String(order.id.uuidString.prefix(8))).pdf")
    try? data.write(to: url)
    return url
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
