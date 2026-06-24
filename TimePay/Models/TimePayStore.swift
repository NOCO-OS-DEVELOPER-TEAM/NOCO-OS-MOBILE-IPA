import Foundation
import SwiftUI
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

struct ProductiveTask: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let icon: String

    static let defaults: [ProductiveTask] = [
        .init(id: "read", title: "Lesen", icon: "book.fill"),
        .init(id: "learn", title: "Lernen", icon: "brain.head.profile"),
        .init(id: "sport", title: "Sport", icon: "figure.run"),
        .init(id: "meditate", title: "Meditieren", icon: "leaf.fill"),
        .init(id: "walk", title: "Spazieren", icon: "figure.walk"),
        .init(id: "code", title: "Programmieren", icon: "chevron.left.forwardslash.chevron.right"),
        .init(id: "journal", title: "Tagebuch", icon: "pencil.and.list.clipboard"),
    ]
}

@MainActor
final class TimePayStore: ObservableObject {
    @Published var balanceHalfMinutes: Int {
        didSet { persist() }
    }
    @Published var spendMinutes: Double = 5
    @Published var earnMinutes: Double = 10
    @Published var selectedTask: ProductiveTask = ProductiveTask.defaults[0]
    @Published var isEarningSessionActive = false
    @Published var earnSessionRemaining: Int = 0
    @Published var earnSessionTotal: Int = 0
    @Published var unlockSessionRemaining: Int = 0
    @Published var unlockSessionTotal: Int = 0
    @Published var pendingUnlockFromShield = false
    @Published var shortcutRequestedApp: String?
    @Published var showUnlockSheet = false
    @Published var showEarnSheet = false
    @Published var openSetupTab = false
    @Published var toastMessage: String?

    @Published var earnedToday: Int = 0
    @Published var spentToday: Int = 0
    @Published var streakDays: Int = 0
    @Published var earnSessionEndDate: Date?
    @Published var sessionExpiredFlash = false

    private var earnTimer: Timer?
    private var unlockTimer: Timer?
    private var unlockBookedHalfMinutes: Int = 0
    private let balanceKey = TimePayKeys.balanceKey
    private let balanceHalfKey = TimePayKeys.balanceHalfMinutesKey

    /// Ganze Minuten (abgerundet) — für Slider & Schnellwahl.
    var balanceMinutes: Int { max(balanceHalfMinutes / 2, 0) }

    /// True wenn Freigabe oder Focus-Session läuft — kein Buchen möglich.
    var isSessionActive: Bool {
        isEarningSessionActive || unlockSessionRemaining > 0
    }

    var canBookTime: Bool { !isSessionActive }

    var activeSessionEndDate: Date? {
        if unlockSessionRemaining > 0 {
            return TimePaySharedStorage.unlockUntilDate
        }
        if isEarningSessionActive, let end = earnSessionEndDate {
            return end
        }
        return nil
    }

    var activeSessionStartDate: Date? {
        guard let end = activeSessionEndDate else { return nil }
        let total = unlockSessionRemaining > 0 ? unlockSessionTotal : earnSessionTotal
        guard total > 0 else { return nil }
        return end.addingTimeInterval(-TimeInterval(total))
    }

    var sessionStatusText: String {
        if isEarningSessionActive {
            return "Focus-Session läuft — kein Buchen möglich"
        }
        if unlockSessionRemaining > 0 {
            return "Freigabe aktiv — kein Buchen möglich"
        }
        return ""
    }

    var formattedBalance: String {
        TimePayFormat.halfMinutes(balanceHalfMinutes)
    }

    var balanceDisplayNumber: String {
        TimePayFormat.halfMinutesNumber(balanceHalfMinutes)
    }

    init() {
        let defaults = TimePaySharedStorage.defaults
        if defaults?.object(forKey: balanceHalfKey) != nil {
            balanceHalfMinutes = max(defaults?.integer(forKey: balanceHalfKey) ?? 0, 0)
        } else {
            let saved = defaults?.integer(forKey: balanceKey) ?? 0
            balanceHalfMinutes = max((saved > 0 ? saved : 20) * 2, 0)
        }
        unlockSessionRemaining = TimePaySharedStorage.remainingUnlockSeconds()
        if unlockSessionRemaining > 0 {
            let savedBooked = defaults?.integer(forKey: TimePayKeys.unlockBookedHalfKey) ?? 0
            unlockBookedHalfMinutes = savedBooked > 0
                ? savedBooked
                : max((unlockSessionRemaining + 29) / 30, 2)
            unlockSessionTotal = max(
                defaults?.integer(forKey: TimePayKeys.unlockSessionTotalKey) ?? 0,
                unlockSessionRemaining
            )
            if unlockSessionTotal == 0 {
                unlockSessionTotal = unlockBookedHalfMinutes * 30
            }
        }
        loadStats()
        refreshStreak()
        resumeEarnSessionIfNeeded()
        syncWidgetData()
    }

