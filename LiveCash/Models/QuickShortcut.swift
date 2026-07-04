import Foundation

struct QuickShortcut: Identifiable, Codable, Equatable {
    var id: UUID
    var merchant: String
    var amount: Double
    var type: TransactionType
    var category: FinanceCategory
    var location: TransactionLocation?
    var sortOrder: Int
    var isUserDefined: Bool

    init(
        id: UUID = UUID(),
        merchant: String,
        amount: Double,
        type: TransactionType = .expense,
        category: FinanceCategory = .other,
        location: TransactionLocation? = nil,
        sortOrder: Int = 0,
        isUserDefined: Bool = false
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = abs(amount)
        self.type = type
        self.category = category
        self.location = location
        self.sortOrder = sortOrder
        self.isUserDefined = isUserDefined
    }

    var label: String {
        String(format: "%@ %.0f€", merchant, amount)
    }
}
