import Foundation

@MainActor
final class LiveIntelligenceEngine {
    static let shared = LiveIntelligenceEngine()

    private let merchantHints = ["netflix", "spotify", "lidl", "aldi", "rewe", "amazon", "dm", "apple", "disney", "prime", "uber"]

    func interpret(_ partial: String) -> InputInterpretation {
        let t = partial.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return .empty }

        guard let draft = SmartInputParser.shared.parseSingle(t) else {
            if SmartInputParser.shared.isLikelyQuery(t) {
                return InputInterpretation(
                    amount: nil, type: nil, category: nil, merchant: nil,
                    isUncertain: false,
                    hint: "Analyse-Anfrage erkannt"
                )
            }
            return .empty
        }

        let uncertain = isUncertainInput(t, draft: draft)
        let typeLabel = draft.type == .income ? "Einnahme" : "Ausgabe"
        let hint = uncertain
            ? "Unklar — bitte bestätigen"
            : "\(typeLabel) · \(draft.category.rawValue)"

        return InputInterpretation(
            amount: draft.amount,
            type: draft.type,
            category: draft.category,
            merchant: draft.merchant,
            isUncertain: uncertain,
            hint: hint
        )
    }

    func liveSuggestions(for partial: String, store: FinanceStore) -> [LiveSuggestion] {
        let t = partial.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return idleSuggestions(store) }

        let lower = t.lowercased()

        if let merchant = merchantHints.first(where: { lower.contains($0) }) {
            return merchantSuggestions(merchant: merchant.capitalized, partial: t, store: store)
        }

        if lower.hasPrefix("spar") || lower.contains(" spar") {
            return [
                LiveSuggestion(title: "Wie kann ich am besten sparen?", action: .insight(.savingsTips)),
                LiveSuggestion(title: "Top-Ausgaben reduzieren", action: .insight(.top5Expenses)),
                LiveSuggestion(title: "Monatsübersicht analysieren", action: .insight(.monthlySummary))
            ]
        }

        if lower.contains("abo") || lower.contains("abonn") {
            return [
                LiveSuggestion(title: "Alle Abos anzeigen", action: .insight(.monthlySubCost)),
                LiveSuggestion(title: "Einspar-Potenzial prüfen", action: .insight(.potentialSavings)),
                LiveSuggestion(title: "Jährliche Abo-Kosten", action: .insight(.yearlySubCost))
            ]
        }

        if lower.contains("wo gebe") || lower.contains("ausgab") || lower.contains("meiste") {
            return [
                LiveSuggestion(title: "Wo gebe ich am meisten aus?", action: .submitText("wo gebe ich am meisten aus")),
                LiveSuggestion(title: "Nach Kategorie", action: .insight(.byCategory)),
                LiveSuggestion(title: "Nach Händler", action: .insight(.byMerchant))
            ]
        }

        if lower.contains("übersicht") || lower.contains("monat") {
            return [
                LiveSuggestion(title: "Monatsübersicht", action: .insight(.monthlySummary)),
                LiveSuggestion(title: "Einnahmen vs. Ausgaben", action: .insight(.incomeVsExpense)),
                LiveSuggestion(title: "Ausgaben-Tempo", action: .insight(.spendingPace))
            ]
        }

        if let draft = SmartInputParser.shared.parseSingle(t), SmartInputParser.shared.containsAmount(t) {
            if isUncertainInput(t, draft: draft) {
                return [
                    LiveSuggestion(title: "Als Ausgabe speichern", action: .saveDraft(uncertainDraft(draft, type: .expense))),
                    LiveSuggestion(title: "Als Einnahme speichern", action: .saveDraft(uncertainDraft(draft, type: .income))),
                    LiveSuggestion(title: "Kategorie: \(draft.category.rawValue)", action: .saveDraft(draft))
                ]
            }
            let sign = draft.type == .income ? "+" : "-"
            return [
                LiveSuggestion(
                    title: "Speichern: \(draft.merchant) \(sign)\(String(format: "%.2f", draft.amount))€",
                    action: .saveDraft(draft)
                ),
                LiveSuggestion(title: "Kategorie ändern → Lebensmittel", action: .saveDraft(copy(draft, category: .food))),
                LiveSuggestion(title: "Kategorie ändern → Einkaufen", action: .saveDraft(copy(draft, category: .shopping)))
            ]
        }

        if lower.hasPrefix("wie ") || lower.hasPrefix("was ") || lower.contains("?") {
            return [
                LiveSuggestion(title: "Ausgaben nach Kategorie", action: .insight(.byCategory)),
                LiveSuggestion(title: "Letzte Transaktionen", action: .insight(.recentTransactions)),
                LiveSuggestion(title: "Spar-Tipps", action: .insight(.savingsTips))
            ]
        }

        return [
            LiveSuggestion(title: "Finanzübersicht", action: .insight(.incomeVsExpense)),
            LiveSuggestion(title: "Top-Ausgaben", action: .insight(.top5Expenses)),
            LiveSuggestion(title: "Spar-Analyse", action: .insight(.savingsTips))
        ]
    }

    func isUncertainInput(_ text: String, draft: ParsedTransactionDraft) -> Bool {
        let lower = text.lowercased()
        let vague = ["irgendwas", "etwas", "unklar", "diverses", "sonstiges", "xyz", "test"]
        if vague.contains(where: { lower.contains($0) }) { return true }
        if draft.merchant.lowercased() == "unbekannt" { return true }
        if draft.merchant.count <= 2 && draft.amount > 0 { return true }
        let words = lower.split(separator: " ").map(String.init)
        if words.count == 1, draft.amount > 0, Double(words[0].replacingOccurrences(of: ",", with: ".")) != nil {
            return true
        }
        return false
    }

    private func idleSuggestions(_ store: FinanceStore) -> [LiveSuggestion] {
        if store.transactions.isEmpty {
            return [
                LiveSuggestion(title: "Beispiel: Kaffee 4,50", action: .submitText("Kaffee 4,50")),
                LiveSuggestion(title: "Monatsübersicht", action: .insight(.monthlySummary)),
                LiveSuggestion(title: "Spar-Tipps", action: .insight(.savingsTips))
            ]
        }
        return [
            LiveSuggestion(title: "Wo gebe ich am meisten aus?", action: .submitText("wo gebe ich am meisten aus")),
            LiveSuggestion(title: "Monatsübersicht", action: .insight(.monthlySummary)),
            LiveSuggestion(title: "Top-Ausgaben", action: .insight(.top5Expenses))
        ]
    }

    private func merchantSuggestions(merchant: String, partial: String, store: FinanceStore) -> [LiveSuggestion] {
        let yearly = store.subscriptions.first(where: { $0.name.lowercased().contains(merchant.lowercased()) })?.yearlyCost
        var items: [LiveSuggestion] = [
            LiveSuggestion(title: "Abo hinzufügen: \(merchant)", action: .addSubscription(name: merchant)),
            LiveSuggestion(title: "Wie viel kostet \(merchant)?", action: .submitText("was kostet \(merchant.lowercased())")),
            LiveSuggestion(title: "Alle Abos anzeigen", action: .insight(.allSubscriptions))
        ]
        if let yearly {
            items[1] = LiveSuggestion(title: "\(merchant): \(String(format: "%.0f€", yearly))/Jahr", action: .insight(.monthlySubCost))
        }
        if let draft = SmartInputParser.shared.parseSingle(partial), SmartInputParser.shared.containsAmount(partial) {
            items[0] = LiveSuggestion(title: "Speichern: \(merchant)", action: .saveDraft(draft))
        }
        return Array(items.prefix(3))
    }

    private func uncertainDraft(_ draft: ParsedTransactionDraft, type: TransactionType) -> ParsedTransactionDraft {
        var d = draft
        d.type = type
        d.category = type == .income ? .income : d.category
        return d
    }

    private func copy(_ draft: ParsedTransactionDraft, category: FinanceCategory) -> ParsedTransactionDraft {
        var d = draft
        d.category = category
        return d
    }
}
