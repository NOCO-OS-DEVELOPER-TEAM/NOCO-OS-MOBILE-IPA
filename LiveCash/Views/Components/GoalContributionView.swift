import SwiftUI

struct GoalContributionView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    let prefilledAmount: Double?

    @State private var amountText = ""
    @State private var selectedGoalId: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Betrag") {
                    TextField("Betrag", text: $amountText)
                        .keyboardType(.decimalPad)
                    Text(String(format: "Verfügbar: %.0f€ — wird beim Sparen abgezogen", max(store.availableBalance, 0)))
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }

                Section("Sparziel") {
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
            }
            .navigationTitle("Zum Sparziel hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let prefilledAmount {
                    amountText = String(format: "%.2f", prefilledAmount)
                }
                selectedGoalId = store.goals.first?.id
            }
        }
    }

    private var canSave: Bool {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return false }
        return !store.goals.isEmpty && amount <= max(store.availableBalance, 0)
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")),
              let id = selectedGoalId ?? store.goals.first?.id else { return }
        store.contributeToGoal(id: id, amount: amount)
        HapticService.success(store: store)
        dismiss()
    }
}
