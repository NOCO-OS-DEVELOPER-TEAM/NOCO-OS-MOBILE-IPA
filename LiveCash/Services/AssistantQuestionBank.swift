import Foundation

/// Local question database — fast prefix matching, no cloud AI.
struct AssistantQuestion: Identifiable, Equatable {
    let id: String
    let prompt: String
    let prefixes: [String]
    let keywords: [String]
    let action: InsightAction?
    /// Full natural-language query passed to the assistant when no direct action.
    let query: String?
    let category: String

    init(
        id: String,
        prompt: String,
        prefixes: [String] = [],
        keywords: [String] = [],
        action: InsightAction? = nil,
        query: String? = nil,
        category: String = "Allgemein"
    ) {
        self.id = id
        self.prompt = prompt
        self.prefixes = prefixes
        self.keywords = keywords
        self.action = action
        self.query = query ?? prompt
        self.category = category
    }
}

enum AssistantQuestionBank {
    static let quickTiles: [(title: String, icon: String, action: InsightAction)] = [
        ("Leisten?", "cart.badge.questionmark", .affordability),
        ("Wochenbudget", "calendar.badge.clock", .weeklyBudget),
        ("Warum mehr?", "chart.line.uptrend.xyaxis", .whySpending),
        ("Finanzbericht", "doc.text.magnifyingglass", .financeReport)
    ]

    /// Featured list on the Smart Assistant hub (scrollable).
    static var featured: [AssistantQuestion] {
        Array(all.prefix(28))
    }

