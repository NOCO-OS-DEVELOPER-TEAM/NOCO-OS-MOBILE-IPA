import ActivityKit
import WidgetKit
import SwiftUI

struct SavingsGoalActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var goalName: String
        var progressPercent: Int
        var currentAmount: Double
        var targetAmount: Double
        var todayExpenses: Double
        var warning: String?
    }

    var goalId: String
}

struct SavingsGoalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SavingsGoalActivityAttributes.self) { context in
            let income = Color(red: 0.15, green: 0.78, blue: 0.42)
            let expense = Color(red: 0.94, green: 0.32, blue: 0.36)
            let accent = Color(red: 0.12, green: 0.72, blue: 0.52)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(context.state.goalName)
                        .font(.headline)
                    Spacer()
                    Text("\(context.state.progressPercent)%")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(income)
                }
                ProgressView(value: Double(context.state.progressPercent), total: 100)
                    .tint(income)
                HStack {
                    Text(String(format: "%.0f€ / %.0f€", context.state.currentAmount, context.state.targetAmount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "Heute: %.0f€", context.state.todayExpenses))
                        .font(.caption)
                        .foregroundStyle(expense)
                }
                if let warning = context.state.warning {
                    Text(warning)
                        .font(.caption2)
                        .foregroundStyle(expense)
                }
            }
            .padding()
            .activityBackgroundTint(accent.opacity(0.15))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.goalName)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.progressPercent)%")
                        .font(.caption.weight(.bold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.progressPercent), total: 100)
                }
            } compactLeading: {
                Image(systemName: "target")
            } compactTrailing: {
                Text("\(context.state.progressPercent)%")
                    .font(.caption2.weight(.bold))
            } minimal: {
                Image(systemName: "target")
            }
        }
    }
}
