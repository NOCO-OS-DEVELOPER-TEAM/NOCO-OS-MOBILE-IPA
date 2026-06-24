import Foundation

#if canImport(DeviceActivity)
import DeviceActivity

enum TimePayActivity {
    static let unlockSession = DeviceActivityName("timepay.unlock")
}
#endif

enum TimePayKeys {
    static let appGroup = "group.de.noco.timepay"
    static let selectionData = "timepay.selection"
    static let unlockUntil = "timepay.unlockUntil"
    static let isUnlocked = "timepay.isUnlocked"
    static let pendingUnlock = "timepay.pendingUnlock"
    static let shieldStoreName = "timepay"
    static let relockNotificationID = "timepay.relock"
    static let warning5ID = "timepay.warning.5min"
    static let warning1ID = "timepay.warning.1min"
    static let unlockStartedID = "timepay.unlock.started"
    static let earnStartedID = "timepay.earn.started"
    static let earnCompleteID = "timepay.earn.complete"
    static let earnCancelledID = "timepay.earn.cancelled"
    static let lowBalanceID = "timepay.balance.low"
    static let streakID = "timepay.streak"
    static let sessionBlockedID = "timepay.session.blocked"
    static let shieldUnlockTapID = "timepay.shield.unlock.tap"
    static let notificationActionKey = "timepay.action"
    static let shieldUnlockAction = "shield-unlock"
    static let earnedTodayKey = "timepay.stats.earnedToday"
    static let spentTodayKey = "timepay.stats.spentToday"
    static let streakDaysKey = "timepay.stats.streak"
    static let lastActiveDayKey = "timepay.stats.lastDay"
    static let lastStreakDayKey = "timepay.stats.lastStreakDay"
}

enum TimePaySharedStorage {
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: TimePayKeys.appGroup) ?? .standard
    }

    static var unlockUntilDate: Date? {
        get {
            let ts = defaults?.double(forKey: TimePayKeys.unlockUntil) ?? 0
            return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        }
        set {
            if let newValue {
                defaults?.set(newValue.timeIntervalSince1970, forKey: TimePayKeys.unlockUntil)
            } else {
                defaults?.removeObject(forKey: TimePayKeys.unlockUntil)
            }
        }
    }

    static var isUnlocked: Bool {
        get { defaults?.bool(forKey: TimePayKeys.isUnlocked) ?? false }
        set { defaults?.set(newValue, forKey: TimePayKeys.isUnlocked) }
    }

    static func remainingUnlockSeconds() -> Int {
        guard let until = unlockUntilDate else { return 0 }
        return max(0, Int(until.timeIntervalSinceNow))
    }

    static func shieldSubtitleText() -> String {
        let remaining = remainingUnlockSeconds()
        if remaining > 0 {
            let m = remaining / 60
            let s = remaining % 60
            return "Freigabe endet in \(m):\(String(format: "%02d", s)) — Zeitkonto nutzen zum Freischalten"
        }
        return "Tippe „Zeit freischalten“ — du erhältst eine Benachrichtigung, um TimePay zu öffnen."
    }
}