    var unlockProgress: Double {
        guard unlockSessionTotal > 0 else { return 0 }
        return 1 - Double(unlockSessionRemaining) / Double(unlockSessionTotal)
    }

    var earnProgress: Double {
        guard earnSessionTotal > 0 else { return 0 }
        return 1 - Double(earnSessionRemaining) / Double(earnSessionTotal)
    }

    func tryOpenUnlockSheet() {
        guard canBookTime else {
            toast("Session läuft — erst warten, dann buchen.")
            NotificationManager.shared.notifySessionBlocked()
            return
        }
        showUnlockSheet = true
    }

    func tryOpenEarnSheet() {
        guard canBookTime else {
            toast("Session läuft — erst warten, dann buchen.")
            NotificationManager.shared.notifySessionBlocked()
            return
        }
        showEarnSheet = true
    }

    func applySpendPreset(_ minutes: Double) {
        guard canBookTime else { return }
        let maxM = Double(balanceHalfMinutes) / 2.0
        spendMinutes = min(minutes, maxM)
    }

    var maxSpendMinutes: Double {
        max(Double(balanceHalfMinutes) / 2.0, 1)
    }

    func consumePendingDeepLink() {
        GateEngine.syncExpiredUnlock()
        guard let action = TimePaySharedStorage.takePendingDeepLink() else { return }
        switch action {
        case "gate":
            let app = TimePaySharedStorage.takePendingAppName()
            presentBlockSheet(appName: app)
        case "setup":
            openSetupTab = true
        case "unlock":
            tryOpenUnlockSheet()
        case "earn":
            tryOpenEarnSheet()
        case "end":
            endUnlockSessionEarly()
        default:
            break
        }
    }

    func confirmUnlock() {
        guard canBookTime else {
            toast("Session läuft — kein Abbuchen möglich.")
            return
        }
        let costHalf = max(Int((spendMinutes * 2).rounded()), 2)
        guard costHalf <= balanceHalfMinutes else {
            toast("Nicht genug Zeit auf dem Konto.")
            return
        }
        let minutesDisplay = TimePayFormat.halfMinutes(costHalf)
        balanceHalfMinutes -= costHalf
        unlockBookedHalfMinutes = costHalf
        TimePaySharedStorage.defaults?.set(costHalf, forKey: TimePayKeys.unlockBookedHalfKey)
        let wholeMinutes = (costHalf + 1) / 2
        recordSpent(wholeMinutes)
        unlockSessionRemaining = costHalf * 30
        unlockSessionTotal = costHalf * 30
        TimePaySharedStorage.defaults?.set(unlockSessionTotal, forKey: TimePayKeys.unlockSessionTotalKey)
        ShortcutGateManager.openGate(seconds: costHalf * 30)
        shortcutRequestedApp = nil
        toast("Apps für \(minutesDisplay) freigeschaltet.")
        NotificationManager.shared.notifyUnlockStarted(seconds: costHalf * 30)
        if balanceHalfMinutes <= 10 && balanceHalfMinutes > 0 {
            NotificationManager.shared.notifyLowBalance(remaining: balanceMinutes)
        }
        LiveActivityManager.startUnlock(totalSeconds: costHalf * 30)
        startUnlockCountdown()
        syncWidgetData()
        showUnlockSheet = false
    }

