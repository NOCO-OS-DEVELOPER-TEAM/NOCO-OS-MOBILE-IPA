import Foundation

struct SimulationStep: Identifiable, Equatable {
    let id: String
    let label: String
    let projectedBalance: Double
    let explanation: String
    let weeksFromNow: Int
}

enum FutureSimulationEngine {
    @MainActor
    static func steps(store: FinanceStore) -> [SimulationStep] {
        let balance = store.allTimeBalance
        let weeklyNet = store.weeklyNetCashflow
        let weeklyExpenses = store.weeklyExpenses
        let weeklyIncome = store.weeklyIncome

        let horizons: [(Int, String)] = [(1, "1 Woche"), (4, "1 Monat"), (12, "3 Monate")]

        return horizons.map { weeks, label in
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
    }
}
