import Foundation

/// In-app personal memory derived from real user data — powers decision answers.
struct AssistantMemory: Equatable {
    var topCategories: [(name: String, amount: Double)]
    var primaryGoalName: String?
    var primaryGoalProgress: Int
    var typicalDailySpend: Double
    var availableBalance: Double
    var monthExpenses: Double
    var prevMonthExpenses: Double
    var expensiveWeekday: String?
    var topSubcategory: String?
    var habitLabel: String?
    var monthlySubscriptionCost: Double
    var focusGoal: String?

    static func == (lhs: AssistantMemory, rhs: AssistantMemory) -> Bool {
        lhs.availableBalance == rhs.availableBalance
            && lhs.monthExpenses == rhs.monthExpenses
            && lhs.primaryGoalName == rhs.primaryGoalName
            && lhs.primaryGoalProgress == rhs.primaryGoalProgress
    }

    @MainActor
    static func build(from store: FinanceStore) -> AssistantMemory {
        let cal = Calendar.current
        let now = Date()
        let expenses = store.accountFilteredTransactions.filter {
            $0.type == .expense && !FinanceStore.isGoalContribution($0)
        }
        let monthExp = expenses.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
        let byCat = Dictionary(grouping: monthExp, by: \.category)
            .map { ($0.key.rawValue, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }

        let bySub = Dictionary(grouping: monthExp.compactMap { tx -> (String, Double)? in
            guard let sub = tx.subcategory ?? SpendingSubcategory.detect(from: tx.merchant)?.rawValue else { return nil }
            return (sub, tx.amount)
        }, by: \.0)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.1 }) }
            .sorted { $0.1 > $1.1 }

        let prev = cal.date(byAdding: .month, value: -1, to: now) ?? now
        let prevTotal = store.transactions(inMonth: prev)
            .filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }
            .reduce(0) { $0 + $1.amount }

        let day = max(cal.component(.day, from: now), 1)
        let goal = store.activeGoals.first ?? store.goals.max(by: { $0.progress < $1.progress })

        let weekdayNames = ["", "Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
        var weekdayTotals: [Int: Double] = [:]
        for tx in expenses.prefix(80) {
            let wd = cal.component(.weekday, from: tx.date)
            weekdayTotals[wd, default: 0] += tx.amount
        }
        let expensiveWD = weekdayTotals.max(by: { $0.value < $1.value }).map { weekdayNames[$0.key] }

        let hours = monthExp.prefix(30).map { cal.component(.hour, from: $0.date) }
        let habit: String?
        if hours.count >= 5 {
            let avg = hours.reduce(0, +) / hours.count
            habit = avg < 12 ? "vormittags" : (avg < 17 ? "nachmittags" : "abends")
        } else {
            habit = nil
        }

        return AssistantMemory(
            topCategories: Array(byCat.prefix(3)),
            primaryGoalName: goal?.name,
            primaryGoalProgress: goal?.progressPercent ?? 0,
            typicalDailySpend: store.currentMonthExpenses / Double(day),
            availableBalance: store.availableBalance,
            monthExpenses: store.currentMonthExpenses,
            prevMonthExpenses: prevTotal,
            expensiveWeekday: expensiveWD,
            topSubcategory: bySub.first?.0,
            habitLabel: habit,
            monthlySubscriptionCost: store.monthlySubscriptionCost,
            focusGoal: store.onboardingProfile?.focusGoal
        )
    }
}

