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

    var defaultBillingDays: Int {
        switch self {
        case .weekly: return 7
        case .monthly: return 30
        case .yearly: return 365
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
    var startDate: Date
    var billingPeriodDays: Int
    var category: FinanceCategory
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        frequency: SubscriptionFrequency = .monthly,
        detectedFromTransactions: Bool = false,
        lastSeen: Date? = nil,
        startDate: Date = Date(),
        billingPeriodDays: Int? = nil,
        category: FinanceCategory = .subscription,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.detectedFromTransactions = detectedFromTransactions
        self.lastSeen = lastSeen
        self.startDate = startDate
        self.billingPeriodDays = billingPeriodDays ?? frequency.defaultBillingDays
        self.category = category
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, amount, frequency, detectedFromTransactions, lastSeen
        case startDate, billingPeriodDays, category, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        amount = try c.decode(Double.self, forKey: .amount)
        frequency = try c.decode(SubscriptionFrequency.self, forKey: .frequency)
        detectedFromTransactions = try c.decode(Bool.self, forKey: .detectedFromTransactions)
        lastSeen = try c.decodeIfPresent(Date.self, forKey: .lastSeen)
        let fallback = lastSeen ?? Date()
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate) ?? fallback
        billingPeriodDays = try c.decodeIfPresent(Int.self, forKey: .billingPeriodDays) ?? frequency.defaultBillingDays
        category = try c.decodeIfPresent(FinanceCategory.self, forKey: .category) ?? .subscription
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? fallback
    }

    var monthlyCost: Double {
        amount * (30.0 / Double(max(billingPeriodDays, 1)))
    }

    var yearlyCost: Double {
        monthlyCost * 12
    }

    var nextRenewalDate: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var next = cal.startOfDay(for: startDate)
        let period = max(billingPeriodDays, 1)
        while next <= today {
            next = cal.date(byAdding: .day, value: period, to: next) ?? next.addingTimeInterval(86400 * Double(period))
        }
        return next
    }

    var daysUntilRenewal: Int {
        let cal = Calendar.current
        return max(
            cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: nextRenewalDate)).day ?? 0,
            0
        )
    }

    var billingPeriodLabel: String {
        switch billingPeriodDays {
        case 7: return "7 Tage"
        case 30: return "30 Tage"
        case 365: return "365 Tage"
        default: return "\(billingPeriodDays) Tage"
        }
    }
}
