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

        scheduleSoftLimitWarnings(store: store, center: center)

        for payload in NotificationBehaviorEngine.scheduledPayloads(for: store, limit: 4) {
            schedule(payload, center: center)
        }
    }

    func notifyTransactionAdded(_ transaction: Transaction, store: FinanceStore) {
        guard store.notificationsEnabled else { return }
        let prefs = store.notificationPreferences
        let center = UNUserNotificationCenter.current()

        if prefs.incomeReactions, let payload = NotificationBehaviorEngine.incomeReaction(for: transaction, store: store) {
            schedule(payload, center: center)
        }
        if prefs.spontaneousSpending, transaction.type == .expense,
           let payload = NotificationBehaviorEngine.spontaneousSpendingAlert(recentWindow: store) {
            schedule(payload, center: center)
        }
    }

    private func schedule(_ payload: SmartNotificationPayload, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default
        content.userInfo = ["kind": payload.kind.rawValue]

        let trigger: UNNotificationTrigger
        if let calendar = payload.calendar {
            trigger = UNCalendarNotificationTrigger(dateMatching: calendar, repeats: payload.repeats)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(payload.delay, 1), repeats: false)
        }

        center.add(UNNotificationRequest(identifier: payload.id, content: content, trigger: trigger))
    }

    private func scheduleSoftLimitWarnings(store: FinanceStore, center: UNUserNotificationCenter) {
        guard store.spendingLimits.enabled, let daily = store.spendingLimits.dailyLimit else { return }
        let used = store.todayExpenses / daily
        guard used >= 0.9 && used < 1.0 else { return }
        schedule(SmartNotificationPayload(
            id: "soft-daily",
            title: "Tageslimit",
            body: String(format: "Du hast %.0f%% deines Tageslimits erreicht.", used * 100),
            kind: .highSpendingToday,
            delay: 3600,
            priority: 75
        ), center: center)
    }
}
