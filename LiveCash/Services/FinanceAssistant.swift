import Foundation

enum FinanceIntent: String, CaseIterable, Identifiable {
    case save = "sparen"
    case spendingOverview = "ausgaben"
    case overview = "übersicht"
    case subscriptions = "abos"
    case monthlySummary = "monat"
    case topExpenses = "top"
    case geography = "karte"
    case goals = "ziele"
    case trends = "trends"
    case category = "kategorie"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .save: return "Spar-Analyse"
        case .spendingOverview: return "Ausgaben-Analyse"
        case .overview: return "Finanzübersicht"
        case .subscriptions: return "Abonnements"
        case .monthlySummary: return "Monatszusammenfassung"
        case .topExpenses: return "Größte Ausgaben"
        case .geography: return "Ausgaben nach Ort"
        case .goals: return "Sparziele"
        case .trends: return "Trends & Vergleich"
        case .category: return "Kategorie-Analyse"
        }
    }
}

enum TimePeriod: Equatable {
    case today
    case yesterday
    case thisWeek
    case last7Days
    case thisMonth
    case lastMonth
    case allTime

    var label: String {
        switch self {
        case .today: return "Heute"
        case .yesterday: return "Gestern"
        case .thisWeek: return "Diese Woche"
        case .last7Days: return "Letzte 7 Tage"
        case .thisMonth: return "Dieser Monat"
        case .lastMonth: return "Letzter Monat"
        case .allTime: return "Gesamt"
        }
    }
}

enum InsightAction: String, Identifiable, Hashable {
    case topExpenses
    case biggestCategory
    case subscriptionOverview
    case monthlySummary
    case incomeVsExpense
    case topCategory
    case recentTransactions
    case goalsProgress
    case monthlySubCost
    case yearlySubCost
    case potentialSavings
    case allSubscriptions
    case totalExpenses
    case totalIncome
    case balance
    case top3Categories
    case top5Expenses
    case byCategory
    case byMerchant
    case thisWeek
    case openMap
    case expensiveAreas
    case frequentAreas
    case withoutLocation
    case last7Days
    case monthCompare
    case dailyAverage
    case spendingPace
    case savingsTips
    case unusualSpending
    case merchantBreakdown
    case categoryDetail
    case analyzeMe
    case affordability
    case weeklyBudget
    case whySpending
    case whatIf
    case financeReport
    case vacationAffordability

    var id: String { rawValue }
}

struct FinanceInsight: Identifiable {
    enum ChartStyle: Equatable {
        case donut
        case bar
        case line
    }

    let id = UUID()
    let title: String
    let rows: [(String, String)]
    let insight: String?
    let followUpActions: [InsightAction]
    let chartSeries: [(label: String, value: Double)]?
    let chartStyle: ChartStyle?

    init(
        title: String,
        rows: [(String, String)],
        insight: String?,
        followUpActions: [InsightAction] = [],
        chartSeries: [(label: String, value: Double)]? = nil,
        chartStyle: ChartStyle? = nil
    ) {
        self.title = title
        self.rows = rows
        self.insight = insight
        self.followUpActions = followUpActions
        self.chartSeries = chartSeries
        self.chartStyle = chartStyle
    }
}

struct AssistantResponse {
    enum Mode {
        case directInsight(FinanceInsight)
        case suggestions(intent: FinanceIntent, headline: String, actions: [InsightAction])
    }

    let mode: Mode
}

struct QueryContext: Equatable {
    var period: TimePeriod = .thisMonth
    var merchant: String?
    var category: FinanceCategory?
}

@MainActor
final class FinanceAssistant {
    static let shared = FinanceAssistant()

    private struct IntentRule {
        let intent: FinanceIntent
        let keywords: [String]
        let weight: Int
        let directAction: InsightAction?
    }

    private let rules: [IntentRule] = [
        IntentRule(intent: .save, keywords: ["sparen", "spartipp", "einspar", "weniger ausgeben", "geld sparen", "budget", "zurücklegen"], weight: 3, directAction: nil),
        IntentRule(intent: .spendingOverview, keywords: ["wo gebe ich", "wo gebe ich mein geld", "ausgaben", "geld aus", "ausgegeben", "wie viel ausgegeben", "was habe ich ausgegeben", "kosten"], weight: 3, directAction: .byCategory),
        IntentRule(intent: .overview, keywords: ["übersicht", "dashboard", "status", "finanzen", "wie steht", "wie sieht", "zusammenfassung"], weight: 2, directAction: .incomeVsExpense),
        IntentRule(intent: .subscriptions, keywords: ["abo", "abos", "abonnement", "wiederkehrend", "monatlich zahle", "fixkosten"], weight: 3, directAction: .monthlySubCost),
        IntentRule(intent: .monthlySummary, keywords: ["monat", "monats", "diesen monat", "monatsbericht", "monatsende"], weight: 4, directAction: .monthlySummary),
        IntentRule(intent: .topExpenses, keywords: ["top", "größte", "größten", "meiste ausgaben", "teuerste", "höchste"], weight: 3, directAction: .top5Expenses),
        IntentRule(intent: .geography, keywords: ["ort", "karte", "geo", "standort", "wo kaufe", "wo einkauf", "geldkarte"], weight: 3, directAction: .expensiveAreas),
        IntentRule(intent: .goals, keywords: ["sparziel", "ziel", "urlaub", "ansparen", "fortschritt"], weight: 3, directAction: .goalsProgress),
        IntentRule(intent: .trends, keywords: ["trend", "vergleich", "vormonat", "mehr als", "weniger als", "entwicklung"], weight: 3, directAction: .monthCompare),
        IntentRule(intent: .category, keywords: ["lebensmittel", "essen", "transport", "einkaufen", "unterhaltung", "kategorie"], weight: 2, directAction: .byCategory),
        IntentRule(intent: .overview, keywords: ["analyze me", "analysiere mich", "wer bin ich finanziell", "finanztyp", "finanz persönlichkeit"], weight: 5, directAction: .analyzeMe)
    ]

