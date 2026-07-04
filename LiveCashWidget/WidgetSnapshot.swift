import Foundation

struct WidgetSnapshot: Codable {
    var balance: Double
    var monthExpenses: Double
    var monthIncome: Double
    var topCategoryName: String?
    var topCategoryAmount: Double
    var savingsProgressPercent: Int
    var primaryGoalName: String?
    var updatedAt: Date
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
