import Foundation
import WidgetKit

enum WidgetDataSync {
    @MainActor
    static func writeSnapshot(from store: FinanceStore) {
        let top = store.topCategoryThisMonth
        let primaryGoal = store.activeGoals.first ?? store.goals.max(by: { $0.progress < $1.progress })
        let prefs = store.widgetPreferences
        let lastExpense = store.accountFilteredTransactions.first {
            $0.type == .expense && !FinanceStore.isGoalContribution($0)
        }
        let lastTx = store.accountFilteredTransactions.first { !FinanceStore.isGoalContribution($0) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970

        let day = max(Calendar.current.component(.day, from: Date()), 1)
        let weeklyBudget = (store.currentMonthExpenses / Double(day)) * 7
        let score = AnalyzeMeEngine.analyze(store: store).score

        let snapshot = WidgetSnapshot(
            balance: store.availableBalance,
            monthExpenses: store.currentMonthExpenses,
            monthIncome: store.currentMonthIncome,
            topCategoryName: top?.0.rawValue,
            topCategoryAmount: top?.1 ?? 0,
            savingsProgressPercent: primaryGoal?.progressPercent ?? 0,
            primaryGoalName: primaryGoal?.name,
            monthlySubscriptionCost: store.monthlySubscriptionCost,
            lastExpenseMerchant: lastExpense?.merchant,
            lastExpenseAmount: lastExpense?.amount ?? 0,
            lastTransactionMerchant: lastTx?.merchant,
            lastTransactionAmount: lastTx?.amount ?? 0,
            lastTransactionIsIncome: lastTx?.type == .income,
            refreshIntervalMinutes: prefs.refreshIntervalMinutes,
            showBalance: prefs.showBalance,
            showExpenses: prefs.showExpenses,
            showSavings: prefs.showSavings,
            showSubscriptions: prefs.showSubscriptions,
            showRecentExpense: prefs.showRecentExpense,
            updatedAt: Date(),
            hasLiveData: true,
            blockedInGoals: store.blockedInGoals,
            totalWealth: store.totalWealth,
            financeScore: score,
            coins: store.loginReward.coins,
            weeklyBudget: weeklyBudget,
            loginStreakDays: store.loginReward.loginStreakDays
        )

        guard let data = try? encoder.encode(snapshot) else { return }

        // 1) App Group UserDefaults
        if let defaults = UserDefaults(suiteName: LiveCashAppGroup.identifier) {
            defaults.set(data, forKey: LiveCashAppGroup.widgetSnapshotKey)
            defaults.synchronize()
        }

        // 2) Shared container file (fallback if defaults fail)
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: LiveCashAppGroup.identifier
        ) {
            let file = container.appendingPathComponent(LiveCashAppGroup.widgetSnapshotFileName)
            try? data.write(to: file, options: .atomic)
        }

        WidgetCenter.shared.reloadAllTimelines()
        WidgetCenter.shared.reloadTimelines(ofKind: "LiveCashWidget")
    }

    @MainActor
    static func clearSnapshot() {
        if let defaults = UserDefaults(suiteName: LiveCashAppGroup.identifier) {
            defaults.removeObject(forKey: LiveCashAppGroup.widgetSnapshotKey)
            defaults.synchronize()
        }
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: LiveCashAppGroup.identifier
        ) {
            let file = container.appendingPathComponent(LiveCashAppGroup.widgetSnapshotFileName)
            try? FileManager.default.removeItem(at: file)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func loadSnapshot() -> WidgetSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        if let data = UserDefaults(suiteName: LiveCashAppGroup.identifier)?.data(forKey: LiveCashAppGroup.widgetSnapshotKey),
           let snap = try? decoder.decode(WidgetSnapshot.self, from: data) {
            return snap
        }

        // Legacy ISO8601 snapshots
        let iso = JSONDecoder()
        iso.dateDecodingStrategy = .iso8601
        if let data = UserDefaults(suiteName: LiveCashAppGroup.identifier)?.data(forKey: LiveCashAppGroup.widgetSnapshotKey),
           let snap = try? iso.decode(WidgetSnapshot.self, from: data) {
            return snap
        }

        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: LiveCashAppGroup.identifier
        ) {
            let file = container.appendingPathComponent(LiveCashAppGroup.widgetSnapshotFileName)
            if let data = try? Data(contentsOf: file) {
                if let snap = try? decoder.decode(WidgetSnapshot.self, from: data) { return snap }
                if let snap = try? iso.decode(WidgetSnapshot.self, from: data) { return snap }
            }
        }

        return .empty
    }
}
