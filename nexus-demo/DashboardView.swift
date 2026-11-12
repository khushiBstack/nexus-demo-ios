import SwiftUI

struct DashboardView: View {
    @State private var showATM = false
    @State private var showAlerts = false
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var bfsiStore: BFSIStore
    @EnvironmentObject var geo: IPGeoManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Welcome banner
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                        Text(initials(for: session.userName)).font(.subheadline.bold()).foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome back,").font(.subheadline).foregroundStyle(.secondary)
                        Text(session.userName.isEmpty ? "User" : session.userName).font(.title3.weight(.semibold))
                        if let place = geo.bestCity ?? geo.country {
                            Label(place, systemImage: "network").font(.caption2).foregroundStyle(.indigo)
                        }
                    }
                    Spacer()
                    NetworkSpeedWidget()
                }
                .padding(.vertical, 4)
                .listRowSeparator(.hidden)
            }

            // Network status row
            if !bfsiStore.isOnline {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "wifi.slash").foregroundStyle(.red).accessibilityHidden(true)
                        Text("You are offline. Some features may be unavailable.").font(.caption).foregroundStyle(.red)
                    }
                }
            }

            // ATMs Near Me
            Section {
                Button { showATM = true } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.green.opacity(0.12)).frame(width: 40, height: 40)
                            Image(systemName: "banknote.fill").foregroundColor(.green).accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ATMs Near Me").font(.headline)
                            Text("Find cash machines close to you").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Find ATMs near me")
            }

            // Accounts
            Section("Accounts") {
                ForEach(bfsiStore.accounts) { account in
                    NavigationLink(destination: account.type == .investment ? AnyView(BFSIInvestmentView()) : AnyView(AccountDetailView(account: account))) {
                        AccountRow(account: account)
                    }
                }
            }

            // Recent Activity
            Section("Recent Activity") {
                ForEach(bfsiStore.transactions.prefix(5)) { tx in
                    TransactionRow(transaction: tx)
                }
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left.square.fill")
                        .font(.title3)
                        .foregroundStyle(.indigo)
                }
                .accessibilityLabel("Back to domains")
            }
        }
        .onAppear { geo.fetchIfNeeded() }
        .sheet(isPresented: $showAlerts) {
            NavigationStack {
                PushNotificationDemoView(
                    domainTitle: "DemoBank",
                    domainTint: .indigo,
                    domainIcon: "bell.badge.fill"
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAlerts = true } label: {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.indigo)
                }
                .accessibilityLabel("Notifications")
            }
        }
        .sheet(isPresented: $showATM) {
            NavigationStack { BFSIATMView() }
        }
        .refreshable {}
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1)) + String(parts[1].prefix(1)) }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Account row

struct AccountRow: View {
    let account: BFSIAccount
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(accountColor(account.color).opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: account.icon).foregroundColor(accountColor(account.color)).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name).font(.headline)
                Text(account.maskedNumber).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(account.formattedBalance).font(.headline).foregroundStyle(account.balance < 0 ? .red : .primary)
        }
        .padding(.vertical, 4)
    }
    private func accountColor(_ name: String) -> Color {
        switch name {
        case "indigo": return .indigo
        case "green": return .green
        case "red": return .red
        case "purple": return .purple
        default: return .indigo
        }
    }
}

// MARK: - Transaction row

struct TransactionRow: View {
    let transaction: BFSITransaction
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(transaction.isCredit ? Color.green.opacity(0.12) : Color.secondary.opacity(0.10)).frame(width: 36, height: 36)
                Image(systemName: transaction.icon).foregroundStyle(transaction.isCredit ? .green : .secondary).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title).font(.subheadline)
                Text(transaction.date, style: .date).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text((transaction.isCredit ? "+" : "-") + transaction.amount.formatted(.currency(code: "USD")))
                .font(.subheadline.weight(.medium)).foregroundStyle(transaction.isCredit ? .green : .primary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Account detail

struct AccountDetailView: View {
    let account: BFSIAccount
    @EnvironmentObject var bfsiStore: BFSIStore
    @State private var showStatementPicker = false
    @State private var showTransfer = false
    @State private var showApplePay = false
    @State private var showATM = false
    @State private var showAlerts = false
    @State private var statementStart = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var statementEnd = Date()
    @State private var showShareSheet = false
    @State private var statementURL: URL?

    private var accountTransactions: [BFSITransaction] { bfsiStore.transactions.filter { $0.accountId == account.id } }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(account.name).font(.headline).foregroundStyle(.secondary)
                    Text(account.formattedBalance).font(.system(size: 44, weight: .bold)).foregroundStyle(account.balance < 0 ? .red : .primary)
                    Text("Account " + account.maskedNumber).font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(28)
                .background(LinearGradient(colors: [.indigo.opacity(0.12), .blue.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                HStack(spacing: 16) {
                    AccountActionButton(title: "Transfer", icon: "arrow.left.arrow.right", color: .indigo) { showTransfer = true }
                    AccountActionButton(title: "Pay", icon: "apple.logo", color: .black) { showApplePay = true }
                    AccountActionButton(title: "Statement", icon: "doc.text", color: .orange) { showStatementPicker = true }
                }.padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Transaction History").font(.headline).padding(.horizontal)
                    if accountTransactions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray").font(.system(size: 40)).foregroundStyle(.secondary).accessibilityHidden(true)
                            Text("No transactions").foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity).padding(.top, 20)
                    } else {
                        ForEach(accountTransactions) { tx in TransactionRow(transaction: tx).padding(.horizontal); Divider().padding(.leading, 60) }
                    }
                }
            }.padding(.vertical)
        }
        .navigationTitle(account.name).navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showStatementPicker) {
            StatementPickerSheet(accountName: account.name, startDate: $statementStart, endDate: $statementEnd) {
                statementURL = bfsiStore.generateStatement(for: account.id, from: statementStart, to: statementEnd)
                showStatementPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showShareSheet = statementURL != nil }
            }
        }
        .sheet(isPresented: $showATM) { NavigationStack { BFSIATMView() } }
        .sheet(isPresented: $showTransfer) { NavigationStack { TransferView().environmentObject(bfsiStore) } }
        .sheet(isPresented: $showApplePay) { NavigationStack { BFSIApplePayView().environmentObject(bfsiStore) } }
        .sheet(isPresented: $showShareSheet) { if let url = statementURL { ShareSheetBFSI(items: [url]) } }
    }
}

struct StatementPickerSheet: View {
    let accountName: String; @Binding var startDate: Date; @Binding var endDate: Date; let onDownload: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Statement Period") {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Section { Button("Download Statement (PDF)") { onDownload() }.foregroundColor(.indigo) }
            }
            .navigationTitle("Download Statement").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

private struct AccountActionButton: View {
    let title: String; let icon: String; let color: Color; var action: (() -> Void)? = nil
    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 8) {
                ZStack { Circle().fill(color.opacity(0.12)).frame(width: 52, height: 52); Image(systemName: icon).font(.title3).foregroundStyle(color).accessibilityHidden(true) }
                Text(title).font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain).accessibilityLabel(title)
    }
}

struct ShareSheetBFSI: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Account: Hashable {
    static func == (lhs: Account, rhs: Account) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(SessionStore())
            .environmentObject(BFSIStore())
            .environmentObject(IPGeoManager.shared)
    }
}
