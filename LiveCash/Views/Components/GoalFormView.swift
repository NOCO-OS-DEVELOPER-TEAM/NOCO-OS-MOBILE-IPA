import SwiftUI

struct GoalFormView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    var editingGoal: SavingsGoal?

    @State private var name = ""
    @State private var targetText = ""
    @State private var hasDeadline = false
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var notifySlow = true
    @State private var notifyFast = false
    @State private var notifyAt50 = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Sparziel") {
                    TextField("Name", text: $name)
                    TextField("Zielbetrag", text: $targetText)
                        .keyboardType(.decimalPad)
                }

                Section("Zeitziel") {
                    Toggle("Zieldatum setzen", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Erreicht bis", selection: $targetDate, in: Date()..., displayedComponents: .date)
                    }
                }

                Section("Smart Tracking") {
                    Toggle("Bei 50% benachrichtigen", isOn: $notifyAt50)
                    Toggle("Warnung bei langsamem Tempo", isOn: $notifySlow)
                    Toggle("Info bei schnellem Tempo", isOn: $notifyFast)
                }

                if hasDeadline, let target = Double(targetText.replacingOccurrences(of: ",", with: ".")) {
                    let preview = SavingsGoal(
                        name: name.isEmpty ? "Ziel" : name,
                        targetAmount: target,
                        targetDate: targetDate
                    )
                    Section("Prognose") {
                        if let pace = preview.requiredDailyPace {
                            LabeledContent("Nötiges Tages-Tempo", value: String(format: "%.2f€", pace))
                        }
                        LabeledContent("Status", value: preview.paceStatus(referenceMonthlySavings: store.monthlySavingsRate).rawValue)
                    }
                }
            }
            .navigationTitle(editingGoal == nil ? "Neues Sparziel" : "Sparziel bearbeiten")
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
            .onAppear(perform: loadEditing)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(targetText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func loadEditing() {
        guard let goal = editingGoal else { return }
        name = goal.name
        targetText = String(format: "%.0f", goal.targetAmount)
        hasDeadline = goal.targetDate != nil
        targetDate = goal.targetDate ?? targetDate
        notifySlow = goal.notifySlowProgress
        notifyFast = goal.notifyFastProgress
        notifyAt50 = goal.notifyAt50Percent
    }

    private func save() {
        guard let target = Double(targetText.replacingOccurrences(of: ",", with: ".")) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if var existing = editingGoal {
            existing.name = trimmed
            existing.targetAmount = target
            existing.targetDate = hasDeadline ? targetDate : nil
            existing.notifySlowProgress = notifySlow
            existing.notifyFastProgress = notifyFast
            existing.notifyAt50Percent = notifyAt50
            store.updateGoal(existing)
        } else {
            store.addGoal(
                name: trimmed,
                target: target,
                targetDate: hasDeadline ? targetDate : nil,
                notifySlowProgress: notifySlow,
                notifyFastProgress: notifyFast,
                notifyAt50Percent: notifyAt50
            )
        }
        dismiss()
    }
}
