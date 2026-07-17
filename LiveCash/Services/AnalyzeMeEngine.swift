import Foundation

struct AnalyzeMeCategoryShare: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var percent: Double
    var amount: Double
}

struct AnalyzeMeReport: Equatable {
    var financeType: String
    var typeSubtitle: String
    var personalityLine: String
    var score: Int
    var strengths: [String]
    var weaknesses: [String]
    var suggestions: [String]
    var categoryShares: [AnalyzeMeCategoryShare]
    var savingsRatePercent: Double
    var monthCompareDeltaPercent: Double
    var goalCompletionPercent: Double
    var futureOutlook: String
    var facts: [String]
    var expensiveWeekday: String?
    var foodSpendPercent: Double
    var loginStreak: Int
}

@MainActor
enum AnalyzeMeEngine {
    static func matchesQuery(_ text: String) -> Bool {
        let n = text.lowercased()
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")
        let triggers = [
            "analyze me", "analysiere mich", "analyse mich", "wer bin ich finanziell",
            "finanz personlichkeit", "finanzpersönlichkeit", "finanz profil", "mein finanztyp",
            "wie gut spare ich", "meine groesste schwaeche", "größte schwäche",
            "was sollte ich aendern", "was sollte ich ändern", "wie sieht meine zukunft",
            "wie viel besser bin ich", "financial personality", "mein score"
        ]
        return triggers.contains(where: { n.contains($0) })
    }

