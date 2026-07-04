import SwiftUI
import UIKit

struct TransactionsListView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showReceiptScan = false
    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            Group {
                if store.transactions.isEmpty {
                    ContentUnavailableView(
                        "Keine Buchungen",
                        systemImage: "tray",
                        description: Text("Tippe + für eine neue Buchung oder nutze die Eingabe auf dem Start-Tab.")
                    )
                } else {
                    List {
                        ForEach(store.transactions) { tx in
                            NavigationLink {
                                TransactionDetailView(transactionID: tx.id)
                            } label: {
                                TransactionRow(transaction: tx)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    store.deleteTransaction(tx)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Buchungen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showAddTransaction = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(LiveCashTheme.accent)
                        }
                        Button {
                            showReceiptScan = true
                        } label: {
                            Image(systemName: "camera")
                        }
                    }
                }
            }
            .sheet(isPresented: $showReceiptScan) {
                ReceiptScanView()
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }
}
