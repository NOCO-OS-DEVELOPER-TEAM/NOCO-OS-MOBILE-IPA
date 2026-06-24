import Foundation
import SwiftUI
import Combine

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
#endif

@MainActor
final class ScreenTimeManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authError: String?
    @Published var blockedAppCount = 0
    @Published var shieldsActive = false

    #if canImport(FamilyControls)
    @Published var selection = FamilyActivitySelection()
    #endif

    func bootstrap() async {
        await requestAuthorization()
        await NotificationManager.shared.requestPermission()
        #if canImport(FamilyControls)
        loadSelection()
        ShieldRelockHelper.syncUnlockStateIfExpired()
        restoreUnlockCountdownIfNeeded()
        if isAuthorized && !TimePaySharedStorage.isUnlocked {
            applyShield()
        }
        #endif
    }

    func requestAuthorization() async {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            if !isAuthorized {
                authError = "Bildschirmzeit-Zugriff nicht erlaubt. Ohne diese Berechtigung kann TimePay Apps nicht sperren."
            } else {
                authError = nil
                if !TimePaySharedStorage.isUnlocked {
                    applyShield()
                }
            }
        } catch {
            authError = error.localizedDescription
            isAuthorized = false
        }
        #else
        authError = "Screen Time API nicht verfügbar."
        #endif
    }

    func temporaryUnlock(minutes: Int) {
        #if canImport(FamilyControls)
        guard isAuthorized, minutes > 0 else { return }

        let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        TimePaySharedStorage.isUnlocked = true
        TimePaySharedStorage.unlockUntilDate = endDate

        ShieldRelockHelper.clearShields()
        shieldsActive = false

        DeviceActivityScheduler.scheduleRelock(at: endDate)
        NotificationManager.shared.scheduleRelockNotification(afterSeconds: minutes * 60)
        #endif
    }

    func relock() {
        #if canImport(FamilyControls)
        DeviceActivityScheduler.cancelRelockSchedule()
        NotificationManager.shared.cancelUnlockNotifications()
        ShieldRelockHelper.relockAll()
        shieldsActive = blockedAppCount > 0
        #endif
    }

    #if canImport(FamilyControls)
    func updateSelection(_ newValue: FamilyActivitySelection) {
        selection = newValue
        blockedAppCount = selection.applicationTokens.count + selection.categoryTokens.count
        ShieldRelockHelper.saveSelection(selection)
        if !TimePaySharedStorage.isUnlocked {
            applyShield()
        }
    }

    func applyShield() {
        guard isAuthorized else { return }
        ShieldRelockHelper.applyShield(selection: selection)
        shieldsActive = blockedAppCount > 0
    }

    private func loadSelection() {
        if let decoded = ShieldRelockHelper.loadSelection() {
            selection = decoded
            blockedAppCount = selection.applicationTokens.count + selection.categoryTokens.count
        }
    }

    private func restoreUnlockCountdownIfNeeded() {
        guard TimePaySharedStorage.isUnlocked else { return }
        let remaining = TimePaySharedStorage.remainingUnlockSeconds()
        if remaining <= 0 {
            relock()
            NotificationManager.shared.postRelockNotificationNow()
        }
    }
    #endif
}
