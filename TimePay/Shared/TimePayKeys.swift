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
    static let balanceKey = "timepay.balance"
    static let widgetSessionKind = "timepay.widget.sessionKind"
    static let widgetSessionRemaining = "timepay.widget.sessionRemaining"
    static let widgetSessionTitle = "timepay.widget.sessionTitle"
    static let widgetSessionEndTimestamp = "timepay.widget.sessionEnd"
    static let widgetStreakDays = "timepay.widget.streak"
    static let widgetBlockedCount = "timepay.widget.blockedCount"
    static let widgetBalanceHalfMinutes = "timepay.widget.balanceHalfMinutes"
    static let protectedAppsKey = "timepay.protectedApps"
    static let shortcutSetupCompletedKey = "timepay.shortcutSetupDone"
    static let pendingShortcutAppKey = "timepay.pendingShortcutApp"
    static let hapticsEnabledKey = "timepay.settings.haptics"
    static let defaultUnlockMinutesKey = "timepay.settings.defaultMinutes"
    static let hasSeenOnboardingKey = "timepay.onboarding.seen"
    static let shortcutImportedKey = "timepay.setup.shortcutImported"
    static let automationConfirmedKey = "timepay.setup.automationConfirmed"
    static let balanceHalfMinutesKey = "timepay.balance.halfMinutes"
    static let pendingEndUnlockKey = "timepay.pendingEndUnlock"
    static let unlockBookedHalfKey = "timepay.unlock.bookedHalf"
    static let unlockSessionTotalKey = "timepay.unlock.sessionTotal"
    static let pendingDeepLinkKey = "timepay.pendingDeepLink"
    static let earnSessionEndKey = "timepay.earn.end"
    static let earnSessionTotalKey = "timepay.earn.total"
    static let earnTaskIdKey = "timepay.earn.taskId"
    static let earnMinutesTargetKey = "timepay.earn.minutesTarget"
    static let earnSessionActiveKey = "timepay.earn.active"
    static let widgetSessionTotal = "timepay.widget.sessionTotal"
    static let widgetLastSyncKey = "timepay.widget.lastSync"
}

