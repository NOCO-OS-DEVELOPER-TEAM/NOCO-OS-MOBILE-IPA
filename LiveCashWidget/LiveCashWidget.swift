import WidgetKit
import SwiftUI

struct LiveCashWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct LiveCashWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LiveCashWidgetEntry {
        LiveCashWidgetEntry(date: Date(), snapshot: WidgetSnapshot(
            balance: 240, monthExpenses: 820, monthIncome: 1200,
            topCategoryName: "Lebensmittel", topCategoryAmount: 210,
            savingsProgressPercent: 35, primaryGoalName: "iPhone",
            monthlySubscriptionCost: 42,
            showBalance: true, showExpenses: true, showSavings: true, showSubscriptions: true,
            updatedAt: Date()
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (LiveCashWidgetEntry) -> Void) {
        completion(LiveCashWidgetEntry(date: Date(), snapshot: WidgetSnapshotLoader.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiveCashWidgetEntry>) -> Void) {
        let entry = LiveCashWidgetEntry(date: Date(), snapshot: WidgetSnapshotLoader.load())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct LiveCashWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LiveCashWidgetEntry

    private var accent: Color { Color(red: 0.12, green: 0.72, blue: 0.52) }
    private var income: Color { Color(red: 0.15, green: 0.78, blue: 0.42) }
    private var expense: Color { Color(red: 0.94, green: 0.32, blue: 0.36) }

    var body: some View {
        Group {
            if let s = entry.snapshot {
                if family == .systemMedium {
                    mediumLayout(s)
                } else {
                    smallLayout(s)
                }
            } else {
                emptyLayout
            }
        }
        .widgetURL(URL(string: "livecash://widget"))
    }

    private func smallLayout(_ s: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header(s)
            if s.showBalance {
                Text(String(format: "%.0f€", s.balance))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(s.balance >= 0 ? income : expense)
                Text("Saldo · Monat")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            HStack {
                if s.showExpenses {
                    statCol("Ausgaben", value: s.monthExpenses, color: expense)
                }
                Spacer()
                if s.showSavings {
                    statCol("Sparen", valueText: "\(s.savingsProgressPercent)%", color: income)
                }
            }
            if s.showSubscriptions, s.monthlySubscriptionCost > 0 {
                Text(String(format: "Abos: %.0f€/M", s.monthlySubscriptionCost))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            } else if let cat = s.topCategoryName, s.showExpenses {
                Text("Top: \(cat)")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
    }

    private func mediumLayout(_ s: WidgetSnapshot) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                header(s)
                if s.showBalance {
                    Text(String(format: "%.0f€", s.balance))
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(s.balance >= 0 ? income : expense)
                    Text("Monatssaldo")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 10) {
                if s.showExpenses {
                    statCol("Ausgaben", value: s.monthExpenses, color: expense)
                }
                if s.showSavings, let goal = s.primaryGoalName {
                    Text("\(goal) · \(s.savingsProgressPercent)%")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if s.showSubscriptions, s.monthlySubscriptionCost > 0 {
                    statCol("Abos/M", value: s.monthlySubscriptionCost, color: accent)
                }
            }
        }
        .padding()
    }

    private var emptyLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live Cash")
                .font(.headline)
            Text("App öffnen für Kontostand")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func header(_ s: WidgetSnapshot) -> some View {
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
        .description("Kontostand, Ausgaben, Sparfortschritt und Abo-Kosten.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
