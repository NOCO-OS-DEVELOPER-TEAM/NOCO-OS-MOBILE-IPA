import SwiftUI
import CoreLocation

struct TransactionDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    let transactionID: UUID

    @State private var isEditing = false
    @State private var merchant = ""
    @State private var amountText = ""
    @State private var type: TransactionType = .expense
    @State private var category: FinanceCategory = .other
    @State private var date = Date()
    @State private var locationLabel = ""
    @State private var hasLocation = false
    @State private var editLatitude: Double?
    @State private var editLongitude: Double?
    @State private var showDeleteConfirm = false
    @State private var showMapPicker = false

    private var transaction: Transaction? {
        store.transactions.first { $0.id == transactionID }
    }

    var body: some View {
        Group {
            if transaction != nil {
                formContent
            } else {
                ContentUnavailableView("Buchung nicht gefunden", systemImage: "tray")
            }
        }
        .navigationTitle(isEditing ? "Bearbeiten" : "Buchung")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                } else {
                    Button {
                        loadFromTransaction()
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Abbrechen") {
                        loadFromTransaction()
                        isEditing = false
                    }
                }
            }
        }
        .onAppear { loadFromTransaction() }
        .sheet(isPresented: $showMapPicker) {
            LocationMapPickerView(
                latitude: $editLatitude,
                longitude: $editLongitude,
                label: $locationLabel
            )
        }
        .alert("Buchung löschen?", isPresented: $showDeleteConfirm) {
            Button("Löschen", role: .destructive) {
                if let tx = transaction {
                    store.deleteTransaction(tx)
                    dismiss()
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            Section("Details") {
                if isEditing {
                    TextField("Händler / Name", text: $merchant)
                    TextField("Betrag", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Typ", selection: $type) {
                        Text("Ausgabe").tag(TransactionType.expense)
                        Text("Einnahme").tag(TransactionType.income)
                    }
                    Picker("Kategorie", selection: $category) {
                        ForEach(FinanceCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    DatePicker("Datum", selection: $date, displayedComponents: [.date, .hourAndMinute])
                } else {
                    LabeledContent("Händler", value: merchant)
                    LabeledContent("Betrag", value: formattedAmount)
                    LabeledContent("Typ", value: type == .income ? "Einnahme" : "Ausgabe")
                    LabeledContent("Kategorie", value: category.rawValue)
                    LabeledContent("Datum", value: date.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section("Standort") {
                if isEditing {
                    TextField("Ortsbezeichnung", text: $locationLabel)
                    Toggle("Standort speichern", isOn: $hasLocation)
                    if hasLocation {
                        Button("Auf Karte verschieben") { showMapPicker = true }
                        Button("Aktuellen Standort übernehmen") {
                            let manager = CLLocationManager()
                            manager.requestWhenInUseAuthorization()
                            if let loc = manager.location {
                                editLatitude = loc.coordinate.latitude
                                editLongitude = loc.coordinate.longitude
                                if locationLabel.isEmpty { locationLabel = "Aktueller Standort" }
                                hasLocation = true
                            }
                        }
                    }
                } else {
                    if hasLocation {
                        LabeledContent("Ort", value: locationLabel.isEmpty ? "Gespeichert" : locationLabel)
                    } else {
                        Text("Kein Standort")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let raw = transaction?.rawInput, !raw.isEmpty, !isEditing {
                Section("Eingabe") {
                    Text(raw)
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Buchung löschen", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
    }

    private var formattedAmount: String {
        guard let value = Double(amountText.replacingOccurrences(of: ",", with: ".")) else {
            return amountText
        }
        let prefix = type == .income ? "+" : "-"
        return String(format: "%@%.2f€", prefix, value)
    }

    private func loadFromTransaction() {
        guard let tx = transaction else { return }
        merchant = tx.merchant
        amountText = String(format: "%.2f", tx.amount)
        type = tx.type
        category = tx.category
        date = tx.date
        hasLocation = tx.location != nil
        locationLabel = tx.location?.label ?? ""
        editLatitude = tx.location?.latitude
        editLongitude = tx.location?.longitude
    }

    private func save() {
        guard var tx = transaction,
              let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")),
              !merchant.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        tx.merchant = merchant.trimmingCharacters(in: .whitespaces)
        tx.amount = abs(amount)
        tx.type = type
        tx.category = type == .income ? .income : category
        tx.date = date

        if hasLocation, let lat = editLatitude, let lon = editLongitude {
            tx.location = TransactionLocation(
                latitude: lat,
                longitude: lon,
                label: locationLabel.isEmpty ? "Manuell" : locationLabel
            )
        } else {
            tx.location = nil
        }

        store.updateTransaction(tx)
        isEditing = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
