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

        // MARK: Einnahmen
        list += [
            q("einnahmen-monat", "Wie hoch sind meine Einnahmen diesen Monat?", ["wie", "wi"], ["einnahmen", "hoch", "monat"], .totalIncome, "Einnahmen"),
            q("einnahmen-vergleich", "Sind meine Einnahmen höher als letzten Monat?", ["sin", "sind"], ["einnahmen", "höher", "hoeher"], .monthCompare, "Einnahmen"),
            q("gehalt-eingang", "Wann kam mein letztes Gehalt?", ["wan", "wann"], ["gehalt", "letztes"], .recentTransactions, "Einnahmen"),
            q("einnahmen-quelle", "Woher kommen meine Einnahmen?", ["woh", "woher"], ["einnahmen", "kommen"], .totalIncome, "Einnahmen"),
            q("einnahmen-vs-aus", "Übersteigen meine Einnahmen die Ausgaben?", ["üb", "ueb"], ["einnahmen", "ausgaben", "übersteigen"], .incomeVsExpense, "Einnahmen"),
            q("einnahmen-durchschnitt", "Wie hoch ist mein durchschnittliches Monatseinkommen?", ["wie", "wi"], ["durchschnitt", "einkommen"], .totalIncome, "Einnahmen"),
            q("mehr-einnahmen", "Wie kann ich meine Einnahmen steigern?", ["wie", "wi"], ["einnahmen", "steigern"], .savingsTips, "Einnahmen"),
        ]

        // MARK: Ausgaben (Erweiterung)
        list += [
            q("zu-viel-monat", "Habe ich diesen Monat zu viel ausgegeben?", ["hab", "ha"], ["zu viel", "ausgegeben", "monat"], .whySpending, "Ausgaben"),
            q("ausgaben-prognose", "Wie hoch werden meine Ausgaben am Monatsende?", ["wie", "wi"], ["prognose", "monatsende", "ausgaben"], .spendingPace, "Ausgaben"),
            q("groesste-buchung", "Was war meine teuerste Buchung?", ["was", "wa"], ["teuerste", "buchung"], .top5Expenses, "Ausgaben"),
            q("ausgaben-gestern", "Was habe ich gestern ausgegeben?", ["was", "wa"], ["gestern", "ausgegeben"], .spendingPace, "Ausgaben"),
            q("ausgaben-wochenende", "Wie viel gebe ich am Wochenende aus?", ["wie", "wi"], ["wochenende", "ausgegeben"], .thisWeek, "Ausgaben"),
            q("fixkosten", "Wie hoch sind meine Fixkosten?", ["wie", "wi"], ["fixkosten", "fix"], .monthlySubCost, "Ausgaben"),
            q("variable-kosten", "Wie viel gebe ich für variable Kosten aus?", ["wie", "wi"], ["variable", "kosten"], .byCategory, "Ausgaben"),
            q("kleine-ausgaben", "Wie viel gehen für Kleinstausgaben drauf?", ["wie", "wi"], ["klein", "kleinstausgaben"], .unusualSpending, "Ausgaben"),
        ]

        // MARK: Sparziele (Erweiterung)
        list += [
            q("ziel-fortschritt", "Wie weit bin ich mit meinem Sparziel?", ["wie", "wi"], ["sparziel", "weit", "fortschritt"], .goalsProgress, "Sparen"),
            q("ziel-zeit", "Wann erreiche ich mein Sparziel?", ["wan", "wann"], ["sparziel", "erreiche"], .goalsProgress, "Sparen"),
            q("ziel-monatlich", "Wie viel muss ich monatlich sparen?", ["wie", "wi"], ["monatlich", "sparen", "ziel"], .goalsProgress, "Sparen"),
            q("ziel-verzoegerung", "Verzögert mich etwas bei meinem Sparziel?", ["ver", "verz"], ["verzögert", "verzoegert", "sparziel"], .goalsProgress, "Sparen"),
            q("mehrere-ziele", "Wie stehen meine Sparziele insgesamt?", ["wie", "wi"], ["sparziele", "insgesamt"], .goalsProgress, "Sparen"),
            q("ziel-tipp", "Was hilft mir, mein Sparziel schneller zu erreichen?", ["was", "wa"], ["sparziel", "schneller", "erreichen"], .savingsTips, "Sparen"),
        ]

        // MARK: Abos (Erweiterung)
        list += [
            q("abo-teuer", "Welches Abo ist am teuersten?", ["wel", "welch"], ["abo", "teuerste"], .allSubscriptions, "Abos"),
            q("abo-anteil", "Wie viel Prozent meiner Ausgaben sind Abos?", ["wie", "wi"], ["abo", "prozent", "ausgaben"], .monthlySubCost, "Abos"),
            q("abo-sparen", "Kann ich bei Abos Geld sparen?", ["kan", "kann"], ["abo", "sparen"], .potentialSavings, "Abos"),
            q("abo-vergleich", "Sind meine Abo-Kosten gestiegen?", ["sin", "sind"], ["abo", "gestiegen", "kosten"], .monthCompare, "Abos"),
            q("abo-liste", "Liste alle wiederkehrenden Zahlungen", ["lis", "list"], ["wiederkehrend", "zahlungen", "abo"], .allSubscriptions, "Abos"),
        ]

        // MARK: Kategorien (Erweiterung)
        list += [
            q("kat-essen", "Wie viel gebe ich für Essen aus?", ["wie", "wi"], ["essen", "ausgeben"], .byCategory, "Kategorien"),
            q("kat-shopping", "Was kostet mich Shopping?", ["was", "wa"], ["shopping", "kleidung"], .byCategory, "Kategorien"),
            q("kat-gesundheit", "Wie hoch sind meine Gesundheitsausgaben?", ["wie", "wi"], ["gesundheit", "apotheke"], .byCategory, "Kategorien"),
            q("kat-wohnen", "Was zahle ich für Wohnen und Nebenkosten?", ["was", "wa"], ["wohnen", "miete", "nebenkosten"], .byCategory, "Kategorien"),
            q("kat-vergleich", "Welche Kategorie ist gegenüber dem Vormonat gestiegen?", ["wel", "welch"], ["kategorie", "gestiegen", "vormonat"], .monthCompare, "Kategorien"),
            q("kat-detail", "Zeig Details zu meiner größten Kategorie", ["zeig", "zeige"], ["details", "größte", "kategorie"], .top3Categories, "Kategorien"),
        ]

        // MARK: Orte (Erweiterung)
        list += [
            q("ort-teuer", "An welchem Ort gebe ich am meisten aus?", ["an", "wel"], ["ort", "meisten", "aus"], .expensiveAreas, "Karte"),
            q("ort-haeufig", "Wo kaufe ich am häufigsten ein?", ["wo"], ["häufig", "haeufig", "kaufe"], .frequentAreas, "Karte"),
            q("ort-neu", "Gibt es neue Ausgabe-Hotspots?", ["gib", "gibt"], ["hotspot", "neu", "ort"], .expensiveAreas, "Karte"),
            q("ort-karte-heatmap", "Zeig mir die Ausgaben-Heatmap", ["zeig", "zeige"], ["heatmap", "karte", "ausgaben"], .openMap, "Karte"),
        ]

        // MARK: Gewohnheiten
        list += [
            q("gewohnheit-wochentag", "An welchem Wochentag gebe ich am meisten aus?", ["an", "wel"], ["wochentag", "meisten"], .whySpending, "Gewohnheiten"),
            q("gewohnheit-tageszeit", "Wann gebe ich tagsüber am meisten aus?", ["wan", "wann"], ["tagsüber", "tagsueber", "ausgeben"], .spendingPace, "Gewohnheiten"),
            q("gewohnheit-impuls", "Bin ich ein impulsiver Käufer?", ["bin", "bi"], ["impulsiv", "käufer", "kaeufer"], .analyzeMe, "Gewohnheiten"),
            q("gewohnheit-sparen", "Spare ich regelmäßig oder unregelmäßig?", ["spa", "spar"], ["regelmäßig", "regelmaessig", "sparen"], .analyzeMe, "Gewohnheiten"),
            q("gewohnheit-gehalt", "Gebe ich nach Gehaltseingang mehr aus?", ["geb", "gebe"], ["gehalt", "eingang", "mehr"], .whySpending, "Gewohnheiten"),
            q("gewohnheit-kleinst", "Habe ich viele kleine Ausgaben?", ["hab", "ha"], ["kleine", "ausgaben", "viele"], .unusualSpending, "Gewohnheiten"),
            q("gewohnheit-disziplin", "Wie diszipliniert sind meine Ausgaben?", ["wie", "wi"], ["diszipliniert", "ausgaben"], .analyzeMe, "Gewohnheiten"),
        ]

        // MARK: Finanzprofil (Erweiterung)
        list += [
            q("profil-typ", "Welcher Finanztyp bin ich?", ["wel", "welch"], ["finanztyp", "typ"], .analyzeMe, "Profil"),
            q("profil-score-detail", "Erkläre mir meinen Finanz-Score", ["erk", "erkl"], ["score", "finanz"], .analyzeMe, "Profil"),
            q("profil-verhalten", "Wie ist mein Ausgabeverhalten?", ["wie", "wi"], ["ausgabeverhalten", "verhalten"], .analyzeMe, "Profil"),
            q("profil-verbesserung", "Wie kann ich mein Finanzprofil verbessern?", ["wie", "wi"], ["profil", "verbessern"], .analyzeMe, "Profil"),
            q("profil-staerke-schwaeche", "Was sind meine Stärken und Schwächen?", ["was", "wa"], ["stärken", "schwächen", "staerken"], .analyzeMe, "Profil"),
        ]

        // MARK: Wochenbudget (Erweiterung)
        list += [
            q("wochenbudget-heute", "Wie viel darf ich heute noch ausgeben?", ["wie", "wi"], ["heute", "darf", "ausgeben"], .weeklyBudget, "Entscheiden"),
            q("wochenbudget-rest", "Wie viel Budget habe ich diese Woche noch?", ["wie", "wi"], ["budget", "woche", "noch"], .weeklyBudget, "Entscheiden"),
            q("wochenbudget-ueberschritten", "Habe ich mein Wochenbudget überschritten?", ["hab", "ha"], ["wochenbudget", "überschritten"], .weeklyBudget, "Entscheiden"),
            q("wochenbudget-tipp", "Wie halte ich mein Wochenbudget ein?", ["wie", "wi"], ["wochenbudget", "halten"], .weeklyBudget, "Entscheiden"),
        ]

        // MARK: Prognosen
        list += [
            q("prog-monatsende", "Wie viel werde ich am Monatsende ausgegeben haben?", ["wie", "wi"], ["monatsende", "ausgegeben", "werde"], .spendingPace, "Prognosen"),
            q("prog-sparquote", "Wie wird meine Sparquote am Monatsende aussehen?", ["wie", "wi"], ["sparquote", "monatsende"], .spendingPace, "Prognosen"),
            q("prog-jahr", "Wie viel spare ich im Jahr voraussichtlich?", ["wie", "wi"], ["jahr", "spare", "voraussichtlich"], .whatIf, "Prognosen"),
            q("prog-ziel", "Wann erreiche ich mein Ziel bei aktuellem Tempo?", ["wan", "wann"], ["ziel", "tempo", "erreiche"], .goalsProgress, "Prognosen"),
            q("prog-saldo", "Wie wird mein Saldo am Monatsende aussehen?", ["wie", "wi"], ["saldo", "monatsende"], .balance, "Prognosen"),
            q("prog-trend", "Steigen oder sinken meine Ausgaben langfristig?", ["ste", "stei"], ["steigen", "sinken", "langfristig"], .monthCompare, "Prognosen"),
        ]

        // MARK: Vergleiche
        list += [
            q("vergl-woche-vorwoche", "Diese Woche vs. letzte Woche — wie stehe ich?", ["die", "dies"], ["woche", "letzte", "vergleich"], .last7Days, "Vergleiche"),
            q("vergl-kategorie-vormonat", "Welche Kategorie ist im Vergleich zum Vormonat gestiegen?", ["wel", "welch"], ["kategorie", "vormonat", "gestiegen"], .monthCompare, "Vergleiche"),
            q("vergl-einnahmen-ausgaben", "Vergleiche Einnahmen und Ausgaben diesen Monat", ["ver", "verg"], ["einnahmen", "ausgaben", "vergleich"], .incomeVsExpense, "Vergleiche"),
            q("vergl-sparquote", "Ist meine Sparquote besser als letzten Monat?", ["is", "ist"], ["sparquote", "besser", "monat"], .monthCompare, "Vergleiche"),
            q("vergl-haendler", "Welcher Händler ist teurer geworden?", ["wel", "welch"], ["händler", "teurer", "haendler"], .merchantBreakdown, "Vergleiche"),
            q("vergl-jahr", "Bin ich dieses Jahr sparsamer als letztes Jahr?", ["bin", "bi"], ["jahr", "sparsamer"], .analyzeMe, "Vergleiche"),
            q("vergl-budget", "Liege ich über oder unter meinem üblichen Budget?", ["lie", "lig"], ["budget", "über", "unter"], .weeklyBudget, "Vergleiche"),
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
            .folding(options: .diacriticInsensitive, locale: .current)
        guard !trimmed.isEmpty else { return [] }

        let words = trimmed.split(separator: " ").map(String.init)
        let firstWord = words.first ?? trimmed
        let secondWord = words.count > 1 ? words[1] : nil
        var scored: [(AssistantQuestion, Int)] = []
        scored.reserveCapacity(min(48, indexed.count))

        for item in indexed {
            var score = 0
            let q = item.q
            let promptNorm = item.promptLower
                .folding(options: .diacriticInsensitive, locale: .current)

            if q.prefixes.contains(where: { firstWord.hasPrefix($0) || $0.hasPrefix(firstWord) }) {
                score += 40
            }
            if let secondWord,
               q.prefixes.contains(where: { secondWord.hasPrefix($0) || $0.hasPrefix(secondWord) }) {
                score += 18
            }
            if promptNorm.hasPrefix(trimmed) {
                score += 55
            } else if promptNorm.contains(trimmed) {
                score += 28
            }
            var keywordHits = 0
            for kw in q.keywords where trimmed.contains(kw) {
                score += 15
                keywordHits += 1
            }
            if keywordHits >= 2 { score += 12 }
            if keywordHits >= 3 { score += 10 }
            if q.prefixes.contains(where: { trimmed.hasPrefix($0) }) {
                score += 22
            }
            for word in words where word.count >= 3 && promptNorm.contains(word) {
                score += 6
            }
            if score > 0 {
                scored.append((q, score))
            }
        }

        scored.sort { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.prompt.count < rhs.0.prompt.count
        }
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
