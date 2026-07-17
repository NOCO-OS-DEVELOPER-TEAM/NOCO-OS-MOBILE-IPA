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

    init(
        id: String,
        prompt: String,
        prefixes: [String] = [],
        keywords: [String] = [],
        action: InsightAction? = nil,
        query: String? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.prefixes = prefixes
        self.keywords = keywords
        self.action = action
        self.query = query ?? prompt
    }
}

enum AssistantQuestionBank {
    static let quickTiles: [(title: String, icon: String, action: InsightAction)] = [
        ("Leisten?", "cart.badge.questionmark", .affordability),
        ("Wochenbudget", "calendar.badge.clock", .weeklyBudget),
        ("Warum mehr?", "chart.line.uptrend.xyaxis", .whySpending),
        ("Finanzbericht", "doc.text.magnifyingglass", .financeReport)
    ]

    static let all: [AssistantQuestion] = [
        // WAS
        AssistantQuestion(
            id: "was-sparen",
            prompt: "Was kann ich tun, um mehr zu sparen?",
            prefixes: ["was", "wa"],
            keywords: ["sparen", "mehr", "tun"],
            action: .savingsTips
        ),
        AssistantQuestion(
            id: "was-groesste",
            prompt: "Was war meine größte Ausgabe diesen Monat?",
            prefixes: ["was", "wa"],
            keywords: ["größte", "groesste", "ausgabe", "monat"],
            action: .top5Expenses
        ),
        AssistantQuestion(
            id: "was-50",
            prompt: "Was würde passieren, wenn ich 50 € pro Monat spare?",
            prefixes: ["was", "wa"],
            keywords: ["50", "passieren", "monat", "spare"],
            action: .goalsProgress
        ),
        AssistantQuestion(
            id: "was-heute",
            prompt: "Was habe ich heute ausgegeben?",
            prefixes: ["was", "wa"],
            keywords: ["heute", "ausgegeben"],
            action: .spendingPace
        ),
        AssistantQuestion(
            id: "was-abo",
            prompt: "Was kosten meine Abos im Monat?",
            prefixes: ["was", "wa"],
            keywords: ["abo", "kosten"],
            action: .monthlySubCost
        ),

        // WIE
        AssistantQuestion(
            id: "wie-verfuegbar",
            prompt: "Wie viel Geld habe ich noch verfügbar?",
            prefixes: ["wie", "wi"],
            keywords: ["verfügbar", "verfuegbar", "geld", "noch"],
            action: .balance
        ),
        AssistantQuestion(
            id: "wie-sparziel",
            prompt: "Wie nah bin ich meinem Sparziel?",
            prefixes: ["wie", "wi"],
            keywords: ["nah", "sparziel", "ziel"],
            action: .goalsProgress
        ),
        AssistantQuestion(
            id: "wie-jahr",
            prompt: "Wie viel habe ich dieses Jahr ausgegeben?",
            prefixes: ["wie", "wi"],
            keywords: ["jahr", "ausgegeben"],
            action: .totalExpenses,
            query: "wie viel ausgegeben dieses jahr"
        ),
        AssistantQuestion(
            id: "wie-woche",
            prompt: "Wie viel habe ich diese Woche ausgegeben?",
            prefixes: ["wie", "wi"],
            keywords: ["woche", "ausgegeben"],
            action: .last7Days
        ),
        AssistantQuestion(
            id: "wie-einkommen",
            prompt: "Wie stehen Einnahmen und Ausgaben?",
            prefixes: ["wie", "wi"],
            keywords: ["einnahmen", "ausgaben", "stehen"],
            action: .incomeVsExpense
        ),
        AssistantQuestion(
            id: "wie-tempo",
            prompt: "Wie ist mein Ausgaben-Tempo diesen Monat?",
            prefixes: ["wie", "wi"],
            keywords: ["tempo", "ausgaben"],
            action: .spendingPace
        ),

        // WO
        AssistantQuestion(
            id: "wo-geld",
            prompt: "Wo gebe ich am meisten Geld aus?",
            prefixes: ["wo"],
            keywords: ["meisten", "geld", "aus"],
            action: .byCategory
        ),
        AssistantQuestion(
            id: "wo-karte",
            prompt: "Wo waren meine teuersten Einkäufe?",
            prefixes: ["wo"],
            keywords: ["teuer", "einkauf", "karte", "ort"],
            action: .expensiveAreas
        ),

        // WANN
        AssistantQuestion(
            id: "wann-abo",
            prompt: "Wann wird mein nächstes Abo abgebucht?",
            prefixes: ["wann", "wa"],
            keywords: ["abo", "abgebucht", "nächste"],
            action: .allSubscriptions
        ),

        // ZEIGE / ZEIG
        AssistantQuestion(
            id: "zeig-monat",
            prompt: "Zeig mir die Monatsübersicht",
            prefixes: ["zeig", "zeige", "ze"],
            keywords: ["monat", "übersicht", "uebersicht"],
            action: .monthlySummary
        ),
        AssistantQuestion(
            id: "zeig-kategorie",
            prompt: "Zeig Ausgaben nach Kategorie",
            prefixes: ["zeig", "zeige", "ze"],
            keywords: ["kategorie"],
            action: .byCategory
        ),
        AssistantQuestion(
            id: "zeig-haendler",
            prompt: "Zeig Ausgaben nach Händler",
            prefixes: ["zeig", "zeige", "ze"],
            keywords: ["händler", "haendler", "merchant"],
            action: .byMerchant
        ),
        AssistantQuestion(
            id: "zeig-abos",
            prompt: "Zeig alle meine Abos",
            prefixes: ["zeig", "zeige", "ze"],
            keywords: ["abo"],
            action: .allSubscriptions
        ),
        AssistantQuestion(
            id: "zeig-ziele",
            prompt: "Zeig meinen Sparziel-Fortschritt",
            prefixes: ["zeig", "zeige", "ze"],
            keywords: ["sparziel", "ziel", "fortschritt"],
            action: .goalsProgress
        ),

        // VERGLEICH / TREND
        AssistantQuestion(
            id: "vergleich-monat",
            prompt: "Vergleich diesen Monat mit dem Vormonat",
            prefixes: ["ver", "verg", "vergleiche"],
            keywords: ["monat", "vormonat", "vergleich"],
            action: .monthCompare
        ),
        AssistantQuestion(
            id: "trend",
            prompt: "Welche Trends sehe ich in meinen Ausgaben?",
            prefixes: ["wel", "welch", "trend"],
            keywords: ["trend", "entwicklung"],
            action: .monthCompare
        ),

        // SPARZIEL
        AssistantQuestion(
            id: "spar-tipp",
            prompt: "Wie erreiche ich mein Sparziel schneller?",
            prefixes: ["wie", "spar"],
            keywords: ["sparziel", "schneller", "erreiche"],
            action: .goalsProgress
        ),
        AssistantQuestion(
            id: "ungewöhnlich",
            prompt: "Gab es ungewöhnliche Ausgaben?",
            prefixes: ["gab", "un", "hab"],
            keywords: ["ungewöhnlich", "ungewoehnlich", "auffällig"],
            action: .unusualSpending
        ),

        // ANALYZE ME
        AssistantQuestion(
            id: "analyze-me",
            prompt: "Analyze Me — wer bin ich finanziell?",
            prefixes: ["ana", "analyze", "wer", "fin"],
            keywords: ["analyze", "analysiere", "finanziell", "persönlichkeit", "personlichkeit"],
            action: .analyzeMe
        ),
        AssistantQuestion(
            id: "wie-spare",
            prompt: "Wie gut spare ich?",
            prefixes: ["wie", "wi"],
            keywords: ["gut", "spare", "sparen"],
            action: .analyzeMe
        ),
        AssistantQuestion(
            id: "schwaeche",
            prompt: "Was ist meine größte Schwäche?",
            prefixes: ["was", "wa"],
            keywords: ["schwäche", "schwaeche", "größte"],
            action: .analyzeMe
        ),
        AssistantQuestion(
            id: "aendern",
            prompt: "Was sollte ich ändern?",
            prefixes: ["was", "wa"],
            keywords: ["ändern", "aendern", "sollte"],
            action: .analyzeMe
        ),
        AssistantQuestion(
            id: "zukunft",
            prompt: "Wie sieht meine Zukunft aus?",
            prefixes: ["wie", "wi"],
            keywords: ["zukunft", "weiter"],
            action: .analyzeMe
        ),
        AssistantQuestion(
            id: "besser-jahr",
            prompt: "Wie viel besser bin ich als letztes Jahr?",
            prefixes: ["wie", "wi"],
            keywords: ["besser", "jahr"],
            action: .analyzeMe
        ),

        // ENTSCHEIDUNGEN
        AssistantQuestion(
            id: "leisten",
            prompt: "Kann ich mir das leisten?",
            prefixes: ["kann", "ka", "leist"],
            keywords: ["leisten", "mir", "kaufen"],
            action: .affordability
        ),
        AssistantQuestion(
            id: "urlaub",
            prompt: "Kann ich mir einen Urlaub leisten?",
            prefixes: ["kann", "ka", "url"],
            keywords: ["urlaub", "leisten", "reise"],
            action: .vacationAffordability
        ),
        AssistantQuestion(
            id: "woche-budget",
            prompt: "Wie viel darf ich diese Woche ausgeben?",
            prefixes: ["wie", "wi"],
            keywords: ["woche", "darf", "ausgeben"],
            action: .weeklyBudget
        ),
        AssistantQuestion(
            id: "warum-mehr",
            prompt: "Warum habe ich diesen Monat mehr ausgegeben?",
            prefixes: ["war", "warum"],
            keywords: ["mehr", "ausgegeben", "warum"],
            action: .whySpending
        ),
        AssistantQuestion(
            id: "wo-sparen",
            prompt: "Wo kann ich sparen?",
            prefixes: ["wo"],
            keywords: ["sparen", "kann"],
            action: .savingsTips
        ),
        AssistantQuestion(
            id: "was-wenn",
            prompt: "Was passiert, wenn ich 50 € pro Monat spare?",
            prefixes: ["was", "wa"],
            keywords: ["passiert", "wenn", "spare"],
            action: .whatIf
        ),
        AssistantQuestion(
            id: "finanzbericht",
            prompt: "Mein Finanzbericht",
            prefixes: ["mein", "fin", "beri"],
            keywords: ["finanzbericht", "bericht"],
            action: .financeReport
        )
    ]

    /// Matches typed text against the local question bank (prefix + keyword scoring).
    static func matches(for partial: String, limit: Int = 3) -> [AssistantQuestion] {
        let trimmed = partial.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        let firstWord = trimmed.split(separator: " ").first.map(String.init) ?? trimmed

        var scored: [(AssistantQuestion, Int)] = []
        for q in all {
            var score = 0
            if q.prefixes.contains(where: { firstWord.hasPrefix($0) || $0.hasPrefix(firstWord) }) {
                score += 40
            }
            if q.prompt.lowercased().hasPrefix(trimmed) {
                score += 50
            } else if q.prompt.lowercased().contains(trimmed) {
                score += 25
            }
            for kw in q.keywords where trimmed.contains(kw) {
                score += 15
            }
            // Soft: any prefix token starts the question
            if q.prefixes.contains(where: { trimmed.hasPrefix($0) }) {
                score += 20
            }
            if score > 0 {
                scored.append((q, score))
            }
        }

        return Array(
            scored
                .sorted { $0.1 > $1.1 }
                .map(\.0)
                .prefix(limit)
        )
    }
}
