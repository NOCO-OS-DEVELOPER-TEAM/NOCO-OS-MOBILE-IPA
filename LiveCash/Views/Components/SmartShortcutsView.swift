import SwiftUI
import UIKit

struct SmartShortcutsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var editingShortcut: QuickShortcut?
    @State private var editMode = false

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Schnellzugriff")
                    .font(LiveCashTheme.headlineFont)
                Spacer()
                Button {
                    editingShortcut = QuickShortcut(merchant: "Neu", amount: 5, isUserDefined: true)
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(LiveCashTheme.accent)
                }
                .buttonStyle(.plain)
                if editMode {
                    Button("Fertig") {
                        withAnimation { editMode = false }
                    }
                    .font(LiveCashTheme.captionFont)
                }
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.shortcuts) { shortcut in
                    shortcutButton(shortcut)
                }
            }
        }
        .sheet(item: $editingShortcut) { shortcut in
            ShortcutEditView(shortcut: shortcut)
        }
    }

    private func shortcutButton(_ shortcut: QuickShortcut) -> some View {
        let color = shortcut.type == .income ? LiveCashTheme.income : LiveCashTheme.expense
        let soft = shortcut.type == .income ? LiveCashTheme.incomeSoft : LiveCashTheme.expenseSoft

        return Button {
            if editMode {
                editingShortcut = shortcut
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.applyShortcut(shortcut)
            }
        } label: {
            VStack(spacing: 6) {
                if shortcut.actionType == .assistant {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(LiveCashTheme.accent)
                } else if shortcut.actionType == .overview {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(LiveCashTheme.accent)
                }
                Text(shortcut.merchant)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                if shortcut.actionType == .book {
                    Text(String(format: "%.0f€", shortcut.amount))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(soft)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(color.opacity(0.25), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation { editMode = true }
                editingShortcut = shortcut
            }
        )
    }
}

struct ShortcutEditView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    @State var shortcut: QuickShortcut
    @State private var amountText: String
    @State private var showMapPicker = false
    @State private var lat: Double?
    @State private var lon: Double?
    @State private var locationLabel = ""

    init(shortcut: QuickShortcut) {
        _shortcut = State(initialValue: shortcut)
        _amountText = State(initialValue: String(format: "%.2f", shortcut.amount))
        _lat = State(initialValue: shortcut.location?.latitude)
        _lon = State(initialValue: shortcut.location?.longitude)
        _locationLabel = State(initialValue: shortcut.location?.label ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shortcut") {
                    TextField("Name", text: $shortcut.merchant)
                    TextField("Betrag", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Typ", selection: $shortcut.type) {
                        Text("Ausgabe").tag(TransactionType.expense)
                        Text("Einnahme").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    Picker("Kategorie", selection: $shortcut.category) {
                        ForEach(FinanceCategory.allCases.filter { cat in
                            shortcut.type == .income ? cat == .income : cat != .income
                        }) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    Picker("Aktion", selection: $shortcut.actionType) {
                        Text("Buchung").tag(ShortcutActionType.book)
                        Text("Assistant").tag(ShortcutActionType.assistant)
                        Text("Übersicht").tag(ShortcutActionType.overview)
                    }
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
            .navigationTitle("Shortcut bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showMapPicker) {
                LocationMapPickerView(latitude: $lat, longitude: $lon, label: $locationLabel)
            }
        }
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        shortcut.amount = abs(amount)
        shortcut.isUserDefined = true
        if shortcut.type == .income { shortcut.category = .income }
        if let lat, let lon {
            shortcut.location = TransactionLocation(latitude: lat, longitude: lon, label: locationLabel)
        } else {
            shortcut.location = nil
        }
        store.updateShortcut(shortcut)
        dismiss()
    }
}