    static func analyze(store: FinanceStore) -> AnalyzeMeReport {
        let cal = Calendar.current
        let now = Date()
        let expenses = store.accountFilteredTransactions.filter {
            $0.type == .expense && !FinanceStore.isGoalContribution($0)
        }
        let incomes = store.accountFilteredTransactions.filter {
            $0.type == .income && !FinanceStore.isGoalContribution($0)
        }
        let monthExpenses = store.currentMonthExpenses
        let monthIncome = store.currentMonthIncome
        let savingsThisMonth = max(0, monthIncome - monthExpenses) + goalContributionsThisMonth(store: store)
        let savingsRate = monthIncome > 0 ? min(100, max(0, (savingsThisMonth / monthIncome) * 100)) : 0

        let categoryTotals = Dictionary(grouping: expenses.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
        let monthExpenseTotal = max(categoryTotals.reduce(0) { $0 + $1.1 }, 1)
        let shares = categoryTotals.prefix(5).map { cat, amount in
            (name: cat.rawValue, percent: amount / monthExpenseTotal * 100, amount: amount)
        }

        let foodAmount = categoryTotals.first { $0.0 == .food }?.1
            ?? categoryTotals.first { $0.0 == .entertainment }?.1
            ?? 0
        let foodPercent = foodAmount / monthExpenseTotal * 100

        let weekday = mostExpensiveWeekday(expenses: expenses)
        let postPaydaySpend = spendsMoreAfterIncome(expenses: expenses, incomes: incomes)
        let loggingHabit = typicalLoggingLabel(expenses: expenses)
        let goalActive = store.activeGoals.count
        let goalCompleted = store.completedGoals.count
        let goalTotal = max(goalActive + goalCompleted, 1)
        let goalCompletion = Double(goalCompleted) / Double(goalTotal) * 100
        let goalUsage = !store.goals.isEmpty
        let contributionCount = store.accountFilteredTransactions.filter {
            $0.rawInput?.hasPrefix("goal:") == true || $0.merchant.hasPrefix("Sparziel:")
        }.count

        let prev = cal.date(byAdding: .month, value: -1, to: now) ?? now
        let prevExpenses = store.transactions(inMonth: prev)
            .filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }
            .reduce(0) { $0 + $1.amount }
        let monthDelta = prevExpenses > 0 ? ((monthExpenses - prevExpenses) / prevExpenses) * 100 : 0

        let missedDays = estimateMissedLoggingDays(store: store)
        let smallExpenseShare = smallExpenseRatio(expenses: expenses)

        var score = 55
        score += Int(min(savingsRate, 40) * 0.45)
        if goalUsage { score += 8 }
        if contributionCount >= 3 { score += 6 }
        if store.loginReward.loginStreakDays >= 7 { score += 6 }
        else if store.loginReward.loginStreakDays >= 3 { score += 3 }
        if monthDelta < -5 { score += 5 }
        if monthDelta > 20 { score -= 8 }
        if foodPercent > 35 { score -= 6 }
        if postPaydaySpend { score -= 5 }
        if missedDays >= 5 { score -= 7 }
        if smallExpenseShare > 0.45 { score -= 5 }
        if store.subscriptions.count >= 4 { score -= 3 }
        if store.spendingLimits.enabled { score += 4 }
        score = min(98, max(18, score))

        let type = financeType(
            savingsRate: savingsRate,
            foodPercent: foodPercent,
            goalUsage: goalUsage,
            postPayday: postPaydaySpend,
            smallShare: smallExpenseShare,
            score: score
        )

        var strengths: [String] = []
        var weaknesses: [String] = []
        var suggestions: [String] = []

        if savingsRate >= 15 { strengths.append("Spart regelmäßig") }
        if goalUsage { strengths.append("Nutzt Sparziele aktiv") }
        if store.loginReward.loginStreakDays >= 5 { strengths.append("Öffnet die App konsequent") }
        if monthDelta <= 0 && prevExpenses > 0 { strengths.append("Ausgaben unter oder auf Vormonatsniveau") }
        if expenses.count >= 15 { strengths.append("Gute Übersicht durch viele erfasste Buchungen") }
        if strengths.isEmpty { strengths.append("Bereit, das Finanzverhalten klarer zu machen") }

        if foodPercent >= 20 {
            weaknesses.append(String(format: "%.0f%% der Ausgaben gehen für Essen/Freizeit drauf", foodPercent))
        }
        if smallExpenseShare > 0.35 { weaknesses.append("Viele kleine Ausgaben") }
        if missedDays >= 4 { weaknesses.append("Vergisst manchmal Buchungen einzutragen") }
        if postPaydaySpend { weaknesses.append("Gibt nach Gehaltseingängen mehr aus") }
        if store.activeGoals.contains(where: { $0.paceStatus(referenceMonthlySavings: store.monthlySavingsRate) == .slow }) {
            weaknesses.append("Liegt bei mindestens einem Sparziel hinter dem Plan")
        }
        if weaknesses.isEmpty { weaknesses.append("Noch zu wenig Daten für klare Schwächen — weiter erfassen") }

        if foodPercent >= 20 {
            suggestions.append("Setze ein wöchentliches Essens-Limit und prüfe es freitags.")
        }
        if smallExpenseShare > 0.35 {
            suggestions.append("Bündele Kleinstausgaben (z. B. max. 1–2 „Sonstiges“-Blöcke pro Woche).")
        }
        if !goalUsage {
            suggestions.append("Lege ein konkretes Sparziel an — das steigert die Sparquote messbar.")
        } else if let goal = store.activeGoals.first {
            suggestions.append(String(format: "Überweise wöchentlich 10€ zu „%@“ — Automatismus schlägt Motivation.", goal.name))
        }
        if postPaydaySpend {
            suggestions.append("Am Gehaltstag zuerst sparen, dann ausgeben (Pay-yourself-first).")
        }
        if missedDays >= 4 {
            suggestions.append("Abend-Reminder nutzen: 30 Sekunden reichen für die Tagesbuchungen.")
        }
        if suggestions.isEmpty {
            suggestions.append("Halte den aktuellen Kurs und prüfe monatlich die Top-Kategorie.")
        }

        let projected = store.monthlySavingsRate > 0 ? store.monthlySavingsRate * 12 : savingsThisMonth * 12
        let future = String(
            format: "Wenn du so weitermachst, wirst du dein aktuelles Sparverhalten in den nächsten 12 Monaten wahrscheinlich beibehalten und etwa %.0f€ sparen.",
            max(projected, 0)
        )

        var facts: [String] = []
        if let weekday {
            facts.append("\(weekday) ist dein teuerster Tag.")
        }
        facts.append(String(format: "Sparquote diesen Monat: %.0f%%.", savingsRate))
        if foodPercent > 5 {
            facts.append(String(format: "%.0f%% deiner Ausgaben gehen für %@ drauf.", foodPercent, shares.first?.name ?? "Essen"))
        }
        if postPaydaySpend {
            facts.append("Du gibst nach Gehaltseingängen typischerweise mehr aus.")
        }
        facts.append("Du trägst Ausgaben meist \(loggingHabit) ein.")
        if goalUsage {
            facts.append(String(format: "Zielerreichung: %.0f%% der Sparziele abgeschlossen.", goalCompletion))
        }
        if store.loginReward.loginStreakDays > 0 {
            facts.append("Login-Serie: \(store.loginReward.loginStreakDays) Tage.")
        }

        let personality = String(
            format: "%@ — %@.",
            type.title,
            type.subtitle.lowercased()
        )

        return AnalyzeMeReport(
            financeType: type.title,
            typeSubtitle: type.subtitle,
            personalityLine: personality,
            score: score,
            strengths: Array(strengths.prefix(4)),
            weaknesses: Array(weaknesses.prefix(4)),
            suggestions: Array(suggestions.prefix(4)),
            categoryShares: shares.map {
                AnalyzeMeCategoryShare(name: $0.name, percent: $0.percent, amount: $0.amount)
            },
            savingsRatePercent: savingsRate,
            monthCompareDeltaPercent: monthDelta,
            goalCompletionPercent: goalCompletion,
            futureOutlook: future,
            facts: Array(facts.prefix(6)),
            expensiveWeekday: weekday,
            foodSpendPercent: foodPercent,
            loginStreak: store.loginReward.loginStreakDays
        )
    }

