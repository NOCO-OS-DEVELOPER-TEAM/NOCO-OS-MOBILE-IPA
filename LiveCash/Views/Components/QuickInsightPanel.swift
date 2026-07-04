import SwiftUI

struct QuickInsightPanel: View {
    @EnvironmentObject private var store: FinanceStore
    var onDismiss: () -> Void

    var body: some View {
        LiveCashGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Schnell-Insight", systemImage: "bolt.fill")
                        .font(LiveCashTheme.headlineFont)
                        .foregroundStyle(LiveCashTheme.accent)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    insightTile(
                        title: "Heute",
                        value: String(format: "%.0f€", store.todayExpenses),
                        color: LiveCashTheme.expense
                    )
                    insightTile(
                        title: "Saldo",
                        value: String(format: "%.0f€", store.currentBalance),
                        color: store.currentBalance >= 0 ? LiveCashTheme.income : LiveCashTheme.expense
                    )
                }

                if let top = store.topCategoryThisMonth {
                    HStack {
                        Text("Top heute: \(top.0.rawValue)")
                        Spacer()
                        Text(String(format: "%.0f€", top.1))
                            .foregroundStyle(LiveCashTheme.expense)
                    }
                    .font(LiveCashTheme.captionFont)
                }

                if let goal = store.goals.first {
                    HStack {
                        Text("Sparziel: \(goal.name)")
                        Spacer()
                        Text("\(goal.progressPercent)%")
                            .foregroundStyle(LiveCashTheme.income)
                    }
                    .font(LiveCashTheme.captionFont)
                }

                if store.todayExpenses > store.dailyAverageExpenses * 1.5, store.dailyAverageExpenses > 0 {
                    Label("Heute über dem Tagesdurchschnitt", systemImage: "exclamationmark.triangle.fill")
                        .font(LiveCashTheme.captionFont)
                        .foregroundStyle(LiveCashTheme.expense)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func insightTile(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LiveCashTheme.captionFont)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
