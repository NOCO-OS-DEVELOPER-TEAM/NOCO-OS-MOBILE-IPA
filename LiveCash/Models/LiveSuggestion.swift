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

enum InputConfidence: Equatable {
    case safe
    case uncertain
    case highRisk
}

struct ConfirmationOption: Identifiable, Equatable {
    let id: String
    let title: String
    let draft: ParsedTransactionDraft
}

struct InputInterpretation: Equatable {
    var amount: Double?
    var type: TransactionType?
    var category: FinanceCategory?
    var merchant: String?
    var confidence: InputConfidence
    var hint: String?

    var isUncertain: Bool { confidence != .safe }

    static let empty = InputInterpretation(
        amount: nil, type: nil, category: nil, merchant: nil, confidence: .safe, hint: nil
    )
}

struct PendingConfirmation: Equatable {
    var draft: ParsedTransactionDraft
    var rawInput: String
    var message: String
    var confidence: InputConfidence
    var options: [ConfirmationOption]

    init(
        draft: ParsedTransactionDraft,
        rawInput: String,
        message: String,
        confidence: InputConfidence = .uncertain,
        options: [ConfirmationOption] = []
    ) {
        self.draft = draft
        self.rawInput = rawInput
        self.message = message
        self.confidence = confidence
        self.options = options
    }
}

struct PendingShakeUndo: Equatable {
    var transaction: Transaction
}
