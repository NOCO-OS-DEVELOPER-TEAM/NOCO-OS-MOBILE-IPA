import SwiftUI

struct SubscriptionsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var showAdd = false
    @State private var editingSubscription: Subscription?

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
                    Button {
                        editingSubscription = sub
                    } label: {
                        LiveCashCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(sub.name)
                                            .font(LiveCashTheme.headlineFont)
                                            .foregroundStyle(.primary)
                                        if sub.detectedFromTransactions {
                                            Image(systemName: "sparkles")
                                                .font(.caption)
                                                .foregroundStyle(LiveCashTheme.accent)
                                        }
                                    }
                                    Text("\(sub.billingPeriodLabel) · \(sub.category.rawValue)")
                                        .font(LiveCashTheme.captionFont)
                                        .foregroundStyle(.secondary)
                                    if sub.daysUntilRenewal <= 14 {
                                        Text("Erneuert in \(sub.daysUntilRenewal) Tag\(sub.daysUntilRenewal == 1 ? "" : "en")")
                                            .font(LiveCashTheme.captionFont)
                                            .foregroundStyle(LiveCashTheme.accent)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(String(format: "%.2f€", sub.amount))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Text(String(format: "%.2f€/Monat", sub.monthlyCost))
                                        .font(LiveCashTheme.captionFont)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
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
        .sheet(isPresented: $showAdd) {
            SubscriptionFormSheet(subscription: nil) { sub in
                store.addSubscription(
                    name: sub.name,
                    amount: sub.amount,
                    frequency: sub.frequency,
                    startDate: sub.startDate,
                    billingPeriodDays: sub.billingPeriodDays,
                    category: sub.category
                )
            }
        }
        .sheet(item: $editingSubscription) { sub in
            SubscriptionFormSheet(subscription: sub) { updated in
                store.updateSubscription(updated)
            }
        }
    }
}

private struct SubscriptionFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription?
    let onSave: (Subscription) -> Void

    @State private var name: String
    @State private var amount: String
    @State private var billingDays: Int
    @State private var startDate: Date
    @State private var category: FinanceCategory

    private let billingOptions = [7, 30, 365]

    init(subscription: Subscription?, onSave: @escaping (Subscription) -> Void) {
        self.subscription = subscription
        self.onSave = onSave
        _name = State(initialValue: subscription?.name ?? "")
        _amount = State(initialValue: subscription.map { String(format: "%.2f", $0.amount) } ?? "")
        _billingDays = State(initialValue: subscription?.billingPeriodDays ?? 30)
        _startDate = State(initialValue: subscription?.startDate ?? Date())
        _category = State(initialValue: subscription?.category ?? .subscription)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Abo") {
                    TextField("Name", text: $name)
                    TextField("Betrag pro Periode", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section("Abrechnung") {
                    Picker("Zeitraum", selection: $billingDays) {
                        Text("7 Tage").tag(7)
                        Text("30 Tage").tag(30)
                        Text("365 Tage").tag(365)
                    }
                    DatePicker("Startdatum", selection: $startDate, displayedComponents: .date)
                }
                Section("Kategorie") {
                    Picker("Kategorie", selection: $category) {
                        ForEach(FinanceCategory.allCases.filter { $0 != .income }) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle(subscription == nil ? "Abo hinzufügen" : "Abo bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || parsedAmount == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var parsedAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: "."))
    }

    private func save() {
        guard let value = parsedAmount, !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let frequency: SubscriptionFrequency = switch billingDays {
        case 7: .weekly
        case 365: .yearly
        default: .monthly
        }
        if var existing = subscription {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.amount = value
            existing.frequency = frequency
            existing.startDate = startDate
            existing.billingPeriodDays = billingDays
            existing.category = category
            onSave(existing)
        } else {
            onSave(Subscription(
                name: name.trimmingCharacters(in: .whitespaces),
                amount: value,
                frequency: frequency,
                detectedFromTransactions: false,
                startDate: startDate,
                billingPeriodDays: billingDays,
                category: category
            ))
        }
        dismiss()
    }
}
