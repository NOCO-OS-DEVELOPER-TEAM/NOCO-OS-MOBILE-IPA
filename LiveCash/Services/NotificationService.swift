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

    func notifyGoalAlert(_ alert: GoalTrackingAlert, store: FinanceStore) {
        guard store.notificationsEnabled else { return }
        guard store.notificationPreferences.goalProgressAlerts || store.appSettings.savings.progressAlerts else { return }
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body
        content.sound = .default
        content.userInfo = ["kind": "goalProgress"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        center.add(UNNotificationRequest(
            identifier: "goal-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        ))
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
        guard store.spendingLimits.enabled else { return }

        if let daily = store.spendingLimits.dailyLimit, daily > 0 {
            let ratio = store.todayExpenses / daily
            if ratio >= 0.5 && ratio < 0.8 {
                schedule(SmartNotificationPayload(
                    id: "limit-daily-50",
                    title: "Tageslimit",
                    body: String(format: "Du hast %.0f%% deines Tageslimits erreicht.", ratio * 100),
                    kind: .highSpendingToday,
                    delay: 300,
                    priority: 70
                ), center: center)
            } else if ratio >= 0.8 && ratio < 1.0 {
                schedule(SmartNotificationPayload(
                    id: "limit-daily-80",
                    title: "Tageslimit — Achtung",
                    body: String(format: "Du hast %.0f%% deines Tageslimits erreicht. Vorsicht!", ratio * 100),
                    kind: .highSpendingToday,
                    delay: 300,
                    priority: 85
                ), center: center)
            }
        }

        if let weekly = store.spendingLimits.weeklyLimit, weekly > 0 {
            let ratio = store.weeklyExpenses / weekly
            if ratio >= 0.5 && ratio < 0.8 {
                schedule(SmartNotificationPayload(
                    id: "limit-weekly-50",
                    title: "Wochenlimit",
                    body: String(format: "%.0f%% deines Wochenlimits erreicht.", ratio * 100),
                    kind: .highSpendingToday,
                    delay: 600,
                    priority: 65
                ), center: center)
            } else if ratio >= 0.8 && ratio < 1.0 {
                schedule(SmartNotificationPayload(
                    id: "limit-weekly-80",
                    title: "Wochenlimit — Achtung",
                    body: String(format: "%.0f%% deines Wochenlimits — fast aufgebraucht!", ratio * 100),
                    kind: .highSpendingToday,
                    delay: 600,
                    priority: 80
                ), center: center)
            }
        }

        if let monthly = store.spendingLimits.monthlyLimit, monthly > 0 {
            let monthSpent = store.transactions(inMonth: Date())
                .filter { $0.type == .expense && !FinanceStore.isGoalContribution($0) }
                .reduce(0) { $0 + $1.amount }
            let ratio = monthSpent / monthly
            if ratio >= 0.5 && ratio < 0.8 {
                schedule(SmartNotificationPayload(
                    id: "limit-monthly-50",
                    title: "Monatslimit",
                    body: String(format: "%.0f%% deines Monatslimits erreicht.", ratio * 100),
                    kind: .highSpendingToday,
                    delay: 900,
                    priority: 60
                ), center: center)
            } else if ratio >= 0.8 && ratio < 1.0 {
                schedule(SmartNotificationPayload(
                    id: "limit-monthly-80",
                    title: "Monatslimit — Achtung",
                    body: String(format: "%.0f%% deines Monatslimits — stark im Limit!", ratio * 100),
                    kind: .highSpendingToday,
                    delay: 900,
                    priority: 78
                ), center: center)
            }
        }
    }
}
