import SwiftUI

private enum AddEntryMode: String, CaseIterable, Identifiable {
    case expense = "Ausgabe"
    case income = "Einnahme"
    case goal = "Sparziel"

    var id: String { rawValue }
}

struct AddTransactionView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State private var entryMode: AddEntryMode = .expense
    @State private var merchant = ""
    @State private var amountText = ""
    @State private var type: TransactionType = .expense
    @State private var category: FinanceCategory = .other
    @State private var date = Date()
    @State private var lat: Double?
    @State private var lon: Double?
    @State private var locationLabel = ""
    @State private var showMapPicker = false
    @State private var selectedGoalId: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Art") {
                    Picker("Eintrag", selection: $entryMode) {
                        ForEach(AddEntryMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: entryMode) { _, mode in
                        type = mode == .income ? .income : .expense
                    }
                }

                if entryMode == .goal {
                    Section("Sparziel") {
                        TextField("Betrag", text: $amountText)
                            .keyboardType(.decimalPad)
                        if store.goals.isEmpty {
                            Text("Lege zuerst ein Sparziel an.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Ziel", selection: Binding(
                                get: { selectedGoalId ?? store.goals.first?.id },
                                set: { selectedGoalId = $0 }
                            )) {
                                ForEach(store.goals) { goal in
                                    Text("\(goal.name) (\(goal.progressPercent)%)").tag(Optional(goal.id))
                                }
                            }
                        }
                    }
                } else {
                    Section("Buchung") {
                        TextField("Name / Händler", text: $merchant)
                        TextField("Betrag", text: $amountText)
                            .keyboardType(.decimalPad)
                        if entryMode == .expense {
                            Picker("Kategorie", selection: $category) {
                                ForEach(FinanceCategory.allCases.filter { $0 != .income }) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                        }
                        DatePicker("Datum", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    }

                    Section("Standort") {
                        Button("Auf Karte wählen") { showMapPicker = true }
                        if lat != nil {
                            Text(locationLabel.isEmpty ? "Standort gesetzt" : locationLabel)
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(entryMode == .goal ? "Sparziel" : "Neue Buchung")
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
            .sheet(isPresented: $showMapPicker) {
                LocationMapPickerView(latitude: $lat, longitude: $lon, label: $locationLabel)
            }
            .onAppear {
                selectedGoalId = store.goals.first?.id
            }
        }
    }

    private var canSave: Bool {
        guard Double(amountText.replacingOccurrences(of: ",", with: ".")) != nil else { return false }
        if entryMode == .goal {
            return !store.goals.isEmpty
        }
        return !merchant.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return }

        if entryMode == .goal {
            guard let id = selectedGoalId ?? store.goals.first?.id else { return }
            store.contributeToGoal(id: id, amount: abs(amount))
            HapticService.success(store: store)
            dismiss()
            return
        }

        var location: TransactionLocation?
        if let lat, let lon {
            location = TransactionLocation(latitude: lat, longitude: lon, label: locationLabel.isEmpty ? nil : locationLabel)
        }
        let resolvedType: TransactionType = entryMode == .income ? .income : .expense
        let draft = ParsedTransactionDraft(
            amount: abs(amount),
            type: resolvedType,
            merchant: merchant.trimmingCharacters(in: .whitespaces),
            category: resolvedType == .income ? .income : category,
            date: date
        )
        if resolvedType == .expense, let message = store.spendLimitExceededMessage(adding: abs(amount)) {
            store.pendingSpendLimit = PendingSpendLimit(draft: draft, rawInput: nil, message: message)
            dismiss()
            return
        }
        let tx = Transaction(
            amount: abs(amount),
            type: resolvedType,
            category: resolvedType == .income ? .income : category,
            merchant: merchant.trimmingCharacters(in: .whitespaces),
            date: date,
            location: location,
            accountId: store.activeAccountId
        )
        store.addTransaction(tx)
        store.lastFeedback = tx.formattedAmount + " · \(tx.merchant)"
        dismiss()
    }
}