    static let all: [AssistantQuestion] = {
        var list: [AssistantQuestion] = []

        // MARK: Entscheiden
        list += [
            q("leisten", "Kann ich mir das leisten?", ["kann", "ka", "leist"], ["leisten", "mir", "kaufen"], .affordability, "Entscheiden"),
            q("leisten-50", "Kann ich mir 50 € leisten?", ["kann", "ka"], ["50", "leisten"], .affordability, "Entscheiden"),
            q("leisten-100", "Kann ich mir 100 € leisten?", ["kann", "ka"], ["100", "leisten"], .affordability, "Entscheiden"),
            q("leisten-200", "Kann ich mir 200 € leisten?", ["kann", "ka"], ["200", "leisten"], .affordability, "Entscheiden"),
            q("urlaub", "Kann ich mir einen Urlaub leisten?", ["kann", "ka", "url"], ["urlaub", "leisten", "reise"], .vacationAffordability, "Entscheiden"),
            q("woche-budget", "Wie viel darf ich diese Woche ausgeben?", ["wie", "wi"], ["woche", "darf", "ausgeben"], .weeklyBudget, "Entscheiden"),
            q("was-wenn", "Was passiert, wenn ich 50 € pro Monat spare?", ["was", "wa"], ["passiert", "wenn", "spare"], .whatIf, "Entscheiden"),
            q("was-wenn-100", "Was wäre, wenn ich 100 € mehr spare?", ["was", "wa"], ["100", "spare", "wenn"], .whatIf, "Entscheiden"),
            q("soll-kaufen", "Soll ich das jetzt kaufen?", ["soll", "so"], ["kaufen", "jetzt"], .affordability, "Entscheiden"),
        ]

        // MARK: Ausgaben
        list += [
            q("was-heute", "Was habe ich heute ausgegeben?", ["was", "wa"], ["heute", "ausgegeben"], .spendingPace, "Ausgaben"),
            q("wie-woche", "Wie viel habe ich diese Woche ausgegeben?", ["wie", "wi"], ["woche", "ausgegeben"], .last7Days, "Ausgaben"),
            q("wie-tempo", "Wie ist mein Ausgaben-Tempo diesen Monat?", ["wie", "wi"], ["tempo", "ausgaben"], .spendingPace, "Ausgaben"),
            q("was-groesste", "Was war meine größte Ausgabe diesen Monat?", ["was", "wa"], ["größte", "groesste", "ausgabe"], .top5Expenses, "Ausgaben"),
            q("top5", "Zeig meine Top 5 Ausgaben", ["zeig", "zeige", "top"], ["top", "5", "ausgaben"], .top5Expenses, "Ausgaben"),
            q("wo-geld", "Wo gebe ich am meisten Geld aus?", ["wo"], ["meisten", "geld", "aus"], .byCategory, "Ausgaben"),
            q("zeig-kategorie", "Zeig Ausgaben nach Kategorie", ["zeig", "zeige", "ze"], ["kategorie"], .byCategory, "Ausgaben"),
            q("zeig-haendler", "Zeig Ausgaben nach Händler", ["zeig", "zeige", "ze"], ["händler", "haendler"], .byMerchant, "Ausgaben"),
            q("top3-kat", "Welche 3 Kategorien kosten am meisten?", ["wel", "welch"], ["kategorien", "kosten"], .top3Categories, "Ausgaben"),
            q("tagesschnitt", "Was ist mein täglicher Ausgabenschnitt?", ["was", "wie"], ["täglich", "taeglich", "schnitt", "durchschnitt"], .dailyAverage, "Ausgaben"),
            q("ungewöhnlich", "Gab es ungewöhnliche Ausgaben?", ["gab", "un", "hab"], ["ungewöhnlich", "ungewoehnlich"], .unusualSpending, "Ausgaben"),
            q("warum-mehr", "Warum habe ich diesen Monat mehr ausgegeben?", ["war", "warum"], ["mehr", "ausgegeben"], .whySpending, "Ausgaben"),
            q("letzte-buchungen", "Zeig meine letzten Buchungen", ["zeig", "zeige", "letzt"], ["letzten", "buchungen"], .recentTransactions, "Ausgaben"),
            q("diese-woche", "Zusammenfassung dieser Woche", ["zus", "dies"], ["woche", "zusammenfassung"], .thisWeek, "Ausgaben"),
            q("jahr-ausgaben", "Wie viel habe ich dieses Jahr ausgegeben?", ["wie", "wi"], ["jahr", "ausgegeben"], .totalExpenses, "Ausgaben"),
            q("haendler-detail", "Welche Händler kosten mich am meisten?", ["wel", "welch"], ["händler", "haendler", "kosten"], .merchantBreakdown, "Ausgaben"),
        ]

        // MARK: Einkommen & Überblick
        list += [
            q("wie-verfuegbar", "Wie viel Geld habe ich noch verfügbar?", ["wie", "wi"], ["verfügbar", "verfuegbar", "geld"], .balance, "Überblick"),
            q("wie-einkommen", "Wie stehen Einnahmen und Ausgaben?", ["wie", "wi"], ["einnahmen", "ausgaben"], .incomeVsExpense, "Überblick"),
            q("zeig-monat", "Zeig mir die Monatsübersicht", ["zeig", "zeige", "ze"], ["monat", "übersicht", "uebersicht"], .monthlySummary, "Überblick"),
            q("vergleich-monat", "Vergleich diesen Monat mit dem Vormonat", ["ver", "verg"], ["monat", "vormonat", "vergleich"], .monthCompare, "Überblick"),
            q("trend", "Welche Trends sehe ich in meinen Ausgaben?", ["wel", "welch", "trend"], ["trend", "entwicklung"], .monthCompare, "Überblick"),
            q("einkommen-total", "Wie hoch waren meine Einnahmen?", ["wie", "wi"], ["einnahmen", "hoch"], .totalIncome, "Überblick"),
            q("finanzbericht", "Mein Finanzbericht", ["mein", "fin", "beri"], ["finanzbericht", "bericht"], .financeReport, "Überblick"),
            q("score", "Wie ist mein Finanz-Score?", ["wie", "wi", "sco"], ["score", "finanz"], .analyzeMe, "Überblick"),
        ]

        // MARK: Sparen & Ziele
        list += [
            q("was-sparen", "Was kann ich tun, um mehr zu sparen?", ["was", "wa"], ["sparen", "mehr", "tun"], .savingsTips, "Sparen"),
            q("wo-sparen", "Wo kann ich sparen?", ["wo"], ["sparen", "kann"], .savingsTips, "Sparen"),
            q("wie-sparziel", "Wie nah bin ich meinem Sparziel?", ["wie", "wi"], ["nah", "sparziel", "ziel"], .goalsProgress, "Sparen"),
            q("spar-tipp", "Wie erreiche ich mein Sparziel schneller?", ["wie", "spar"], ["sparziel", "schneller"], .goalsProgress, "Sparen"),
            q("zeig-ziele", "Zeig meinen Sparziel-Fortschritt", ["zeig", "zeige", "ze"], ["sparziel", "fortschritt"], .goalsProgress, "Sparen"),
            q("wie-spare", "Wie gut spare ich?", ["wie", "wi"], ["gut", "spare", "sparen"], .analyzeMe, "Sparen"),
            q("potential", "Wo steckt Sparpotenzial?", ["wo", "spa"], ["sparpotenzial", "potential"], .potentialSavings, "Sparen"),
            q("notgroschen", "Habe ich genug Notgroschen-Puffer?", ["hab", "not"], ["notgroschen", "puffer"], .balance, "Sparen"),
        ]

        // MARK: Abos
        list += [
            q("was-abo", "Was kosten meine Abos im Monat?", ["was", "wa"], ["abo", "kosten"], .monthlySubCost, "Abos"),
            q("abo-jahr", "Was kosten meine Abos im Jahr?", ["was", "wa"], ["abo", "jahr"], .yearlySubCost, "Abos"),
            q("zeig-abos", "Zeig alle meine Abos", ["zeig", "zeige", "ze"], ["abo"], .allSubscriptions, "Abos"),
            q("wann-abo", "Wann wird mein nächstes Abo abgebucht?", ["wann", "wa"], ["abo", "abgebucht"], .allSubscriptions, "Abos"),
            q("abo-sinn", "Welche Abos könnte ich kündigen?", ["wel", "welch"], ["abo", "kündigen", "kuendigen"], .potentialSavings, "Abos"),
        ]

        // MARK: Karte & Orte
        list += [
            q("wo-karte", "Wo waren meine teuersten Einkäufe?", ["wo"], ["teuer", "einkauf", "ort"], .expensiveAreas, "Karte"),
            q("haeufige-orte", "Welche Orte besuche ich am häufigsten?", ["wel", "welch"], ["orte", "häufig", "haeufig"], .frequentAreas, "Karte"),
            q("oeffne-karte", "Öffne die Geldkarte", ["öff", "oeff", "kart"], ["geldkarte", "karte", "karte"], .openMap, "Karte"),
            q("ohne-ort", "Welche Buchungen haben keinen Ort?", ["wel", "welch"], ["ohne", "ort", "standort"], .withoutLocation, "Karte"),
        ]

        // MARK: Profil / Analyze Me
        list += [
            q("analyze-me", "Analyze Me — wer bin ich finanziell?", ["ana", "analyze", "wer"], ["analyze", "finanziell", "persönlichkeit"], .analyzeMe, "Profil"),
            q("schwaeche", "Was ist meine größte Schwäche?", ["was", "wa"], ["schwäche", "schwaeche"], .analyzeMe, "Profil"),
            q("aendern", "Was sollte ich ändern?", ["was", "wa"], ["ändern", "aendern", "sollte"], .analyzeMe, "Profil"),
            q("zukunft", "Wie sieht meine Zukunft aus?", ["wie", "wi"], ["zukunft"], .analyzeMe, "Profil"),
            q("besser-jahr", "Wie viel besser bin ich als letztes Jahr?", ["wie", "wi"], ["besser", "jahr"], .analyzeMe, "Profil"),
            q("disziplin", "Wie diszipliniert gebe ich Geld aus?", ["wie", "wi"], ["disziplin", "ausgegeben"], .analyzeMe, "Profil"),
            q("staerken", "Was mache ich finanziell schon gut?", ["was", "wa"], ["gut", "stärken", "staerken"], .analyzeMe, "Profil"),
        ]

        // MARK: Alltag / Schnell
        list += [
            q("kaffee", "Wie viel gebe ich für Essen aus?", ["wie", "ess"], ["essen", "food", "restaurant"], .categoryDetail, "Alltag"),
            q("lebensmittel", "Wie viel kostet Supermarkt diesen Monat?", ["wie", "sup"], ["supermarkt", "lebensmittel", "rewe"], .byCategory, "Alltag"),
            q("transport", "Was kostet mich Transport?", ["was", "tra"], ["transport", "auto", "bahn", "benzin"], .byCategory, "Alltag"),
            q("freizeit", "Wie viel geht für Freizeit drauf?", ["wie", "frei"], ["freizeit", "spaß", "spass"], .byCategory, "Alltag"),
            q("rest-monat", "Wie viel bleibt mir diesen Monat?", ["wie", "wiev"], ["bleibt", "rest", "monat"], .balance, "Alltag"),
            q("spare-genug", "Spare ich genug?", ["spa", "spar"], ["genug", "spare"], .analyzeMe, "Alltag"),
            q("mehr-sparen-wie", "Wie kann ich mehr sparen?", ["wie", "wi"], ["mehr", "sparen"], .savingsTips, "Alltag"),
            q("welche-ziele", "Welche Sparziele habe ich?", ["wel", "welch"], ["sparziele", "ziele"], .goalsProgress, "Alltag"),
        ]

        return list
    }()

