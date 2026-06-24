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
    @Published var showSideloadHelp = false

    let sideloadHelpSteps = """
    SideStore / Sideload — Bildschirmzeit aktivieren:

    1. Neuen Build installieren (NEUER BUILD.bat → IPA in SideStore).
    2. In SideStore beim Signieren die Entitlements aus sidestore-entitlements/ nutzen (Family Controls).
    3. iOS: Einstellungen → Bildschirmzeit → Apps mit Bildschirmzeit-Zugriff → TimePay aktivieren.

    Hinweis: In den TimePay-App-Einstellungen gibt es keinen Bildschirmzeit-Schalter — das ist normal bei Sideload-Apps.
    Die gelbe Meldung „Kommunikation mit der Hilfe-App“ bedeutet meist: Erweiterungen sind nicht korrekt signiert.
    """

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
            noteFamilyControlsUnavailable()
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
            authError = "Bildschirmzeit blockiert. iOS: Einstellungen → Bildschirmzeit → Apps mit Bildschirmzeit-Zugriff → TimePay erlauben."
            showSideloadHelp = true
        case .notDetermined:
            authError = "Tippe „Berechtigung erteilen“ — nicht die normalen App-Einstellungen (dort gibt es keinen Schalter)."
        @unknown default:
            authError = "Bildschirmzeit-Status unbekannt. Bitte erneut erlauben."
        }
        #endif
    }

    func noteFamilyControlsUnavailable() {
        showSideloadHelp = true
        if authError == nil {
            authError = "Bildschirmzeit-Erweiterungen nicht erreichbar. Siehe SideStore-Hilfe unten."
        }
    }

    func noteAppPickerIssue() {
        guard isAuthorized, blockedAppCount == 0 else { return }
        showSideloadHelp = true
        authError = "App-Auswahl fehlgeschlagen? Meist fehlt Family-Controls beim SideStore-Signieren."
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
        LiveActivityManager.endAll()
        #endif
    }

    #if canImport(FamilyControls)
    func updateSelection(_ newValue: FamilyActivitySelection) {
        selection = newValue
        blockedAppCount = selection.applicationTokens.count + selection.categoryTokens.count
        ShieldRelockHelper.saveSelection(selection)
        TimePaySharedStorage.defaults?.set(blockedAppCount, forKey: TimePayKeys.widgetBlockedCount)
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
            TimePaySharedStorage.defaults?.set(blockedAppCount, forKey: TimePayKeys.widgetBlockedCount)
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
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                let status = AuthorizationCenter.shared.authorizationStatus
                let approved = status == .approved
                if approved != isAuthorized {
                    isAuthorized = approved
                    if approved {
                        authError = nil
                        loadSelection()
                        updateNeedsAppSelection()
                        if !TimePaySharedStorage.isUnlocked {
                            applyShield()
                        }
                    } else if status == .denied {
                        authError = "Bildschirmzeit blockiert. iOS: Einstellungen → Bildschirmzeit → Apps mit Bildschirmzeit-Zugriff."
                        showSideloadHelp = true
                    }
                }
            }
        }
    }
    #endif
}
