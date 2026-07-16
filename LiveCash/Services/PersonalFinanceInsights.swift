import Foundation

/// Personalized behavior insights for the Smart Assistant.
@MainActor
enum PersonalFinanceInsights {
    struct Tip {
        let shortTitle: String
        let message: String
        let action: InsightAction
    }

    static func topSuggestion(store: FinanceStore) -> Tip? {
        if let tip = categoryMonthOverMonth(store: store) { return tip }
        if let tip = loggingHabit(store: store) { return tip }
        if let tip = goalAccelerationTip(store: store) { return tip }
        if let tip = frequentCategory(store: store) { return tip }
        return nil
    }

    static func personalInsightLines(store: FinanceStore) -> [String] {
        var lines: [String] = []
        if let tip = categoryMonthOverMonth(store: store) { lines.append(tip.message) }
        if let tip = loggingHabit(store: store) { lines.append(tip.message) }
        if let tip = goalAccelerationTip(store: store) { lines.append(tip.message) }
        if let tip = frequentCategory(store: store) { lines.append(tip.message) }
        return Array(lines.prefix(3))
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
        let weekly = 10.0
        let weeks = Int(ceil(goal.remaining / weekly))
        return Tip(
            shortTitle: "10€/Woche zu \(goal.name)",
            message: String(
                format: "Wenn du 10€ pro Woche sparst, erreichst du „%@“ in ca. %d Wochen.",
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
            message: String(format: "Deine häufigste Kategorie diesen Monat: %@ (%.0f€).", top.key.rawValue, top.value),
            action: .byCategory
        )
    }

    private static func categoryTotals(store: FinanceStore, in date: Date) -> [FinanceCategory: Double] {
        var totals: [FinanceCategory: Double] = [:]
        for tx in store.transactions(inMonth: date) where tx.type == .expense && !FinanceStore.isGoalContribution(tx) {
            totals[tx.category, default: 0] += tx.amount
        }
        return totals
    }
}
