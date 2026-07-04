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
    var lastExpenseMerchant: String?
    var lastExpenseAmount: Double
    var showBalance: Bool
    var showExpenses: Bool
    var showSavings: Bool
    var showSubscriptions: Bool
    var showRecentExpense: Bool
    var updatedAt: Date

    static let empty = WidgetSnapshot(
        balance: 0,
        monthExpenses: 0,
        monthIncome: 0,
        topCategoryName: nil,
        topCategoryAmount: 0,
        savingsProgressPercent: 0,
        primaryGoalName: nil,
        monthlySubscriptionCost: 0,
        lastExpenseMerchant: nil,
        lastExpenseAmount: 0,
        showBalance: true,
        showExpenses: true,
        showSavings: true,
        showSubscriptions: true,
        showRecentExpense: true,
        updatedAt: Date()
    )

    init(
        balance: Double,
        monthExpenses: Double,
        monthIncome: Double,
        topCategoryName: String?,
        topCategoryAmount: Double,
        savingsProgressPercent: Int,
        primaryGoalName: String?,
        monthlySubscriptionCost: Double,
        lastExpenseMerchant: String?,
        lastExpenseAmount: Double,
        showBalance: Bool,
        showExpenses: Bool,
        showSavings: Bool,
        showSubscriptions: Bool,
        showRecentExpense: Bool,
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
        self.lastExpenseMerchant = lastExpenseMerchant
        self.lastExpenseAmount = lastExpenseAmount
        self.showBalance = showBalance
        self.showExpenses = showExpenses
        self.showSavings = showSavings
        self.showSubscriptions = showSubscriptions
        self.showRecentExpense = showRecentExpense
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
        lastExpenseMerchant = try c.decodeIfPresent(String.self, forKey: .lastExpenseMerchant)
        lastExpenseAmount = try c.decodeIfPresent(Double.self, forKey: .lastExpenseAmount) ?? 0
        showBalance = try c.decodeIfPresent(Bool.self, forKey: .showBalance) ?? true
        showExpenses = try c.decodeIfPresent(Bool.self, forKey: .showExpenses) ?? true
        showSavings = try c.decodeIfPresent(Bool.self, forKey: .showSavings) ?? true
        showSubscriptions = try c.decodeIfPresent(Bool.self, forKey: .showSubscriptions) ?? true
        showRecentExpense = try c.decodeIfPresent(Bool.self, forKey: .showRecentExpense) ?? true
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case balance, monthExpenses, monthIncome, topCategoryName, topCategoryAmount
        case savingsProgressPercent, primaryGoalName, monthlySubscriptionCost
        case lastExpenseMerchant, lastExpenseAmount
        case showBalance, showExpenses, showSavings, showSubscriptions, showRecentExpense, updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(balance, forKey: .balance)
        try c.encode(monthExpenses, forKey: .monthExpenses)
        try c.encode(monthIncome, forKey: .monthIncome)
        try c.encodeIfPresent(topCategoryName, forKey: .topCategoryName)
        try c.encode(topCategoryAmount, forKey: .topCategoryAmount)
        try c.encode(savingsProgressPercent, forKey: .savingsProgressPercent)
        try c.encodeIfPresent(primaryGoalName, forKey: .primaryGoalName)
        try c.encode(monthlySubscriptionCost, forKey: .monthlySubscriptionCost)
        try c.encodeIfPresent(lastExpenseMerchant, forKey: .lastExpenseMerchant)
        try c.encode(lastExpenseAmount, forKey: .lastExpenseAmount)
        try c.encode(showBalance, forKey: .showBalance)
        try c.encode(showExpenses, forKey: .showExpenses)
        try c.encode(showSavings, forKey: .showSavings)
        try c.encode(showSubscriptions, forKey: .showSubscriptions)
        try c.encode(showRecentExpense, forKey: .showRecentExpense)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

struct WidgetPreferences: Codable, Equatable {
    var showBalance: Bool = true
    var showExpenses: Bool = true
    var showSavings: Bool = true
    var showSubscriptions: Bool = true
    var showRecentExpense: Bool = true
    var refreshIntervalMinutes: Int = 15
}

enum LiveCashAppGroup {
    static let identifier = "group.de.noco.timepay"
    static let widgetSnapshotKey = "livecash_widget_snapshot"
}