    // Precomputed for match speed
    private static let indexed: [(q: AssistantQuestion, promptLower: String)] = {
        all.map { ($0, $0.prompt.lowercased()) }
    }()

    private static func q(
        _ id: String,
        _ prompt: String,
        _ prefixes: [String],
        _ keywords: [String],
        _ action: InsightAction?,
        _ category: String
    ) -> AssistantQuestion {
        AssistantQuestion(
            id: id,
            prompt: prompt,
            prefixes: prefixes,
            keywords: keywords,
            action: action,
            category: category
        )
    }

    /// Matches typed text against the local question bank (prefix + keyword scoring).
    static func matches(for partial: String, limit: Int = 3) -> [AssistantQuestion] {
        let trimmed = partial.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        let firstWord = trimmed.split(separator: " ").first.map(String.init) ?? trimmed
        var scored: [(AssistantQuestion, Int)] = []
        scored.reserveCapacity(min(24, indexed.count))

        for item in indexed {
            var score = 0
            let q = item.q

            if q.prefixes.contains(where: { firstWord.hasPrefix($0) || $0.hasPrefix(firstWord) }) {
                score += 40
            }
            if item.promptLower.hasPrefix(trimmed) {
                score += 50
            } else if item.promptLower.contains(trimmed) {
                score += 25
            }
            for kw in q.keywords where trimmed.contains(kw) {
                score += 15
            }
            if q.prefixes.contains(where: { trimmed.hasPrefix($0) }) {
                score += 20
            }
            if score > 0 {
                scored.append((q, score))
            }
        }

        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(limit).map(\.0))
    }

    static func questions(in category: String) -> [AssistantQuestion] {
        all.filter { $0.category == category }
    }

    static var categories: [String] {
        var seen: [String] = []
        for q in all where !seen.contains(q.category) {
            seen.append(q.category)
        }
        return seen
    }
}