    private let merchantKeywords = ["netflix", "spotify", "amazon", "lidl", "aldi", "rewe", "dm", "apple", "google", "disney", "prime"]

    // MARK: - Public API

    func respond(to input: String, store: FinanceStore) -> AssistantResponse {
        let normalized = normalize(input)
        let context = parseContext(from: normalized)

        // Decision answers first — personal, not "bitte Ausgabe eingeben"
        if (normalized.contains("urlaub") || normalized.contains("reise")) &&
            (normalized.contains("leisten") || normalized.contains("kann ich")) {
            return .init(mode: .directInsight(DecisionEngine.vacationAffordability(store: store)))
        }
        if normalized.contains("kann ich mir") || (normalized.contains("leisten") && !normalized.contains("urlaub")) {
            let amount = SmartInputParser.shared.parseSingle(input)?.amount
            return .init(mode: .directInsight(
                DecisionEngine.affordability(amount: amount, store: store, contextHint: input)
            ))
        }
        if normalized.contains("wie viel darf ich") || normalized.contains("wochenbudget") {
            return .init(mode: .directInsight(DecisionEngine.weeklyBudget(store: store)))
        }
        if normalized.contains("warum") && (normalized.contains("mehr") || normalized.contains("ausgegeben")) {
            return .init(mode: .directInsight(DecisionEngine.whyMoreSpending(store: store)))
        }
        if (normalized.contains("zu viel") || normalized.contains("zuviel")) &&
            (normalized.contains("ausgegeben") || normalized.contains("ausgebe")) {
            return .init(mode: .directInsight(DecisionEngine.whyMoreSpending(store: store)))
        }
        if normalized.contains("was passiert wenn") || normalized.contains("was waere wenn") || normalized.contains("was wäre wenn") {
            return .init(mode: .directInsight(DecisionEngine.whatIf(store: store)))
        }
        if normalized.contains("finanzbericht") {
            store.showFinanceReport = true
            return .init(mode: .directInsight(generateInsight(action: .financeReport, store: store, context: context)))
        }

        // Direktantworten für klare Analysefragen
        let directPhrases: [(String, InsightAction)] = [
            ("wo gebe ich", .byCategory),
            ("am meisten aus", .byCategory),
            ("meiste geld", .byCategory),
            ("monat zusammen", .monthlySummary),
            ("übersicht", .incomeVsExpense),
            ("wo kann ich sparen", .savingsTips),
            ("sparen", .savingsTips),
            ("abos", .monthlySubCost),
            ("abonnement", .monthlySubCost),
            ("analyze me", .analyzeMe),
            ("analysiere mich", .analyzeMe),
            ("wer bin ich finanziell", .analyzeMe),
            ("wie gut spare ich", .analyzeMe),
            ("größte schwäche", .analyzeMe),
            ("groesste schwaeche", .analyzeMe),
            ("was sollte ich ändern", .analyzeMe),
            ("was sollte ich aendern", .analyzeMe),
            ("wie sieht meine zukunft", .whatIf),
            ("besser bin ich", .analyzeMe),
            ("wochenbudget", .weeklyBudget),
            ("warum habe ich", .whySpending),
            ("zu viel ausgegeben", .whySpending),
            ("diesen monat zu viel", .whySpending)
        ]
        for (phrase, action) in directPhrases where normalized.contains(phrase) {
            let insight = generateInsight(action: action, store: store, context: context)
            return .init(mode: .directInsight(insight))
        }

        if let merchant = context.merchant ?? detectMerchant(in: normalized) {
            let insight = merchantInsight(merchant: merchant, context: context, store: store)
            return .init(mode: .directInsight(insight))
        }

        if let category = context.category ?? detectCategory(in: normalized) {
            let insight = categoryInsight(category: category, context: context, store: store)
            return .init(mode: .directInsight(insight))
        }

        if let direct = detectDirectQuestion(normalized, context: context, store: store) {
            return .init(mode: .directInsight(direct))
        }

        guard let (intent, score) = bestIntent(for: normalized), score >= 2 else {
            let fallback = contextualFallback(store: store)
            return .init(mode: .suggestions(
                intent: .overview,
                headline: fallback.headline,
                actions: fallback.actions
            ))
        }

        let rule = rules.first { $0.intent == intent }
        if score >= 5, let action = rule?.directAction {
            let insight = generateInsight(action: action, store: store, context: context)
            return .init(mode: .directInsight(insight))
        }

        let headline = contextualHeadline(for: intent, store: store)
        let actions = rankedSuggestions(for: intent, store: store)
        return .init(mode: .suggestions(intent: intent, headline: headline, actions: actions))
    }

    func matchIntent(_ input: String) -> FinanceIntent? {
        bestIntent(for: normalize(input))?.0
    }

    func suggestionButtons(for intent: FinanceIntent, store: FinanceStore) -> [InsightAction] {
        rankedSuggestions(for: intent, store: store)
    }

