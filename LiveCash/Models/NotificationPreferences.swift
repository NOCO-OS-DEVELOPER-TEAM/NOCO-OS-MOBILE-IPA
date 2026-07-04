import Foundation

struct NotificationPreferences: Codable, Equatable {
    var weekdayPatterns: Bool = true
    var spontaneousSpending: Bool = true
    var incomeReactions: Bool = true
    var subscriptionReminders: Bool = true
    var softEngagement: Bool = true
    var assistantSuggestionsOnIdle: Bool = true
    var monthStartReminder: Bool = true
    var weeklyReminder: Bool = true
    var savingsMonthReminder: Bool = true
    var financeCheckWeekly: Bool = true
    var highSpendingAlerts: Bool = true
    var unusualActivityAlerts: Bool = true
    var goalProgressAlerts: Bool = true
}
