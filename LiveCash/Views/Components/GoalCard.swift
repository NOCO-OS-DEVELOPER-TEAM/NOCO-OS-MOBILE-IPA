import SwiftUI

struct GoalCard: View {
    let goal: SavingsGoal
    var monthlySavingsRate: Double = 0
    var compact: Bool = false
    var showProgress: Bool = true

    private var etaMonths: Int? {
        goal.estimatedMonthsToComplete(monthlySavings: monthlySavingsRate > 0 ? monthlySavingsRate : goal.monthlyRequired())
    }

    var body: some View {
        LiveCashCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(goal.name)
                        .font(LiveCashTheme.headlineFont)
                    Spacer()
                    Text("\(goal.progressPercent)%")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(LiveCashTheme.income)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LiveCashTheme.incomeSoft)
                        .clipShape(Capsule())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LiveCashTheme.incomeSoft)
                        Capsule()
                            .fill(LiveCashTheme.income)
                            .frame(width: geo.size.width * goal.progress)
                    }
                }
                .frame(height: 8)
                .opacity(showProgress ? 1 : 0)

                HStack {
                    Text(String(format: "%.0f€ von %.0f€", goal.currentAmount, goal.targetAmount))
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f€ übrig", goal.remaining))
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(.secondary)
                }

                if !compact {
                    HStack(spacing: 12) {
                        if let months = etaMonths {
                            Label("ETA: \(months) Monat\(months == 1 ? "" : "e")", systemImage: "calendar")
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(LiveCashTheme.accent)
                        }
                        if let date = goal.estimatedCompletionDate(monthlySavings: monthlySavingsRate > 0 ? monthlySavingsRate : goal.monthlyRequired()) {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(LiveCashTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
