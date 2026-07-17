import SwiftUI

enum GoalTransferMode: String, CaseIterable, Identifiable {
    case deposit = "Hinzufügen"
    case withdraw = "Entnehmen"
    var id: String { rawValue }
}

struct GoalContributionView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    let prefilledAmount: Double?
    var initialMode: GoalTransferMode = .deposit

    @State private var mode: GoalTransferMode = .deposit
    @State private var amountText = ""
    @State private var selectedGoalId: UUID?

    private var selectedGoal: SavingsGoal? {
        let id = selectedGoalId ?? store.goals.first?.id
        return store.goals.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Aktion", selection: $mode) {
                        ForEach(GoalTransferMode.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Betrag") {
                    TextField("Betrag", text: $amountText)
                        .keyboardType(.decimalPad)
                    if mode == .deposit {
                        Text(String(format: "Verfügbar: %.0f€ — wird vom Konto abgezogen", max(store.availableBalance, 0)))
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    } else {
                        let maxWithdraw = selectedGoal?.currentAmount ?? 0
                        Text(String(format: "Im Sparziel: %.0f€ — wird wieder verfügbar", maxWithdraw))
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
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
                                Text("\(goal.name) (\(String(format: "%.0f€", goal.currentAmount)))").tag(Optional(goal.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle(mode == .deposit ? "Geld hinzufügen" : "Geld entnehmen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode == .deposit ? "Hinzufügen" : "Entnehmen") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                mode = initialMode
                if let prefilledAmount {
                    amountText = String(format: "%.2f", prefilledAmount)
                }
                selectedGoalId = store.goals.first?.id
            }
        }
    }

    private var canSave: Bool {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return false }
        guard !store.goals.isEmpty else { return false }
        if mode == .deposit {
            return amount <= max(store.availableBalance, 0)
        }
        return amount <= (selectedGoal?.currentAmount ?? 0)
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")),
              let id = selectedGoalId ?? store.goals.first?.id else { return }
        if mode == .deposit {
            store.contributeToGoal(id: id, amount: amount)
        } else {
            store.withdrawFromGoal(id: id, amount: amount)
        }
        HapticService.success(store: store)
        dismiss()
    }
}
