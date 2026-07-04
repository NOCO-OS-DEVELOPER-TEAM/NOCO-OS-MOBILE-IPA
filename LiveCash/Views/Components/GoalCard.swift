import SwiftUI

struct GoalCard: View {
    let goal: SavingsGoal
    var compact: Bool = false

    var body: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(goal.name)
                        .font(LiveCashTheme.headlineFont)
                    Spacer()
                    Text("\(goal.progressPercent)%")
                        .font(LiveCashTheme.captionFont.weight(.semibold))
                        .foregroundStyle(LiveCashTheme.accent)
                }

                ProgressView(value: goal.progress)
                    .tint(LiveCashTheme.accent)

                HStack {
                    Text(String(format: "%.0f€ von %.0f€", goal.currentAmount, goal.targetAmount))
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !compact {
                        Text(String(format: "%.0f€/Monat nötig", goal.monthlyRequired()))
                            .font(LiveCashTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }

                if !compact, let eta = goal.estimatedCompletionDate(monthlySavings: goal.monthlyRequired()) {
                    Text("Voraussichtlich: \(eta.formatted(date: .abbreviated, time: .omitted))")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.accent)
                }
            }
        }
    }
}
