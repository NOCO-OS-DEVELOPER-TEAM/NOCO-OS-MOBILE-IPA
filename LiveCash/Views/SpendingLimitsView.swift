import SwiftUI

struct SpendingLimitsView: View {
    @EnvironmentObject private var store: FinanceStore
    @State private var dailyText = ""
    @State private var weeklyText = ""
    @State private var monthlyText = ""

    var body: some View {
        Form {
            Section {
                Toggle("Limits aktiv", isOn: Binding(
                    get: { store.spendingLimits.enabled },
                    set: { store.setSpendingLimitsEnabled($0) }
                ))
            }

            Section("Limits") {
                limitField(title: "Tageslimit", text: $dailyText) {
                    store.spendingLimits.dailyLimit = parse(dailyText)
                    store.saveSpendingLimits()
                }
                limitField(title: "Wochenlimit", text: $weeklyText) {
                    store.spendingLimits.weeklyLimit = parse(weeklyText)
                    store.saveSpendingLimits()
                }
                limitField(title: "Monatslimit", text: $monthlyText) {
                    store.spendingLimits.monthlyLimit = parse(monthlyText)
                    store.saveSpendingLimits()
                }
            }

            Section("Benachrichtigungen") {
                Text("Bei 50% deines Limits erhältst du eine Warnung, bei 80% eine starke Warnung. Überschreitungen werden beim Buchen bestätigt.")
                    .font(LiveCashTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ausgaben-Limits")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadFields)
        .onDisappear { saveLimits() }
    }

    private func saveLimits() {
        store.spendingLimits.dailyLimit = parse(dailyText)
        store.spendingLimits.weeklyLimit = parse(weeklyText)
        store.spendingLimits.monthlyLimit = parse(monthlyText)
        store.saveSpendingLimits()
    }

    private func limitField(title: String, text: Binding<String>, onCommit: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .onSubmit(onCommit)
        }
    }

    private func loadFields() {
        dailyText = store.spendingLimits.dailyLimit.map { String(format: "%.0f", $0) } ?? ""
        weeklyText = store.spendingLimits.weeklyLimit.map { String(format: "%.0f", $0) } ?? ""
        monthlyText = store.spendingLimits.monthlyLimit.map { String(format: "%.0f", $0) } ?? ""
    }

    private func parse(_ text: String) -> Double? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        return Double(t.replacingOccurrences(of: ",", with: "."))
    }
}
