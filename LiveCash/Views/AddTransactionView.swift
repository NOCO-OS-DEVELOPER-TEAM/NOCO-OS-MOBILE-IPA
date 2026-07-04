import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State private var merchant = ""
    @State private var amountText = ""
    @State private var type: TransactionType = .expense
    @State private var category: FinanceCategory = .other
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Buchung") {
                    TextField("Name / Händler", text: $merchant)
                    TextField("Betrag", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Typ", selection: $type) {
                        Text("Ausgabe").tag(TransactionType.expense)
                        Text("Einnahme").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    if type == .expense {
                        Picker("Kategorie", selection: $category) {
                            ForEach(FinanceCategory.allCases.filter { $0 != .income }) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                    }
                    DatePicker("Datum", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Neue Buchung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !merchant.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amountText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        let tx = Transaction(
            amount: abs(amount),
            type: type,
            category: type == .income ? .income : category,
            merchant: merchant.trimmingCharacters(in: .whitespaces),
            date: date
        )
        store.addTransaction(tx)
        store.lastFeedback = tx.formattedAmount + " · \(tx.merchant)"
        dismiss()
    }
}