    func actionTitle(_ action: InsightAction) -> String {
        switch action {
        case .topExpenses: return "Top-Ausgaben"
        case .biggestCategory: return "Größte Kategorie"
        case .subscriptionOverview: return "Abo-Übersicht"
        case .monthlySummary: return "Monatszusammenfassung"
        case .incomeVsExpense: return "Einnahmen vs. Ausgaben"
        case .topCategory: return "Top-Kategorie"
        case .recentTransactions: return "Letzte Transaktionen"
        case .goalsProgress: return "Sparziele"
        case .monthlySubCost: return "Monatliche Abo-Kosten"
        case .yearlySubCost: return "Jährliche Abo-Kosten"
        case .potentialSavings: return "Einspar-Potenzial"
        case .allSubscriptions: return "Alle Abos"
        case .totalExpenses: return "Ausgaben gesamt"
        case .totalIncome: return "Einnahmen gesamt"
        case .balance: return "Saldo"
        case .top3Categories: return "Top 3 Kategorien"
        case .top5Expenses: return "Top 5 Ausgaben"
        case .byCategory: return "Nach Kategorie"
        case .byMerchant: return "Nach Händler"
        case .thisWeek: return "Diese Woche"
        case .openMap: return "Karte öffnen"
        case .expensiveAreas: return "Teuerste Orte"
        case .frequentAreas: return "Häufigste Orte"
        case .withoutLocation: return "Ohne Standort"
        case .last7Days: return "Letzte 7 Tage"
        case .monthCompare: return "Monatsvergleich"
        case .dailyAverage: return "Tagesdurchschnitt"
        case .spendingPace: return "Ausgaben-Tempo"
        case .savingsTips: return "Spar-Tipps"
        case .unusualSpending: return "Ungewöhnliche Ausgaben"
        case .merchantBreakdown: return "Nach Händler"
        case .categoryDetail: return "Kategorie-Details"
        case .analyzeMe: return "Analyze Me"
        case .affordability: return "Kann ich mir das leisten?"
        case .weeklyBudget: return "Wochenbudget"
        case .whySpending: return "Warum mehr ausgegeben?"
        case .whatIf: return "Was-wäre-wenn"
        case .financeReport: return "Mein Finanzbericht"
        case .vacationAffordability: return "Urlaub leisten?"
        }
    }

