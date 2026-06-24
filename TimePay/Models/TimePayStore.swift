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
    @Published var balanceMinutes: Int {
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
    @Published var showUnlockSheet = false
    @Published var showEarnSheet = false
    @Published var toastMessage: String?

    @Published var earnedToday: Int = 0
    @Published var spentToday: Int = 0
    @Published var streakDays: Int = 0

    private var earnTimer: Timer?
    private var unlockTimer: Timer?
    private let balanceKey = TimePayKeys.balanceKey

    /// True wenn Freigabe oder Focus-Session läuft — kein Buchen möglich.
    var isSessionActive: Bool {
        isEarningSessionActive || unlockSessionRemaining > 0
    }

    var canBookTime: Bool { !isSessionActive }

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
        "\(balanceMinutes) Min"
    }

    var unlockProgress: Double {
        guard unlockSessionTotal > 0 else { return 0 }
        return 1 - Double(unlockSessionRemaining) / Double(unlockSessionTotal)
    }

    var earnProgress: Double {
        guard earnSessionTotal > 0 else { return 0 }
        return 1 - Double(earnSessionRemaining) / Double(earnSessionTotal)
    }

    init() {
        let saved = TimePaySharedStorage.defaults?.integer(forKey: balanceKey) ?? 0
        balanceMinutes = saved > 0 ? saved : 20
        unlockSessionRemaining = TimePaySharedStorage.remainingUnlockSeconds()
        if unlockSessionRemaining > 0 {
            unlockSessionTotal = unlockSessionRemaining
        }
        loadStats()
        refreshStreak()
        syncWidgetData()
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

    func applySpendPreset(_ minutes: Int) {
        guard canBookTime else { return }
        spendMinutes = Double(min(minutes, balanceMinutes))
    }

    func confirmUnlock(onUnlock: @escaping (Int) -> Void, onRelock: @escaping () -> Void) {
        guard canBookTime else {
            toast("Session läuft — kein Abbuchen möglich.")
            return
        }
        let minutes = Int(spendMinutes.rounded())
        guard minutes > 0, minutes <= balanceMinutes else {
            toast("Nicht genug Zeit auf dem Konto.")
            return
        }
        balanceMinutes -= minutes
        recordSpent(minutes)
        unlockSessionRemaining = minutes * 60
        unlockSessionTotal = minutes * 60
        toast("Apps für \(minutes) Min freigeschaltet.")
        NotificationManager.shared.notifyUnlockStarted(minutes: minutes)
        if balanceMinutes <= 5 && balanceMinutes > 0 {
            NotificationManager.shared.notifyLowBalance(remaining: balanceMinutes)
        }
        onUnlock(minutes)
        LiveActivityManager.startUnlock(totalSeconds: minutes * 60)
        startUnlockCountdown(onRelock: onRelock)
        showUnlockSheet = false
    }

    func startEarnSession() {
        guard canBookTime else {
            toast("Session läuft — kein Gutschreiben möglich.")
            return
        }
        let target = Int(earnMinutes.rounded())
        guard target > 0 else { return }
        isEarningSessionActive = true
        earnSessionRemaining = target * 60
        earnSessionTotal = target * 60
        earnTimer?.invalidate()
        earnTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickEarn()
            }
        }
        NotificationManager.shared.notifyEarnStarted(task: selectedTask.title, minutes: target)
        LiveActivityManager.startEarn(title: selectedTask.title, totalSeconds: target * 60)
        showEarnSheet = false
    }

    func cancelEarnSession() {
        earnTimer?.invalidate()
        isEarningSessionActive = false
        earnSessionRemaining = 0
        earnSessionTotal = 0
        NotificationManager.shared.notifyEarnCancelled()
        LiveActivityManager.endAll()
        toast("Session abgebrochen — keine Gutschrift.")
    }

    func resumeUnlockTimerIfNeeded(onRelock: @escaping () -> Void) {
        unlockSessionRemaining = TimePaySharedStorage.remainingUnlockSeconds()
        guard unlockSessionRemaining > 0 else { return }
        if unlockSessionTotal == 0 {
            unlockSessionTotal = unlockSessionRemaining
        }
        LiveActivityManager.startUnlock(totalSeconds: unlockSessionRemaining)
        startUnlockCountdown(onRelock: onRelock)
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

    private func tickEarn() {
        guard earnSessionRemaining > 0 else { return }
        earnSessionRemaining -= 1
        LiveActivityManager.update(
            remainingSeconds: earnSessionRemaining,
            title: selectedTask.title,
            kind: "earn"
        )
        syncWidgetData()
        if earnSessionRemaining == 0 {
            let earned = Int(earnMinutes.rounded())
            balanceMinutes += earned
            recordEarned(earned)
            isEarningSessionActive = false
            earnSessionTotal = 0
            earnTimer?.invalidate()
            toast("+\(earned) Min gutgeschrieben!")
            NotificationManager.shared.notifyEarnComplete(minutes: earned)
            LiveActivityManager.endAll()
            refreshStreak()
        }
    }

    private func startUnlockCountdown(onRelock: @escaping () -> Void) {
        unlockTimer?.invalidate()
        unlockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.unlockSessionRemaining = TimePaySharedStorage.remainingUnlockSeconds()
                if self.unlockSessionRemaining > 0 {
                    LiveActivityManager.update(
                        remainingSeconds: self.unlockSessionRemaining,
                        title: "Apps freigeschaltet",
                        kind: "unlock"
                    )
                    self.syncWidgetData()
                    return
                }
                self.unlockTimer?.invalidate()
                self.unlockSessionTotal = 0
                LiveActivityManager.endAll()
                self.toast("Zeit abgelaufen — Apps wieder gesperrt.")
                NotificationManager.shared.postRelockNotificationNow()
                onRelock()
            }
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
        TimePaySharedStorage.defaults?.set(balanceMinutes, forKey: balanceKey)
        syncWidgetData()
    }

    func syncWidgetData() {
        let kind: String
        let remaining: Int
        let title: String
        if unlockSessionRemaining > 0 {
            kind = "unlock"
            remaining = unlockSessionRemaining
            title = "Freigabe aktiv"
        } else if isEarningSessionActive {
            kind = "earn"
            remaining = earnSessionRemaining
            title = selectedTask.title
        } else {
            kind = "none"
            remaining = 0
            title = ""
        }
        let blocked = TimePaySharedStorage.defaults?.integer(forKey: TimePayKeys.widgetBlockedCount) ?? 0
        TimePaySharedStorage.syncWidgetSnapshot(
            balance: balanceMinutes,
            streak: streakDays,
            blockedCount: blocked,
            sessionKind: kind,
            sessionRemaining: remaining,
            sessionTitle: title
        )
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
