import WidgetKit
import SwiftUI

struct LiveCashWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct LiveCashWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LiveCashWidgetEntry {
        LiveCashWidgetEntry(date: Date(), snapshot: WidgetSnapshot(
            balance: 1240, monthExpenses: 820, monthIncome: 1200,
            topCategoryName: "Lebensmittel", topCategoryAmount: 210,
            savingsProgressPercent: 65, primaryGoalName: "iPhone",
            monthlySubscriptionCost: 42,
            lastExpenseMerchant: "Döner", lastExpenseAmount: 6,
            lastTransactionMerchant: "Döner", lastTransactionAmount: 6,
            lastTransactionIsIncome: false, refreshIntervalMinutes: 15,
            showBalance: true, showExpenses: true, showSavings: true,
            showSubscriptions: true, showRecentExpense: true,
            updatedAt: Date(),
            hasLiveData: true,
            blockedInGoals: 180,
            totalWealth: 1420,
            financeScore: 72,
            coins: 40,
            weeklyBudget: 180,
            loginStreakDays: 5
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (LiveCashWidgetEntry) -> Void) {
        completion(LiveCashWidgetEntry(date: Date(), snapshot: WidgetSnapshotLoader.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiveCashWidgetEntry>) -> Void) {
        let snapshot = WidgetSnapshotLoader.load()
        let entry = LiveCashWidgetEntry(date: Date(), snapshot: snapshot)
        let minutes = max(snapshot.refreshIntervalMinutes, 15)
        let next = Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) ?? Date().addingTimeInterval(Double(minutes * 60))
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct LiveCashWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LiveCashWidgetEntry

    private var s: WidgetSnapshot { entry.snapshot }
    private var accent: Color { Color(red: 0.12, green: 0.72, blue: 0.52) }
    private var income: Color { Color(red: 0.15, green: 0.78, blue: 0.42) }
    private var expense: Color { Color(red: 0.94, green: 0.32, blue: 0.36) }
    private var hasData: Bool { s.hasLiveData && s.updatedAt.timeIntervalSince1970 > 1_000_000 }

    var body: some View {
        Group {
            if !hasData {
                emptyLayout
            } else if family == .systemMedium {
                mediumLayout
            } else {
                smallLayout
            }
        }
        .widgetURL(URL(string: "livecash://widget"))
    }

    private var emptyLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Cash")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Keine Live-Daten")
                .font(.system(.headline, design: .rounded).weight(.bold))
            Text("App öffnen → Einstellungen → Widget aktualisieren.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if s.showBalance {
                Text(String(format: "%.0f€", s.balance))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(s.balance >= 0 ? income : expense)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            HStack(spacing: 10) {
                if s.financeScore > 0 {
                    miniStat("Score", "\(s.financeScore)")
                }
                if s.showSavings, s.primaryGoalName != nil {
                    miniStat("Ziel", "\(s.savingsProgressPercent)%")
                }
                if s.coins > 0 {
                    miniStat("Coins", "\(s.coins)")
                }
            }
            if s.weeklyBudget > 0 {
                Text(String(format: "Woche ~%.0f€", s.weeklyBudget))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var mediumLayout: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                header
                if s.showBalance {
                    Text(String(format: "%.0f€", s.balance))
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(s.balance >= 0 ? income : expense)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("Verfügbar")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                if s.weeklyBudget > 0 {
                    Text(String(format: "Wochenbudget ~%.0f€", s.weeklyBudget))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(accent)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 8) {
                if s.financeScore > 0 {
                    labeledValue("Score", "\(s.financeScore)", accent)
                }
                if s.showSavings, let goal = s.primaryGoalName {
                    labeledValue(goal, "\(s.savingsProgressPercent)%", income)
                }
                if s.coins > 0 || s.loginStreakDays > 0 {
                    HStack(spacing: 8) {
                        if s.loginStreakDays > 0 {
                            Text("🔥 \(s.loginStreakDays)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        if s.coins > 0 {
                            Text("🟡 \(s.coins)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                    }
                }
                if s.showExpenses {
                    labeledValue("Ausgaben", String(format: "%.0f€", s.monthExpenses), expense)
                }
            }
        }
        .padding()
    }

    private var header: some View {
        HStack {
            Text("Live Cash")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(s.updatedAt, style: .time)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func miniStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(accent)
        }
    }

    private func labeledValue(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

struct LiveCashWidget: Widget {
    let kind = "LiveCashWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiveCashWidgetProvider()) { entry in
            LiveCashWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Live Cash")
        .description("Kontostand, Sparziel, Finanzscore, Coins und Wochenbudget.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
