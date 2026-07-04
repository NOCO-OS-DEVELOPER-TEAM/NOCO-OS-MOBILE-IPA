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
            savingsProgressPercent: 35, primaryGoalName: "iPhone", updatedAt: Date()
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (LiveCashWidgetEntry) -> Void) {
        completion(LiveCashWidgetEntry(date: Date(), snapshot: WidgetSnapshotLoader.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiveCashWidgetEntry>) -> Void) {
        let entry = LiveCashWidgetEntry(date: Date(), snapshot: WidgetSnapshotLoader.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct LiveCashWidgetView: View {
    let entry: LiveCashWidgetEntry

    private var accent: Color { Color(red: 0.12, green: 0.72, blue: 0.52) }
    private var income: Color { Color(red: 0.15, green: 0.78, blue: 0.42) }
    private var expense: Color { Color(red: 0.94, green: 0.32, blue: 0.36) }

    var body: some View {
        if let s = entry.snapshot {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Live Cash")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(s.updatedAt, style: .time)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text(String(format: "%.0f€", s.balance))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(s.balance >= 0 ? income : expense)
                Text("Saldo · Monat")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Ausgaben")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f€", s.monthExpenses))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(expense)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Sparen")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("\(s.savingsProgressPercent)%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(income)
                    }
                }
                if let cat = s.topCategoryName {
                    Text("Top: \(cat)")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Live Cash")
                    .font(.headline)
                Text("App öffnen für Daten")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
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
        .description("Saldo, Ausgaben und Sparfortschritt.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
