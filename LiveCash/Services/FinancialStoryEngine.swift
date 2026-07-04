import Foundation

enum StoryPeriod: String, CaseIterable, Identifiable {
    case day = "Tag"
    case week = "Woche"
    case month = "Monat"
    case year = "Jahr"

    var id: String { rawValue }
}

struct StorySlide: Identifiable, Equatable {
    let id: String
    let title: String
    let headline: String
    let detail: String
    let value: String
    let isIncome: Bool

    init(title: String, headline: String, detail: String, value: String, isIncome: Bool = false) {
        self.id = title + headline
        self.title = title
        self.headline = headline
        self.detail = detail
        self.value = value
        self.isIncome = isIncome
    }
}

enum FinancialStoryEngine {
    @MainActor
    static func slides(for period: StoryPeriod, store: FinanceStore) -> [StorySlide] {
        let range = dateRange(for: period)
        let txs = store.accountFilteredTransactions.filter { $0.date >= range.start && $0.date <= range.end }
        let expenses = txs.filter { $0.type == .expense }
        let income = txs.filter { $0.type == .income }
        let totalExp = expenses.reduce(0) { $0 + $1.amount }
        let totalInc = income.reduce(0) { $0 + $1.amount }

        var slides: [StorySlide] = [
            StorySlide(
                title: "Ausgaben",
                headline: String(format: "%.0f€ ausgegeben", totalExp),
                detail: expenses.isEmpty ? "Keine Ausgaben in diesem Zeitraum" : "\(expenses.count) Buchungen · Ø \(String(format: "%.0f€", totalExp / Double(max(expenses.count, 1))))",
                value: String(format: "%.0f€", totalExp)
            )
        ]

        if let top = Dictionary(grouping: expenses, by: \.category)
            .map({ ($0.key, $0.value.reduce(0) { $0 + $1.amount }) })
            .max(by: { $0.1 < $1.1 }) {
            let insight = totalInc >= totalExp
                ? "Du hältst dein Budget im Griff."
                : "Hier liegt dein größtes Sparpotenzial."
            slides.append(StorySlide(
                title: "Insight",
                headline: top.0.rawValue,
                detail: insight,
                value: String(format: "%.0f€", top.1)
            ))
        } else {
            slides.append(StorySlide(
                title: "Insight",
                headline: "Noch keine Daten",
                detail: "Buche Ausgaben, um Muster zu sehen.",
                value: "—"
            ))
        }

        if let goal = store.goals.max(by: { $0.progress < $1.progress }) {
            slides.append(StorySlide(
                title: "Sparstatus",
                headline: goal.name,
                detail: goal.progress > 0 ? "Weiter so — jedes Stück zählt." : "Lege heute den ersten Betrag an.",
                value: "\(goal.progressPercent)%",
                isIncome: true
            ))
        } else {
            slides.append(StorySlide(
                title: "Sparstatus",
                headline: "Kein Sparziel",
                detail: "Erstelle ein Ziel unter Sparziele.",
                value: "0%",
                isIncome: true
            ))
        }

        return Array(slides.prefix(3))
    }

    private static func dateRange(for period: StoryPeriod) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let end = Date()
        let start: Date
        switch period {
        case .day:
            start = cal.startOfDay(for: end)
        case .week:
            start = cal.date(byAdding: .day, value: -7, to: end) ?? end
        case .month:
            start = cal.date(from: cal.dateComponents([.year, .month], from: end)) ?? end
        case .year:
            start = cal.date(from: cal.dateComponents([.year], from: end)) ?? end
        }
        return (start, end)
    }
}
