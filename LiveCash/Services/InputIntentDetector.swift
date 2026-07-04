import Foundation

enum DetectedInputIntent: Equatable {
    case advisory(FinanceIntent)
    case subscription
    case goalContribution
    case transaction
    case unclear
}

@MainActor
enum InputIntentDetector {
    private static let savingsKeywords = ["sparen", "sparziel", "spar-tip", "spar tip", "sparplan", "finanzberatung"]
    private static let subscriptionKeywords = ["abo", "abonnement", "subscription", "netflix", "spotify", "disney", "prime"]
    private static let goalKeywords = ["sparziel", "zum sparziel", "sparen auf", "goal"]
    private static let bookingKeywords = ["eingeben", "buchen", "eintragen", "hinzufügen"]

    static func detect(_ text: String, store: FinanceStore) -> DetectedInputIntent {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        guard !trimmed.isEmpty else { return .unclear }

        if goalKeywords.contains(where: { lower.contains($0) }),
           store.goals.isEmpty == false,
           SmartInputParser.shared.containsAmount(trimmed) {
            return .goalContribution
        }

        if savingsKeywords.contains(where: { lower.contains($0) }),
           !SmartInputParser.shared.containsAmount(trimmed) {
            return .advisory(.save)
        }

        if subscriptionKeywords.contains(where: { lower.contains($0) }) {
            if SmartInputParser.shared.containsAmount(trimmed) {
                return .transaction
            }
            return .subscription
        }

        if SmartInputParser.shared.isLikelyQuery(trimmed) {
            if let intent = FinanceAssistant.shared.matchIntent(trimmed) {
                return .advisory(intent)
            }
            return .advisory(.overview)
        }

        if FinanceAssistant.shared.matchIntent(trimmed) != nil,
           !SmartInputParser.shared.looksLikeTransaction(trimmed) {
            return .advisory(FinanceAssistant.shared.matchIntent(trimmed) ?? .overview)
        }

        if SmartInputParser.shared.containsAmount(trimmed) {
            return .transaction
        }

        if bookingKeywords.contains(where: { lower.contains($0) }) {
            return .unclear
        }

        if lower == "abo" || lower.hasPrefix("abo ") {
            return .subscription
        }

        return .unclear
    }

    static func subscriptionDraft(from text: String) -> ParsedTransactionDraft? {
        guard let amount = SmartInputParser.shared.parseSingle(text)?.amount ?? extractLooseAmount(text) else {
            return nil
        }
        let merchant = text
            .replacingOccurrences(of: #"[\d.,€]+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let name = merchant.isEmpty ? "Abo" : merchant.capitalized
        return ParsedTransactionDraft(
            amount: amount,
            type: .expense,
            merchant: name,
            category: .subscription,
            date: Date()
        )
    }

    private static func extractLooseAmount(_ text: String) -> Double? {
        SmartInputParser.shared.parseSingle(text)?.amount
    }
}
