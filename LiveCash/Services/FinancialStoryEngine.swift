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
    let accentEmoji: String?

    init(title: String, headline: String, detail: String, value: String, isIncome: Bool = false, accentEmoji: String? = nil) {
        self.id = title + headline + value
        self.title = title
        self.headline = headline
        self.detail = detail
        self.value = value
        self.isIncome = isIncome
        self.accentEmoji = accentEmoji
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

        if period == .day {
            let todayExp = store.todayExpenses
            let avgDaily = store.currentMonthExpenses / Double(max(Calendar.current.component(.day, from: Date()), 1))
            let detail: String
            if todayExp > avgDaily * 1.4 && avgDaily > 0 {
                detail = "Du hast heute viel ausgegeben — über deinem üblichen Tagesniveau."
            } else if todayExp == 0 {
                detail = "Noch keine Ausgaben heute — stark!"
            } else {
                detail = "Dein Tages-Tempo sieht normal aus."
            }
            slides.append(StorySlide(
                title: "Heute",
                headline: String(format: "%.0f€ ausgegeben", todayExp),
                detail: detail,
                value: String(format: "%.0f€", todayExp)
            ))
        }

        if period == .month {
            let prevRange = previousMonthRange(endingBefore: range.start)
            let prevExp = store.accountFilteredTransactions
                .filter { $0.type == .expense && $0.date >= prevRange.start && $0.date < prevRange.end }
                .reduce(0) { $0 + $1.amount }
            let saved = max(0, totalInc - totalExp)
            slides.append(StorySlide(
                title: "Dein Monat",
                headline: "Einkommen, Ausgaben, Gespart",
                detail: String(format: "💰 %.0f€ rein · 💸 %.0f€ raus · 🎯 %.0f€ gespart", totalInc, totalExp, saved),
                value: String(format: "%.0f€", saved),
                isIncome: true,
                accentEmoji: "💰"
            ))
            if let top = expenses.max(by: { $0.amount < $1.amount }) {
                slides.append(StorySlide(
                    title: "Deine größte Ausgabe",
                    headline: top.merchant,
                    detail: "\(top.category.rawValue) war dein größter Einzelposten.",
                    value: String(format: "%.0f€", top.amount),
                    accentEmoji: "💸"
                ))
            }
            if prevExp > 0 {
                let pct = ((totalExp - prevExp) / prevExp) * 100
                let better = -pct
                slides.append(StorySlide(
                    title: "Dein Fortschritt",
                    headline: better > 0
                        ? String(format: "Du bist %.0f%% besser als letzten Monat.", better)
                        : String(format: "%.0f%% mehr Ausgaben als letzten Monat.", abs(pct)),
                    detail: better > 0 ? "Weiter so — der Trend stimmt." : "Schau dir deine Top-Kategorie an.",
                    value: String(format: "%+.0f%%", pct),
                    isIncome: better > 0,
                    accentEmoji: "📈"
                ))
            }
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
                    title: "Warnung",
                    headline: unusual.name,
                    detail: unusual.detail,
                    value: String(format: "%.0f€", unusual.amount)
                ))
            }

            let savedThisMonth = store.goals.reduce(0) { $0 + $1.currentAmount }
            if savedThisMonth > 0 {
                slides.append(StorySlide(
                    title: "Sparverhalten",
                    headline: String(format: "%.0f€ gespart", savedThisMonth),
                    detail: totalInc > totalExp ? "Du sparst mehr als du ausgibst — starkes Signal." : "Jeder Euro Richtung Ziel zählt.",
                    value: String(format: "%.0f€", savedThisMonth),
                    isIncome: true
                ))
            }
        } else if period != .day {
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
            let paceBetter: String
            if goal.progressPercent >= 50 {
                paceBetter = "Deine Sparziele laufen besser als zuletzt — weiter so."
            } else if goal.paceStatus(referenceMonthlySavings: store.monthlySavingsRate) == .slow {
                paceBetter = "Dein Ziel braucht etwas mehr Tempo."
            } else {
                paceBetter = "Jeder Beitrag bringt dich näher."
            }
            slides.append(StorySlide(
                title: "Sparstatus",
                headline: goal.name,
                detail: paceBetter,
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

        // Personal pattern slides
        slides.append(contentsOf: personalPatternSlides(expenses: expenses, store: store, period: period))

        return Array(slides.prefix(period == .month ? 10 : (period == .day ? 5 : 6)))
    }

    @MainActor
    private static func personalPatternSlides(expenses: [Transaction], store: FinanceStore, period: StoryPeriod) -> [StorySlide] {
        var extra: [StorySlide] = []
        let spending = expenses.filter { !FinanceStore.isGoalContribution($0) }

        if let weekday = expensiveWeekdayInsight(spending) {
            extra.append(StorySlide(
                title: "Muster",
                headline: weekday.title,
                detail: weekday.detail,
                value: weekday.value
            ))
        }

        if let top = Dictionary(grouping: spending, by: \.category)
            .map({ ($0.key, $0.value.reduce(0) { $0 + $1.amount }) })
            .max(by: { $0.1 < $1.1 }), top.1 > 0 {
            let total = max(spending.reduce(0) { $0 + $1.amount }, 1)
            let pct = top.1 / total * 100
            extra.append(StorySlide(
                title: "Lieblingskategorie",
                headline: "Deine häufigste Kategorie ist \(top.0.rawValue).",
                detail: String(format: "%.0f%% deiner Ausgaben in diesem Zeitraum.", pct),
                value: String(format: "%.0f€", top.1)
            ))
        }

        let places = spending.compactMap { $0.location?.label ?? ($0.merchant.isEmpty ? nil : $0.merchant) }
        if let favorite = Dictionary(grouping: places, by: { $0 }).max(by: { $0.value.count < $1.value.count }),
           favorite.value.count >= 2 {
            extra.append(StorySlide(
                title: "Ort",
                headline: "Dein Lieblingsort: \(favorite.key)",
                detail: "\(favorite.value.count)× besucht in diesem Zeitraum.",
                value: "\(favorite.value.count)×"
            ))
        }

        if period == .month || period == .week {
            let rate = store.monthlySavingsRate
            if rate > 0 {
                extra.append(StorySlide(
                    title: "Trend",
                    headline: "Dein Sparverhalten trägt",
                    detail: String(format: "Aktuelles Tempo: ca. %.0f€/Monat Richtung Ziele.", rate),
                    value: String(format: "%.0f€", rate),
                    isIncome: true
                ))
            }
        }

        return extra
    }

    private static func expensiveWeekdayInsight(_ expenses: [Transaction]) -> (title: String, detail: String, value: String)? {
        guard expenses.count >= 8 else { return nil }
        let names = ["", "Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
        var totals: [Int: Double] = [:]
        for tx in expenses {
            let wd = Calendar.current.component(.weekday, from: tx.date)
            totals[wd, default: 0] += tx.amount
        }
        guard let peak = totals.max(by: { $0.value < $1.value }),
              let avg = totals.values.isEmpty ? nil : totals.values.reduce(0, +) / Double(totals.count),
              avg > 0 else { return nil }
        let pct = ((peak.value - avg) / avg) * 100
        guard pct >= 15 else { return nil }
        let name = names[peak.key]
        return (
            "\(name) ist teurer",
            String(format: "Du gibst %@s durchschnittlich %.0f%% mehr aus.", name.lowercased(), pct),
            String(format: "+%.0f%%", pct)
        )
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
