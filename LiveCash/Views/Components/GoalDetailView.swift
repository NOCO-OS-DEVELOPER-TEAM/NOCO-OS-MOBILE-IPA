import SwiftUI

struct GoalDetailView: View {
    @EnvironmentObject private var store: FinanceStore
    @Environment(\.dismiss) private var dismiss

    let goal: SavingsGoal

    private var pace: GoalPaceStatus {
        goal.paceStatus(referenceMonthlySavings: store.monthlySavingsRate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    LiveCashCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(goal.name)
                                    .font(LiveCashTheme.titleFont)
                                Spacer()
                                Text("\(goal.progressPercent)%")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundStyle(goal.isCompleted ? LiveCashTheme.income : LiveCashTheme.accent)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(LiveCashTheme.incomeSoft)
                                    Capsule()
                                        .fill(goal.isCompleted ? LiveCashTheme.income : LiveCashTheme.accent)
                                        .frame(width: geo.size.width * goal.progress)
                                }
                            }
                            .frame(height: 12)

                            HStack {
                                statBlock(title: "Gespart", value: String(format: "%.0f€", goal.currentAmount), color: LiveCashTheme.income)
                                Spacer()
                                statBlock(title: "Ziel", value: String(format: "%.0f€", goal.targetAmount), color: .primary)
                                Spacer()
                                statBlock(title: "Übrig", value: String(format: "%.0f€", goal.remaining), color: .secondary)
                            }
                        }
                    }

                    LiveCashCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Status")
                                .font(LiveCashTheme.headlineFont)

                            if let days = goal.daysRemaining, goal.goalTimeTrackingEnabled {
                                LabeledContent("Verbleibende Zeit", value: "\(days) Tag\(days == 1 ? "" : "e")")
                            }
                            if let targetDate = goal.targetDate {
                                LabeledContent("Zieldatum", value: targetDate.formatted(date: .long, time: .omitted))
                            }
                            if let required = goal.requiredDailyPace, goal.goalTimeTrackingEnabled {
                                LabeledContent("Nötiges Tages-Tempo", value: String(format: "%.2f€", required))
                            }
                            if let actual = goal.actualDailyPace {
                                LabeledContent("Aktuelles Tages-Tempo", value: String(format: "%.2f€", actual))
                            }
                            if pace != .noDeadline {
                                LabeledContent("Tempo", value: pace.rawValue)
                            }
                            if goal.isCompleted {
                                Label("Ziel erreicht", systemImage: "checkmark.seal.fill")
                                    .font(LiveCashTheme.bodyFont)
                                    .foregroundStyle(LiveCashTheme.income)
                            }
                        }
                    }

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            store.showGoalContributionSheet = true
                        }
                    } label: {
                        Label("Betrag hinzufügen", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LiveCashTheme.income)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(goal.isCompleted)
                }
                .padding(20)
            }
            .background(LiveCashTheme.screenBackground)
            .navigationTitle("Sparziel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }

    private func statBlock(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LiveCashTheme.captionFont)
                .foregroundStyle(.secondary)
            Text(value)
                .font(LiveCashTheme.headlineFont)
                .foregroundStyle(color)
        }
    }
}