    func startEarnSession() {
        guard canBookTime else {
            toast("Session läuft — kein Gutschreiben möglich.")
            return
        }
        let targetHalf = max(Int((earnMinutes * 2).rounded()), 2)
        let targetSeconds = targetHalf * 30
        isEarningSessionActive = true
        earnSessionRemaining = targetSeconds
        earnSessionTotal = targetSeconds
        earnSessionEndDate = Date().addingTimeInterval(TimeInterval(targetSeconds))
        persistEarnSession()
        earnTimer?.invalidate()
        earnTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickEarn()
            }
        }
        let targetWhole = (targetHalf + 1) / 2
        NotificationManager.shared.notifyEarnStarted(task: selectedTask.title, minutes: targetWhole)
        LiveActivityManager.startEarn(
            title: selectedTask.title,
            totalSeconds: targetSeconds,
            endDate: earnSessionEndDate
        )
        syncWidgetData()
        showEarnSheet = false
    }

    func cancelEarnSession() {
        earnTimer?.invalidate()
        isEarningSessionActive = false
        earnSessionRemaining = 0
        earnSessionTotal = 0
        earnSessionEndDate = nil
        clearPersistedEarnSession()
        NotificationManager.shared.notifyEarnCancelled()
        LiveActivityManager.endAll()
        toast("Session abgebrochen — keine Gutschrift.")
    }

    func resumeUnlockTimerIfNeeded() {
        checkPendingEndUnlock()
        unlockSessionRemaining = TimePaySharedStorage.remainingUnlockSeconds()
        guard unlockSessionRemaining > 0 else { return }
        let savedBooked = TimePaySharedStorage.defaults?.integer(forKey: TimePayKeys.unlockBookedHalfKey) ?? 0
        if savedBooked > 0 {
            unlockBookedHalfMinutes = savedBooked
        }
        let savedTotal = TimePaySharedStorage.defaults?.integer(forKey: TimePayKeys.unlockSessionTotalKey) ?? 0
        if savedTotal > 0 {
            unlockSessionTotal = savedTotal
        } else if unlockSessionTotal == 0 {
            unlockSessionTotal = max(unlockBookedHalfMinutes * 30, unlockSessionRemaining)
        }
        LiveActivityManager.syncUnlock(
            remainingSeconds: unlockSessionRemaining,
            totalSeconds: unlockSessionTotal
        )
        startUnlockCountdown()
        syncWidgetData()
    }

    func resumeEarnSessionIfNeeded() {
        let defaults = TimePaySharedStorage.defaults
        guard defaults?.bool(forKey: TimePayKeys.earnSessionActiveKey) == true else { return }
        let endTS = defaults?.double(forKey: TimePayKeys.earnSessionEndKey) ?? 0
        guard endTS > 0 else {
            clearPersistedEarnSession()
            return
        }
        let end = Date(timeIntervalSince1970: endTS)
        let remaining = max(0, Int(end.timeIntervalSinceNow))
        guard remaining > 0 else {
            clearPersistedEarnSession()
            isEarningSessionActive = false
            earnSessionRemaining = 0
            earnSessionTotal = 0
            earnSessionEndDate = nil
            LiveActivityManager.endAll()
            return
        }

        let savedTotal = defaults?.integer(forKey: TimePayKeys.earnSessionTotalKey) ?? 0
        earnSessionTotal = savedTotal > 0 ? savedTotal : remaining
        earnSessionRemaining = remaining
        earnSessionEndDate = end
        earnMinutes = defaults?.double(forKey: TimePayKeys.earnMinutesTargetKey) ?? earnMinutes
        if let taskId = defaults?.string(forKey: TimePayKeys.earnTaskIdKey),
           let task = ProductiveTask.defaults.first(where: { $0.id == taskId }) {
            selectedTask = task
        }

        isEarningSessionActive = true
        earnTimer?.invalidate()
        earnTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickEarn()
            }
        }
        LiveActivityManager.syncEarn(
            title: selectedTask.title,
            remainingSeconds: remaining,
            totalSeconds: earnSessionTotal,
            endDate: end
        )
        syncWidgetData()
    }

    func presentBlockSheet(appName: String?) {
        shortcutRequestedApp = appName
        guard canBookTime else {
            toast("Session läuft — erst warten, dann freischalten.")
            return
        }
        showUnlockSheet = true
    }

    func notifyGateAlreadyOpen() {
        toast("Freigabe läuft — wechsel zurück zur App.")
    }

    /// Legacy-Alias
    func openUnlockFromShortcut(appName: String?) {
        GateEngine.syncExpiredUnlock()
        if GateEngine.isOpen {
            notifyGateAlreadyOpen()
            return
        }
        presentBlockSheet(appName: appName)
    }

    func checkPendingUnlockFromShield() {
        if TimePaySharedStorage.defaults?.bool(forKey: TimePayKeys.pendingUnlock) == true {
            TimePaySharedStorage.defaults?.set(false, forKey: TimePayKeys.pendingUnlock)
            openUnlockFromShield()
        }
    }

    func openUnlockFromShield() {
        TimePaySharedStorage.defaults?.set(false, forKey: TimePayKeys.pendingUnlock)
        if canBookTime {
            pendingUnlockFromShield = true
        } else {
            toast("Session läuft — erst warten, dann freischalten.")
        }
    }

    func checkPendingEndUnlock() {
        guard TimePaySharedStorage.takePendingEndUnlock() else { return }
        endUnlockSessionEarly()
    }

    func endUnlockSessionEarly() {
        guard unlockSessionRemaining > 0 else { return }
        let refundHalf = unlockSessionRemaining / 30

        if refundHalf > 0 {
            balanceHalfMinutes += refundHalf
            let usedHalf = max(0, unlockBookedHalfMinutes - refundHalf)
            let bookedWhole = unlockBookedHalfMinutes / 2
            let usedWhole = usedHalf / 2
            spentToday = max(0, spentToday - bookedWhole + usedWhole)
            persistStats()
        }

        unlockTimer?.invalidate()
        unlockSessionRemaining = 0
        unlockSessionTotal = 0
        unlockBookedHalfMinutes = 0
        TimePaySharedStorage.defaults?.set(0, forKey: TimePayKeys.unlockBookedHalfKey)
        TimePaySharedStorage.defaults?.set(0, forKey: TimePayKeys.unlockSessionTotalKey)
        ShortcutGateManager.closeGate()
        LiveActivityManager.endAll()
        NotificationManager.shared.cancelUnlockNotifications()
        syncWidgetData()

        if refundHalf > 0 {
            toast("Freigabe beendet — \(TimePayFormat.halfMinutes(refundHalf)) zurückerstattet.")
        } else {
            toast("Freigabe beendet.")
        }
    }

    private func tickEarn() {
        if let end = earnSessionEndDate {
            earnSessionRemaining = max(0, Int(end.timeIntervalSinceNow))
        }
        syncWidgetData()
        guard earnSessionRemaining <= 0 else { return }

        let earnedHalf = max(Int((earnMinutes * 2).rounded()), 2)
        balanceHalfMinutes += earnedHalf
        recordEarned((earnedHalf + 1) / 2)
        isEarningSessionActive = false
        earnSessionTotal = 0
        earnSessionEndDate = nil
        clearPersistedEarnSession()
        earnTimer?.invalidate()
        playSessionExpiredAnimation()
        toast("+\(TimePayFormat.halfMinutes(earnedHalf)) gutgeschrieben!")
        NotificationManager.shared.notifyEarnComplete(minutes: (earnedHalf + 1) / 2)
        LiveActivityManager.endAll()
        refreshStreak()
    }

    private func startUnlockCountdown() {
        unlockTimer?.invalidate()
        unlockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.unlockSessionRemaining = TimePaySharedStorage.remainingUnlockSeconds()
                if self.unlockSessionRemaining > 0 {
                    self.syncWidgetData()
                    return
                }
                self.unlockTimer?.invalidate()
                self.unlockSessionTotal = 0
                self.unlockBookedHalfMinutes = 0
                TimePaySharedStorage.defaults?.set(0, forKey: TimePayKeys.unlockBookedHalfKey)
                TimePaySharedStorage.defaults?.set(0, forKey: TimePayKeys.unlockSessionTotalKey)
                LiveActivityManager.endAll()
                ShortcutGateManager.closeGate()
                self.playSessionExpiredAnimation()
                self.toast("Zeit abgelaufen — Gate geschlossen.")
                NotificationManager.shared.postRelockNotificationNow()
            }
        }
    }

    private func playSessionExpiredAnimation() {
        sessionExpiredFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.sessionExpiredFlash = false
        }
    }

    private func recordEarned(_ minutes: Int) {
        earnedToday += minutes
        persistStats()
    }

    private func recordSpent(_ minutes: Int) {
        spentToday += minutes
        persistStats()
    }

    private func loadStats() {
        let defaults = TimePaySharedStorage.defaults
        earnedToday = defaults?.integer(forKey: TimePayKeys.earnedTodayKey) ?? 0
        spentToday = defaults?.integer(forKey: TimePayKeys.spentTodayKey) ?? 0
        streakDays = defaults?.integer(forKey: TimePayKeys.streakDaysKey) ?? 0
        resetStatsIfNewDay()
    }

    private func persistStats() {
        let defaults = TimePaySharedStorage.defaults
        defaults?.set(earnedToday, forKey: TimePayKeys.earnedTodayKey)
        defaults?.set(spentToday, forKey: TimePayKeys.spentTodayKey)
        defaults?.set(streakDays, forKey: TimePayKeys.streakDaysKey)
    }

    private func resetStatsIfNewDay() {
        let today = dayStamp(Date())
        let last = TimePaySharedStorage.defaults?.string(forKey: TimePayKeys.lastActiveDayKey) ?? ""
        if last != today {
            earnedToday = 0
            spentToday = 0
            TimePaySharedStorage.defaults?.set(today, forKey: TimePayKeys.lastActiveDayKey)
            persistStats()
        }
    }

    private func refreshStreak() {
        let today = dayStamp(Date())
        let defaults = TimePaySharedStorage.defaults
        let lastStreak = defaults?.string(forKey: TimePayKeys.lastStreakDayKey) ?? ""
        guard lastStreak != today else { return }

        let yesterday = dayStamp(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if lastStreak == yesterday {
            streakDays += 1
        } else {
            streakDays = 1
        }
        defaults?.set(today, forKey: TimePayKeys.lastStreakDayKey)
        persistStats()
        NotificationManager.shared.notifyStreak(days: streakDays)
    }

    private func dayStamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    func toast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            if self?.toastMessage == message { self?.toastMessage = nil }
        }
    }

    private func persist() {
        TimePaySharedStorage.defaults?.set(balanceHalfMinutes, forKey: balanceHalfKey)
        TimePaySharedStorage.defaults?.set(balanceMinutes, forKey: balanceKey)
        syncWidgetData()
    }

    func syncWidgetData() {
        let kind: String
        let remaining: Int
        let title: String
        let total: Int
        if unlockSessionRemaining > 0 {
            kind = "unlock"
            remaining = unlockSessionRemaining
            title = "Freigabe aktiv"
            total = unlockSessionTotal
        } else if isEarningSessionActive {
            kind = "earn"
            remaining = earnSessionRemaining
            title = selectedTask.title
            total = earnSessionTotal
        } else {
            kind = "none"
            remaining = 0
            title = ""
            total = 0
        }
        let blocked = TimePaySharedStorage.defaults?.integer(forKey: TimePayKeys.widgetBlockedCount) ?? 0
        let endTS = activeSessionEndDate?.timeIntervalSince1970 ?? 0
        TimePaySharedStorage.syncWidgetSnapshot(
            balance: balanceMinutes,
            balanceHalfMinutes: balanceHalfMinutes,
            streak: streakDays,
            blockedCount: blocked,
            sessionKind: kind,
            sessionRemaining: remaining,
            sessionTitle: title,
            sessionEndTimestamp: endTS,
            sessionTotalSeconds: total
        )
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func persistEarnSession() {
        let defaults = TimePaySharedStorage.defaults
        defaults?.set(true, forKey: TimePayKeys.earnSessionActiveKey)
        defaults?.set(earnSessionEndDate?.timeIntervalSince1970 ?? 0, forKey: TimePayKeys.earnSessionEndKey)
        defaults?.set(earnSessionTotal, forKey: TimePayKeys.earnSessionTotalKey)
        defaults?.set(selectedTask.id, forKey: TimePayKeys.earnTaskIdKey)
        defaults?.set(earnMinutes, forKey: TimePayKeys.earnMinutesTargetKey)
    }

    private func clearPersistedEarnSession() {
        let defaults = TimePaySharedStorage.defaults
        defaults?.set(false, forKey: TimePayKeys.earnSessionActiveKey)
        defaults?.removeObject(forKey: TimePayKeys.earnSessionEndKey)
        defaults?.removeObject(forKey: TimePayKeys.earnSessionTotalKey)
        defaults?.removeObject(forKey: TimePayKeys.earnTaskIdKey)
        defaults?.removeObject(forKey: TimePayKeys.earnMinutesTargetKey)
    }
}
