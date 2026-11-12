import SwiftUI
import Charts

// MARK: - Investment View

struct Holding: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let shares: Double
    let price: Double
    let change: Double
    var value: Double { shares * price }
    var changePercent: Double { change / (price - change) * 100 }
}

enum InvestmentSampleData {
    static let holdings: [Holding] = [
        Holding(symbol: "AAPL", name: "Apple Inc.", shares: 10, price: 182.50, change: 1.25),
        Holding(symbol: "MSFT", name: "Microsoft Corp.", shares: 5, price: 378.90, change: -2.10),
        Holding(symbol: "GOOGL", name: "Alphabet Inc.", shares: 3, price: 141.80, change: 0.95),
        Holding(symbol: "AMZN", name: "Amazon.com Inc.", shares: 8, price: 178.25, change: 3.40),
        Holding(symbol: "NVDA", name: "NVIDIA Corp.", shares: 4, price: 495.00, change: 12.50)
    ]
}

struct BFSIInvestmentView: View {
    let holdings = InvestmentSampleData.holdings

    private var totalValue: Double { holdings.reduce(0) { $0 + $1.value } }
    private var totalChange: Double { holdings.reduce(0) { $0 + $1.change * $1.shares } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Portfolio summary card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Portfolio Value")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(totalValue, format: .currency(code: "USD"))
                        .font(.largeTitle.bold())
                    HStack(spacing: 6) {
                        Image(systemName: totalChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .accessibilityHidden(true)
                        Text(abs(totalChange), format: .currency(code: "USD"))
                        Text("today")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(totalChange >= 0 ? .green : .red)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.indigo.opacity(0.15), .blue.opacity(0.08)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Portfolio value: " + totalValue.formatted(.currency(code: "USD")))

                // Allocation bar chart (iOS 16 safe — BarMark)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Allocation").font(.headline).padding(.horizontal)
                    Chart(holdings) { h in
                        BarMark(
                            x: .value("Symbol", h.symbol),
                            y: .value("Value", h.value)
                        )
                        .foregroundStyle(by: .value("Symbol", h.symbol))
                        .cornerRadius(4)
                    }
                    .frame(height: 180)
                    .padding(.horizontal)
                }

                // Holdings list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Holdings").font(.headline).padding(.horizontal)
                    ForEach(holdings) { holding in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.indigo.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Text(holding.symbol.prefix(2))
                                    .font(.caption.bold())
                                    .foregroundStyle(.indigo)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(holding.symbol)
                                    .font(.subheadline.weight(.semibold))
                                Text(holding.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(holding.shares, specifier: "%.0f") shares")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(holding.value, format: .currency(code: "USD"))
                                    .font(.subheadline.weight(.semibold))
                                HStack(spacing: 2) {
                                    Image(systemName: holding.change >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.caption2)
                                        .accessibilityHidden(true)
                                    Text(abs(holding.changePercent), format: .percent.precision(.fractionLength(2)))
                                        .font(.caption2)
                                }
                                .foregroundStyle(holding.change >= 0 ? .green : .red)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(holding.name + ", " + holding.value.formatted(.currency(code: "USD")))
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Investments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { BFSIInvestmentView() }
}
