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
            totalWealth: 1420
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
            Text("App einmal öffnen — Widgets aktualisieren sich automatisch.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding()
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if s.showBalance {
                Text(String(format: "%.0f€", s.balance))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(s.balance >= 0 ? income : expense)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Verfügbar")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            HStack {
                if s.showExpenses {
                    statCol("Ausgaben", value: s.monthExpenses, color: expense)
                }
                Spacer()
                if s.showSavings, let goal = s.primaryGoalName {
                    statCol("Sparen", valueText: "\(s.savingsProgressPercent)%", color: income)
                }
            }
            if s.showRecentExpense {
                lastTransactionRow
            } else if s.showSubscriptions, s.monthlySubscriptionCost > 0 {
                Text(String(format: "Abos: %.0f€/M", s.monthlySubscriptionCost))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var mediumLayout: some View {
        HStack(spacing: 16) {
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
                    if s.blockedInGoals > 0 {
                        Text(String(format: "Vermögen %.0f€", s.totalWealth))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                if s.showRecentExpense {
                    lastTransactionRow
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 10) {
                if s.showExpenses {
                    statCol("Ausgaben", value: s.monthExpenses, color: expense)
                }
                if s.showSavings, let goal = s.primaryGoalName {
                    VStack(alignment: .trailing) {
                        Text(goal)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text("\(s.savingsProgressPercent)%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(income)
                    }
                }
                if s.showSubscriptions, s.monthlySubscriptionCost > 0 {
                    statCol("Abos/M", value: s.monthlySubscriptionCost, color: accent)
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private var lastTransactionRow: some View {
        if let merchant = s.lastTransactionMerchant, s.lastTransactionAmount > 0 {
            let color = s.lastTransactionIsIncome ? income : expense
            let prefix = s.lastTransactionIsIncome ? "+" : "−"
            Text("Letzte: \(merchant) · \(prefix)\(String(format: "%.0f€", s.lastTransactionAmount))")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
        }
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

    private func statCol(_ title: String, value: Double, color: Color) -> some View {
        statCol(title, valueText: String(format: "%.0f€", value), color: color)
    }

    private func statCol(_ title: String, valueText: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(valueText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
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
        .description("Kontostand, Ausgaben, Sparfortschritt und letzte Bewegung.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
