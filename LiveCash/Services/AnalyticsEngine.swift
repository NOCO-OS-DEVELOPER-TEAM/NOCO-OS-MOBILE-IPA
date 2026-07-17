import Foundation
import CoreLocation

struct AnalyticsCategorySlice: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let amount: Double
    let percent: Double
    let icon: String
}

struct AnalyticsMonthBar: Identifiable, Equatable {
    var id: String { label }
    let label: String
    let amount: Double
}

struct AnalyticsCashflowEvent: Identifiable, Equatable {
    let id: String
    let date: Date
    let title: String
    let amount: Double
    let isIncome: Bool
    var runningBalance: Double
}

struct AnalyticsGoalInsight: Identifiable, Equatable {
    let id: UUID
    let name: String
    let progress: Double
    let progressPercent: Int
    let weeklyAverage: Double
    let daysRemaining: Int?
    let remaining: Double
    let neededWeekly: Double?
}

struct AnalyticsHotspot: Identifiable, Equatable {
    let id: String
    let title: String
    let amount: Double
    let intensity: MapHeatIntensity
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: AnalyticsHotspot, rhs: AnalyticsHotspot) -> Bool {
        lhs.id == rhs.id
    }
}

struct AnalyticsProfileScores: Equatable {
    let savings: Int
    let spendingControl: Int
    let planning: Int
    let overall: Int
}

struct AnalyticsReport: Equatable {
    let financeScore: Int
    let savingsRatePercent: Double
    let spendingBehaviorLabel: String
    let goalAchievementPercent: Double
    let balanceTrendLabel: String
    let categorySlices: [AnalyticsCategorySlice]
    let monthBars: [AnalyticsMonthBar]
    let monthCompareDeltaPercent: Double
    let cashflow: [AnalyticsCashflowEvent]
    let goals: [AnalyticsGoalInsight]
    let hotspots: [AnalyticsHotspot]
    let topHotspotCaption: String?
    let profile: AnalyticsProfileScores
    let monthIncome: Double
    let monthExpenses: Double
    let monthSaved: Double
}

@MainActor
enum AnalyticsEngine {
    static func report(store: FinanceStore) -> AnalyticsReport {
        let analyze = AnalyzeMeEngine.analyze(store: store)
        let cal = Calendar.current
        let now = Date()

        let monthTxs = store.transactions(inMonth: now)
            .filter { !FinanceStore.isGoalContribution($0) }
        let expenses = monthTxs.filter { $0.type == .expense }
        let totalExp = max(expenses.reduce(0) { $0 + $1.amount }, 0)
        let totalInc = monthTxs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }

        let grouped = Dictionary(grouping: expenses, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
        let denom = max(totalExp, 1)
        let slices = grouped.prefix(6).map { cat, amount in
            AnalyticsCategorySlice(
                name: cat.rawValue,
                amount: amount,
                percent: amount / denom * 100,
                icon: cat.icon
            )
        }

        let prev = cal.date(byAdding: .month, value: -1, to: now) ?? now
        let prevExp = store.transactions(inMonth: prev)
            .filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }
            .reduce(0) { $0 + $1.amount }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "MMMM"
        let bars = [
            AnalyticsMonthBar(label: formatter.string(from: prev).capitalized, amount: prevExp),
            AnalyticsMonthBar(label: formatter.string(from: now).capitalized, amount: totalExp)
        ]
        let delta = prevExp > 0 ? ((totalExp - prevExp) / prevExp) * 100 : 0

        let cashflow = buildCashflow(store: store, limit: 12)
        let goals = store.activeGoals.map { goal -> AnalyticsGoalInsight in
            let weeks = max(cal.dateComponents([.weekOfYear], from: goal.createdAt, to: now).weekOfYear ?? 1, 1)
            let weekly = goal.currentAmount / Double(weeks)
            let needed: Double? = {
                guard let days = goal.daysRemaining, days > 0 else { return nil }
                return goal.remaining / (Double(days) / 7.0)
            }()
            return AnalyticsGoalInsight(
                id: goal.id,
                name: goal.name,
                progress: goal.progress,
                progressPercent: goal.progressPercent,
                weeklyAverage: weekly,
                daysRemaining: goal.daysRemaining,
                remaining: goal.remaining,
                neededWeekly: needed
            )
        }

        let hotspots = MapHeatLayout.hotspots(from: monthTxs.filter { $0.type == .expense }, limit: 5)
        let topCaption = hotspots.first.map {
            "Dein teuerster Ort: \($0.title) — \(String(format: "%.0f€", $0.amount)) diesen Monat"
        }

        let spendLabel: String
        if delta < -10 { spendLabel = "Zurückhaltend" }
        else if delta > 15 { spendLabel = "Großzügig" }
        else { spendLabel = "Ausgeglichen" }

        let balanceLabel: String
        if store.availableBalance > store.currentMonthIncome * 0.5 {
            balanceLabel = "Stabil steigend"
        } else if store.availableBalance < 0 {
            balanceLabel = "Unter Druck"
        } else {
            balanceLabel = "Im Rahmen"
        }

        let profile = AnalyticsProfileScores(
            savings: Int(min(100, max(0, analyze.savingsRatePercent * 1.1))),
            spendingControl: Int(min(100, max(0, 100 - abs(min(delta, 40))))),
            planning: Int(min(100, max(20, analyze.goalCompletionPercent + (store.goals.isEmpty ? 0 : 25)))),
            overall: analyze.score
        )

        return AnalyticsReport(
            financeScore: analyze.score,
            savingsRatePercent: analyze.savingsRatePercent,
            spendingBehaviorLabel: spendLabel,
            goalAchievementPercent: analyze.goalCompletionPercent,
            balanceTrendLabel: balanceLabel,
            categorySlices: Array(slices),
            monthBars: bars,
            monthCompareDeltaPercent: delta,
            cashflow: cashflow,
            goals: goals,
            hotspots: hotspots,
            topHotspotCaption: topCaption,
            profile: profile,
            monthIncome: totalInc,
            monthExpenses: totalExp,
            monthSaved: max(0, totalInc - totalExp)
        )
    }

    private static func buildCashflow(store: FinanceStore, limit: Int) -> [AnalyticsCashflowEvent] {
        let monthTxs = store.transactions(inMonth: Date())
            .sorted { $0.date < $1.date }
        var running = 0.0
        var events: [AnalyticsCashflowEvent] = []
        for tx in monthTxs.prefix(40) {
            let signed = tx.type == .income ? tx.amount : -tx.amount
            running += signed
            let title: String
            if FinanceStore.isGoalContribution(tx) {
                title = tx.merchant
            } else {
                title = tx.merchant
            }
            events.append(AnalyticsCashflowEvent(
                id: tx.id.uuidString,
                date: tx.date,
                title: title,
                amount: signed,
                isIncome: tx.type == .income,
                runningBalance: running
            ))
        }
        if events.count > limit {
            return Array(events.suffix(limit))
        }
        return events
    }
}
