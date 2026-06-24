import Foundation

/// Zentrale Sperr-Logik — ein Timestamp, eine Prüfung, zwei Wege (URL oder App-Aktion).
enum GateEngine {
    static let gateURL = "timepay://gate"

    /// Abgelaufene Freigabe sofort bereinigen (wichtig für Automation im Hintergrund).
    static func syncExpiredUnlock() {
        guard TimePaySharedStorage.remainingUnlockSeconds() <= 0 else { return }
        if TimePaySharedStorage.hasAnyUnlockState() {
            closeUnlock()
        }
    }

    /// Freigabe aktiv? Nur der End-Zeitstempel zählt.
    static var isOpen: Bool {
        syncExpiredUnlock()
        return TimePaySharedStorage.remainingUnlockSeconds() > 0
    }

    static var remainingSeconds: Int {
        syncExpiredUnlock()
        return TimePaySharedStorage.remainingUnlockSeconds()
    }

    static func grantUnlock(seconds: Int) {
        guard seconds > 0 else { return }
        let end = Date().addingTimeInterval(TimeInterval(seconds))
        TimePaySharedStorage.setUnlockUntil(end)
    }

    static func closeUnlock() {
        TimePaySharedStorage.setUnlockUntil(nil)
    }

    /// Automation / Intent: TimePay soll sich öffnen und ggf. Abbuchen anbieten.
    static func requestBlock(appName: String? = nil) {
        syncExpiredUnlock()
        guard !isOpen else { return }
        TimePaySharedStorage.queuePendingDeepLink("gate")
        if let appName, !appName.isEmpty {
            TimePaySharedStorage.setPendingAppName(appName)
        }
    }

    /// Deep-Link aus Automation (URL öffnen → timepay://gate).
    @MainActor
    static func handleGateURL(_ url: URL, store: TimePayStore) {
        guard url.scheme == "timepay" else { return }
        guard ["gate", "unlock", "block"].contains(url.host) else { return }

        let app = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "app" })?
            .value?
            .removingPercentEncoding

        syncExpiredUnlock()
        if isOpen {
            store.notifyGateAlreadyOpen()
            return
        }
        store.presentBlockSheet(appName: app)
    }
}
