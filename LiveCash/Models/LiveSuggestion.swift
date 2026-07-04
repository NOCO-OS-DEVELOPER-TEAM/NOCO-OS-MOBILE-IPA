import Foundation

struct LiveSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let action: LiveSuggestionAction

    init(id: String? = nil, title: String, action: LiveSuggestionAction) {
        self.id = id ?? title
        self.title = title
        self.action = action
    }
}

enum LiveSuggestionAction: Equatable {
    case submitText(String)
    case insight(InsightAction)
    case saveDraft(ParsedTransactionDraft)
    case addSubscription(name: String)
}

struct InputInterpretation: Equatable {
    var amount: Double?
    var type: TransactionType?
    var category: FinanceCategory?
    var merchant: String?
    var isUncertain: Bool
    var hint: String?

    static let empty = InputInterpretation(
        amount: nil, type: nil, category: nil, merchant: nil, isUncertain: false, hint: nil
    )
}

struct PendingConfirmation: Equatable {
    var draft: ParsedTransactionDraft
    var rawInput: String
    var message: String
}
