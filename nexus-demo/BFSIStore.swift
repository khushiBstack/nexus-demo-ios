import UIKit
import Foundation
import Combine
import Network

// MARK: - BFSI Models

struct BFSIAccount: Identifiable {
    let id = UUID()
    let name: String
    let number: String
    var balance: Double
    let type: AccountType
    let currency: String = "USD"

    enum AccountType { case checking, savings, credit, investment }

    var maskedNumber: String { "xxxx " + number.suffix(4) }
    var formattedBalance: String { balance.formatted(.currency(code: currency)) }
    var icon: String {
        switch type {
        case .checking:   return "creditcard.fill"
        case .savings:    return "banknote.fill"
        case .credit:     return "creditcard.and.123"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }
    var color: String {
        switch type {
        case .checking:   return "indigo"
        case .savings:    return "green"
        case .credit:     return "red"
        case .investment: return "purple"
        }
    }
}

struct BFSITransaction: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let date: Date
    let amount: Double
    let isCredit: Bool
    let accountId: UUID
    var icon: String {
        switch category {
        case "Food":       return "fork.knife"
        case "Salary":     return "briefcase.fill"
        case "Utilities":  return "bolt.fill"
        case "Transfer":   return "arrow.left.arrow.right"
        case "Shopping":   return "bag.fill"
        case "Apple Pay":  return "apple.logo"
        default:           return "dollarsign.circle.fill"
        }
    }
}

struct ApplePayRecord: Identifiable {
    let id = UUID()
    let merchant: String
    let amount: Double
    let date: Date
    let status: String
}

// MARK: - BFSI Store

