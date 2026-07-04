import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showReceiptScan = false

    var body: some View {
        NavigationStack {
            Group {
                if store.transactions.isEmpty {
                    ContentUnavailableView(
                        "Keine Buchungen",
                        systemImage: "tray",
                        description: Text("Erfasse Ausgaben über die Eingabe auf dem Start-Tab.")
                    )
                } else {
                    List {
                        ForEach(store.transactions) { tx in
                            TransactionRow(transaction: tx)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Buchungen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showReceiptScan = true
                    } label: {
                        Image(systemName: "camera")
                    }
                }
            }
            .sheet(isPresented: $showReceiptScan) {
                ReceiptScanView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            store.deleteTransaction(store.transactions[index])
        }
    }
}
