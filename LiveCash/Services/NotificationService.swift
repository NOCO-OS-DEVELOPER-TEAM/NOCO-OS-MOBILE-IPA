import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func refreshNotifications(for store: FinanceStore, enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }

        scheduleGoalProgress(store: store, center: center)
        scheduleSpendingAlerts(store: store, center: center)
        scheduleInactivityReminder(store: store, center: center)
    }

    private func scheduleGoalProgress(store: FinanceStore, center: UNUserNotificationCenter) {
        guard let goal = store.goals.max(by: { $0.progress < $1.progress }), goal.progress > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Sparziel: \(goal.name)"
        content.body = "Du bist bei \(goal.progressPercent)% — weiter so!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 26, repeats: false)
        center.add(UNNotificationRequest(identifier: "goal-progress", content: content, trigger: trigger))
    }

    private func scheduleSpendingAlerts(store: FinanceStore, center: UNUserNotificationCenter) {
        let today = store.todayExpenses
        guard today > 80 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Ausgaben heute"
        content.body = String(format: "Du hast heute bereits %.0f€ ausgegeben.", today)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 30, repeats: false)
        center.add(UNNotificationRequest(identifier: "spending-today", content: content, trigger: trigger))
    }

    private func scheduleInactivityReminder(store: FinanceStore, center: UNUserNotificationCenter) {
        guard let last = store.lastTransactionDate else { return }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        guard days >= 5 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Live Cash"
        content.body = "Du hast \(days) Tage keine Ausgaben eingetragen."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 48, repeats: false)
        center.add(UNNotificationRequest(identifier: "inactivity", content: content, trigger: trigger))
    }
}
