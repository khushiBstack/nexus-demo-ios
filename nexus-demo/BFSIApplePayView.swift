import SwiftUI
import PassKit

// MARK: - BFSI Apple Pay

struct BFSIApplePayView: View {
    @EnvironmentObject var bfsiStore: BFSIStore

    @State private var selectedAccountId: UUID?
    @State private var merchant = ""
    @State private var amountText = ""
    @State private var showResult = false
    @State private var resultMessage = ""

    private var selectedAccount: BFSIAccount? {
        bfsiStore.accounts.first(where: { $0.id == selectedAccountId })
    }
    private var amount: Double { Double(amountText) ?? 0 }
    private var canPay: Bool { selectedAccountId != nil && amount > 0 && !merchant.isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Account picker
                VStack(alignment: .leading, spacing: 8) {
                    Label("Pay from Account", systemImage: "creditcard").font(.headline)
                    Menu {
                        ForEach(bfsiStore.accounts.filter { $0.type != .credit }) { acc in
                            Button("\(acc.name)  \(acc.maskedNumber)  \(acc.formattedBalance)") {
                                selectedAccountId = acc.id
                            }
                        }
                    } label: {
                        HStack {
                            if let acc = selectedAccount {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acc.name).font(.headline)
                                    Text(acc.maskedNumber + "  ·  " + acc.formattedBalance)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Select account").foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                // Merchant + amount
                VStack(alignment: .leading, spacing: 12) {
                    Label("Payment Details", systemImage: "doc.text").font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Merchant").font(.caption).foregroundStyle(.secondary)
                        TextField("Merchant name", text: $merchant)
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("Merchant name")
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Amount").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Text("$").font(.title2.bold()).foregroundStyle(.secondary)
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.title2.bold())
                                .accessibilityLabel("Payment amount")
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                // Apple Pay button
                if canPay {
                    BFSIApplePayButton(
                        merchant: merchant,
                        amount: amount
                    ) { success in
                        if success {
                            bfsiStore.recordApplePay(merchant: merchant, amount: amount,
                                                     accountId: selectedAccountId!)
                            resultMessage = "Payment of \(amount.formatted(.currency(code: "USD"))) to \(merchant) completed."
                        } else {
                            resultMessage = "Payment was cancelled."
                        }
                        showResult = true
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // History
                if !bfsiStore.applePayHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Apple Pay").font(.headline).padding(.horizontal)
                        ForEach(bfsiStore.applePayHistory.prefix(10)) { record in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color.black.opacity(0.08)).frame(width: 40, height: 40)
                                    Image(systemName: "apple.logo").foregroundStyle(.primary)
                                        .accessibilityHidden(true)
                                }
                                VStack(alignment: .leading, spacing: 2) {                                    Text(record.merchant).font(.subheadline.bold())
                                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("-" + record.amount.formatted(.currency(code: "USD")))
                                        .font(.subheadline.bold()).foregroundStyle(.red)
                                    Text(record.status).font(.caption2)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.green.opacity(0.12), in: Capsule())
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal)
                            Divider().padding(.leading, 68)
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.vertical)
        }
        .navigationTitle("Apple Pay")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Payment", isPresented: $showResult) {
            Button("OK") { merchant = ""; amountText = "" }
        } message: {
            Text(resultMessage)
        }
    }
}

// MARK: - Apple Pay button (BFSI)

struct BFSIApplePayButton: UIViewRepresentable {
    let merchant: String
    let amount: Double
    let onResult: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(merchant: merchant, amount: amount, onResult: onResult) }

    func makeUIView(context: Context) -> PKPaymentButton {
        let btn = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        btn.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: UIControl.Event.touchUpInside)
        return btn
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        context.coordinator.merchant = merchant
        context.coordinator.amount = amount
    }

    final class Coordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
        var merchant: String
        var amount: Double
        let onResult: (Bool) -> Void
        init(merchant: String, amount: Double, onResult: @escaping (Bool) -> Void) {
            self.merchant = merchant; self.amount = amount; self.onResult = onResult
        }

        @objc func tapped() {
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant.com.bstack.nexus-demo"
            request.supportedNetworks = [.visa, .masterCard, .amex]
            request.merchantCapabilities = .capability3DS
            request.countryCode = "US"
            request.currencyCode = "USD"
            let rounded = (amount * 100).rounded() / 100
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(label: merchant,
                                     amount: NSDecimalNumber(string: String(format: "%.2f", rounded)))
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
            controller.dismiss { DispatchQueue.main.async { self.onResult(true) } }
        }
    }
}