    // MARK: - Helpers

    private static func goalContributionsThisMonth(store: FinanceStore) -> Double {
        store.transactions(inMonth: Date())
            .filter { $0.rawInput?.hasPrefix("goal:") == true || ($0.merchant.hasPrefix("Sparziel:") && !$0.merchant.hasPrefix("Sparziel Entnahme:")) }
            .reduce(0) { $0 + $1.amount }
    }

    private static func mostExpensiveWeekday(expenses: [Transaction]) -> String? {
        guard expenses.count >= 8 else { return nil }
        let names = ["", "Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
        var totals: [Int: Double] = [:]
        for tx in expenses {
            let wd = Calendar.current.component(.weekday, from: tx.date)
            totals[wd, default: 0] += tx.amount
        }
        guard let peak = totals.max(by: { $0.value < $1.value }) else { return nil }
        return names[peak.key]
    }

    private static func spendsMoreAfterIncome(expenses: [Transaction], incomes: [Transaction]) -> Bool {
        guard !incomes.isEmpty, expenses.count >= 6 else { return false }
        var after: [Double] = []
        var other: [Double] = []
        for income in incomes.prefix(8) {
            let windowEnd = income.date.addingTimeInterval(60 * 60 * 72)
            for tx in expenses {
                if tx.date >= income.date && tx.date <= windowEnd {
                    after.append(tx.amount)
                } else if tx.date < income.date.addingTimeInterval(-60 * 60 * 24) {
                    other.append(tx.amount)
                }
            }
        }
        guard !after.isEmpty, !other.isEmpty else { return false }
        let avgAfter = after.reduce(0, +) / Double(after.count)
        let avgOther = other.reduce(0, +) / Double(other.count)
        return avgAfter > avgOther * 1.25
    }

    private static func typicalLoggingLabel(expenses: [Transaction]) -> String {
        guard expenses.count >= 5 else { return "unregelmäßig" }
        let hours = expenses.prefix(40).map { Calendar.current.component(.hour, from: $0.date) }
        let avg = hours.reduce(0, +) / max(hours.count, 1)
        if avg < 12 { return "vormittags" }
        if avg < 17 { return "nachmittags" }
        return "abends"
    }

    private static func estimateMissedLoggingDays(store: FinanceStore) -> Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -21, to: Date()) ?? Date()
        let daysWithTx = Set(
            store.accountFilteredTransactions
                .filter { $0.date >= start }
                .map { cal.startOfDay(for: $0.date) }
        )
        return max(0, 21 - daysWithTx.count - 7) // weekends tolerance
    }

    private static func smallExpenseRatio(expenses: [Transaction]) -> Double {
        let recent = Array(expenses.prefix(40))
        guard !recent.isEmpty else { return 0 }
        let small = recent.filter { $0.amount < 12 }.count
        return Double(small) / Double(recent.count)
    }

    private static func financeType(
        savingsRate: Double,
        foodPercent: Double,
        goalUsage: Bool,
        postPayday: Bool,
        smallShare: Double,
        score: Int
    ) -> (title: String, subtitle: String) {
        if savingsRate >= 25 && goalUsage {
            return ("Der Planer", "Motivierter Sparer mit klaren Zielen und guter Übersicht")
        }
        if foodPercent >= 30 || smallShare > 0.45 {
            return ("Der Spontane", "Motivierter Typ mit spontanen Ausgaben bei Essen und Freizeit")
        }
        if postPayday && savingsRate < 15 {
            return ("Der Impuls-Ausgeber", "Denkt oft kurzfristig nach Geldeingängen — Potenzial nach oben")
        }
        if score >= 80 {
            return ("Der Disziplinierte", "Starke Kontrolle, regelmäßiges Sparen, wenig Chaos")
        }
        if goalUsage {
            return ("Der Zielorientierte", "Nutzt Sparziele aktiv und denkt langfristig")
        }
        return ("Der Beobachter", "Baut gerade eine belastbare Finanzübersicht auf")
    }
}
