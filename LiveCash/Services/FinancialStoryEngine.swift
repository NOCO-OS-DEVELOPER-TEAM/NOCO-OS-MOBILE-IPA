import Foundation
import CoreLocation

enum StoryPeriod: String, CaseIterable, Identifiable {
    case day = "Tag"
    case week = "Woche"
    case month = "Monat"
    case year = "Jahr"

    var id: String { rawValue }
}

enum StorySceneKind: Equatable {
    case greeting
    case mapHotspot
    case categoryChart
    case goalsProgress
    case personalInsight
    case tip
}

struct StorySlide: Identifiable, Equatable {
    let id: String
    let kind: StorySceneKind
    let title: String
    let headline: String
    let detail: String
    let value: String
    let isIncome: Bool
    let accentEmoji: String?
    let chartSeries: [(String, Double)]?
    let mapLatitude: Double?
    let mapLongitude: Double?
    let mapLabel: String?
    let periodLabel: String
    let displayAmount: Double?

    init(
        kind: StorySceneKind,
        title: String,
        headline: String,
        detail: String,
        value: String,
        isIncome: Bool = false,
        accentEmoji: String? = nil,
        chartSeries: [(String, Double)]? = nil,
        mapLatitude: Double? = nil,
        mapLongitude: Double? = nil,
        mapLabel: String? = nil,
        periodLabel: String = "",
        displayAmount: Double? = nil
    ) {
        self.kind = kind
        self.id = "\(kind)-\(title)-\(headline)-\(value)-\(periodLabel)"
        self.title = title
        self.headline = headline
        self.detail = detail
        self.value = value
        self.isIncome = isIncome
        self.accentEmoji = accentEmoji
        self.chartSeries = chartSeries
        self.mapLatitude = mapLatitude
        self.mapLongitude = mapLongitude
        self.mapLabel = mapLabel
        self.periodLabel = periodLabel
        self.displayAmount = displayAmount
    }

    var mapCoordinate: CLLocationCoordinate2D? {
        guard let mapLatitude, let mapLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: mapLatitude, longitude: mapLongitude)
    }

    static func == (lhs: StorySlide, rhs: StorySlide) -> Bool {
        lhs.id == rhs.id
            && lhs.kind == rhs.kind
            && lhs.value == rhs.value
            && lhs.headline == rhs.headline
            && lhs.displayAmount == rhs.displayAmount
    }
}

enum FinancialStoryEngine {
    @MainActor
    static func slides(for period: StoryPeriod, store: FinanceStore) -> [StorySlide] {
        let range = dateRange(for: period)
        let label = periodLabel(for: period, range: range)
        let txs = store.accountFilteredTransactions.filter { $0.date >= range.start && $0.date <= range.end }
        let expenses = txs.filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }
        let income = txs.filter { $0.type == .income }
        let totalExp = expenses.reduce(0) { $0 + $1.amount }
        let totalInc = income.reduce(0) { $0 + $1.amount }
        let saved = max(0, totalInc - totalExp)

        var scenes: [StorySlide] = []

        scenes.append(greetingScene(
            period: period,
            periodLabel: label,
            totalIncome: totalInc,
            totalExpenses: totalExp,
            saved: saved,
            store: store
        ))

        let kinds = sceneKinds(for: period)
        for kind in kinds where kind != .greeting {
            if let slide = buildScene(
                kind,
                period: period,
                periodLabel: label,
                range: range,
                expenses: expenses,
                income: income,
                totalExp: totalExp,
                totalInc: totalInc,
                saved: saved,
                store: store
            ) {
                scenes.append(slide)
            }
        }

