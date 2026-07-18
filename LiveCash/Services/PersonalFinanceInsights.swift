import Foundation

/// Personalized behavior insights for the Smart Assistant & Dashboard.
@MainActor
enum PersonalFinanceInsights {
    struct Tip: Identifiable {
        var id: String { shortTitle + message }
        let shortTitle: String
        let message: String
        let action: InsightAction
    }

    static func dashboardTips(store: FinanceStore, limit: Int = 6) -> [Tip] {
        var tips: [Tip] = []
        let generators: [(FinanceStore) -> Tip?] = [
            weekOverWeekSpend,
            categoryMonthOverMonth,
            expensiveWeekdayTip,
            goalProgressTip,
            goalAccelerationTip,
            frequentCategory,
            weeklyBudgetTip,
            subscriptionTip,
            loggingHabit,
            incomePaceTip
        ]
        for gen in generators {
            if let tip = gen(store) {
                tips.append(tip)
            }
            if tips.count >= limit { break }
        }
        if tips.isEmpty {
            tips.append(contentsOf: fallbackTips(store: store))
        }
        return Array(tips.prefix(limit))
    }

    static func topSuggestion(store: FinanceStore) -> Tip? {
        dashboardTips(store: store, limit: 1).first
    }

    static func personalInsightLines(store: FinanceStore) -> [String] {
        dashboardTips(store: store, limit: 3).map(\.message)
    }