    func generateInsight(action: InsightAction, store: FinanceStore, context: QueryContext = QueryContext()) -> FinanceInsight {
        let txs = transactions(for: context.period, store: store, reference: Date())

        switch action {
        case .topExpenses, .top5Expenses:
            let top = txs.filter { $0.type == .expense }.sorted { $0.amount > $1.amount }.prefix(5)
            let rows = top.map { ($0.merchant, String(format: "-%.2f€", $0.amount)) }
            let pct = shareOfExpenses(top.first?.amount ?? 0, in: txs)
            let insight: String? = rows.isEmpty ? "Noch keine Ausgaben in \(context.period.label)." :
                "Größte Ausgabe: \(top.first?.merchant ?? "") (\(pct)% deiner Ausgaben)."
            return FinanceInsight(
                title: "Top-Ausgaben · \(context.period.label)",
                rows: Array(rows),
                insight: insight,
                followUpActions: [.byCategory, .savingsTips],
                chartSeries: top.map { (label: String($0.merchant.prefix(14)), value: $0.amount) },
                chartStyle: .bar
            )

        case .biggestCategory, .topCategory, .byCategory, .top3Categories:
            return categoryBreakdownInsight(txs: txs, period: context.period, limit: action == .top3Categories ? 3 : 5)

        case .subscriptionOverview, .allSubscriptions, .monthlySubCost:
            let subs = store.subscriptions
            let rows = subs.map { ($0.name, String(format: "%.2f€/Monat", $0.monthlyCost)) }
            let total = subs.reduce(0) { $0 + $1.monthlyCost }
            let expenseShare = store.currentMonthExpenses > 0 ? (total / store.currentMonthExpenses * 100) : 0
            return FinanceInsight(
                title: "Abonnements",
                rows: rows,
                insight: subs.isEmpty ? "Keine Abos erkannt — wiederkehrende Zahlungen werden automatisch gefunden." :
                    String(format: "%.0f€/Monat · %.0f%% deiner Monatsausgaben", total, expenseShare),
                followUpActions: [.potentialSavings, .yearlySubCost]
            )

        case .yearlySubCost:
            let total = store.subscriptions.reduce(0) { $0 + $1.yearlyCost }
            let rows = store.subscriptions.map { ($0.name, String(format: "%.2f€/Jahr", $0.yearlyCost)) }
            return FinanceInsight(title: "Jährliche Abo-Kosten", rows: rows, insight: String(format: "Gesamt: %.2f€ pro Jahr", total), followUpActions: [.potentialSavings])

        case .potentialSavings, .savingsTips:
            return savingsInsight(store: store)

        case .monthlySummary, .totalExpenses, .totalIncome, .balance, .incomeVsExpense:
            return summaryInsight(txs: txs, period: context.period, store: store)

        case .recentTransactions:
            let recent = store.transactions.prefix(8)
            let rows = recent.map { ($0.merchant, $0.formattedAmount) }
            return FinanceInsight(title: "Letzte Transaktionen", rows: Array(rows), insight: nil, followUpActions: [.top5Expenses])

        case .goalsProgress:
            let rows = store.goals.map {
                ($0.name, "\($0.progressPercent)% · \(String(format: "%.0f€", $0.currentAmount))/\(String(format: "%.0f€", $0.targetAmount))")
            }
            var insightLines = PersonalFinanceInsights.personalInsightLines(store: store)
            if insightLines.isEmpty {
                if let next = store.activeGoals.min(by: { $0.remaining < $1.remaining }) {
                    insightLines = ["Nächstes Ziel: \(next.name) — noch \(String(format: "%.0f€", next.remaining))."]
                } else {
                    insightLines = ["Lege ein Sparziel unter „Mehr“ an."]
                }
            }
            let chartSeries = store.goals.map { (label: String($0.name.prefix(12)), value: Double($0.progressPercent)) }
            return FinanceInsight(
                title: "Sparziele",
                rows: rows.isEmpty ? [("—", "Noch keine Ziele")] : rows,
                insight: insightLines.joined(separator: " "),
                followUpActions: [.savingsTips, .monthCompare],
                chartSeries: chartSeries.isEmpty ? nil : chartSeries,
                chartStyle: chartSeries.isEmpty ? nil : .bar
            )

        case .byMerchant, .merchantBreakdown:
            let grouped = Dictionary(grouping: txs.filter { $0.type == .expense }, by: \.merchant)
            let sorted = grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }.sorted { $0.1 > $1.1 }.prefix(8)
            let top = sorted.first
            let insight = top.map { "\($0.0) ist dein häufigster Kostenpunkt (\(String(format: "%.2f€", $0.1)))." }
            return FinanceInsight(
                title: "Nach Händler · \(context.period.label)",
                rows: Array(sorted.map { ($0.0, String(format: "%.2f€", $0.1)) }),
                insight: insight,
                followUpActions: [.top5Expenses, .monthCompare],
                chartSeries: sorted.prefix(6).map { (label: String($0.0.prefix(14)), value: $0.1) },
                chartStyle: .bar
            )

        case .thisWeek, .last7Days:
            let weekTxs = transactions(for: .last7Days, store: store, reference: Date())
            let total = weekTxs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let rows = weekTxs.filter { $0.type == .expense }.sorted { $0.amount > $1.amount }.prefix(5)
                .map { ($0.merchant, String(format: "-%.2f€", $0.amount)) }
            let dailySeries = dailyExpenseSeries(transactions: weekTxs.filter { $0.type == .expense }, days: 7)
            return FinanceInsight(
                title: "Letzte 7 Tage",
                rows: Array(rows),
                insight: String(format: "Gesamt: %.2f€ · Ø %.2f€/Tag", total, total / 7),
                followUpActions: [.monthCompare, .unusualSpending],
                chartSeries: dailySeries,
                chartStyle: dailySeries.isEmpty ? nil : .bar
            )

        case .monthCompare:
            return monthCompareInsight(store: store)

        case .dailyAverage:
            let monthTxs = store.transactions(inMonth: Date()).filter { $0.type == .expense }
            let total = monthTxs.reduce(0) { $0 + $1.amount }
            let day = max(Calendar.current.component(.day, from: Date()), 1)
            let avg = total / Double(day)
            return FinanceInsight(
                title: "Tagesdurchschnitt",
                rows: [
                    ("Ausgaben bisher", String(format: "%.2f€", total)),
                    ("Tage im Monat", "\(day)"),
                    ("Ø pro Tag", String(format: "%.2f€", avg))
                ],
                insight: avg > 30 ? "Überdurchschnittliches Tagesbudget — prüfe Top-Ausgaben." : "Dein Tagesbudget liegt im Rahmen.",
                followUpActions: [.spendingPace, .top5Expenses]
            )

        case .spendingPace:
            return spendingPaceInsight(store: store)

        case .unusualSpending:
            return unusualSpendingInsight(store: store)

        case .analyzeMe:
            let report = AnalyzeMeEngine.analyze(store: store)
            var rows: [(String, String)] = [
                ("Finanz-Typ", report.financeType),
                ("Persönlichkeit", report.typeSubtitle),
                ("Score", "\(report.score)/100"),
                ("Sparquote", String(format: "%.0f%%", report.savingsRatePercent))
            ]
            if let strength = report.strengths.first {
                rows.append(("Stärke", strength))
            }
            if let weakness = report.weaknesses.first {
                rows.append(("Schwäche", weakness))
            }
            let profileMeters: [(label: String, value: Double)] = [
                (label: "Score", value: Double(report.score)),
                (label: "Sparquote", value: report.savingsRatePercent),
                (label: "Ziele", value: report.goalCompletionPercent)
            ].filter { $0.value > 0 }
            return FinanceInsight(
                title: "Analyze Me",
                rows: rows,
                insight: report.personalityLine + " Öffne „Mein Finanzbericht“ für die volle Analyse.",
                followUpActions: [.financeReport, .savingsTips, .monthCompare],
                chartSeries: profileMeters.isEmpty ? nil : profileMeters,
                chartStyle: profileMeters.isEmpty ? nil : .bar
            )

        case .affordability:
            return DecisionEngine.affordability(amount: nil, store: store)

        case .weeklyBudget:
            return DecisionEngine.weeklyBudget(store: store)

        case .whySpending:
            return DecisionEngine.whyMoreSpending(store: store)

        case .whatIf:
            return DecisionEngine.whatIf(store: store)

        case .vacationAffordability:
            return DecisionEngine.vacationAffordability(store: store)

        case .financeReport:
            store.showFinanceReport = true
            return FinanceInsight(
                title: "Mein Finanzbericht",
                rows: [
                    ("Status", "Wird geöffnet"),
                    ("Inhalt", "Profil · Ausgaben · Stärken · Prognose")
                ],
                insight: "Dein persönlicher Finanzbericht öffnet sich jetzt.",
                followUpActions: [.analyzeMe, .monthCompare, .goalsProgress]
            )

        case .openMap, .expensiveAreas, .frequentAreas, .withoutLocation:
            let monthExpenses = store.transactions(inMonth: Date()).filter { $0.type == .expense }
            let hotspots = MapHeatLayout.hotspots(from: monthExpenses, limit: 5)
            let without = store.transactions.filter { $0.location == nil }.count
            if !hotspots.isEmpty {
                let top = hotspots[0]
                return FinanceInsight(
                    title: "Ausgaben-Hotspots",
                    rows: hotspots.map { ("\($0.intensity.label.capitalized) · \($0.title)", String(format: "%.0f€", $0.amount)) }
                        + [("Ohne Standort", "\(without) Buchungen")],
                    insight: "Dein teuerster Ort: \(top.title) — \(String(format: "%.0f€", top.amount)) diesen Monat.",
                    followUpActions: [.openMap, .byCategory],
                    chartSeries: hotspots.map { (label: $0.title, value: $0.amount) },
                    chartStyle: .bar
                )
            }
            let withLoc = store.transactions.filter { $0.location != nil && $0.type == .expense }
            let grouped = Dictionary(grouping: withLoc, by: { $0.location?.label ?? "Unbekannt" })
            let sorted = grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }.sorted { $0.1 > $1.1 }.prefix(5)
            return FinanceInsight(
                title: "Ausgaben nach Ort",
                rows: Array(sorted.map { ($0.0, String(format: "%.2f€", $0.1)) }) + [("Ohne Standort", "\(without) Buchungen")],
                insight: withLoc.isEmpty ? "Standort in Einstellungen aktivieren für die Geldkarte." : "Tippe auf der Karte einen Pin für Details.",
                followUpActions: [.openMap]
            )

