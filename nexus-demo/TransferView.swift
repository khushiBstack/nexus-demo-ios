import SwiftUI
import Combine

struct TransferView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var bfsiStore: BFSIStore

    @State private var fromAccountId: UUID?
    @State private var toRecipient: String = ""
    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var showConfirmation = false
    @State private var showSuccess = false
    @State private var showError = false

    private var fromAccount: BFSIAccount? {
        bfsiStore.accounts.first(where: { $0.id == fromAccountId })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // From account picker
                VStack(alignment: .leading, spacing: 8) {
                    Label("From Account", systemImage: "creditcard")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)

                    Menu {
                        Button("Select an account") { fromAccountId = nil }
                        ForEach(bfsiStore.accounts.filter { $0.type != .credit }) { account in
                            Button("\(account.name)  \(account.maskedNumber)  \(account.formattedBalance)") {
                                fromAccountId = account.id
                            }
                        }
                    } label: {
                        HStack {
                            if let acc = fromAccount {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acc.name).font(.headline)
                                    Text(acc.maskedNumber + "  ·  " + acc.formattedBalance)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Select an account").foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                // Recipient
                VStack(alignment: .leading, spacing: 8) {
                    Label("To", systemImage: "person")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    TextField("Recipient name or email", text: $toRecipient)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Recipient")
                }

                // Amount
                VStack(alignment: .leading, spacing: 8) {
                    Label("Amount", systemImage: "dollarsign.circle")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    HStack {
                        Text("$").font(.title2.bold()).foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad).font(.title2.bold())
                            .accessibilityLabel("Transfer amount")
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Note
                VStack(alignment: .leading, spacing: 8) {
                    Label("Note (optional)", systemImage: "text.bubble")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    TextField("What's this for?", text: $note)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Transfer note")
                }

                // Summary card
                if canSubmit {
                    VStack(spacing: 6) {
                        HStack {
                            Text("From").foregroundStyle(.secondary)
                            Spacer()
                            Text(fromAccount?.name ?? "").font(.subheadline.weight(.medium))
                        }
                        Divider()
                        HStack {
                            Text("To").foregroundStyle(.secondary)
                            Spacer()
                            Text(toRecipient).font(.subheadline.weight(.medium))
                        }
                        Divider()
                        HStack {
                            Text("Amount").foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(amountText)").font(.subheadline.weight(.medium))
                        }
                    }
                    .font(.subheadline)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Button {
                    showConfirmation = true
                } label: {
                    Text("Review Transfer")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(canSubmit ? Color.indigo : Color.secondary.opacity(0.3),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .disabled(!canSubmit)
            }
            .padding()
            .animation(.easeInOut(duration: 0.2), value: canSubmit)
        }
        .navigationTitle("Transfer Money")
        .alert("Confirm Transfer", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Send") {
                let amount = Double(amountText) ?? 0
                let success = bfsiStore.transfer(
                    fromAccountId: fromAccountId!,
                    toRecipient: toRecipient,
                    amount: amount,
                    note: note
                )
                if success { showSuccess = true; resetForm() }
                else { showError = true }
            }
        } message: {
            Text("Send $\(amountText) from \(fromAccount?.name ?? "") to \(toRecipient)?")
        }
        .alert("Transfer Sent!", isPresented: $showSuccess) {
            Button("Done") {}
        } message: {
            Text("Your transfer has been submitted and your balance has been updated.")
        }
        .alert("Transfer Failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text("Insufficient funds or invalid account. Please check your balance and try again.")
        }
    }

    private var canSubmit: Bool {
        fromAccountId != nil &&
        !toRecipient.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amountText).map { $0 > 0 } ?? false
    }

    private func resetForm() {
        fromAccountId = nil
        toRecipient = ""
        amountText = ""
        note = ""
    }
}

#Preview {
    NavigationStack {
        TransferView()
            .environmentObject(SessionStore())
            .environmentObject(BFSIStore())
    }
}
