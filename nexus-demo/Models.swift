import Foundation

struct Account: Identifiable {
    let id = UUID()
    let name: String
    let number: String
    let balance: Double
    let currency: String = "USD"

    var maskedNumber: String {
        "•••• " + number.suffix(4)
    }

    var formattedBalance: String {
        balance.formatted(.currency(code: currency))
    }
}

struct Transaction: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let amount: Double
    let isCredit: Bool
}

enum SampleData {
    static let accounts: [Account] = [
        Account(name: "Everyday Checking", number: "4821 3390", balance: 4218.63),
        Account(name: "Savings", number: "9012 7745", balance: 18342.10),
        Account(name: "Credit Card", number: "5566 1123", balance: -412.75)
    ]

    static let transactions: [Transaction] = [
        Transaction(title: "Whole Foods Market", date: .now.addingTimeInterval(-86400), amount: 62.14, isCredit: false),
        Transaction(title: "Payroll Deposit", date: .now.addingTimeInterval(-172800), amount: 2400.00, isCredit: true),
        Transaction(title: "Electric Bill", date: .now.addingTimeInterval(-259200), amount: 88.20, isCredit: false),
        Transaction(title: "Transfer from Savings", date: .now.addingTimeInterval(-345600), amount: 300.00, isCredit: true)
    ]
}