enum TimePaySharedStorage {
    static func storageTargets() -> [UserDefaults] {
        var targets: [UserDefaults] = []
        if let group = UserDefaults(suiteName: TimePayKeys.appGroup) {
            targets.append(group)
        }
        if !targets.contains(where: { $0 === UserDefaults.standard }) {
            targets.append(.standard)
        }
        return targets
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: TimePayKeys.appGroup) ?? .standard
    }

    static func queuePendingDeepLink(_ action: String) {
        for d in storageTargets() {
            d.set(action, forKey: TimePayKeys.pendingDeepLinkKey)
        }
    }

    static func takePendingDeepLink() -> String? {
        for d in storageTargets() {
            guard let action = d.string(forKey: TimePayKeys.pendingDeepLinkKey), !action.isEmpty else { continue }
            for target in storageTargets() {
                target.removeObject(forKey: TimePayKeys.pendingDeepLinkKey)
            }
            return action
        }
        return nil
    }

    static func queuePendingEndUnlock() {
        for d in storageTargets() {
            d.set(true, forKey: TimePayKeys.pendingEndUnlockKey)
        }
    }

    static func takePendingEndUnlock() -> Bool {
        for d in storageTargets() {
            guard d.bool(forKey: TimePayKeys.pendingEndUnlockKey) else { continue }
            for target in storageTargets() {
                target.set(false, forKey: TimePayKeys.pendingEndUnlockKey)
            }
            return true
        }
        return false
    }

    static func takePendingEndUnlock() -> Bool {
        for d in storageTargets() {
            guard d.bool(forKey: TimePayKeys.pendingEndUnlockKey) else { continue }
            for target in storageTargets() {
                target.set(false, forKey: TimePayKeys.pendingEndUnlockKey)
            }
            return true
        }
        return false
    }

    static func unlockUntilTimestamp() -> TimeInterval {
        var best: TimeInterval = 0
        for d in storageTargets() {
            let ts = d.double(forKey: TimePayKeys.unlockUntil)
            if ts > best { best = ts }
        }
        return best
    }

    static func hasAnyUnlockState() -> Bool {
        storageTargets().contains { d in
            d.double(forKey: TimePayKeys.unlockUntil) > 0 || d.bool(forKey: TimePayKeys.isUnlocked)
        }
    }

    static func setUnlockUntil(_ date: Date?) {
        for d in storageTargets() {
            if let date {
                d.set(date.timeIntervalSince1970, forKey: TimePayKeys.unlockUntil)
                d.set(true, forKey: TimePayKeys.isUnlocked)
            } else {
                d.removeObject(forKey: TimePayKeys.unlockUntil)
                d.set(false, forKey: TimePayKeys.isUnlocked)
            }
        }
    }

    static func setPendingAppName(_ name: String) {
        for d in storageTargets() {
            d.set(name, forKey: TimePayKeys.pendingShortcutAppKey)
        }
    }

    static func takePendingAppName() -> String? {
        for d in storageTargets() {
            guard let name = d.string(forKey: TimePayKeys.pendingShortcutAppKey), !name.isEmpty else { continue }
            for target in storageTargets() {
                target.removeObject(forKey: TimePayKeys.pendingShortcutAppKey)
            }
            return name
        }
        return nil
    }

    static var unlockUntilDate: Date? {
        get {
            let ts = unlockUntilTimestamp()
            return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        }
        set {
            setUnlockUntil(newValue)
        }
    }

    static var isUnlocked: Bool {
        get { remainingUnlockSeconds() > 0 }
        set {
            if newValue, unlockUntilDate == nil {
                setUnlockUntil(Date().addingTimeInterval(60))
            } else if !newValue {
                setUnlockUntil(nil)
            }
        }
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
        return "Tippe „Mehr Zeit“ — Benachrichtigung antippen — TimePay öffnet sich zum Freischalten."
    }

    static func syncWidgetSnapshot(
        balance: Int,
        balanceHalfMinutes: Int,
        streak: Int,
        blockedCount: Int,
        sessionKind: String,
        sessionRemaining: Int,
        sessionTitle: String,
        sessionEndTimestamp: TimeInterval,
        sessionTotalSeconds: Int = 0
    ) {
        let now = Date().timeIntervalSince1970
        for d in storageTargets() {
            d.set(balance, forKey: TimePayKeys.balanceKey)
            d.set(balanceHalfMinutes, forKey: TimePayKeys.widgetBalanceHalfMinutes)
            d.set(balanceHalfMinutes, forKey: TimePayKeys.balanceHalfMinutesKey)
            d.set(streak, forKey: TimePayKeys.widgetStreakDays)
            d.set(blockedCount, forKey: TimePayKeys.widgetBlockedCount)
            d.set(sessionKind, forKey: TimePayKeys.widgetSessionKind)
            d.set(sessionRemaining, forKey: TimePayKeys.widgetSessionRemaining)
            d.set(sessionTitle, forKey: TimePayKeys.widgetSessionTitle)
            d.set(sessionEndTimestamp, forKey: TimePayKeys.widgetSessionEndTimestamp)
            d.set(sessionTotalSeconds, forKey: TimePayKeys.widgetSessionTotal)
            d.set(now, forKey: TimePayKeys.widgetLastSyncKey)
        }
    }

    /// Liest Widget-Daten — App Group zuerst, dann Standard-Fallback (Sideload).
    static func widgetSnapshotData() -> UserDefaults? {
        if let group = UserDefaults(suiteName: TimePayKeys.appGroup) {
            let half = group.integer(forKey: TimePayKeys.widgetBalanceHalfMinutes)
            let balanceHalf = group.integer(forKey: TimePayKeys.balanceHalfMinutesKey)
            if half > 0 || balanceHalf > 0 { return group }
        }
        let standard = UserDefaults.standard
        let half = standard.integer(forKey: TimePayKeys.widgetBalanceHalfMinutes)
        let balanceHalf = standard.integer(forKey: TimePayKeys.balanceHalfMinutesKey)
        if half > 0 || balanceHalf > 0 { return standard }
        return UserDefaults(suiteName: TimePayKeys.appGroup) ?? standard
    }
}

enum TimePayFormat {
    static func halfMinutes(_ half: Int) -> String {
        let whole = half / 2
        if half % 2 == 0 {
            return "\(whole) Min"
        }
        return "\(whole),5 Min"
    }

    static func halfMinutesNumber(_ half: Int) -> String {
        let whole = half / 2
        if half % 2 == 0 {
            return "\(whole)"
        }
        return "\(whole),5"
    }
}