        case .categoryDetail:
            if let cat = context.category {
                return categoryInsight(category: cat, context: context, store: store)
            }
            return categoryBreakdownInsight(txs: txs, period: context.period, limit: 5)
        }
    }

    // MARK: - Private helpers

    private func normalize(_ input: String) -> String {
        input.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "€", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func bestIntent(for text: String) -> (FinanceIntent, Int)? {
        var scores: [FinanceIntent: Int] = [:]
        for rule in rules {
            for kw in rule.keywords where text.contains(kw) {
                scores[rule.intent, default: 0] += rule.weight
            }
        }
        if text.contains("?") { scores = scores.mapValues { $0 + 1 } }
        return scores.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    private func parseContext(from text: String) -> QueryContext {
        var ctx = QueryContext()
        if text.contains("heute") { ctx.period = .today }
        else if text.contains("gestern") { ctx.period = .yesterday }
        else if text.contains("letzte 7") || text.contains("letzten 7") || text.contains("woche") { ctx.period = .last7Days }
        else if text.contains("letzten monat") || text.contains("vormonat") { ctx.period = .lastMonth }
        else if text.contains("diesen monat") || text.contains("monat") { ctx.period = .thisMonth }
        ctx.category = detectCategory(in: text)
        ctx.merchant = detectMerchant(in: text)
        return ctx
    }

    private func detectCategory(in text: String) -> FinanceCategory? {
        let map: [(FinanceCategory, [String])] = [
            (.food, ["lebensmittel", "essen", "food", "supermarkt", "restaurant"]),
            (.transport, ["transport", "tanken", "bahn", "auto"]),
            (.shopping, ["einkaufen", "shopping", "kleidung"]),
            (.subscription, ["abo", "abonnement", "netflix", "spotify"]),
            (.entertainment, ["unterhaltung", "kino", "freizeit"]),
            (.health, ["gesundheit", "apotheke", "arzt"]),
            (.housing, ["wohnen", "miete", "strom", "nebenkosten"])
        ]
        for (cat, words) in map where words.contains(where: { text.contains($0) }) {
            return cat
        }
        return nil
    }

    private func detectMerchant(in text: String) -> String? {
        for m in merchantKeywords where text.contains(m) {
            return m.capitalized
        }
        if text.contains("bei ") {
            let parts = text.components(separatedBy: "bei ")
            if parts.count > 1 {
                let name = parts[1].components(separatedBy: .whitespaces).prefix(2).joined(separator: " ")
                if !name.isEmpty, !name.contains(where: \.isNumber) { return name.capitalized }
            }
        }
        return nil
    }

    private func detectDirectQuestion(_ text: String, context: QueryContext, store: FinanceStore) -> FinanceInsight? {
        let asksAmount = text.contains("wie viel") || text.contains("was kostet") || text.contains("wieviel")
        let asksBalance = text.contains("saldo") || text.contains("plus") || text.contains("minus") || text.contains("übrig")
        let asksToday = text.contains("heute")

        if asksToday && asksAmount {
            return summaryInsight(txs: transactions(for: .today, store: store, reference: Date()), period: .today, store: store)
        }
        if asksBalance {
            return summaryInsight(txs: transactions(for: .thisMonth, store: store, reference: Date()), period: .thisMonth, store: store)
        }
        if text.contains("tages") || text.contains("pro tag") || text.contains("durchschnitt") {
            return generateInsight(action: .dailyAverage, store: store, context: context)
        }
        if text.contains("tempo") || text.contains("schnell") {
            return generateInsight(action: .spendingPace, store: store, context: context)
        }
        return nil
    }

    private func transactions(for period: TimePeriod, store: FinanceStore, reference: Date) -> [Transaction] {
        let cal = Calendar.current
        switch period {
        case .today:
            return store.transactions.filter { cal.isDateInToday($0.date) }
        case .yesterday:
            return store.transactions.filter { cal.isDateInYesterday($0.date) }
        case .thisWeek:
            return store.transactions.filter { cal.isDate($0.date, equalTo: reference, toGranularity: .weekOfYear) }
        case .last7Days:
            let start = cal.date(byAdding: .day, value: -7, to: reference)!
            return store.transactions.filter { $0.date >= start }
        case .thisMonth:
            return store.transactions(inMonth: reference)
        case .lastMonth:
            let prev = cal.date(byAdding: .month, value: -1, to: reference)!
            return store.transactions(inMonth: prev)
        case .allTime:
            return store.transactions
        }
    }

    private func merchantInsight(merchant: String, context: QueryContext, store: FinanceStore) -> FinanceInsight {
        let txs = transactions(for: context.period, store: store, reference: Date())
            .filter { $0.merchant.lowercased().contains(merchant.lowercased()) }
        let total = txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let count = txs.count
        let rows = txs.prefix(5).map { ($0.date.formatted(date: .abbreviated, time: .omitted), $0.formattedAmount) }
        return FinanceInsight(
            title: "\(merchant) · \(context.period.label)",
            rows: rows.isEmpty ? [("Ausgaben", "0,00€")] : rows + [("Gesamt", String(format: "%.2f€", total))],
            insight: count == 0 ? "Keine Buchungen bei \(merchant) gefunden." :
                "\(count) Buchungen · Ø \(String(format: "%.2f€", total / Double(max(count, 1)))) pro Einkauf",
            followUpActions: [.byCategory, .monthCompare]
        )
    }

    private func categoryInsight(category: FinanceCategory, context: QueryContext, store: FinanceStore) -> FinanceInsight {
        let txs = transactions(for: context.period, store: store, reference: Date())
            .filter { $0.category == category && $0.type == .expense }
        let total = txs.reduce(0) { $0 + $1.amount }
        let allExpenses = transactions(for: context.period, store: store, reference: Date()).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let share = allExpenses > 0 ? total / allExpenses * 100 : 0
        let top = txs.sorted { $0.amount > $1.amount }.prefix(3).map { ($0.merchant, String(format: "-%.2f€", $0.amount)) }
        return FinanceInsight(
            title: "\(category.rawValue) · \(context.period.label)",
            rows: top + [("Gesamt", String(format: "%.2f€", total))],
            insight: txs.isEmpty ? "Keine Ausgaben in dieser Kategorie." :
                String(format: "%.0f%% deiner Ausgaben in \(context.period.label)", share),
            followUpActions: [.byCategory, .savingsTips]
        )
    }

    private func categoryBreakdownInsight(txs: [Transaction], period: TimePeriod, limit: Int) -> FinanceInsight {
        let grouped = Dictionary(grouping: txs.filter { $0.type == .expense }, by: \.category)
        let sorted = grouped.map { ($0.key.rawValue, $0.value.reduce(0) { $0 + $1.amount }) }.sorted { $0.1 > $1.1 }
        let top = sorted.prefix(limit)
        let insight = sorted.first.map { topCat in
            let total = sorted.reduce(0) { $0 + $1.1 }
            let pct = total > 0 ? topCat.1 / total * 100 : 0
            return String(format: "Du gibst am meisten für %@ aus (%.0f%%).", topCat.0, pct)
        }
        return FinanceInsight(
            title: "Nach Kategorie · \(period.label)",
            rows: top.map { ($0.0, String(format: "%.2f€", $0.1)) },
            insight: insight,
            followUpActions: [.savingsTips, .top5Expenses],
            chartSeries: sorted.prefix(6).map { (label: $0.0, value: $0.1) },
            chartStyle: .donut
        )
    }

    private func summaryInsight(txs: [Transaction], period: TimePeriod, store: FinanceStore) -> FinanceInsight {
        let expenses = txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let income = txs.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let balance = income - expenses
        var insight = balance >= 0 ? "Du liegst im Plus." : "Du gibst mehr aus als du einnimmst."
        if period == .thisMonth, expenses > 0 {
            let day = max(Calendar.current.component(.day, from: Date()), 1)
            let projected = expenses / Double(day) * 30
            insight += String(format: " Hochrechnung Monatsende: ~%.0f€ Ausgaben.", projected)
            if projected > income && income > 0 {
                insight += String(format: " Prognose: ~%.0f€ über den Einnahmen.", projected - income)
            }
        }
        return FinanceInsight(
            title: "Übersicht · \(period.label)",
            rows: [
                ("Ausgaben", String(format: "%.2f€", expenses)),
                ("Einnahmen", String(format: "%.2f€", income)),
                ("Saldo", String(format: "%+.2f€", balance))
            ],
            insight: txs.isEmpty ? "Noch keine Daten für \(period.label)." : insight,
            followUpActions: [.top5Expenses, .byCategory, .monthCompare],
            chartSeries: [
                (label: "Einnahmen", value: max(income, 0.01)),
                (label: "Ausgaben", value: max(expenses, 0.01))
            ],
            chartStyle: .bar
        )
    }

    private func monthCompareInsight(store: FinanceStore) -> FinanceInsight {
        let cal = Calendar.current
        let now = Date()
        let prev = cal.date(byAdding: .month, value: -1, to: now)!
        let cur = store.transactions(inMonth: now).filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }.reduce(0) { $0 + $1.amount }
        let prevTotal = store.transactions(inMonth: prev).filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }.reduce(0) { $0 + $1.amount }
        let diff = cur - prevTotal
        let pct = prevTotal > 0 ? diff / prevTotal * 100 : 0
        let personal = PersonalFinanceInsights.categoryMonthOverMonth(store: store)?.message
        var fallback = diff > 0 ? "Du gibst \(String(format: "%.0f%%", abs(pct))) mehr aus als im Vormonat." :
            (diff < 0 ? "Du gibst weniger aus — gut gemacht!" : "Gleich wie im Vormonat.")
        let day = max(cal.component(.day, from: now), 1)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let projected = cur / Double(day) * Double(daysInMonth)
        if diff > 0 {
            fallback += String(format: " Tipp: Reduziere Top-Kategorie um ~%.0f€/Monat.", min(diff, cur * 0.15))
            fallback += String(format: " Prognose Monatsende: ~%.0f€.", projected)
        } else if cur > 0 {
            fallback += String(format: " Prognose Monatsende: ~%.0f€.", projected)
        }
        return FinanceInsight(
            title: "Monatsvergleich",
            rows: [
                ("Dieser Monat", String(format: "%.2f€", cur)),
                ("Vormonat", String(format: "%.2f€", prevTotal)),
                ("Differenz", String(format: "%+.2f€ (%.0f%%)", diff, pct)),
                ("Prognose", String(format: "~%.0f€", projected))
            ],
            insight: personal ?? fallback,
            followUpActions: [.byCategory, .spendingPace, .unusualSpending],
            chartSeries: [
                (label: "Vormonat", value: prevTotal),
                (label: "Dieser Monat", value: cur)
            ],
            chartStyle: .bar
        )
    }

    private func dailyExpenseSeries(transactions: [Transaction], days: Int) -> [(label: String, value: Double)] {
        let cal = Calendar.current
        let now = Date()
        var series: [(label: String, value: Double)] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: now) else { continue }
            let total = transactions
                .filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amount }
            let label = day.formatted(.dateTime.weekday(.abbreviated))
            series.append((label: label, value: total))
        }
        return series
    }

    private func spendingPaceInsight(store: FinanceStore) -> FinanceInsight {
        let cal = Calendar.current
        let day = max(cal.component(.day, from: Date()), 1)
        let daysInMonth = cal.range(of: .day, in: .month, for: Date())?.count ?? 30
        let spent = store.currentMonthExpenses
        let pace = spent / Double(day) * Double(daysInMonth)
        let income = store.currentMonthIncome
        let monthTxs = store.transactions(inMonth: Date()).filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }
        let dailySeries = dailyExpenseSeries(transactions: monthTxs, days: min(day, 14))
        var insight = pace > income && income > 0
            ? "Bei diesem Tempo überziehst du deine Einnahmen."
            : "Dein Ausgaben-Tempo ist stabil."
        insight += String(format: " Prognose Monatsende: ~%.0f€.", pace)
        return FinanceInsight(
            title: "Ausgaben-Tempo",
            rows: [
                ("Bisher ausgegeben", String(format: "%.2f€", spent)),
                ("Tage vergangen", "\(day) von \(daysInMonth)"),
                ("Prognose Monatsende", String(format: "~%.0f€", pace))
            ],
            insight: insight,
            followUpActions: [.dailyAverage, .savingsTips, .monthCompare],
            chartSeries: dailySeries.isEmpty ? nil : dailySeries,
            chartStyle: dailySeries.isEmpty ? nil : .line
        )
    }

    private func unusualSpendingInsight(store: FinanceStore) -> FinanceInsight {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: Date())!
        let weekTx = store.transactions.filter { $0.date >= weekAgo && $0.type == .expense }
        let avg = weekTx.isEmpty ? 0 : weekTx.reduce(0) { $0 + $1.amount } / Double(weekTx.count)
        let unusual = weekTx.filter { $0.amount > avg * 2 }.sorted { $0.amount > $1.amount }.prefix(5)
        let rows = unusual.map { ($0.merchant, String(format: "-%.2f€", $0.amount)) }
        return FinanceInsight(
            title: "Ungewöhnliche Ausgaben",
            rows: rows.isEmpty ? [("—", "Keine Auffälligkeiten")] : Array(rows),
            insight: unusual.isEmpty ? "Keine ungewöhnlich hohen Buchungen diese Woche." :
                "Diese Buchungen liegen über dem Doppelten deines Wochendurchschnitts.",
            followUpActions: [.top5Expenses]
        )
    }

    private func savingsInsight(store: FinanceStore) -> FinanceInsight {
        var tips: [(String, String)] = []
        for line in PersonalFinanceInsights.personalInsightLines(store: store) {
            tips.append(("Persönlich", line))
        }
        if let top = store.topCategoryThisMonth {
            tips.append(("Größte Kategorie", "\(top.0.rawValue): \(String(format: "%.0f€", top.1))"))
        }
        let subTotal = store.monthlySubscriptionCost
        if subTotal > 0 {
            tips.append(("Abos", String(format: "%.0f€/Monat — prüfe was du noch brauchst", subTotal)))
        }
        if store.currentMonthExpenses > store.currentMonthIncome, store.currentMonthIncome > 0 {
            tips.append(("Warnung", "Ausgaben > Einnahmen"))
        }
        let topMerchant = Dictionary(grouping: store.transactions(inMonth: Date()).filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }, by: \.merchant)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .max(by: { $0.1 < $1.1 })
        if let m = topMerchant {
            tips.append(("Top-Händler", "\(m.0): \(String(format: "%.0f€", m.1))"))
        }
        if tips.isEmpty {
            tips.append(("Tipp", "Erfasse mehr Buchungen für personalisierte Tipps"))
        }
        let insight = tips.first?.1 ?? "Je mehr du nutzt, desto besser versteht dich Live Cash."
        let income = store.currentMonthIncome
        let expenses = store.currentMonthExpenses
        let saved = max(0, income - expenses)
        let rate = income > 0 ? saved / income * 100 : 0
        let rows: [(String, String)] = [
            ("Sparquote", String(format: "%.0f%%", rate)),
            ("Gespart", String(format: "%.0f€", saved)),
            ("Prognose (Jahr)", String(format: "~%.0f€", max(store.monthlySavingsRate, saved) * 12))
        ] + Array(tips.prefix(3))
        return FinanceInsight(
            title: "Wie gut sparst du?",
            rows: rows,
            insight: String(format: "Sparquote %.0f%% — %@", rate, insight),
            followUpActions: [.monthCompare, .goalsProgress, .byCategory],
            chartSeries: [
                (label: "Gespart", value: max(saved, 0.01)),
                (label: "Ausgegeben", value: max(expenses, 0.01))
            ],
            chartStyle: .donut
        )
    }

    private func shareOfExpenses(_ amount: Double, in txs: [Transaction]) -> Int {
        let total = txs.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return 0 }
        return Int((amount / total * 100).rounded())
    }

    private func rankedSuggestions(for intent: FinanceIntent, store: FinanceStore) -> [InsightAction] {
        var base: [InsightAction]
        switch intent {
        case .save:
            base = [.savingsTips, .biggestCategory, .potentialSavings, .subscriptionOverview, .dailyAverage]
        case .spendingOverview:
            base = [.byCategory, .byMerchant, .last7Days, .monthCompare, .top5Expenses]
        case .overview:
            base = [.incomeVsExpense, .topCategory, .recentTransactions, .spendingPace]
        case .subscriptions:
            base = [.monthlySubCost, .yearlySubCost, .potentialSavings, .allSubscriptions]
        case .monthlySummary:
            base = [.monthlySummary, .top3Categories, .balance, .spendingPace]
        case .topExpenses:
            base = [.top5Expenses, .byCategory, .byMerchant, .unusualSpending]
        case .geography:
            base = [.expensiveAreas, .frequentAreas, .withoutLocation]
        case .goals:
            base = [.goalsProgress, .savingsTips, .monthlySummary]
        case .trends:
            base = [.monthCompare, .spendingPace, .dailyAverage, .last7Days]
        case .category:
            base = [.byCategory, .top5Expenses, .byMerchant]
        }

        if store.subscriptions.isEmpty { base.removeAll { $0 == .potentialSavings || $0 == .subscriptionOverview } }
        if store.goals.isEmpty { base.removeAll { $0 == .goalsProgress } }
        if store.transactions.isEmpty { return [.recentTransactions, .monthlySummary] }

        return Array(base.prefix(5))
    }

    private func contextualHeadline(for intent: FinanceIntent, store: FinanceStore) -> String {
        let memory = AssistantMemory.build(from: store)
        if store.transactions.isEmpty {
            return "Deine Finanzreise beginnt — frag z. B. „Kann ich mir 40€ leisten?“"
        }
        switch intent {
        case .save:
            if store.currentMonthExpenses > store.currentMonthIncome, store.currentMonthIncome > 0 {
                return "Du gibst mehr aus als du einnimmst — hier sind Spar-Optionen:"
            }
            if let goal = memory.primaryGoalName {
                return "Dein \(goal)-Ziel steht bei \(memory.primaryGoalProgress)% — so kommst du schneller hin:"
            }
            return "Personalisierte Spar-Ideen basierend auf deinen Gewohnheiten:"
        case .spendingOverview:
            if let top = memory.topCategories.first {
                return "Du gibst am meisten für \(top.name) aus (\(String(format: "%.0f€", top.amount)))."
            }
            return "Wähle eine Ausgaben-Analyse:"
        case .subscriptions:
            return store.subscriptions.isEmpty ?
                "Noch keine Abos erkannt — wiederkehrende Zahlungen werden automatisch gefunden." :
                String(format: "%.0f€/Monat an Abos — Details:", store.monthlySubscriptionCost)
        default:
            return "Was möchtest du entscheiden oder genauer sehen?"
        }
    }

    private func contextualFallback(store: FinanceStore) -> (headline: String, actions: [InsightAction]) {
        if store.transactions.isEmpty {
            return ("Frag mich z. B. „Kann ich mir das leisten?“ oder tippe „Kaffee 4,50“", [.affordability, .financeReport, .savingsTips])
        }
        let memory = AssistantMemory.build(from: store)
        let headline: String
        if let goal = memory.primaryGoalName {
            headline = "Ich kenne dein \(goal)-Ziel (\(memory.primaryGoalProgress)%) — wonach suchst du?"
        } else {
            headline = String(format: "Du hast noch %.0f€ verfügbar — wonach suchst du?", memory.availableBalance)
        }
        return (headline, [.affordability, .weeklyBudget, .whySpending, .financeReport, .savingsTips])
    }
}
