import Foundation

enum SubscriptionFrequency: String, Codable, CaseIterable {
    case weekly = "Wöchentlich"
    case monthly = "Monatlich"
    case yearly = "Jährlich"

    var multiplierToMonthly: Double {
        switch self {
        case .weekly: return 52.0 / 12.0
        case .monthly: return 1
        case .yearly: return 1.0 / 12.0
        }
    }
}

struct Subscription: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var amount: Double
    var frequency: SubscriptionFrequency
    var detectedFromTransactions: Bool
    var lastSeen: Date?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        frequency: SubscriptionFrequency = .monthly,
        detectedFromTransactions: Bool = false,
        lastSeen: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.detectedFromTransactions = detectedFromTransactions
        self.lastSeen = lastSeen
    }

    var monthlyCost: Double {
        amount * frequency.multiplierToMonthly
    }

    var yearlyCost: Double {
        monthlyCost * 12
    }
}
