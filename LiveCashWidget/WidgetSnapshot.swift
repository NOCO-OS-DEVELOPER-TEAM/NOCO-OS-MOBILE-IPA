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
    var lastTransactionMerchant: String?
    var lastTransactionAmount: Double
    var lastTransactionIsIncome: Bool
    var refreshIntervalMinutes: Int
    var showBalance: Bool
    var showExpenses: Bool
    var showSavings: Bool
    var showSubscriptions: Bool
    var showRecentExpense: Bool
    var updatedAt: Date
    var hasLiveData: Bool
    var blockedInGoals: Double
    var totalWealth: Double
    var financeScore: Int
    var coins: Int
    var weeklyBudget: Double
    var loginStreakDays: Int

    static let empty = WidgetSnapshot(
        balance: 0, monthExpenses: 0, monthIncome: 0,
        topCategoryName: nil, topCategoryAmount: 0,
        savingsProgressPercent: 0, primaryGoalName: nil,
        monthlySubscriptionCost: 0,
        lastExpenseMerchant: nil, lastExpenseAmount: 0,
        lastTransactionMerchant: nil, lastTransactionAmount: 0,
        lastTransactionIsIncome: false, refreshIntervalMinutes: 15,
        showBalance: true, showExpenses: true, showSavings: true,
        showSubscriptions: true, showRecentExpense: true,
        updatedAt: .distantPast,
        hasLiveData: false,
        blockedInGoals: 0,
        totalWealth: 0,
        financeScore: 0,
        coins: 0,
        weeklyBudget: 0,
        loginStreakDays: 0
    )

    init(
        balance: Double,
        monthExpenses: Double,
        monthIncome: Double,
        topCategoryName: String?,
        topCategoryAmount: Double,
        savingsProgressPercent: Int,
        primaryGoalName: String?,
        monthlySubscriptionCost: Double = 0,
        lastExpenseMerchant: String? = nil,
        lastExpenseAmount: Double = 0,
        lastTransactionMerchant: String? = nil,
        lastTransactionAmount: Double = 0,
        lastTransactionIsIncome: Bool = false,
        refreshIntervalMinutes: Int = 15,
        showBalance: Bool = true,
        showExpenses: Bool = true,
        showSavings: Bool = true,
        showSubscriptions: Bool = true,
        showRecentExpense: Bool = true,
        updatedAt: Date,
        hasLiveData: Bool = true,
        blockedInGoals: Double = 0,
        totalWealth: Double = 0,
        financeScore: Int = 0,
        coins: Int = 0,
        weeklyBudget: Double = 0,
        loginStreakDays: Int = 0
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
        self.lastTransactionMerchant = lastTransactionMerchant
        self.lastTransactionAmount = lastTransactionAmount
        self.lastTransactionIsIncome = lastTransactionIsIncome
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.showBalance = showBalance
        self.showExpenses = showExpenses
        self.showSavings = showSavings
        self.showSubscriptions = showSubscriptions
        self.showRecentExpense = showRecentExpense
        self.updatedAt = updatedAt
        self.hasLiveData = hasLiveData
        self.blockedInGoals = blockedInGoals
        self.totalWealth = totalWealth
        self.financeScore = financeScore
        self.coins = coins
        self.weeklyBudget = weeklyBudget
        self.loginStreakDays = loginStreakDays
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
        lastTransactionMerchant = try c.decodeIfPresent(String.self, forKey: .lastTransactionMerchant)
        lastTransactionAmount = try c.decodeIfPresent(Double.self, forKey: .lastTransactionAmount) ?? 0
        lastTransactionIsIncome = try c.decodeIfPresent(Bool.self, forKey: .lastTransactionIsIncome) ?? false
        refreshIntervalMinutes = try c.decodeIfPresent(Int.self, forKey: .refreshIntervalMinutes) ?? 15
        showBalance = try c.decodeIfPresent(Bool.self, forKey: .showBalance) ?? true
        showExpenses = try c.decodeIfPresent(Bool.self, forKey: .showExpenses) ?? true
        showSavings = try c.decodeIfPresent(Bool.self, forKey: .showSavings) ?? true
        showSubscriptions = try c.decodeIfPresent(Bool.self, forKey: .showSubscriptions) ?? true
        showRecentExpense = try c.decodeIfPresent(Bool.self, forKey: .showRecentExpense) ?? true
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
        hasLiveData = try c.decodeIfPresent(Bool.self, forKey: .hasLiveData) ?? true
        blockedInGoals = try c.decodeIfPresent(Double.self, forKey: .blockedInGoals) ?? 0
        totalWealth = try c.decodeIfPresent(Double.self, forKey: .totalWealth) ?? balance
        financeScore = try c.decodeIfPresent(Int.self, forKey: .financeScore) ?? 0
        coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? 0
        weeklyBudget = try c.decodeIfPresent(Double.self, forKey: .weeklyBudget) ?? 0
        loginStreakDays = try c.decodeIfPresent(Int.self, forKey: .loginStreakDays) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case balance, monthExpenses, monthIncome, topCategoryName, topCategoryAmount
        case savingsProgressPercent, primaryGoalName, monthlySubscriptionCost
        case lastExpenseMerchant, lastExpenseAmount
        case lastTransactionMerchant, lastTransactionAmount, lastTransactionIsIncome, refreshIntervalMinutes
        case showBalance, showExpenses, showSavings, showSubscriptions, showRecentExpense, updatedAt
        case hasLiveData, blockedInGoals, totalWealth
        case financeScore, coins, weeklyBudget, loginStreakDays
    }
}

enum WidgetConstants {
    static let appGroup = "group.de.noco.timepay"
    static let snapshotKey = "livecash_widget_snapshot"
    static let snapshotFileName = "livecash_widget_snapshot.json"
}

enum WidgetSnapshotLoader {
    static func load() -> WidgetSnapshot {
        let primary = JSONDecoder()
        primary.dateDecodingStrategy = .secondsSince1970
        let legacy = JSONDecoder()
        legacy.dateDecodingStrategy = .iso8601

        func decode(_ data: Data) -> WidgetSnapshot? {
            if let snap = try? primary.decode(WidgetSnapshot.self, from: data) { return snap }
            if let snap = try? legacy.decode(WidgetSnapshot.self, from: data) { return snap }
            return nil
        }

        if let data = UserDefaults(suiteName: WidgetConstants.appGroup)?.data(forKey: WidgetConstants.snapshotKey),
           let snap = decode(data),
           snap.hasLiveData || snap.updatedAt.timeIntervalSince1970 > 1_000_000 {
            return snap
        }

        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WidgetConstants.appGroup
        ) {
            let file = container.appendingPathComponent(WidgetConstants.snapshotFileName)
            if let data = try? Data(contentsOf: file),
               let snap = decode(data),
               snap.hasLiveData || snap.updatedAt.timeIntervalSince1970 > 1_000_000 {
                return snap
            }
        }

        return .empty
    }
}
