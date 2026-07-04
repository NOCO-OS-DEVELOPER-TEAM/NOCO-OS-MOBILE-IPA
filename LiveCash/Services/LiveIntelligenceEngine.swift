import Foundation

@MainActor
final class LiveIntelligenceEngine {
    static let shared = LiveIntelligenceEngine()

    private let merchantHints = ["netflix", "spotify", "lidl", "aldi", "rewe", "amazon", "dm", "apple", "disney", "prime", "uber"]
    private let subscriptionHints = ["netflix", "spotify", "disney", "prime", "apple", "cursor", "chatgpt", "icloud", "abo", "subscription"]
    private let vagueTokens = ["irgendwas", "etwas", "unklar", "diverses", "sonstiges", "xyz", "test", "irgendwo", "keine ahnung"]

    func detectMode(for partial: String, store: FinanceStore) -> AssistantMode {
        let t = partial.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return .suggestion }
        if SmartInputParser.shared.isLikelyQuery(t) || t.contains("?") { return .question }
        if SmartInputParser.shared.containsAmount(t) || SmartInputParser.shared.looksLikeTransaction(t) { return .input }
        if FinanceAssistant.shared.matchIntent(t) != nil { return .question }
        return store.assistantModePreference
    }

    func classifyInputConfidence(
        _ text: String,
        draft: ParsedTransactionDraft,
        preferredType: TransactionType?,
        store: FinanceStore
    ) -> InputConfidence {
        let settings = store.appSettings.assistant
        let lower = text.lowercased()

        if vagueTokens.contains(where: { lower.contains($0) }) { return .highRisk }
        if draft.merchant.lowercased() == "unbekannt",
           !SmartInputParser.shared.hasExplicitType(in: text),
           preferredType == nil {
            return .highRisk
        }
        if draft.merchant.count <= 2, draft.amount > 0 { return .highRisk }

        if settings.subscriptionDetection,
           (subscriptionHints.contains(where: { lower.contains($0) }) || draft.category == .subscription) {
            return .uncertain
        }

        let words = lower.split(separator: " ").map(String.init)
        if words.count == 1, draft.amount > 0,
           Double(words[0].replacingOccurrences(of: ",", with: ".")) != nil {
            return .safe
        }

        if draft.merchant.lowercased() == "unbekannt" { return .uncertain }
        if settings.autoDetectIncomeExpense,
           !SmartInputParser.shared.hasExplicitType(in: text),
           preferredType == nil {
            return .uncertain
        }

        if settings.confidenceThreshold >= 80,
           draft.merchant.count <= 4 {
            return .uncertain
        }

        return .safe
    }

    func effectiveConfidence(_ base: InputConfidence, store: FinanceStore) -> InputConfidence {
        switch store.appSettings.assistant.confirmationMode {
        case .off:
            return .safe
        case .smart:
            if store.appSettings.assistant.confidenceThreshold >= 85, base == .uncertain {
                return .highRisk
            }
            if store.appSettings.assistant.confidenceThreshold <= 50, base == .uncertain {
                return .safe
            }
            return base
        case .strict:
            return base == .safe ? .uncertain : base
        }
    }

    func highRiskOptions(for draft: ParsedTransactionDraft, text: String) -> [ConfirmationOption] {
        var expense = draft
        expense.type = .expense
        if expense.category == .income { expense.category = .other }

        var income = draft
        income.type = .income
        income.category = .income

        var subscription = draft
        subscription.type = .expense
        subscription.category = .subscription

        return [
            ConfirmationOption(
                id: "expense",
                title: "Ausgabe · \(expense.merchant)",
                draft: expense
            ),
            ConfirmationOption(
                id: "income",
                title: "Einnahme · \(income.merchant)",
                draft: income
            ),
            ConfirmationOption(
                id: "subscription",
                title: "Abo · \(String(format: "%.2f€", subscription.amount))",
                draft: subscription
            )
        ]
    }

    func uncertainMessage(for draft: ParsedTransactionDraft, text: String) -> String {
        let lower = text.lowercased()
        if subscriptionHints.contains(where: { lower.contains($0) }) || draft.category == .subscription {
            return "Einmalige Zahlung oder Abo?"
        }
        if draft.merchant.lowercased() == "unbekannt" || draft.merchant.count <= 3 {
            return "Wofür war das? Bitte kurz bestätigen."
        }
        return "Ausgabe oder Einnahme?"
    }

    func interpret(_ partial: String, preferredType: TransactionType = .expense, store: FinanceStore) -> InputInterpretation {
        let t = partial.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return .empty }

        guard var draft = SmartInputParser.shared.parseSingle(t) else {
            if SmartInputParser.shared.isLikelyQuery(t) {
                return InputInterpretation(
                    amount: nil, type: nil, category: nil, merchant: nil,
                    confidence: .safe,
                    hint: "Frage — wähle eine Antwort"
                )
            }
            return .empty
        }

        SmartInputParser.shared.applyPreferredType(preferredType, to: &draft, text: t)
        let confidence = effectiveConfidence(
            classifyInputConfidence(t, draft: draft, preferredType: preferredType, store: store),
            store: store
        )
        let typeLabel = draft.type == .income ? "Einnahme" : "Ausgabe"

        let hint: String
        switch confidence {
        case .safe:
            hint = "\(typeLabel) · \(draft.merchant)"
        case .uncertain:
            hint = uncertainMessage(for: draft, text: t)
        case .highRisk:
            hint = "Mehrdeutig — bitte auswählen"
        }

        return InputInterpretation(
            amount: draft.amount,
            type: draft.type,
            category: draft.category,
            merchant: draft.merchant,
            confidence: confidence,
            hint: hint
        )
    }

    func liveSuggestions(for partial: String, store: FinanceStore) -> [LiveSuggestion] {
        let t = partial.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return [] }
        guard store.appSettings.assistant.suggestionsEnabled else { return [] }

        let mode = detectMode(for: partial, store: store)
        store.currentAssistantMode = mode

        let suggestions: [LiveSuggestion]
        switch mode {
        case .suggestion:
            suggestions = suggestionModeChips(for: t, store: store)
        case .question:
            suggestions = questionModeChips(for: t, store: store)
        case .input:
            suggestions = inputModeChips(for: t, store: store)
        }

        let limit: Int
        switch store.appSettings.assistant.suggestionIntensity {
        case .low: limit = 1
        case .medium, .high: limit = 3
        }
        return Array(suggestions.prefix(limit))
    }

    private func suggestionModeChips(for partial: String, store: FinanceStore) -> [LiveSuggestion] {
        let lower = partial.lowercased()
        if lower.contains("abo") {
            return [
                LiveSuggestion(title: "Alle Abos anzeigen", action: .insight(.allSubscriptions)),
                LiveSuggestion(title: "Monatliche Abo-Kosten", action: .insight(.monthlySubCost)),
                LiveSuggestion(title: "Einspar-Potenzial", action: .insight(.potentialSavings))
            ]
        }
        if store.transactions.isEmpty {
            return [
                LiveSuggestion(title: "Beispiel: Kaffee 4,50", action: .submitText("Kaffee 4,50"))
            ]
        }
        return [
            LiveSuggestion(title: "Wo gebe ich am meisten aus?", action: .submitText("wo gebe ich am meisten aus")),
            LiveSuggestion(title: "Monatsübersicht", action: .insight(.monthlySummary)),
            LiveSuggestion(title: "Einnahmen vs. Ausgaben", action: .insight(.incomeVsExpense))
        ]
    }

    private func questionModeChips(for partial: String, store: FinanceStore) -> [LiveSuggestion] {
        let lower = partial.lowercased()
        if lower.contains("abo") {
            return [
                LiveSuggestion(title: "Alle Abos anzeigen", action: .insight(.allSubscriptions)),
                LiveSuggestion(title: "Monatliche Abo-Kosten", action: .insight(.monthlySubCost)),
                LiveSuggestion(title: "Einspar-Potenzial", action: .insight(.potentialSavings))
            ]
        }
        if lower.contains("spar") {
            return [
                LiveSuggestion(title: "Spar-Tipps", action: .insight(.savingsTips)),
                LiveSuggestion(title: "Top-Ausgaben", action: .insight(.top5Expenses)),
                LiveSuggestion(title: "Ausgaben-Tempo", action: .insight(.spendingPace))
            ]
        }
        return [
            LiveSuggestion(title: "Antwort anzeigen", action: .submitText(partial)),
            LiveSuggestion(title: "Nach Kategorie", action: .insight(.byCategory)),
            LiveSuggestion(title: "Nach Händler", action: .insight(.byMerchant))
        ]
    }

    private func inputModeChips(for partial: String, store: FinanceStore) -> [LiveSuggestion] {
        let preferredType = store.inputMode

        guard var draft = SmartInputParser.shared.parseSingle(partial),
              SmartInputParser.shared.containsAmount(partial) else {
            return suggestionModeChips(for: partial, store: store)
        }

        SmartInputParser.shared.applyPreferredType(preferredType, to: &draft, text: partial)
        let confidence = effectiveConfidence(
            classifyInputConfidence(partial, draft: draft, preferredType: preferredType, store: store),
            store: store
        )

        switch confidence {
        case .safe:
            let sign = draft.type == .income ? "+" : "-"
            return [
                LiveSuggestion(
                    title: "Speichern: \(draft.merchant) \(sign)\(String(format: "%.2f", draft.amount))€",
                    action: .saveDraft(draft)
                )
            ]
        case .uncertain:
            var options = [
                LiveSuggestion(title: "Als Ausgabe speichern", action: .saveDraft(uncertainDraft(draft, type: .expense))),
                LiveSuggestion(title: "Als Einnahme speichern", action: .saveDraft(uncertainDraft(draft, type: .income)))
            ]
            if subscriptionHints.contains(where: { partial.lowercased().contains($0) }) || draft.category == .subscription {
                var sub = uncertainDraft(draft, type: .expense)
                sub.category = .subscription
                options.append(LiveSuggestion(title: "Als Abo buchen", action: .saveDraft(sub)))
            }
            return Array(options.prefix(3))
        case .highRisk:
            return highRiskOptions(for: draft, text: partial).map { option in
                LiveSuggestion(id: option.id, title: option.title, action: .saveDraft(option.draft))
            }
        }
    }

    func isUncertainInput(_ text: String, draft: ParsedTransactionDraft, preferredType: TransactionType? = nil, store: FinanceStore) -> Bool {
        effectiveConfidence(
            classifyInputConfidence(text, draft: draft, preferredType: preferredType, store: store),
            store: store
        ) != .safe
    }

    private func uncertainDraft(_ draft: ParsedTransactionDraft, type: TransactionType) -> ParsedTransactionDraft {
        var d = draft
        d.type = type
        d.category = type == .income ? .income : d.category
        return d
    }
}
