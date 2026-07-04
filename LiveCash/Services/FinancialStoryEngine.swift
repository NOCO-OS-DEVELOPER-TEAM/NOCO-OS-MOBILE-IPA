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

        var slides: [StorySlide] = []

        if period == .month {
            let prevRange = previousMonthRange(endingBefore: range.start)
            let prevExp = store.accountFilteredTransactions
                .filter { $0.type == .expense && $0.date >= prevRange.start && $0.date < prevRange.end }
                .reduce(0) { $0 + $1.amount }
            let trendDetail: String
            if prevExp > 0 {
                let pct = ((totalExp - prevExp) / prevExp) * 100
                if pct > 5 {
                    trendDetail = String(format: "Deine Ausgaben sind %.0f%% höher als letzten Monat.", pct)
                } else if pct < -5 {
                    trendDetail = String(format: "Du gibst %.0f%% weniger aus als letzten Monat — gut!", abs(pct))
                } else {
                    trendDetail = "Dein Ausgaben-Tempo ist stabil."
                }
            } else {
                trendDetail = expenses.isEmpty ? "Keine Ausgaben in diesem Monat" : "\(expenses.count) Buchungen"
            }
            slides.append(StorySlide(
                title: "Ausgaben",
                headline: String(format: "%.0f€ ausgegeben", totalExp),
                detail: trendDetail,
                value: String(format: "%.0f€", totalExp)
            ))

            let cal = Calendar.current
            let newSubs = store.subscriptions.filter {
                cal.isDate($0.createdAt, equalTo: range.start, toGranularity: .month)
            }
            if !newSubs.isEmpty {
                slides.append(StorySlide(
                    title: "Abos",
                    headline: "\(newSubs.count) neue Abo\(newSubs.count == 1 ? "" : "s")",
                    detail: "Deine Fixkosten steigen — prüfe, ob du alle noch brauchst.",
                    value: String(format: "%.0f€/M", store.monthlySubscriptionCost)
                ))
            } else if store.monthlySubscriptionCost > 0 {
                slides.append(StorySlide(
                    title: "Fixkosten",
                    headline: String(format: "%.0f€/Monat an Abos", store.monthlySubscriptionCost),
                    detail: "Wiederkehrende Kosten belasten dein Budget.",
                    value: String(format: "%.0f€", store.monthlySubscriptionCost)
                ))
            }

            if let unusual = unusualCategory(expenses: expenses, store: store) {
                slides.append(StorySlide(
                    title: "Auffällig",
                    headline: unusual.name,
                    detail: unusual.detail,
                    value: String(format: "%.0f€", unusual.amount)
                ))
            }
        } else {
            slides.append(StorySlide(
                title: "Ausgaben",
                headline: String(format: "%.0f€ ausgegeben", totalExp),
                detail: expenses.isEmpty ? "Keine Ausgaben in diesem Zeitraum" : "\(expenses.count) Buchungen · Ø \(String(format: "%.0f€", totalExp / Double(max(expenses.count, 1))))",
                value: String(format: "%.0f€", totalExp)
            ))

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
            }
        }

        if let goal = store.goals.max(by: { $0.progress < $1.progress }) {
            slides.append(StorySlide(
                title: "Sparstatus",
                headline: goal.name,
                detail: goal.progress > 0 ? "Weiter so — jedes Stück zählt." : "Lege heute den ersten Betrag an.",
                value: "\(goal.progressPercent)%",
                isIncome: true
            ))
        } else if slides.count < 3 {
            slides.append(StorySlide(
                title: "Sparstatus",
                headline: "Kein Sparziel",
                detail: "Erstelle ein Ziel unter Sparziele.",
                value: "0%",
                isIncome: true
            ))
        }

        return Array(slides.prefix(period == .month ? 4 : 3))
    }

    @MainActor
    private static func unusualCategory(expenses: [Transaction], store: FinanceStore) -> (name: String, amount: Double, detail: String)? {
        guard expenses.count >= 5 else { return nil }
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        let prevStart = cal.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart

        let currentByCat = Dictionary(grouping: expenses, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        let prevExpenses = store.accountFilteredTransactions.filter {
            $0.type == .expense && $0.date >= prevStart && $0.date < monthStart
        }
        let prevByCat = Dictionary(grouping: prevExpenses, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        for (cat, amount) in currentByCat.sorted(by: { $0.value > $1.value }) {
            let prev = prevByCat[cat] ?? 0
            if prev > 0, amount > prev * 1.35 {
                return (
                    cat.rawValue,
                    amount,
                    String(format: "Ungewöhnlich hoch — %.0f%% mehr als letzten Monat.", ((amount - prev) / prev) * 100)
                )
            }
        }
        return nil
    }

    private static func previousMonthRange(endingBefore start: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let end = start
        let prevStart = cal.date(byAdding: .month, value: -1, to: start) ?? start
        return (prevStart, end)
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