@MainActor
enum DecisionEngine {
    static func affordability(amount: Double?, store: FinanceStore, contextHint: String = "") -> FinanceInsight {
        let memory = AssistantMemory.build(from: store)
        let spend = amount ?? inferredAmount(from: contextHint, memory: memory)
        let available = memory.availableBalance
        let after = available - spend

        var rows: [(String, String)] = [
            ("Verfügbar", String(format: "%.0f€", available)),
            ("Geplante Ausgabe", spend > 0 ? String(format: "%.0f€", spend) : "Betrag offen"),
            ("Danach übrig", spend > 0 ? String(format: "%.0f€", after) : "—")
        ]

        var insight: String
        var delayDays = 0

        if let goal = store.activeGoals.first, goal.remaining > 0, spend > 0 {
            let weeklyPace = max(store.monthlySavingsRate / 4.3, 5)
            delayDays = Int(ceil(spend / weeklyPace * 7))
            rows.append(("Sparziel \(goal.name)", "\(goal.progressPercent)%"))
            rows.append(("Ziel-Verzögerung", delayDays > 0 ? "~\(delayDays) Tage" : "kaum"))
        }

        if spend <= 0 {
            insight = String(
                format: "Du hast diesen Monat noch %.0f€ verfügbar. Nenne einen Betrag (z. B. „Kann ich mir 80€ leisten?“), dann rechne ich es genau durch.",
                available
            )
        } else if spend > available {
            insight = String(
                format: "Eher nicht — die Ausgabe übersteigt dein verfügbares Geld um %.0f€.",
                spend - available
            )
        } else if after < memory.typicalDailySpend * 3 {
            insight = String(
                format: "Grenzwertig. Nach der Ausgabe bleiben %.0f€ — das sind nur noch wenige Tage bei deinem üblichen Tempo.",
                after
            )
        } else if delayDays >= 5, let name = memory.primaryGoalName {
            insight = String(
                format: "Du hast noch %.0f€ verfügbar. Dein %@-Sparziel ist bei %d%%. Die Ausgabe würde dein Ziel wahrscheinlich um %d Tage verzögern.",
                available, name, memory.primaryGoalProgress, delayDays
            )
        } else {
            insight = String(
                format: "Ja, das geht. Du hättest danach noch %.0f€ frei — und dein Ausgaben-Tempo bleibt im Rahmen.",
                after
            )
        }

        if let top = memory.topCategories.first {
            rows.append(("Häufigste Kategorie", "\(top.name) (\(String(format: "%.0f€", top.amount)))"))
        }

        return FinanceInsight(
            title: "Kann ich mir das leisten?",
            rows: rows,
            insight: insight,
            followUpActions: [.weeklyBudget, .goalsProgress, .savingsTips]
        )
    }

    static func weeklyBudget(store: FinanceStore) -> FinanceInsight {
        let memory = AssistantMemory.build(from: store)
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        // Days left in week (Mon-Sun DE: weekday 2=Mon)
        let daysLeftInWeek = max(1, 8 - ((weekday + 5) % 7 + 1))
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let day = cal.component(.day, from: now)
        let remainingMonth = max(0, memory.availableBalance)
        let weeksLeft = max(Double(daysInMonth - day + 1) / 7.0, 0.5)
        let weeklyAllow = remainingMonth / weeksLeft
        let todayAllow = remainingMonth / Double(max(daysInMonth - day + 1, 1))

        let compare: String
        if memory.prevMonthExpenses > 0 {
            let delta = memory.monthExpenses - memory.prevMonthExpenses
            if delta < -1 {
                compare = String(format: "Du hast bisher %.0f€ weniger ausgegeben als im Vormonat.", abs(delta))
            } else if delta > 1 {
                compare = String(format: "Du liegst %.0f€ über dem Vormonat — diese Woche etwas zurückhalten.", delta)
            } else {
                compare = "Dein Monatstempo liegt auf Vormonatsniveau."
            }
        } else {
            compare = "Noch kein Vormonatsvergleich möglich — weiter erfassen."
        }

        return FinanceInsight(
            title: "Wochenbudget",
            rows: [
                ("Diese Woche max.", String(format: "%.0f€", weeklyAllow)),
                ("Heute max.", String(format: "%.0f€", todayAllow)),
                ("Tage übrig (Woche)", "\(daysLeftInWeek)"),
                ("Verfügbar", String(format: "%.0f€", remainingMonth))
            ],
            insight: "\(compare) Dein typischer Tag: \(String(format: "%.0f€", memory.typicalDailySpend)).",
            followUpActions: [.affordability, .monthCompare, .spendingPace],
            chartSeries: [
                (label: "Woche", value: max(weeklyAllow, 1)),
                (label: "Ø Tag", value: max(memory.typicalDailySpend, 1))
            ],
            chartStyle: .bar
        )
    }

