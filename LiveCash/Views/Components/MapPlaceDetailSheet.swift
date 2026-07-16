import SwiftUI

/// Place-level aggregate for map pin drill-down.
struct MapPlaceDetail: Identifiable {
    let id: UUID
    let title: String
    let visitCount: Int
    let expenseTotal: Double
    let incomeTotal: Double
    let netTotal: Double
    let lastVisit: Date
    let transactions: [Transaction]
    let dominantType: TransactionType

    var lastVisitLabel: String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastVisit), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        if days == 0 { return "heute" }
        if days == 1 { return "gestern" }
        return "vor \(days) Tagen"
    }
}

struct MapPlaceDetailSheet: View {
    @EnvironmentObject private var store: FinanceStore
    let detail: MapPlaceDetail
    @Environment(\.dismiss) private var dismiss

    private var accent: Color {
        detail.dominantType == .income ? LiveCashTheme.income : LiveCashTheme.expense
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: detail.dominantType == .income ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundStyle(accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(detail.title)
                                    .font(LiveCashTheme.headlineFont)
                                Text("\(detail.visitCount) Besuch\(detail.visitCount == 1 ? "" : "e") · zuletzt \(detail.lastVisitLabel)")
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            placeStat(title: "Ausgaben", value: detail.expenseTotal, color: LiveCashTheme.expense)
                            placeStat(title: "Einnahmen", value: detail.incomeTotal, color: LiveCashTheme.income)
                            placeStat(title: "Netto", value: abs(detail.netTotal), color: detail.netTotal >= 0 ? LiveCashTheme.income : LiveCashTheme.expense)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)
                }

                Section("Buchungen") {
                    ForEach(detail.transactions) { tx in
                        NavigationLink {
                            TransactionDetailView(transactionID: tx.id)
                        } label: {
                            TransactionRow(transaction: tx)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Standort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func placeStat(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            Text(String(format: "%.0f€", value))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