    static func weekOverWeekSpend(store: FinanceStore) -> Tip? {
        let cal = Calendar.current
        let now = Date()
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: now),
              let twoWeeks = cal.date(byAdding: .day, value: -14, to: now) else { return nil }
        let thisWeek = expenses(store: store, from: weekAgo, to: now)
        let lastWeek = expenses(store: store, from: twoWeeks, to: weekAgo)
        guard thisWeek + lastWeek > 10 else { return nil }
        let delta = thisWeek - lastWeek
        if abs(delta) < 3 { return nil }
        return Tip(
            shortTitle: delta < 0 ? "Sparsame Woche" : "Mehr ausgegeben",
            message: delta < 0
                ? String(format: "Du hast diese Woche %.0f€ weniger ausgegeben als letzte Woche.", abs(delta))
                : String(format: "Du hast diese Woche %.0f€ mehr ausgegeben als letzte Woche.", delta),
            action: .last7Days
        )
    }

    static func expensiveWeekdayTip(store: FinanceStore) -> Tip? {
        let memory = AssistantMemory.build(from: store)
        guard let wd = memory.expensiveWeekday else { return nil }
        return Tip(
            shortTitle: "Teuerster Tag",
            message: "\(wd) ist weiterhin dein teuerster Tag.",
            action: .spendingPace
        )
    }

    static func goalProgressTip(store: FinanceStore) -> Tip? {
        guard let goal = store.activeGoals.first else { return nil }
        return Tip(
            shortTitle: "Sparziel \(goal.progressPercent)%",
            message: String(
                format: "Du bist %d%% auf dem Weg zu „%@“ (%.0f€ von %.0f€).",
                goal.progressPercent,
                goal.name,
                goal.currentAmount,
                goal.targetAmount
            ),
            action: .goalsProgress
        )
    }

    static func weeklyBudgetTip(store: FinanceStore) -> Tip? {
        let day = max(Calendar.current.component(.day, from: Date()), 1)
        let daily = store.currentMonthExpenses / Double(day)
        let weekBudget = daily * 7
        guard weekBudget > 5 else { return nil }
        return Tip(
            shortTitle: "Wochenbudget",
            message: String(format: "Dein aktuelles Wochen-Ausgaben-Tempo liegt bei ca. %.0f€.", weekBudget),
            action: .weeklyBudget
        )
    }

    static func subscriptionTip(store: FinanceStore) -> Tip? {
        let cost = store.monthlySubscriptionCost
        guard cost >= 15 else { return nil }
        return Tip(
            shortTitle: "Abos",
            message: String(format: "Deine Abos kosten dich %.0f€ im Monat — ca. %.0f€ im Jahr.", cost, cost * 12),
            action: .monthlySubCost
        )
    }

    static func incomePaceTip(store: FinanceStore) -> Tip? {
        let income = store.currentMonthIncome
        let expenses = store.currentMonthExpenses
        guard income > 0 else { return nil }
        let rate = expenses / income
        if rate > 0.9 {
            return Tip(
                shortTitle: "Hohe Ausgabenquote",
                message: String(format: "Du hast schon %.0f%% deiner Einnahmen diesen Monat ausgegeben.", rate * 100),
                action: .incomeVsExpense
            )
        }
        if rate < 0.5 && expenses > 20 {
            return Tip(
                shortTitle: "Gute Quote",
                message: String(format: "Nur %.0f%% deiner Einnahmen sind bisher ausgegeben — starker Puffer.", rate * 100),
                action: .incomeVsExpense
            )
        }
        return nil
    }

    static func categoryMonthOverMonth(store: FinanceStore) -> Tip? {
        let cal = Calendar.current
        let now = Date()
        guard let lastMonthDate = cal.date(byAdding: .month, value: -1, to: now) else { return nil }

        let thisMonth = categoryTotals(store: store, in: now)
        let lastMonth = categoryTotals(store: store, in: lastMonthDate)
        guard !thisMonth.isEmpty, !lastMonth.isEmpty else { return nil }

        var biggest: (FinanceCategory, Double, Double)?
        for (cat, current) in thisMonth {
            let previous = lastMonth[cat] ?? 0
            guard previous > 5, current > previous * 1.2 else { continue }
            let delta = current - previous
            if biggest == nil || delta > (biggest!.1 - biggest!.2) {
                biggest = (cat, current, previous)
            }
        }
        guard let hit = biggest else { return nil }
        return Tip(
            shortTitle: "Mehr für \(hit.0.rawValue)",
            message: String(
                format: "Du gibst aktuell mehr für %@ aus als letzten Monat (%.0f€ vs. %.0f€).",
                hit.0.rawValue,
                hit.1,
                hit.2
            ),
            action: .monthCompare
        )
    }

    static func loggingHabit(store: FinanceStore) -> Tip? {
        let expenses = store.accountFilteredTransactions.filter {
            $0.type == .expense && !FinanceStore.isGoalContribution($0)
        }
        guard expenses.count >= 8 else { return nil }
        let hours = expenses.prefix(40).map { Calendar.current.component(.hour, from: $0.date) }
        guard !hours.isEmpty else { return nil }
        let avg = hours.reduce(0, +) / hours.count
        let label: String
        if avg < 12 { label = "vormittags" }
        else if avg < 17 { label = "nachmittags" }
        else { label = "abends" }
        return Tip(
            shortTitle: "Eingabe meist \(label)",
            message: "Du trägst deine Ausgaben meistens \(label) ein.",
            action: .spendingPace
        )
    }

    static func goalAccelerationTip(store: FinanceStore) -> Tip? {
        guard let goal = store.activeGoals.first, goal.remaining > 0 else { return nil }
        let weekly = max(store.monthlySavingsRate / 4.0, 10)
        let weeks = Int(ceil(goal.remaining / weekly))
        return Tip(
            shortTitle: "Tempo zu \(goal.name)",
            message: String(
                format: "Mit ca. %.0f€/Woche erreichst du „%@“ in etwa %d Wochen.",
                weekly,
                goal.name,
                max(weeks, 1)
            ),
            action: .goalsProgress
        )
    }

    static func frequentCategory(store: FinanceStore) -> Tip? {
        let month = categoryTotals(store: store, in: Date())
        guard let top = month.max(by: { $0.value < $1.value }), top.value > 20 else { return nil }
        return Tip(
            shortTitle: "Häufig: \(top.key.rawValue)",
            message: String(format: "Deine stärkste Kategorie diesen Monat: %@ (%.0f€).", top.key.rawValue, top.value),
            action: .byCategory
        )
    }

    private static func fallbackTips(store: FinanceStore) -> [Tip] {
        var tips: [Tip] = []
        let memory = AssistantMemory.build(from: store)
        if memory.prevMonthExpenses > 0 {
            let delta = memory.monthExpenses - memory.prevMonthExpenses
            tips.append(.init(
                shortTitle: delta <= 0 ? "Weniger als Vormonat" : "Mehr als Vormonat",
                message: delta <= 0
                    ? String(format: "Du hast %.0f€ weniger ausgegeben als letzten Monat.", abs(delta))
                    : String(format: "Du hast %.0f€ mehr ausgegeben als letzten Monat.", delta),
                action: .monthCompare
            ))
        }
        tips.append(.init(
            shortTitle: "Smart Assistant",
            message: "Frag z. B.: „Habe ich diesen Monat zu viel ausgegeben?“",
            action: .whySpending
        ))
        return tips
    }

    private static func expenses(store: FinanceStore, from: Date, to: Date) -> Double {
        store.accountFilteredTransactions
            .filter {
                $0.type == .expense
                    && !FinanceStore.isGoalContribution($0)
                    && $0.date >= from
                    && $0.date < to
            }
            .reduce(0) { $0 + $1.amount }
    }

    private static func categoryTotals(store: FinanceStore, in date: Date) -> [FinanceCategory: Double] {
        var totals: [FinanceCategory: Double] = [:]
        for tx in store.transactions(inMonth: date) where tx.type == .expense && !FinanceStore.isGoalContribution(tx) {
            totals[tx.category, default: 0] += tx.amount
        }
        return totals
    }
}
