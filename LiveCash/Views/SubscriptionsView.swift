import SwiftUI

struct SubscriptionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var name = ""
    @State private var amount = ""

    var body: some View {
        List {
            if store.subscriptions.isEmpty {
                ContentUnavailableView(
                    "Keine Abos",
                    systemImage: "repeat.circle",
                    description: Text("Abos werden automatisch aus wiederkehrenden Buchungen erkannt.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    LiveCashCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Gesamtkosten")
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f€ / Monat · %.2f€ / Jahr", store.monthlySubscriptionCost, store.monthlySubscriptionCost * 12))
                                .font(LiveCashTheme.headlineFont)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                ForEach(store.subscriptions) { sub in
                    LiveCashCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(sub.name)
                                        .font(LiveCashTheme.headlineFont)
                                    if sub.detectedFromTransactions {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                            .foregroundStyle(LiveCashTheme.accent)
                                    }
                                }
                                Text(sub.frequency.rawValue)
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "%.2f€", sub.amount))
                                    .fontWeight(.semibold)
                                Text(String(format: "%.2f€/Jahr", sub.yearlyCost))
                                    .font(LiveCashTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                .onDelete { idx in
                    idx.forEach { store.deleteSubscription(store.subscriptions[$0]) }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(LiveCashTheme.screenBackground)
        .navigationTitle("Abonnements")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Aktualisieren") { store.refreshSubscriptions() }
                    Button("Manuell hinzufügen") { showAdd = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Abo hinzufügen", isPresented: $showAdd) {
            TextField("Name", text: $name)
            TextField("Betrag", text: $amount)
                .keyboardType(.decimalPad)
            Button("Abbrechen", role: .cancel) { resetForm() }
            Button("Speichern (monatlich)") {
                if let a = Double(amount.replacingOccurrences(of: ",", with: ".")), !name.isEmpty {
                    store.addSubscription(name: name, amount: a, frequency: .monthly)
                }
                resetForm()
            }
        } message: {
            Text("Monatlicher Betrag eingeben.")
        }
    }

    private func resetForm() {
        name = ""
        amount = ""
    }
}