final class BFSIStore: ObservableObject {
    @Published var accounts: [BFSIAccount] = []
    @Published var transactions: [BFSITransaction] = []
    @Published var applePayHistory: [ApplePayRecord] = []
    @Published var isOnline: Bool = true
    @Published var networkStatusMessage: String? = nil

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "bfsi.network")
    private var wasOffline = false

    init() {
        setupAccounts()
        setupTransactions()
        startNetworkMonitor()
    }

    private func setupAccounts() {
        let seed = Double.random(in: 3000...8000)
        accounts = [
            BFSIAccount(name: "Everyday Checking", number: "4821 3390",
                        balance: (seed * 100).rounded() / 100, type: .checking),
            BFSIAccount(name: "Savings", number: "9012 7745",
                        balance: ((seed * 4.2) * 100).rounded() / 100, type: .savings),
            BFSIAccount(name: "Credit Card", number: "5566 1123",
                        balance: -((seed * 0.1) * 100).rounded() / 100, type: .credit),
            BFSIAccount(name: "Investment", number: "7734 8821",
                        balance: ((seed * 8.5) * 100).rounded() / 100, type: .investment)
        ]
    }

    private func setupTransactions() {
        guard let checkingId = accounts.first(where: { $0.type == .checking })?.id else { return }
        transactions = [
            BFSITransaction(title: "Payroll Deposit", category: "Salary",
                            date: .now.addingTimeInterval(-86400 * 2), amount: 2400.00, isCredit: true, accountId: checkingId),
            BFSITransaction(title: "Whole Foods Market", category: "Food",
                            date: .now.addingTimeInterval(-86400), amount: 62.14, isCredit: false, accountId: checkingId),
            BFSITransaction(title: "Electric Bill", category: "Utilities",
                            date: .now.addingTimeInterval(-86400 * 3), amount: 88.20, isCredit: false, accountId: checkingId),
            BFSITransaction(title: "Amazon Purchase", category: "Shopping",
                            date: .now.addingTimeInterval(-86400 * 4), amount: 134.99, isCredit: false, accountId: checkingId),
            BFSITransaction(title: "Transfer from Savings", category: "Transfer",
                            date: .now.addingTimeInterval(-86400 * 5), amount: 300.00, isCredit: true, accountId: checkingId)
        ]
    }

    // MARK: - Transfer

    func transfer(fromAccountId: UUID, toRecipient: String, amount: Double, note: String) -> Bool {
        guard let idx = accounts.firstIndex(where: { $0.id == fromAccountId }),
              accounts[idx].balance >= amount else { return false }
        accounts[idx].balance = ((accounts[idx].balance - amount) * 100).rounded() / 100
        let tx = BFSITransaction(title: "Transfer to \(toRecipient)", category: "Transfer",
                                 date: Date(), amount: amount, isCredit: false, accountId: fromAccountId)
        transactions.insert(tx, at: 0)
        return true
    }

    // MARK: - Apple Pay

    func recordApplePay(merchant: String, amount: Double, accountId: UUID) {
        guard let idx = accounts.firstIndex(where: { $0.id == accountId }) else { return }
        accounts[idx].balance = ((accounts[idx].balance - amount) * 100).rounded() / 100
        let tx = BFSITransaction(title: "Apple Pay - \(merchant)", category: "Apple Pay",
                                 date: Date(), amount: amount, isCredit: false, accountId: accountId)
        transactions.insert(tx, at: 0)
        let record = ApplePayRecord(merchant: merchant, amount: amount, date: Date(), status: "Completed")
        applePayHistory.insert(record, at: 0)
    }

    // MARK: - Network monitor

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let online = path.status == .satisfied
                if !online && self.isOnline {
                    self.networkStatusMessage = "You are offline. Some features may be unavailable."
                } else if online && !self.isOnline {
                    self.networkStatusMessage = "Back online!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.networkStatusMessage = nil
                    }
                }
                self.isOnline = online
                self.wasOffline = !online
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Statement PDF

    func generateStatement(for accountId: UUID, from startDate: Date, to endDate: Date) -> URL? {
        guard let account = accounts.first(where: { $0.id == accountId }) else { return nil }
        let txs = transactions.filter { $0.accountId == accountId && $0.date >= startDate && $0.date <= endDate }
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            let bold: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14)]
            var y: CGFloat = 40
            func draw(_ text: String, x: CGFloat = 40, isBold: Bool = false) {
                text.draw(at: CGPoint(x: x, y: y), withAttributes: isBold ? bold : attrs)
                y += 20
            }
            draw("DemoBank — Account Statement", isBold: true)
            draw("Account: \(account.name) (\(account.maskedNumber))")
            draw("Period: \(startDate.formatted(date: .abbreviated, time: .omitted)) – \(endDate.formatted(date: .abbreviated, time: .omitted))")
            draw("Current Balance: \(account.formattedBalance)")
            y += 10
            draw("────────────────────────────────────────────")
            draw("Date", x: 40, isBold: true)
            draw("Description", x: 120, isBold: true)
            draw("Amount", x: 450, isBold: true)
            y -= 20
            "Date".draw(at: CGPoint(x: 40, y: y), withAttributes: bold)
            "Description".draw(at: CGPoint(x: 120, y: y), withAttributes: bold)
            "Amount".draw(at: CGPoint(x: 450, y: y), withAttributes: bold)
            y += 20
            draw("────────────────────────────────────────────")
            for tx in txs {
                let dateStr = tx.date.formatted(date: .abbreviated, time: .omitted)
                let amtStr = (tx.isCredit ? "+" : "-") + tx.amount.formatted(.currency(code: "USD"))
                dateStr.draw(at: CGPoint(x: 40, y: y), withAttributes: attrs)
                tx.title.draw(at: CGPoint(x: 120, y: y), withAttributes: attrs)
                amtStr.draw(at: CGPoint(x: 450, y: y), withAttributes: attrs)
                y += 20
                if y > 800 { ctx.beginPage(); y = 40 }
            }
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Statement_\(account.name.replacingOccurrences(of: " ", with: "_")).pdf")
        try? data.write(to: url)
        return url
    }
}
