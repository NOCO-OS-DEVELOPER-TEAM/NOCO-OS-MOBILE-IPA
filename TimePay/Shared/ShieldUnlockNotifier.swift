import Foundation
import UserNotifications

enum ShieldUnlockNotifier {
  static func requestUnlockFromShield() {
    TimePaySharedStorage.defaults?.set(true, forKey: TimePayKeys.pendingUnlock)

    let content = UNMutableNotificationContent()
    content.title = "TimePay"
    content.body = "Tippe hier, um Zeit freizuschalten."
    content.sound = .default
    content.userInfo = [TimePayKeys.notificationActionKey: TimePayKeys.shieldUnlockAction]

    let request = UNNotificationRequest(
      identifier: TimePayKeys.shieldUnlockTapID,
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
  }
}
