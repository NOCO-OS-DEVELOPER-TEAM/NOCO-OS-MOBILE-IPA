import Foundation

struct SimulationStep: Identifiable, Equatable {
    let id: String
    let label: String
    let projectedBalance: Double
    let explanation: String
    let weeksFromNow: Int
}

struct WhatIfScenario: Identifiable, Equatable {
    let id: String
    let title: String
    let resultLabel: String
    let detail: String
    let monthsSaved: Int
}

enum FutureSimulationEngine {
    @MainActor
    static func whatIfScenarios(store: FinanceStore, extraMonthlySavings: Double = 50) -> [WhatIfScenario] {
        let goal = store.activeGoals.first
        let remaining = goal?.remaining ?? 1000
        let currentMonthly = max(store.monthlySavingsRate, 20)
        let baselineMonths = Int(ceil(remaining / currentMonthly))

        func months(at rate: Double) -> Int {
            guard rate > 0 else { return 99 }
            return max(Int(ceil(remaining / rate)), 1)
        }

        let with50 = months(at: currentMonthly + extraMonthlySavings)
        let foodCut = months(at: currentMonthly + max(store.currentMonthExpenses * 0.1, 30))
        let cancelAbo = months(at: currentMonthly + max(store.monthlySubscriptionCost * 0.4, 10))

        var scenarios: [WhatIfScenario] = [
            WhatIfScenario(
                id: "save50",
                title: String(format: "+%.0f€/Monat sparen", extraMonthlySavings),
                resultLabel: goal.map { "\($0.name): \(max(baselineMonths - with50, 0)) Mon. früher" } ?? "+\(Int(extraMonthlySavings * 12))€/Jahr",
                detail: goal.map {
                    let saved = max(baselineMonths - with50, 0)
                    return String(format: "Du erreichst „%@“ etwa %d Monat%@ früher.", $0.name, saved, saved == 1 ? "" : "e")
                } ?? "Dein Polster wächst spürbar.",
                monthsSaved: max(baselineMonths - with50, 0)
            ),
            WhatIfScenario(
                id: "lessfood",
                title: "10 % weniger Essen",
                resultLabel: "~\(max(baselineMonths - foodCut, 0)) Mon. früher",
                detail: "Weniger Restaurant/Lieferung — Ziel früher, ohne radikal zu verzichten.",
                monthsSaved: max(baselineMonths - foodCut, 0)
            ),
            WhatIfScenario(
                id: "cancelabo",
                title: "Ein Abo kündigen",
                resultLabel: String(format: "~%.0f€/Monat frei", max(store.monthlySubscriptionCost * 0.35, 8)),
                detail: store.subscriptions.first.map {
                    "Wenn du „\($0.name)“ pausierst, kommt Geld direkt in dein Sparziel."
                } ?? "Prüfe ungenutzte Abos unter Mehr → Abonnements.",
                monthsSaved: max(baselineMonths - cancelAbo, 0)
            )
        ]

        if let goal {
            scenarios.insert(
                WhatIfScenario(
                    id: "baseline",
                    title: "Aktueller Kurs",
                    resultLabel: "~\(baselineMonths) Monate",
                    detail: String(format: "Mit %.0f€/Monat Sparrate erreichst du „%@“ in ca. %d Monaten.", currentMonthly, goal.name, baselineMonths),
                    monthsSaved: 0
                ),
                at: 0
            )
        }

        return scenarios
    }

    @MainActor
    static func steps(store: FinanceStore) -> [SimulationStep] {
        let balance = store.allTimeBalance
        let weeklyNet = store.weeklyNetCashflow
        let weeklyExpenses = store.weeklyExpenses
        let weeklyIncome = store.weeklyIncome

        let horizons: [(Int, String)] = [(1, "1 Woche"), (4, "1 Monat"), (12, "3 Monate")]

        var result = horizons.map { weeks, label -> SimulationStep in
            let projected = balance + weeklyNet * Double(weeks)
            let explanation: String
            if weeklyNet >= 0 {
                explanation = "Bei \(String(format: "%.0f€", weeklyIncome))/Woche Einnahmen und \(String(format: "%.0f€", weeklyExpenses)) Ausgaben erwartest du +\(String(format: "%.0f€", weeklyNet * Double(weeks))) in \(label.lowercased())."
            } else {
                explanation = "Dein wöchentliches Defizit von \(String(format: "%.0f€", abs(weeklyNet))) reduziert den Saldo in \(label.lowercased()) um etwa \(String(format: "%.0f€", abs(weeklyNet * Double(weeks)))). Weniger Ausgaben bei \(store.topCategoryThisMonth?.0.rawValue ?? "Top-Kategorie") würde helfen."
            }
            return SimulationStep(
                id: label,
                label: label,
                projectedBalance: projected,
                explanation: explanation,
                weeksFromNow: weeks
            )
        }

        for scenario in whatIfScenarios(store: store).prefix(3) {
            result.append(SimulationStep(
                id: scenario.id,
                label: scenario.title,
                projectedBalance: balance + Double(scenario.monthsSaved) * max(store.monthlySavingsRate, 20),
                explanation: scenario.detail,
                weeksFromNow: max(scenario.monthsSaved, 1) * 4
            ))
        }

        return result
    }
}
