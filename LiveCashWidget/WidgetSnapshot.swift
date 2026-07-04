import Foundation

struct WidgetSnapshot: Codable {
    var balance: Double
    var monthExpenses: Double
    var monthIncome: Double
    var topCategoryName: String?
    var topCategoryAmount: Double
    var savingsProgressPercent: Int
    var primaryGoalName: String?
    var monthlySubscriptionCost: Double
    var showBalance: Bool
    var showExpenses: Bool
    var showSavings: Bool
    var showSubscriptions: Bool
    var updatedAt: Date

    init(
        balance: Double,
        monthExpenses: Double,
        monthIncome: Double,
        topCategoryName: String?,
        topCategoryAmount: Double,
        savingsProgressPercent: Int,
        primaryGoalName: String?,
        monthlySubscriptionCost: Double = 0,
        showBalance: Bool = true,
        showExpenses: Bool = true,
        showSavings: Bool = true,
        showSubscriptions: Bool = true,
        updatedAt: Date
    ) {
        self.balance = balance
        self.monthExpenses = monthExpenses
        self.monthIncome = monthIncome
        self.topCategoryName = topCategoryName
        self.topCategoryAmount = topCategoryAmount
        self.savingsProgressPercent = savingsProgressPercent
        self.primaryGoalName = primaryGoalName
        self.monthlySubscriptionCost = monthlySubscriptionCost
        self.showBalance = showBalance
        self.showExpenses = showExpenses
        self.showSavings = showSavings
        self.showSubscriptions = showSubscriptions
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        balance = try c.decode(Double.self, forKey: .balance)
        monthExpenses = try c.decode(Double.self, forKey: .monthExpenses)
        monthIncome = try c.decode(Double.self, forKey: .monthIncome)
        topCategoryName = try c.decodeIfPresent(String.self, forKey: .topCategoryName)
        topCategoryAmount = try c.decodeIfPresent(Double.self, forKey: .topCategoryAmount) ?? 0
        savingsProgressPercent = try c.decodeIfPresent(Int.self, forKey: .savingsProgressPercent) ?? 0
        primaryGoalName = try c.decodeIfPresent(String.self, forKey: .primaryGoalName)
        monthlySubscriptionCost = try c.decodeIfPresent(Double.self, forKey: .monthlySubscriptionCost) ?? 0
        showBalance = try c.decodeIfPresent(Bool.self, forKey: .showBalance) ?? true
        showExpenses = try c.decodeIfPresent(Bool.self, forKey: .showExpenses) ?? true
        showSavings = try c.decodeIfPresent(Bool.self, forKey: .showSavings) ?? true
        showSubscriptions = try c.decodeIfPresent(Bool.self, forKey: .showSubscriptions) ?? true
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
}

enum WidgetConstants {
    static let appGroup = "group.de.noco.timepay"
    static let snapshotKey = "livecash_widget_snapshot"
}

enum WidgetSnapshotLoader {
    static func load() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: WidgetConstants.appGroup)?.data(forKey: WidgetConstants.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}
