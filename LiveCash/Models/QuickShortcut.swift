import Foundation

enum ShortcutActionType: String, Codable, CaseIterable, Identifiable {
    case book
    case assistant
    case overview
    case map
    case goals

    var id: String { rawValue }

    var label: String {
        switch self {
        case .book: return "Buchung erstellen"
        case .assistant: return "Smart Assistant"
        case .overview: return "Übersicht"
        case .map: return "Geldkarte öffnen"
        case .goals: return "Sparziele öffnen"
        }
    }
}

struct QuickShortcut: Identifiable, Codable, Equatable {
    var id: UUID
    var merchant: String
    var amount: Double
    var type: TransactionType
    var category: FinanceCategory
    var location: TransactionLocation?
    var sortOrder: Int
    var isUserDefined: Bool
    var isPinned: Bool
    var actionType: ShortcutActionType

    init(
        id: UUID = UUID(),
        merchant: String,
        amount: Double,
        type: TransactionType = .expense,
        category: FinanceCategory = .other,
        location: TransactionLocation? = nil,
        sortOrder: Int = 0,
        isUserDefined: Bool = false,
        isPinned: Bool = false,
        actionType: ShortcutActionType = .book
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = abs(amount)
        self.type = type
        self.category = category
        self.location = location
        self.sortOrder = sortOrder
        self.isUserDefined = isUserDefined
        self.isPinned = isPinned
        self.actionType = actionType
    }

    var label: String {
        switch actionType {
        case .book:
            return String(format: "%@ %.0f€", merchant, amount)
        case .assistant:
            return merchant
        case .overview:
            return merchant
        case .map:
            return "Karte"
        case .goals:
            return "Sparziele"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, merchant, amount, type, category, location, sortOrder, isUserDefined, isPinned, actionType
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        merchant = try c.decode(String.self, forKey: .merchant)
        amount = try c.decode(Double.self, forKey: .amount)
        type = try c.decode(TransactionType.self, forKey: .type)
        category = try c.decode(FinanceCategory.self, forKey: .category)
        location = try c.decodeIfPresent(TransactionLocation.self, forKey: .location)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        isUserDefined = try c.decodeIfPresent(Bool.self, forKey: .isUserDefined) ?? false
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        actionType = try c.decodeIfPresent(ShortcutActionType.self, forKey: .actionType) ?? .book
    }
}
