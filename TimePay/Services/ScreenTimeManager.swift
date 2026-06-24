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
    @Published var needsAppSelection = false

    #if canImport(FamilyControls)
    @Published var selection = FamilyActivitySelection()
    private var authorizationObserver: Task<Void, Never>?
    #endif

    func bootstrap() async {
        #if canImport(FamilyControls)
        refreshAuthorizationStatus()
        startAuthorizationObserver()
        if AuthorizationCenter.shared.authorizationStatus == .notDetermined {
            await requestAuthorization()
        }
        #endif
        await NotificationManager.shared.requestPermission()
        #if canImport(FamilyControls)
        loadSelection()
        updateNeedsAppSelection()
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
            refreshAuthorizationStatus()
            if isAuthorized {
                loadSelection()
                updateNeedsAppSelection()
                if !TimePaySharedStorage.isUnlocked {
                    applyShield()
                }
            }
        } catch {
            authError = "Bildschirmzeit-Freigabe fehlgeschlagen: \(error.localizedDescription)"
            isAuthorized = false
        }
        #else
        authError = "Screen Time API nicht verfuegbar."
        #endif
    }

    func refreshAuthorizationStatus() {
        #if canImport(FamilyControls)
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = status == .approved
        switch status {
        case .approved:
            authError = nil
        case .denied:
            authError = "Bildschirmzeit blockiert. Einstellungen → Bildschirmzeit → App- und Website-Beschraenkungen → TimePay erlauben."
        case .notDetermined:
            authError = "TimePay braucht die Bildschirmzeit-Berechtigung, um Apps zu sperren."
        @unknown default:
            authError = "Bildschirmzeit-Status unbekannt. Bitte erneut erlauben."
        }
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
        updateNeedsAppSelection()
        if !TimePaySharedStorage.isUnlocked {
            applyShield()
        }
    }

    func applyShield() {
        guard isAuthorized else { return }
        guard blockedAppCount > 0 else {
            shieldsActive = false
            return
        }
        ShieldRelockHelper.applyShield(selection: selection)
        shieldsActive = true
    }

    private func loadSelection() {
        if let decoded = ShieldRelockHelper.loadSelection() {
            selection = decoded
            blockedAppCount = selection.applicationTokens.count + selection.categoryTokens.count
        }
    }

    private func updateNeedsAppSelection() {
        needsAppSelection = isAuthorized && blockedAppCount == 0
    }

    private func restoreUnlockCountdownIfNeeded() {
        guard TimePaySharedStorage.isUnlocked else { return }
        let remaining = TimePaySharedStorage.remainingUnlockSeconds()
        if remaining <= 0 {
            relock()
            NotificationManager.shared.postRelockNotificationNow()
        }
    }

    private func startAuthorizationObserver() {
        authorizationObserver?.cancel()
        authorizationObserver = Task {
            for await status in AuthorizationCenter.shared.authorizationStatusUpdates {
                guard !Task.isCancelled else { return }
                isAuthorized = status == .approved
                if isAuthorized {
                    authError = nil
                    loadSelection()
                    updateNeedsAppSelection()
                    if !TimePaySharedStorage.isUnlocked {
                        applyShield()
                    }
                } else if status == .denied {
                    authError = "Bildschirmzeit blockiert. Bitte in den iOS-Einstellungen erlauben."
                }
            }
        }
    }
    #endif
}