    static func vacationAffordability(store: FinanceStore) -> FinanceInsight {
        let memory = AssistantMemory.build(from: store)
        let estimate = max(memory.typicalDailySpend * 7, 400)
        let monthsToSave = memory.availableBalance >= estimate
            ? 0
            : Int(ceil((estimate - memory.availableBalance) / max(store.monthlySavingsRate, 50)))

        var rows: [(String, String)] = [
            ("Geschätzter Kurztrip", String(format: "~%.0f€", estimate)),
            ("Verfügbar", String(format: "%.0f€", memory.availableBalance))
        ]
        if let goal = memory.primaryGoalName {
            rows.append(("Aktives Sparziel", "\(goal) · \(memory.primaryGoalProgress)%"))
        }

        let insight: String
        if memory.availableBalance >= estimate * 1.2 {
            insight = String(
                format: "Ein Kurztrip (~%.0f€) wäre machbar, ohne dich komplett leer zu machen.",
                estimate
            )
        } else if memory.availableBalance >= estimate {
            insight = "Knapp machbar — plane einen Puffer und pausiere große Extra-Ausgaben."
        } else {
            insight = String(
                format: "Noch nicht. Bei deinem Spar-Tempo brauchst du etwa %d Monat%@, bis ein Trip von ~%.0f€ komfortabel wird.",
                max(monthsToSave, 1),
                monthsToSave == 1 ? "" : "e",
                estimate
            )
        }

        return FinanceInsight(
            title: "Urlaub leisten?",
            rows: rows,
            insight: insight,
            followUpActions: [.whatIf, .goalsProgress, .savingsTips]
        )
    }

    static func whyMoreSpending(store: FinanceStore) -> FinanceInsight {
        let memory = AssistantMemory.build(from: store)
        let delta = memory.monthExpenses - memory.prevMonthExpenses
        let pct = memory.prevMonthExpenses > 0 ? delta / memory.prevMonthExpenses * 100 : 0

        var rows: [(String, String)] = [
            ("Dieser Monat", String(format: "%.0f€", memory.monthExpenses)),
            ("Vormonat", String(format: "%.0f€", memory.prevMonthExpenses)),
            ("Differenz", String(format: "%+.0f€ (%.0f%%)", delta, pct))
        ]

        if let top = memory.topCategories.first {
            rows.append(("Treiber", top.name))
        }
        if let sub = memory.topSubcategory {
            rows.append(("Feinheit", sub))
        }
        if let wd = memory.expensiveWeekday {
            rows.append(("Teuerster Tag", wd))
        }

        let insight: String
        if memory.prevMonthExpenses <= 0 {
            insight = "Noch kein Vormonat zum Vergleich — gib weiter Buchungen ein."
        } else if delta > 0, let top = memory.topCategories.first {
            insight = String(
                format: "Du hast %.0f€ mehr ausgegeben als letzten Monat — vor allem bei %@. %@",
                delta,
                top.name,
                memory.expensiveWeekday.map { "\($0) ist typischerweise dein teuerster Tag." } ?? ""
            )
        } else if delta < 0 {
            insight = String(format: "Gute Nachricht: Du hast %.0f€ weniger ausgegeben als letzten Monat.", abs(delta))
        } else {
            insight = "Dein Ausgaben-Niveau ist stabil gegenüber dem Vormonat."
        }

        return FinanceInsight(
            title: "Warum mehr ausgegeben?",
            rows: rows,
            insight: insight.trimmingCharacters(in: .whitespaces),
            followUpActions: [.byCategory, .unusualSpending, .savingsTips],
            chartSeries: [
                (label: "Vormonat", value: memory.prevMonthExpenses),
                (label: "Monat", value: memory.monthExpenses)
            ],
            chartStyle: .bar
        )
    }

    static func whatIf(store: FinanceStore, extraMonthlySavings: Double = 50) -> FinanceInsight {
        let scenarios = FutureSimulationEngine.whatIfScenarios(store: store, extraMonthlySavings: extraMonthlySavings)
        let rows = scenarios.map { ($0.title, $0.resultLabel) }
        let best = scenarios.first
        return FinanceInsight(
            title: "Was passiert wenn…",
            rows: rows,
            insight: best?.detail ?? "Ändere eine Gewohnheit — die Simulation zeigt den Effekt auf deine Ziele.",
            followUpActions: [.goalsProgress, .savingsTips, .financeReport]
        )
    }

    private static func inferredAmount(from hint: String, memory: AssistantMemory) -> Double {
        if let parsed = SmartInputParser.shared.parseSingle(hint)?.amount { return parsed }
        let lower = hint.lowercased()
        if lower.contains("urlaub") || lower.contains("reise") {
            return max(memory.typicalDailySpend * 7, 400)
        }
        if lower.contains("handy") || lower.contains("iphone") { return 800 }
        if lower.contains("ps5") || lower.contains("konsole") { return 500 }
        return 0
    }
}
