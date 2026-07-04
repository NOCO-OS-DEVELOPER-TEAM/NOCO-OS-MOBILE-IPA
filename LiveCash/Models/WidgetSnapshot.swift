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

    static let empty = WidgetSnapshot(
        balance: 0,
        monthExpenses: 0,
        monthIncome: 0,
        topCategoryName: nil,
        topCategoryAmount: 0,
        savingsProgressPercent: 0,
        primaryGoalName: nil,
        updatedAt: Date()
    )
}

enum LiveCashAppGroup {
    static let identifier = "group.de.noco.timepay"
    static let widgetSnapshotKey = "livecash_widget_snapshot"
}
