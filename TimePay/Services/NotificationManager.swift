import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    var onShieldUnlockRequested: (() -> Void)?

    private override init() {
        super.init()
    }

    func installDelegate() {
        center.delegate = self
    }

    func requestPermission() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func handleShieldUnlockNotification() {
        onShieldUnlockRequested?()
    }

    // MARK: - Unlock session

    func notifyUnlockStarted(minutes: Int) {
        post(
            id: TimePayKeys.unlockStartedID,
            title: "Apps freigeschaltet",
            body: "Du hast \(minutes) Min ausgegeben — Apps sind jetzt offen."
        )
        scheduleUnlockWarnings(totalSeconds: minutes * 60)
    }

    func scheduleRelockNotification(afterSeconds seconds: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [TimePayKeys.relockNotificationID])
        guard seconds > 0 else { return }
        schedule(
            id: TimePayKeys.relockNotificationID,
            title: "TimePay",
            body: "Deine Zeit ist abgelaufen. Die App wurde wieder gesperrt.",
            afterSeconds: seconds
        )
    }

    func scheduleUnlockWarnings(totalSeconds: Int) {
        center.removePendingNotificationRequests(
            withIdentifiers: [TimePayKeys.warning5ID, TimePayKeys.warning1ID]
        )
        if totalSeconds > 300 {
            schedule(
                id: TimePayKeys.warning5ID,
                title: "Noch 5 Minuten",
                body: "Deine App-Freigabe endet bald. Plane deine Zeit.",
                afterSeconds: totalSeconds - 300
            )
        }
        if totalSeconds > 60 {
            schedule(
                id: TimePayKeys.warning1ID,
                title: "Noch 1 Minute",
                body: "Gleich werden deine Apps wieder gesperrt.",
                afterSeconds: totalSeconds - 60
            )
        }
    }

    func cancelUnlockNotifications() {
        center.removePendingNotificationRequests(
            withIdentifiers: [
                TimePayKeys.relockNotificationID,
                TimePayKeys.warning5ID,
                TimePayKeys.warning1ID,
            ]
        )
    }

    func postRelockNotificationNow() {
        post(
            id: TimePayKeys.relockNotificationID + ".now",
            title: "TimePay",
            body: "Deine Zeit ist abgelaufen. Die App wurde wieder gesperrt."
        )
    }

    // MARK: - Earn session

    func notifyEarnStarted(task: String, minutes: Int) {
        post(
            id: TimePayKeys.earnStartedID,
            title: "Focus-Session gestartet",
            body: "\(task) — in \(minutes) Min erhältst du Zeit auf dein Konto."
        )
    }

    func notifyEarnComplete(minutes: Int) {
        post(
            id: TimePayKeys.earnCompleteID,
            title: "Zeit gutgeschrieben!",
            body: "+\(minutes) Min auf dein Konto. Stark gemacht!"
        )
    }

    func notifyEarnCancelled() {
        post(
            id: TimePayKeys.earnCancelledID,
            title: "Session abgebrochen",
            body: "Keine Zeit gutgeschrieben. Beim nächsten Mal durchhalten!"
        )
    }

    // MARK: - Balance & streak

    func notifyLowBalance(remaining: Int) {
        post(
            id: TimePayKeys.lowBalanceID,
            title: "Zeitkonto fast leer",
            body: "Nur noch \(remaining) Min übrig. Verdiene Zeit mit einer Focus-Session."
        )
    }

    func notifyStreak(days: Int) {
        guard days >= 2 else { return }
        post(
            id: TimePayKeys.streakID,
            title: "\(days)-Tage-Streak!",
            body: "Du bleibst dran — weiter so mit TimePay."
        )
    }

    func notifySessionBlocked() {
        post(
            id: TimePayKeys.sessionBlockedID,
            title: "Session läuft",
            body: "Während eine Session aktiv ist, kannst du kein Zeit buchen."
        )
    }

    // MARK: - Helpers

    private func schedule(id: String, title: String, body: String, afterSeconds: Int) {
        guard afterSeconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterSeconds), repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func post(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard isShieldUnlockNotification(notification) else {
            return [.banner, .sound]
        }
        await MainActor.run {
            handleShieldUnlockNotification()
        }
        return [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard isShieldUnlockNotification(response.notification) else { return }
        await MainActor.run {
            handleShieldUnlockNotification()
        }
    }

    nonisolated private func isShieldUnlockNotification(_ notification: UNNotification) -> Bool {
        notification.request.content.userInfo[TimePayKeys.notificationActionKey] as? String
            == TimePayKeys.shieldUnlockAction
    }
}