        return scenes
    }

    // MARK: - Scene plan

    private static func sceneKinds(for period: StoryPeriod) -> [StorySceneKind] {
        switch period {
        case .month:
            return [.greeting, .mapHotspot, .categoryChart, .goalsProgress, .personalInsight, .tip]
        case .week:
            return [.greeting, .mapHotspot, .categoryChart, .goalsProgress, .personalInsight, .tip]
        case .year:
            return [.greeting, .categoryChart, .goalsProgress, .personalInsight, .tip]
        case .day:
            return [.greeting, .categoryChart, .personalInsight, .tip]
        }
    }

    @MainActor
    private static func buildScene(
        _ kind: StorySceneKind,
        period: StoryPeriod,
        periodLabel: String,
        range: (start: Date, end: Date),
        expenses: [Transaction],
        income: [Transaction],
        totalExp: Double,
        totalInc: Double,
        saved: Double,
        store: FinanceStore
    ) -> StorySlide? {
        switch kind {
        case .greeting:
            return nil
        case .mapHotspot:
            return mapScene(expenses: expenses, periodLabel: periodLabel)
        case .categoryChart:
            return categoryScene(expenses: expenses, period: period, periodLabel: periodLabel, totalExp: totalExp)
        case .goalsProgress:
            return goalsScene(store: store, periodLabel: periodLabel)
        case .personalInsight:
            return insightScene(
                period: period,
                periodLabel: periodLabel,
                range: range,
                saved: saved,
                totalExp: totalExp,
                totalInc: totalInc,
                expenses: expenses,
                store: store
            )
        case .tip:
            return tipScene(store: store, periodLabel: periodLabel)
        }
    }

    // MARK: - Individual scenes

    @MainActor
    private static func greetingScene(
        period: StoryPeriod,
        periodLabel: String,
        totalIncome: Double,
        totalExpenses: Double,
        saved: Double,
        store: FinanceStore
    ) -> StorySlide {
        let title: String
        let headline: String
        let detail: String
        let highlight: Double
        let isIncome: Bool

        switch period {
        case .day:
            title = "Dein Tag"
            headline = periodLabel
            let todayExp = store.todayExpenses
            highlight = todayExp
            isIncome = false
            if todayExp == 0 {
                detail = "Noch keine Ausgaben heute — stark!"
            } else {
                detail = String(format: "💰 %.0f€ rein · 💸 %.0f€ raus heute", totalIncome, todayExp)
            }
        case .week:
            title = "Deine Woche"
            headline = periodLabel
            highlight = saved
            isIncome = saved > 0
            detail = String(format: "💰 %.0f€ rein · 💸 %.0f€ raus · 🎯 %.0f€ übrig", totalIncome, totalExpenses, saved)
        case .month:
            title = "Dein Monat"
            headline = periodLabel
            highlight = saved
            isIncome = true
            detail = String(format: "💰 %.0f€ rein · 💸 %.0f€ raus · 🎯 %.0f€ gespart", totalIncome, totalExpenses, saved)
        case .year:
            title = "Dein Jahr"
            headline = periodLabel
            highlight = saved
            isIncome = saved > 0
            detail = String(format: "💰 %.0f€ rein · 💸 %.0f€ raus · 🎯 %.0f€ Netto", totalIncome, totalExpenses, saved)
        }

        return StorySlide(
            kind: .greeting,
            title: title,
            headline: headline,
            detail: detail,
            value: String(format: "%.0f€", highlight),
            isIncome: isIncome,
            accentEmoji: isIncome ? "💰" : "📊",
            periodLabel: periodLabel,
            displayAmount: highlight
        )
    }

    private static func mapScene(expenses: [Transaction], periodLabel: String) -> StorySlide? {
        guard let hotspot = mostExpensivePlace(expenses: expenses) else { return nil }

        return StorySlide(
            kind: .mapHotspot,
            title: "Teuerster Ort",
            headline: hotspot.label,
            detail: String(format: "%.0f€ ausgegeben — dein größter Hotspot in diesem Zeitraum.", hotspot.amount),
            value: String(format: "%.0f€", hotspot.amount),
            accentEmoji: "📍",
            mapLatitude: hotspot.latitude,
            mapLongitude: hotspot.longitude,
            mapLabel: hotspot.label,
            periodLabel: periodLabel,
            displayAmount: hotspot.amount
        )
    }

    private static func categoryScene(
        expenses: [Transaction],
        period: StoryPeriod,
        periodLabel: String,
        totalExp: Double
    ) -> StorySlide? {
        guard totalExp > 0 else { return nil }

        let series = topCategories(expenses: expenses, limit: period == .day ? 4 : 5)
        guard !series.isEmpty else { return nil }

        let top = series[0]
        let headline = period == .day ? "Heute nach Kategorie" : "Top-Kategorien"
        let detail = String(format: "%@ führt mit %.0f€ — %.0f%% deiner Ausgaben.", top.0, top.1, (top.1 / totalExp) * 100)

        return StorySlide(
            kind: .categoryChart,
            title: "Ausgaben-Mix",
            headline: headline,
            detail: detail,
            value: String(format: "%.0f€", totalExp),
            chartSeries: series,
            periodLabel: periodLabel,
            displayAmount: totalExp
        )
    }

    @MainActor
    private static func goalsScene(store: FinanceStore, periodLabel: String) -> StorySlide? {
        guard let goal = store.activeGoals.max(by: { $0.progress < $1.progress }) ?? store.goals.first else {
            return StorySlide(
                kind: .goalsProgress,
                title: "Sparziele",
                headline: "Noch kein Ziel",
                detail: "Erstelle ein Sparziel — dann feiern wir hier deinen Fortschritt.",
                value: "0%",
                isIncome: true,
                accentEmoji: "🎯",
                chartSeries: [("Start", 0)],
                periodLabel: periodLabel
            )
        }

        let pct = Double(goal.progressPercent)
        let paceDetail: String
        switch goal.paceStatus(referenceMonthlySavings: store.monthlySavingsRate) {
        case .fast:
            paceDetail = "Du liegst über Plan — weiter so!"
        case .slow:
            paceDetail = "Ein kleiner Schub bringt dich schneller ans Ziel."
        case .onTrack:
            paceDetail = "Dein Tempo passt — Schritt für Schritt."
        case .noDeadline:
            paceDetail = "Jeder Beitrag zählt Richtung \(goal.name)."
        }

        return StorySlide(
            kind: .goalsProgress,
            title: "Sparziel",
            headline: goal.name,
            detail: paceDetail,
            value: "\(goal.progressPercent)%",
            isIncome: true,
            accentEmoji: "🎯",
            chartSeries: [
                ("Erreicht", pct),
                ("Offen", max(100 - pct, 0))
            ],
            periodLabel: periodLabel,
            displayAmount: goal.currentAmount
        )
    }

    @MainActor
    private static func insightScene(
        period: StoryPeriod,
        periodLabel: String,
        range: (start: Date, end: Date),
        saved: Double,
        totalExp: Double,
        totalInc: Double,
        expenses: [Transaction],
        store: FinanceStore
    ) -> StorySlide? {
        let prevRange = previousRange(for: period, before: range.start)
        let prevTxs = store.accountFilteredTransactions.filter { $0.date >= prevRange.start && $0.date < prevRange.end }
        let prevExp = prevTxs.filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }.reduce(0) { $0 + $1.amount }
        let prevInc = prevTxs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let prevSaved = max(0, prevInc - prevExp)

        let headline: String
        let detail: String
        let isIncome: Bool
        let value: String

        if period == .day {
            let avgDaily = store.currentMonthExpenses / Double(max(Calendar.current.component(.day, from: Date()), 1))
            let todayExp = store.todayExpenses
            if avgDaily > 0 {
                let pct = ((todayExp - avgDaily) / avgDaily) * 100
                if pct <= -10 {
                    headline = "Unter deinem Tages-Schnitt"
                    detail = String(format: "Du gibst heute %.0f%% weniger aus als üblich — sparsam!", abs(pct))
                    isIncome = true
                    value = String(format: "%+.0f%%", pct)
                } else if pct >= 15 {
                    headline = "Über deinem Tages-Schnitt"
                    detail = String(format: "Heute %.0f%% mehr als dein Monats-Durchschnitt.", pct)
                    isIncome = false
                    value = String(format: "%+.0f%%", pct)
                } else {
                    headline = "Dein Tages-Tempo"
                    detail = "Heute liegst du nah an deinem üblichen Ausgaben-Niveau."
                    isIncome = false
                    value = String(format: "%.0f€", todayExp)
                }
            } else {
                headline = expenses.isEmpty ? "Ruhiger Tag" : "Dein Tag im Blick"
                detail = expenses.isEmpty ? "Keine Ausgaben erfasst — perfekt für dein Budget." : "\(expenses.count) Buchungen heute."
                isIncome = expenses.isEmpty
                value = String(format: "%.0f€", totalExp)
            }
        } else if prevSaved > 0 || saved > 0 {
            let delta = saved - prevSaved
            if delta > 5 {
                headline = period == .month
                    ? "Diesen Monat hast du deutlich besser gespart."
                    : "Mehr übrig als zuvor"
                detail = String(format: "Du hast %.0f€ mehr übrig als im vorherigen Zeitraum.", delta)
                isIncome = true
                value = String(format: "+%.0f€", delta)
            } else if delta < -5 {
                headline = "Weniger Puffer als zuvor"
                detail = String(format: "%.0f€ weniger übrig als im vorherigen Zeitraum.", abs(delta))
                isIncome = false
                value = String(format: "%.0f€", delta)
            } else if prevExp > 0 {
                let pct = ((totalExp - prevExp) / prevExp) * 100
                if pct <= -8 {
                    headline = "Weniger ausgegeben"
                    detail = String(format: "Du gibst %.0f%% weniger aus als zuvor — starke Disziplin.", abs(pct))
                    isIncome = true
                    value = String(format: "%+.0f%%", -pct)
                } else if pct >= 8 {
                    headline = "Mehr ausgegeben"
                    detail = String(format: "%.0f%% mehr Ausgaben als im vorherigen Zeitraum.", pct)
                    isIncome = false
                    value = String(format: "%+.0f%%", pct)
                } else {
                    headline = "Stabiles Tempo"
                    detail = "Deine Ausgaben liegen auf ähnlichem Niveau wie zuvor."
                    isIncome = false
                    value = String(format: "%.0f€", totalExp)
                }
            } else {
                headline = saved > 0 ? "Positives Saldo" : "Ausgaben im Blick"
                detail = saved > 0
                    ? String(format: "Du hast %.0f€ mehr eingenommen als ausgegeben.", saved)
                    : "\(expenses.count) Buchungen in diesem Zeitraum."
                isIncome = saved > 0
                value = String(format: "%.0f€", saved)
            }
        } else if prevExp > 0 {
            let pct = ((totalExp - prevExp) / prevExp) * 100
            headline = pct < 0 ? "Sparsamer unterwegs" : "Ausgaben gestiegen"
            detail = pct < 0
                ? String(format: "Du gibst %.0f%% weniger aus als zuvor.", abs(pct))
                : String(format: "%.0f%% mehr Ausgaben als zuvor.", pct)
            isIncome = pct < 0
            value = String(format: "%+.0f%%", pct)
        } else {
            let lines = PersonalFinanceInsights.personalInsightLines(store: store)
            headline = lines.first ?? "Dein Muster"
            detail = lines.dropFirst().first ?? "Live Cash lernt deine Gewohnheiten — weiter erfassen für bessere Insights."
            isIncome = saved >= 0
            value = String(format: "%.0f€", saved)
        }

        return StorySlide(
            kind: .personalInsight,
            title: "Persönlich",
            headline: headline,
            detail: detail,
            value: value,
            isIncome: isIncome,
            accentEmoji: isIncome ? "✨" : "💡",
            periodLabel: periodLabel,
            displayAmount: saved > 0 ? saved : nil
        )
    }

    @MainActor
    private static func tipScene(store: FinanceStore, periodLabel: String) -> StorySlide {
        if let goal = store.activeGoals.first, store.monthlySavingsRate > 0 {
            let remaining = max(goal.targetAmount - goal.currentAmount, 0)
            let weeklyRate = max(store.monthlySavingsRate / 4, 1)
            let weeksAtCurrent = remaining / weeklyRate
            let boostedWeekly = weeklyRate + 20
            let weeksWithBoost = remaining / boostedWeekly
            let weeksSaved = max(weeksAtCurrent - weeksWithBoost, 1)

            return StorySlide(
                kind: .tip,
                title: "Unser Tipp",
                headline: "20 € weniger pro Woche",
                detail: String(
                    format: "20 € weniger pro Woche würden dein Ziel „%@“ ca. %.0f Wochen früher erreichen.",
                    goal.name,
                    weeksSaved
                ),
                value: "−20€/Wo",
                isIncome: true,
                accentEmoji: "✨",
                periodLabel: periodLabel
            )
        }

        if store.currentMonthExpenses > 0 {
            return StorySlide(
                kind: .tip,
                title: "Unser Tipp",
                headline: "Kleine Gewohnheiten",
                detail: "Erfasse jede Ausgabe sofort — so erkennt Live Cash Muster und gibt bessere Tipps.",
                value: "1×/Tag",
                isIncome: true,
                accentEmoji: "✨",
                periodLabel: periodLabel
            )
        }

        return StorySlide(
            kind: .tip,
            title: "Unser Tipp",
            headline: "Starte mit einem Ziel",
            detail: "Lege ein Sparziel an — dann zeigen wir dir hier, wie schneller Sparen dein Ziel näher bringt.",
            value: "🎯",
            isIncome: true,
            accentEmoji: "✨",
            periodLabel: periodLabel
        )
    }

    // MARK: - Helpers

    private static func mostExpensivePlace(expenses: [Transaction]) -> (label: String, amount: Double, latitude: Double?, longitude: Double?)? {
        struct PlaceKey: Hashable {
            let label: String
            let lat: Double?
            let lon: Double?
        }

        var totals: [PlaceKey: Double] = [:]
        for tx in expenses {
            let label = tx.location?.label?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? (tx.merchant.isEmpty ? nil : tx.merchant)
            guard let placeLabel = label, !placeLabel.isEmpty else { continue }
            let key = PlaceKey(
                label: placeLabel,
                lat: tx.location?.latitude,
                lon: tx.location?.longitude
            )
            totals[key, default: 0] += tx.amount
        }

        guard let best = totals.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key.label, best.value, best.key.lat, best.key.lon)
    }

    private static func topCategories(expenses: [Transaction], limit: Int) -> [(String, Double)] {
        Dictionary(grouping: expenses, by: \.category)
            .map { ($0.key.rawValue, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { ($0.0, $0.1) }
    }

    private static func periodLabel(for period: StoryPeriod, range: (start: Date, end: Date)) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        switch period {
        case .day:
            formatter.dateFormat = "EEEE, d. MMMM"
            return formatter.string(from: range.end)
        case .week:
            return "Letzte 7 Tage"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: range.start)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: range.start)
        }
    }

    private static func previousRange(for period: StoryPeriod, before start: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch period {
        case .day:
            let prev = cal.date(byAdding: .day, value: -1, to: start) ?? start
            return (prev, start)
        case .week:
            let prev = cal.date(byAdding: .day, value: -7, to: start) ?? start
            return (prev, start)
        case .month:
            let prev = cal.date(byAdding: .month, value: -1, to: start) ?? start
            return (prev, start)
        case .year:
            let prev = cal.date(byAdding: .year, value: -1, to: start) ?? start
            return (prev, start)
        }
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
