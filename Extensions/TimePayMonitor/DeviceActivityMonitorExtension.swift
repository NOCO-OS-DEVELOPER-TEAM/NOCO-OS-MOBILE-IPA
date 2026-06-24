import DeviceActivity
import FamilyControls
import ManagedSettings
import UserNotifications

final class TimePayDeviceActivityMonitor: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == TimePayActivity.unlockSession else { return }
        ShieldRelockHelper.relockAll()
        postRelockNotification()
    }

    private func postRelockNotification() {
        let content = UNMutableNotificationContent()
        content.title = "TimePay"
        content.body = "Deine Zeit ist abgelaufen. Die App wurde wieder gesperrt."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: TimePayKeys.relockNotificationID,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
