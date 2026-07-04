import Foundation
import WidgetKit

enum WidgetDataSync {
    @MainActor
    static func writeSnapshot(from store: FinanceStore) {
        let top = store.topCategoryThisMonth
        let primaryGoal = store.goals.max(by: { $0.progress < $1.progress })
        let snapshot = WidgetSnapshot(
            balance: store.currentBalance,
            monthExpenses: store.currentMonthExpenses,
            monthIncome: store.currentMonthIncome,
            topCategoryName: top?.0.rawValue,
            topCategoryAmount: top?.1 ?? 0,
            savingsProgressPercent: primaryGoal?.progressPercent ?? 0,
            primaryGoalName: primaryGoal?.name,
            updatedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults(suiteName: LiveCashAppGroup.identifier)?.set(data, forKey: LiveCashAppGroup.widgetSnapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func loadSnapshot() -> WidgetSnapshot {
        guard let data = UserDefaults(suiteName: LiveCashAppGroup.identifier)?.data(forKey: LiveCashAppGroup.widgetSnapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}
